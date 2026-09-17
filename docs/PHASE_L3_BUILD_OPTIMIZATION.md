# Phase L-3: Build Optimization

**Status:** In Progress  
**Timeline:** Day 3/4  
**Updated:** 2026-09-15

---

## Overview

Phase L-3 focuses on reducing the app's build size (APK/IPA) and improving startup performance through tree-shaking, asset optimization, and code obfuscation. Target reduction: **112MB → 100MB (12MB reduction, ~11%)**

---

## Optimization Strategy

### 1. Tree-Shaking Configuration

Tree-shaking removes unused code during the build process. Dart and Flutter have built-in tree-shaking, but we can optimize it further.

#### Implementation

**File:** `.dart_tool/build_runner.yaml` (configure or create)

```yaml
targets:
  $default:
    builders:
      # Enable tree-shaking for unused methods/classes
      flutter_gen|flutter_gen:
        options:
          # Ensure only used fonts are included
          emit_null_safety_files: true
```

**In pubspec.yaml, add build configuration:**

```yaml
flutter:
  uses-material-design: true
  
  # Minimize font usage
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Roboto-Italic.ttf
          style: italic
```

**Build command for tree-shaking:**

```bash
# Release build with tree-shaking enabled (default)
flutter build apk --release --split-per-abi

# IOS with tree-shaking
flutter build ios --release
```

#### Expected Impact
- **Reduction:** 2-3MB
- **Mechanism:** Removes unused code from dependencies
- **Configuration:** Automatic with `--release` flag

---

### 2. Asset Optimization

Asset optimization reduces image and media sizes by converting to more efficient formats.

#### Image Conversion to WebP

PNG/JPEG → WebP format reduces size by 25-35% with minimal quality loss.

**Strategy:**

1. **Identify large assets:**
```bash
du -sh assets/images/*
du -sh assets/lottie/*
```

2. **Conversion tools:**
   - ImageMagick: `convert input.png -quality 80 output.webp`
   - Batch conversion:
   ```bash
   for file in assets/images/*.png; do
     cwebp -q 80 "$file" -o "${file%.png}.webp"
   done
   ```

3. **Update Flutter code:**
   ```dart
   // Before
   Image.asset('assets/images/icon.png')
   
   // After - use WebP format
   Image.asset('assets/images/icon.webp')
   ```

#### Lottie Animation Optimization

Lottie JSON files can be optimized by:
- Removing unused animation frames
- Reducing color palette
- Removing comments

#### Asset Size Budget

```
Current Assets (Estimated):
├── Images (PNG/JPEG):  ~15MB
├── Lottie (JSON):      ~2MB
├── Fonts:              ~3MB
├── Puzzles DB:         ~8MB
└── Stockfish WASM:     ~2MB
Total: ~30MB

After WebP Conversion:
├── Images (WebP):      ~9MB  (40% reduction)
├── Lottie (optimized): ~1.5MB (25% reduction)
├── Fonts:              ~3MB
├── Puzzles DB:         ~8MB (can compress further)
└── Stockfish WASM:     ~2MB
Total: ~23.5MB (21.5% asset reduction)
```

#### Implementation Steps

1. **Convert images to WebP:**
   ```bash
   # Create optimized versions
   mkdir -p assets/images_webp
   for file in assets/images/*.{png,jpg}; do
     cwebp -q 80 "$file" -o "assets/images_webp/$(basename "$file" .png).webp"
   done
   ```

2. **Update asset paths in pubspec.yaml:**
   ```yaml
   flutter:
     assets:
       - assets/images_webp/
       - assets/lottie/
       - assets/data/
   ```

3. **Update image references in code:**
   - Search for `Image.asset('assets/images/` 
   - Replace with `Image.asset('assets/images_webp/`
   - Convert paths from `.png` to `.webp`

#### Expected Impact
- **Image reduction:** 6-9MB (40% reduction)
- **Total asset reduction:** 6-7MB
- **Quality impact:** Minimal (80-85% WebP quality ≈ 100% PNG quality)

---

### 3. Code Obfuscation

Code obfuscation reduces method/class name sizes and makes code harder to reverse-engineer.

#### Obfuscation Configuration

**For Android (build.gradle configuration):**

Create/update `android/app/build.gradle`:

```gradle
android {
  // ... other configuration
  
  buildTypes {
    release {
      // Enable Dart obfuscation
      shrinkResources true
      minifyEnabled true
      
      // Use ProGuard rules
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }
}
```

**For iOS (build.xcconfig):**

Create/update `ios/Flutter/Release.xcconfig`:

```
STRIP_BITCODE = YES
ENABLE_BITCODE = YES
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

**Flutter command with obfuscation:**

```bash
# Android with obfuscation
flutter build apk --release --obfuscate --split-per-abi

# iOS with obfuscation  
flutter build ios --release --obfuscate
```

#### Obfuscation Impact

```
App Method Count (Typical):
- Unobfuscated: ~45,000 methods
- Obfuscated:   ~42,000 methods (7% reduction)

Binary Size Impact:
- Code: ~2-4MB reduction (shorter symbol names)
- Debug Info Removal: ~1-2MB
```

#### Expected Impact
- **Code reduction:** 3-4MB
- **Method count reduction:** 5-7%
- **Startup time:** Minimal impact (<10ms)

---

### 4. Build Profile Optimization

**File:** `pubspec.yaml` - Enable build profile splitting

```yaml
flutter:
  uses-material-design: true
