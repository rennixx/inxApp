import 'dart:async';
import '../../core/utils/logger.dart';
import 'gemini_service.dart';

/// API tier with rate limits
enum ApiTier {
  free(
    requestsPerMinute: 15,
    requestsPerDay: 1500,
    name: 'Free',
  ),
  paid(
    requestsPerMinute: 60,
    requestsPerDay: 15000,
    name: 'Paid',
  );

  final int requestsPerMinute;
  final int requestsPerDay;
  final String name;

  const ApiTier({
    required this.requestsPerMinute,
    required this.requestsPerDay,
    required this.name,
  });
}

/// Queued translation request
class QueuedRequest {
  final String id;
  final String text;
  final String targetLanguage;
  final String sourceLanguage;
  final GeminiModel preferredModel;
  final MangaTranslationContext? context;
  final Completer<TranslationResult> completer;
  final int priority; // Higher = more important
  final DateTime queuedAt;

  QueuedRequest({
    required this.id,
    required this.text,
    required this.targetLanguage,
    this.sourceLanguage = 'auto',
    this.preferredModel = GeminiModel.flash,
    this.context,
    required this.completer,
    this.priority = 0,
    DateTime? queuedAt,
  }) : queuedAt = queuedAt ?? DateTime.now();
}

/// API usage statistics
class ApiUsageStats {
  int requestsToday = 0;
  int requestsThisMinute = 0;
  double totalCost = 0.0;
  int cacheHits = 0;
  int cacheMisses = 0;
  final List<DateTime> requestTimestamps = [];
  final Map<String, int> modelUsage = {};
  final Map<String, int> languagePairUsage = {};

  void resetDaily() {
    requestsToday = 0;
    totalCost = 0.0;
  }

  void resetMinute() {
    requestsThisMinute = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'requestsToday': requestsToday,
      'requestsThisMinute': requestsThisMinute,
      'totalCost': totalCost,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'modelUsage': modelUsage,
      'languagePairUsage': languagePairUsage,
    };
  }
}

/// Cost estimation per model
class CostEstimator {
  static const Map<GeminiModel, double> costPer1kTokens = {
    GeminiModel.flash: 0.000075, // $0.075 per 1M tokens
    GeminiModel.pro: 0.0025, // $2.50 per 1M tokens
  };

  static double estimateCost(GeminiModel model, int tokens) {
    final costPerToken = costPer1kTokens[model] ?? 0.0;
    return (tokens / 1000) * costPerToken;
  }

  static int estimateTokens(String text) {
    // Rough estimate: ~4 characters per token
    return (text.length / 4).ceil();
  }
}

/// Request batching manager
class RequestBatcher {
  final int maxBatchSize;
  final int maxWaitTimeMs;
  final List<QueuedRequest> _batch = [];
  Timer? _batchTimer;

  RequestBatcher({
    this.maxBatchSize = 5,
    this.maxWaitTimeMs = 500,
  });

  /// Add request to batch
  Future<List<QueuedRequest>> add(QueuedRequest request) async {
    _batch.add(request);

    // Start batch timer if not running
    _batchTimer ??= Timer(Duration(milliseconds: maxWaitTimeMs), () {
      flush();
    });

    // Flush if batch is full
    if (_batch.length >= maxBatchSize) {
      return flush();
    }

    return [];
  }

  /// Flush current batch
  List<QueuedRequest> flush() {
    _batchTimer?.cancel();
    _batchTimer = null;

    final batch = List<QueuedRequest>.from(_batch);
    _batch.clear();

    return batch;
  }

  /// Cancel pending batch
  void cancel() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _batch.clear();
  }
}

/// Translation API manager with rate limiting and cost optimization
class TranslationApiManager {
  TranslationApiManager._();

  static final List<QueuedRequest> _requestQueue = [];
  static ApiTier _currentTier = ApiTier.free;
  static final ApiUsageStats _stats = ApiUsageStats();
  static Timer? _rateLimitTimer;
  static Timer? _dailyResetTimer;
  static RequestBatcher? _batcher;
  static bool _isProcessing = false;

