# MODULE 02 — Plymouth Animation Script

**Owner:** Atharva Jadhav  
**Status:** ✅ Complete  
**Folder:** `theme/`  
**File:** `CipherBoot.script`

---

## What This Module Does

The `.script` file is the **brain** of the Plymouth theme. It's written in Plymouth's own scripting language (similar to JavaScript/C) and controls:

- Loading and upscaling half-resolution frames to native screen size
- Loading an optional centered boot signature overlay
- Animation frame advancement via a continuous refresh callback
- Smooth, hybrid progress bar (time-based + system-reported)
- Text and status message rendering
- Password prompt for encrypted disk unlock
- Prompt cleanup and display-manager handoff handling

---

## Plymouth Script Language — Basics

Plymouth uses its own simple scripting language. Key concepts:

### Sprites
A "sprite" is any image displayed on screen:

```plaintext
logo.image = Image("assets/background.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(0);
logo.sprite.SetY(0);
logo.sprite.SetZ(0);  # Z = layer depth (higher = in front)
```

### Image Scaling
Load a smaller image and upscale it to screen size:

```plaintext
raw = Image("assets/frames/frame-0000.png");   # 960×540
scaled = raw.Scale(screen_width, screen_height); # → native res
sprite.SetImage(scaled);
```

### Refresh Callback
Runs continuously at the set refresh rate — used for animation and smooth progress:

```plaintext
Plymouth.SetRefreshRate(15);
Plymouth.SetRefreshFunction(fun () {
    # Advance frame, update progress, etc.
});
```

### Boot Progress
Receives system-reported progress (0.0 to 1.0, but often caps at ~0.5):

```plaintext
Plymouth.SetBootProgressFunction(fun (time, progress) {
    global.target_progress = progress;
});
```

---

## Architecture: `CipherBoot.script`

The script has 11 well-documented sections:

### 1. Screen Setup
- Get screen dimensions
- Load and scale `background.png` to fill the screen

### 2. Zero-Pad Helper
- Plymouth lacks `String.ZeroPad`, so we build filenames with a custom function
- Handles 0-9999 range for frame naming

### 3. Load Animation Frames (Half-Res → Upscaled)
- Load 48 frames from `assets/frames/frame-NNNN.png`
- Each frame is 960×540 — upscaled to screen resolution via `Scale()`
- Upscaling is done once at load time, not every frame

### 4. Boot Signature Overlay
- Loads `signature.png` as a transparent full-screen overlay
- Places it above the rain and below status/password text
- Temporarily hides it while password prompts are displayed

### 5. Progress Bar Setup
- Load `progress_bar_bg.png` and `progress_bar_fg.png`
- Position at bottom-centre of screen

### 6. Refresh Callback (Animation + Smooth Progress)
The core loop runs at 30 refreshes per second, with animation frames advancing every third refresh:

```plaintext
fun refresh_callback() {
    # 1. Advance to next animation frame
    # 2. Increment boot time counter
    # 3. Calculate time-based progress floor (reaches 100% over ~3.5 seconds)
    # 4. Take max of system-reported and time-based progress
    # 5. Smooth interpolation towards target
    # 6. Update progress bar width
}
```

**Why hybrid progress?** systemd often reports progress up to ~0.5 (50%) and then stops before Plymouth quits. Fast restarts can make this more obvious, so the time-based floor reaches 100% during the refresh loop instead of waiting for the quit callback.

### 7. Boot/System Progress Target Setter
- Receives systemd's reported progress
- Clamps progress into the documented `0.0` to `1.0` range
- Stores the highest reported progress; the refresh callback handles the rest

### 8. Message Display
- Renders system messages ("Checking disks...") in cyan text at the bottom

### 9. Password Prompt
- For LUKS-encrypted disk unlock
- Shows prompt text and bullet dots for typed characters

### 10. Normal Display Callback
- Clears LUKS/password prompt sprites after the prompt exits
- Prevents stale prompt state during the next boot phase

### 11. Quit Handler (DM Handoff)
```plaintext
Plymouth.SetQuitFunction(fun () {
    # Complete progress bar to 100%
    # Clear prompt sprites
    # Keep the current visual frame visible for the DM handoff
});
```

**Critical design decision:** The background and animation sprites are not hidden during quit. This gives Plymouth the best chance to retain the final frame until the display manager paints, though exact handoff behavior still depends on the GPU driver, display manager, and distro service ordering.

---

## Checklist

- [x] `theme/CipherBoot.script` created with all 11 sections
- [x] Half-resolution frame upscaling implemented
- [x] Optional boot signature overlay implemented
- [x] Refresh callback at 30fps with 10fps animation cadence
- [x] Hybrid progress bar (time + system, smooth interpolation)
- [x] Quit handler preserves the final frame for the DM transition where supported
- [x] Password prompt functional
- [x] Password prompt cleanup functional
- [x] Message display functional