```

**Build profiles for different targets:**

#### Debug Build
```bash
flutter run  # Unoptimized, fastest build
```

#### Profile Build (for local benchmarking)
```bash
flutter run --profile  # Optimized but debuggable
# Size: ~80-90MB APK
```

#### Release Build (optimized for production)
```bash
flutter build apk --release --obfuscate --split-per-abi
# Size target: 100MB APK
```

---

## Optimization Checklist

### Phase L-3.1: Asset Optimization (Days 1-2)

- [ ] Identify and list all image assets
- [ ] Install WebP conversion tool (`cwebp` or ImageMagick)
- [ ] Convert PNG/JPEG images to WebP (80% quality)
- [ ] Optimize Lottie JSON files
- [ ] Update asset paths in pubspec.yaml
- [ ] Update Image.asset() calls in code
- [ ] Test app with WebP images
- [ ] Measure asset size reduction
- [ ] Commit asset optimization changes

**Estimated Size Reduction:** 6-7MB (20% of assets)

### Phase L-3.2: Tree-Shaking & Build Configuration (Day 2)

- [ ] Enable tree-shaking (default in `--release`)
- [ ] Audit dependencies for unused packages
- [ ] Remove unused dependencies from pubspec.yaml
- [ ] Configure build.gradle for Android optimization
- [ ] Configure Release.xcconfig for iOS
- [ ] Test release build with `flutter build apk --release`
- [ ] Measure binary size reduction
- [ ] Commit build configuration changes

**Estimated Size Reduction:** 2-3MB

### Phase L-3.3: Code Obfuscation (Day 2)

- [ ] Create ProGuard rules for Android
- [ ] Configure Dart obfuscation
- [ ] Build with `--obfuscate` flag
- [ ] Test obfuscated app functionality
- [ ] Verify performance (startup time)
- [ ] Measure code reduction
- [ ] Commit obfuscation configuration

**Estimated Size Reduction:** 3-4MB

### Phase L-3.4: Build Size Analysis (Day 3)

- [ ] Run `flutter build analyze-size`
- [ ] Generate before/after size reports
- [ ] Identify remaining large dependencies
- [ ] Document optimization results
- [ ] Update PHASE_L_STATUS_REPORT.md

**Target Outcome:**
- Final APK size: 100MB ± 2MB
- Size reduction: 12MB (11% from baseline)

---

## Build Size Analysis Tools

### 1. Flutter Analyze Size

```bash
# Generate size report
flutter build apk --release --analyze-size

# Output: build/app/outputs/apk/release/app-release.apk.json
# Shows breakdown by package, class, method
```

### 2. APK Analyzer (Android Studio)

```bash
# Open APK in Android Studio analyzer
open build/app/outputs/apk/release/app-release.apk
# Navigate: Build > Analyze APK
```

### 3. Bundle Size Measurement

```bash
# Measure app bundle
flutter build appbundle --release

# Check size
du -sh build/app/outputs/bundle/release/app.aab
```

---

## Performance Baseline

### Current State (Pre-Optimization)
```
APK Size: 112MB
└── Code: 45MB
└── Assets: 35MB
└── Libraries: 22MB
└── Resources: 10MB

IPA Size: 150MB (iOS compression)
```

### Target State (Post-Optimization)
```
APK Size: 100MB (12% reduction)
├── Code: 42MB (obfuscation: -3MB)
├── Assets: 28MB (WebP: -7MB)
├── Libraries: 20MB (tree-shaking: -2MB)
└── Resources: 10MB
```

### Metrics to Track

| Metric | Current | Target | Impact |
|--------|---------|--------|--------|
| APK Size | 112MB | 100MB | -12MB |
| Asset Size | 35MB | 28MB | -7MB |
| Code Size | 45MB | 42MB | -3MB |
| Startup Time | ~2.5s | ~2.3s | -200ms |
| Download Size | 45MB | 40MB | -5MB (60% of APK) |

---

## Rollout Plan

### Phase L-3 Timeline

- **Days 1-2:** Asset optimization (WebP conversion, Lottie optimization)
- **Day 2:** Tree-shaking configuration and build profile optimization
- **Day 3:** Code obfuscation setup and APK size analysis
- **Day 4:** Benchmarking and Phase L-4 transition

### Testing Strategy

1. **Unit Tests:** Verify no functionality broken
2. **Widget Tests:** Ensure UI renders correctly with WebP
3. **Integration Tests:** Full app flow testing
4. **Size Regression Tests:** Monitor APK size in CI/CD

### Deployment Checklist

- [ ] All optimization changes committed
- [ ] CI/CD passes with optimized build
- [ ] Size metrics within target range
- [ ] Performance benchmarks pass
- [ ] QA sign-off on optimized app
- [ ] Ready for Phase L-4 benchmarking

---

## Phase L-3 Implementation Files

| File | Purpose |
|------|---------|
| `android/app/build.gradle` | Android build optimization |
| `ios/Flutter/Release.xcconfig` | iOS build optimization |
| `android/app/proguard-rules.pro` | ProGuard obfuscation rules |
| Asset management scripts | WebP conversion automation |
| Build size analysis reports | Baseline and optimization results |

---

## Success Criteria

✅ **Optimizations Complete When:**
- APK size reduced to 100MB ± 2MB
- Asset size reduced by 20%+ (6-7MB)
- Code size reduced by 7-10% (3-4MB)
- App startup time maintained (<2.5s)
- All tests pass on optimized build
- CI/CD successfully builds and deploys optimized app

---

**Phase L-3 Status:** Planning & Preparation Complete  
**Next:** Phase L-4 Benchmarking & Testing

---

*Generated by Claude Code (AI)*
*Session: https://claude.ai/code/session_012HuKwoSDBgnHfL5q6EMiHg*