  /// Initialize the API manager
  static void initialize({
    ApiTier tier = ApiTier.free,
    int batchSize = 5,
    int maxWaitTimeMs = 500,
  }) {
    _currentTier = tier;
    _batcher = RequestBatcher(
      maxBatchSize: batchSize,
      maxWaitTimeMs: maxWaitTimeMs,
    );

    // Start rate limit timer (resets every minute)
    _rateLimitTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _stats.resetMinute();
      _requestTimestampsCleanup();
    });

    // Start daily reset timer
    _dailyResetTimer = Timer.periodic(const Duration(days: 1), (timer) {
      _stats.resetDaily();
    });

    AppLogger.info('API Manager initialized with ${tier.name} tier', tag: 'ApiManager');
  }

  /// Queue a translation request
  static Future<TranslationResult> queueRequest({
    required String text,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    GeminiModel preferredModel = GeminiModel.flash,
    MangaTranslationContext? context,
    int priority = 0,
  }) async {
    final completer = Completer<TranslationResult>();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    final request = QueuedRequest(
      id: requestId,
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
      preferredModel: preferredModel,
      context: context,
      completer: completer,
      priority: priority,
    );

    _requestQueue.add(request);
    _sortQueue();

    AppLogger.info('Queued request $requestId (queue size: ${_requestQueue.length})', tag: 'ApiManager');

    // Start processing if not already running
    if (!_isProcessing) {
      _processQueue();
    }

    return completer.future;
  }

  /// Process the request queue
  static Future<void> _processQueue() async {
    if (_isProcessing || _requestQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    while (_requestQueue.isNotEmpty) {
      // Check rate limits
      if (!canMakeRequest()) {
        AppLogger.info('Rate limit reached, waiting...', tag: 'ApiManager');
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      final request = _requestQueue.removeAt(0);

      try {
        AppLogger.info('Processing request ${request.id}', tag: 'ApiManager');

        final result = await GeminiService.translateText(
          request.text,
          request.targetLanguage,
          sourceLanguage: request.sourceLanguage,
          preferredModel: request.preferredModel,
          context: request.context,
        );

        // Update stats
        _updateStats(result);

        request.completer.complete(result);
      } catch (e) {
        AppLogger.error('Request ${request.id} failed', error: e, tag: 'ApiManager');
        request.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }

  /// Check if we can make a request (rate limiting)
  static bool canMakeRequest() {
    final now = DateTime.now();

    // Check per-minute limit
    if (_stats.requestsThisMinute >= _currentTier.requestsPerMinute) {
      // Check if we're in a new minute
      final recentRequests = _stats.requestTimestamps.where((timestamp) {
        return now.difference(timestamp).inMinutes < 1;
      }).length;

      if (recentRequests >= _currentTier.requestsPerMinute) {
        return false;
      }
    }

    // Check per-day limit
    if (_stats.requestsToday >= _currentTier.requestsPerDay) {
      return false;
    }

    return true;
  }

  /// Update usage statistics
  static void _updateStats(TranslationResult result) {
    _stats.requestsToday++;
    _stats.requestsThisMinute++;
    _stats.requestTimestamps.add(DateTime.now());

    // Track model usage
    final modelName = result.modelUsed.modelName;
    _stats.modelUsage[modelName] = (_stats.modelUsage[modelName] ?? 0) + 1;

    // Update cost estimate
    final estimatedCost = CostEstimator.estimateCost(result.modelUsed, result.tokensUsed);
    _stats.totalCost += estimatedCost;

    AppLogger.info(
      'Request complete: ${result.tokensUsed} tokens, estimated cost: \$${estimatedCost.toStringAsFixed(6)}',
      tag: 'ApiManager',
    );
  }

  /// Sort queue by priority
  static void _sortQueue() {
    _requestQueue.sort((a, b) {
      // First by priority (higher first)
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Then by queue time (older first)
      return a.queuedAt.compareTo(b.queuedAt);
    });
  }

  /// Cleanup old timestamps
  static void _requestTimestampsCleanup() {
    final now = DateTime.now();
    _stats.requestTimestamps.removeWhere((timestamp) {
      return now.difference(timestamp).inMinutes >= 1;
    });
  }

  /// Get current statistics
  static ApiUsageStats getStatistics() {
    return _stats;
  }

  /// Get remaining quota for today
  static int getRemainingDailyQuota() {
    return _currentTier.requestsPerDay - _stats.requestsToday;
  }

  /// Get remaining quota for this minute
  static int getRemainingMinuteQuota() {
    return _currentTier.requestsPerMinute - _stats.requestsThisMinute;
  }

  /// Estimate cost for a request
  static double estimateRequestCost({
    required String text,
    GeminiModel model = GeminiModel.flash,
  }) {
    final tokens = CostEstimator.estimateTokens(text);
    return CostEstimator.estimateCost(model, tokens);
  }

  /// Set API tier
  static void setTier(ApiTier tier) {
    _currentTier = tier;
    AppLogger.info('API tier changed to ${tier.name}', tag: 'ApiManager');
  }

  /// Get current tier
  static ApiTier getTier() {
    return _currentTier;
  }

  /// Clear the queue
  static void clearQueue() {
    for (final request in _requestQueue) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(Exception('Request cancelled'));
      }
    }
    _requestQueue.clear();
    AppLogger.info('Request queue cleared', tag: 'ApiManager');
  }

  /// Reset statistics
  static void resetStatistics() {
    _stats.requestsToday = 0;
    _stats.requestsThisMinute = 0;
    _stats.totalCost = 0.0;
    _stats.cacheHits = 0;
    _stats.cacheMisses = 0;
    _stats.requestTimestamps.clear();
    _stats.modelUsage.clear();
    _stats.languagePairUsage.clear();
    AppLogger.info('Statistics reset', tag: 'ApiManager');
  }

  /// Cleanup resources
  static void dispose() {
    clearQueue();
    _rateLimitTimer?.cancel();
    _dailyResetTimer?.cancel();
    _batcher?.cancel();
    _isProcessing = false;
    AppLogger.info('API Manager disposed', tag: 'ApiManager');
  }

  /// Batch multiple requests
  static Future<List<TranslationResult>> batchRequest({
    required List<Map<String, dynamic>> requests,
    String targetLanguage = 'en',
    String sourceLanguage = 'auto',
    GeminiModel preferredModel = GeminiModel.flash,
    MangaTranslationContext? context,
  }) async {
    final futures = requests.map((req) {
      return queueRequest(
        text: req['text'] as String,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
        preferredModel: preferredModel,
        context: context,
      );
    }).toList();

    return Future.wait(futures);
  }

  /// Smart model selection based on text complexity
  static GeminiModel selectOptimalModel(String text) {
    // Simple heuristic: use pro for complex text
    final wordCount = text.split(RegExp(r'\s+')).length;

    // Use pro for:
    // - Very long text (>100 words)
    // - Text with complex characters (Japanese, Chinese)
    final hasComplexChars = RegExp(r'[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);

    if (wordCount > 100 || hasComplexChars) {
      return GeminiModel.pro;
    }

    return GeminiModel.flash;
  }

  /// Check if text is worth caching
  static bool shouldCache(String text) {
    // Cache if:
    // - More than 10 characters
    // - Not just numbers or punctuation
    if (text.length < 10) return false;

    final hasLetters = RegExp(r'[a-zA-Z\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]').hasMatch(text);
    return hasLetters;
  }

  /// Get recommended tier based on usage
  static ApiTier getRecommendedTier() {
    // If using more than 80% of free tier daily quota, recommend paid
    final usagePercent = _stats.requestsToday / _currentTier.requestsPerDay;

    if (usagePercent > 0.8 && _currentTier == ApiTier.free) {
      return ApiTier.paid;
    }

    return _currentTier;
  }
}
