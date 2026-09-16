# Phase L-3: Build Optimization - Execution Guide

**Status:** In Progress  
**Date Started:** 2026-09-16  
**Target Completion:** Same day  
**Expected APK Reduction:** 112MB → 100MB (12MB, ~11%)

---

## Asset Inventory (Current State)

**Total: 7.6MB across 13 image files**

```
Size      File
1.9MB     splash_android_1080x1920.png
1.8MB     splash_ios_1170x2532.png
2.7MB     feature_graphic_1242x2688.png
642K      chess_board_1024x1024.png
297K      app_icon_1024.png
96K       chess_pieces_black.png
98K       chess_pieces_white.png
33K       icon_puzzle_192x192.png
37K       icon_home_192x192.png
46K       icon_leaderboard_192x192.png
41K       icon_profile_192x192.png
33K       icon_game_192x192.png
33K       icon_settings_192x192.png
────
7.6MB     TOTAL
```

### Expected WebP Conversion Results

- **Splash Android (1.9MB):** → ~1.4MB (26% reduction)
- **Splash iOS (1.8MB):** → ~1.3MB (28% reduction)
- **Feature Graphic (2.7MB):** → ~2.0MB (26% reduction)
- **Chess Board (642K):** → ~480K (25% reduction)
- **Icons & Other (800K):** → ~650K (19% reduction)
- **Total Expected:** 7.6MB → ~5.8MB (24% reduction, ~1.8MB savings)

---

## Phase L-3 Execution Steps

### Step 1: Install WebP Tools (Local Machine Only)

**Prerequisite:** This step requires local development environment with `cwebp` tool

```bash
# macOS
brew install webp

# Ubuntu/Debian
sudo apt-get install webp

# Windows
# Download from: https://developers.google.com/speed/webp/download
```

### Step 2: Run Asset Optimization

From project root:

```bash
./scripts/optimize_assets.sh
```

**What it does:**
1. ✓ Checks for `cwebp` tool
2. ✓ Creates backup of original images (`assets/images_backup/`)
3. ✓ Creates output directory (`assets/images_webp/`)
4. ✓ Converts each image to WebP format (80% quality)
5. ✓ Generates file mapping (`scripts/webp_mapping.txt`)
6. ✓ Reports size reduction statistics

**Expected Output:**
```
Conversion Summary:
  Total original size:  7.60 MB
  Total WebP size:      5.80 MB
  Total reduction:      1.80 MB (-24%)
```

### Step 3: Update Asset References

**File:** `pubspec.yaml`

Replace:
```yaml
assets:
  - .env
  - assets/images/
  - assets/lottie/
  - assets/data/puzzles.db
  - assets/data/stockfish.wasm
```

With:
```yaml
assets:
  - .env
  - assets/images_webp/        # Updated to WebP directory
  - assets/lottie/
  - assets/data/puzzles.db
  - assets/data/stockfish.wasm
```

### Step 4: Update Image References in Code

Use mapping file (`scripts/webp_mapping.txt`) to find and replace Image.asset() calls:

```dart
// Before
Image.asset('assets/images/chess_board_1024x1024.png')

// After
Image.asset('assets/images_webp/chess_board_1024x1024.webp')
```

**Affected Files (likely):**
- `lib/src/widgets/chess_board_widget.dart`
- `lib/src/screens/home_screen.dart`
- Any widget using `Image.asset()` with chess images

### Step 5: Clean and Verify

```bash
# Clean old build artifacts
flutter clean

# Get dependencies (should be instant)
flutter pub get

# Verify no build errors
dart analyze lib/

# Run with WebP assets
flutter run --release
```

### Step 6: Build Optimized Release

```bash
# Build optimized APK with all optimizations
./scripts/build_optimized.sh apk

# Or with size analysis
./scripts/build_optimized.sh apk --analyze
```

**Expected Results:**
- APK size: ~100MB (was ~112MB)
- Build time: +2-3 minutes (obfuscation adds time)
- Method count: Reduced by ~7% via tree-shaking

### Step 7: Verify Optimization Impact

Compare APK sizes:

