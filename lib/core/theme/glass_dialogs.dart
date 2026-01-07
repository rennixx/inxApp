import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'glass_container.dart';

/// Glassmorphic dialog with blur effect
class GlassDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final double? borderRadius;
  final VoidCallback? onDismiss;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.borderRadius,
    this.onDismiss,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? content,
    List<Widget>? actions,
    EdgeInsetsGeometry? contentPadding,
    double? borderRadius,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => GlassDialog(
        title: title,
        content: content,
        actions: actions,
        contentPadding: contentPadding,
        borderRadius: borderRadius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Content
            if (content != null)
              Padding(
                padding: contentPadding ?? EdgeInsets.zero,
                child: content!,
              ),

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Glassmorphic bottom sheet
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? borderRadius;
  final VoidCallback? onDismiss;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.borderRadius,
    this.onDismiss,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? height,
    double? borderRadius,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => GlassBottomSheet(
        height: height,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius ?? 20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius ?? 20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: child,
        ),
      ),
    );
  }
}

/// Glassmorphic confirmation dialog
class GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onConfirm;

  const GlassConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmText,
    this.cancelText,
    this.icon,
    this.iconColor,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    IconData? icon,
    Color? iconColor,
  }) {
    return GlassDialog.show<bool>(
      context: context,
      title: title,
      content: message != null
          ? Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor ?? const Color(0xFF2196F3),
          ),
          child: Text(confirmText ?? 'Confirm'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassDialog(
      title: title,
      content: message != null
          ? Text(
              message!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor ?? const Color(0xFF2196F3),
          ),
          child: Text(confirmText ?? 'Confirm'),
        ),
      ],
    );
  }
}

/// Glassmorphic alert dialog for errors
class GlassErrorDialog extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onDismiss;

  const GlassErrorDialog({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => GlassErrorDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.warning(PhosphorIconsStyle.fill),
                size: 32,
                color: const Color(0xFFF44336),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),

            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Dismiss Button
            ElevatedButton(
              onPressed: onDismiss ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphic snackbar/toast
class GlassSnackBar extends SnackBar {
  GlassSnackBar({
    super.key,
    required String message,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) : super(
          content: Text(message),
          action: action,
          duration: duration,
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        );

  Widget buildGlass(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: content ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
