# How to Test the Translation Bubble

## Current Integration Status: ✅ CORRECTLY INTEGRATED

The translation bubble IS properly integrated in the reader screen at:
- File: [lib/presentation/screens/reader/vertical_reader_screen.dart](lib/presentation/screens/reader/vertical_reader_screen.dart:201-205)
- Lines 201-205

## How to Access the Bubble:

### Step-by-Step:

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Import a manga file first**
   - Go to **Import** tab (bottom navigation)
   - Add a CBZ/ZIP file with manga images
   - Wait for import to complete

3. **Go to Library tab**
   - Tap the **Library** tab (book icon)
   - You should see your imported manga

4. **Open the reader**
   - **Tap on the manga cover**
   - A dialog will appear with manga details
   - **Tap the "Read" button** in the dialog
   - The reader screen will open

5. **Look for the bubble**
   - The bubble should be visible in the **bottom-right area**
   - It's a **purple circle** with a **magic wand icon**
   - It should be **pulsing** (animating)
   - Position: `Offset(20, 100)` = 20px from left, 100px from top

## What the Bubble Should Look Like:

### Default State (Idle):
- Color: Purple (#6C5CE7)
- Icon: Magic wand ⭐
- Animation: Pulsing (scaling 1.0 → 1.15 → 1.0)
- Position: Draggable

### When You Tap It:
- Color: Green (#00B894)
- Icon: Spinning spinner 🔄
- State: Processing

## If the Bubble Doesn't Appear:

### Check 1: Are you in the reader screen?
- Make sure you tapped "Read" in the dialog
- You should see manga images scrolling vertically

### Check 2: Is there content loaded?
- The `_imagePaths` list needs to have images
- Check if you see manga pages

### Check 3: Check the console
```bash
# Run with verbose logging
flutter run --verbose
```

### Quick Test - Force Bubble Visibility:

I've created a test wrapper at [lib/presentation/screens/reader/reader_wrapper.dart](lib/presentation/screens/reader/reader_wrapper.dart)

To use it, modify [library_screen.dart:126](lib/presentation/screens/library_screen.dart:126):
```dart
// Change from:
builder: (context) => VerticalReaderScreen(manga: manga),

// To:
builder: (context) => ReaderWrapper(manga: manga),
```

This will show debug info overlay confirming the bubble state.

## Bubble Features:

✅ **Draggable** - Drag to reposition anywhere on screen
✅ **Animated** - Pulsing when idle, spinning when processing
✅ **Tappable** - Tap to trigger translation
✅ **States** - Idle → Processing → Complete/Error
✅ **Auto-reset** - Returns to idle after completion/error

## Common Issues:

### Issue: "I don't see any manga in library"
**Solution**: Import a manga file first using the Import tab

### Issue: "I tap the manga but nothing happens"
**Solution**: A dialog appears - you need to tap "Read" button in that dialog

### Issue: "I see the reader but no bubble"
**Solution**:
1. Check if images are loaded
2. Check console for errors
3. The bubble should be at position (20, 100) from top-left

## Testing the Tap Action:

When you tap the bubble, it should:
1. Change color to green
2. Show spinning icon
3. Print "Bubble tapped!" in console (with debug wrapper)
4. Try to start translation (will fail without API key - this is expected)

## Need Help?

If you still can't see the bubble:
1. Import a manga file
2. Go to Library
3. Tap manga → Tap "Read" in dialog
4. Look for purple pulsing circle
5. Try dragging around the screen

The bubble is there - it just needs the reader to be open! 😊