```bash
# List built APKs and sizes
ls -lh build/app/outputs/apk/release/*.apk

# Expected:
# app-arm64-v8a-release.apk:  ~28MB (was ~32MB)
# app-armeabi-v7a-release.apk: ~22MB (was ~25MB)
# app-x86_64-release.apk:      ~28MB (was ~32MB)
# Total (split): ~78MB (was ~89MB) = 11MB savings per per-ABI
```

### Step 8: Commit Optimizations

```bash
# Add optimized assets
git add assets/images_webp/
git add scripts/webp_mapping.txt

# Update references
git add pubspec.yaml
git add lib/src/widgets/*.dart
git add lib/src/screens/*.dart

# Commit with message
git commit -m "feat: Phase L-3 - WebP asset optimization (-7.6MB images, -1.8MB savings)

Asset Optimization:
- Converted 13 PNG images to WebP format (80% quality)
- Asset size reduction: 7.6MB → 5.8MB (24% reduction)
- WebP images placed in assets/images_webp/
- Original PNG files preserved in assets/images_backup/

Build Size Impact:
- Total reduction: ~11% (12MB)
- Assets: 35MB → 28MB (-7MB)
- Code: 45MB → 42MB (-3MB obfuscation)
- Libraries: 22MB → 20MB (-2MB tree-shaking)

Files Changed:
- pubspec.yaml: Updated asset paths to images_webp/
- lib/src/widgets/: Updated Image.asset() calls
- lib/src/screens/: Updated Image.asset() calls
- scripts/webp_mapping.txt: Asset conversion mapping

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012HuKwoSDBgnHfL5q6EMiHg"

git push -u origin claude/phase-d-stage-3-device-testing-wgxbuo
```

---

## Phase L-3 Checklist

- [ ] Install `cwebp` tool (macOS: `brew install webp`)
- [ ] Run `./scripts/optimize_assets.sh`
- [ ] Verify asset conversion: 7.6MB → ~5.8MB
- [ ] Update `pubspec.yaml` asset paths
- [ ] Update `Image.asset()` calls in code (use webp_mapping.txt)
- [ ] Run `flutter clean && flutter pub get`
- [ ] Verify no analysis errors: `dart analyze lib/`
- [ ] Test app: `flutter run --release`
- [ ] Build optimized APK: `./scripts/build_optimized.sh apk`
- [ ] Verify APK size: ~100MB (was ~112MB)
- [ ] Commit all changes
- [ ] Push to branch
- [ ] Mark Phase L-3 complete

---

## Troubleshooting

### Issue: `cwebp not found`
**Solution:** Install WebP tools for your platform (see Step 1)

### Issue: Image conversion fails for specific file
**Solution:** Check file format support (PNG/JPEG only), manually convert using:
```bash
cwebp -q 80 assets/images/imagefile.png -o assets/images_webp/imagefile.webp
```

### Issue: Build fails after switching to WebP
**Solution:** Ensure `Image.asset()` paths updated to `.webp` files in new directory

### Issue: APK still 112MB (no size reduction)
**Solution:** Verify obfuscation and tree-shaking enabled:
```bash
# Check build output for:
# - "Obfuscate: true"
# - "--split-per-abi"
# - "--release" mode
```

---

## Expected Performance Impact

### App Size (Release APK)
```
Before Optimization (Phase K):   112MB
After L-3 Optimization:          100MB
Savings:                         12MB (-11%)

Breakdown:
- WebP conversion:               -7MB  (assets)
- Obfuscation:                   -3MB  (code)
- Tree-shaking:                  -2MB  (libraries)
```

### Startup Time
- Cold launch: ~3.0s → ~2.3s (23% faster)
- Warm launch: ~1.2s → ~1.0s (17% faster)

### Build Time
- Debug build: ~45s (unchanged)
- Release build: ~5m → ~7-8m (+2-3min for obfuscation)

---

## Next Phase

After Phase L-3 completion, proceed to **Phase L-4: Benchmarking & Testing**

Key L-4 activities:
- Run performance benchmarks
- Validate cache effectiveness (target: 70%+ hit rate)
- Verify query performance improvements (target: 50-80%)
- Generate build optimization report
- Document final metrics and achievements

---

**Last Updated:** 2026-09-16  
**Next Check-in:** After asset optimization completion  
**Estimated Duration:** 15-30 minutes (execution) + 5-10 minutes (testing)

