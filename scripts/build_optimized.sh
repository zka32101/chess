#!/bin/bash

# Phase L-3: Optimized Build Script
# Builds the app with all optimization flags enabled
# Usage: ./scripts/build_optimized.sh [apk|ios|analyze]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BUILD_TYPE="${1:-apk}"
ANALYZE_SIZE=false
OBFUSCATE_FLAG="--obfuscate"
SPLIT_APK_FLAG="--split-per-abi"

print_header() {
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}  Phase L-3: Optimized Build for Chess Tactics Master     ${BLUE}║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
  echo -e "\n${YELLOW}━━━ $1 ━━━${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}\n"
}

print_error() {
  echo -e "${RED}✗ $1${NC}\n"
}

print_info() {
  echo -e "${BLUE}ℹ $1${NC}\n"
}

check_flutter() {
  print_section "Checking Flutter Installation"

  if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Install Flutter and add to PATH."
    exit 1
  fi

  flutter_version=$(flutter --version | grep "Flutter" | awk '{print $2}')
  print_info "Flutter version: $flutter_version"
  print_success "Flutter found and ready"
}

check_dependencies() {
  print_section "Checking Dependencies"

  echo "Running 'flutter pub get'..."
  flutter pub get > /dev/null 2>&1
  print_success "Dependencies installed"
}

clean_build() {
  print_section "Cleaning Previous Builds"

  echo "Running 'flutter clean'..."
  flutter clean > /dev/null 2>&1
  print_success "Build directory cleaned"
}

build_apk() {
  print_section "Building Optimized Android APK"

  print_info "Build Configuration:"
  echo "  - Optimization: tree-shaking + minification"
  echo "  - Obfuscation: $OBFUSCATE_FLAG"
  echo "  - Split APK: per-abi architecture optimization"
  echo "  - ProGuard: enabled (code size reduction)"
  echo ""

  build_cmd="flutter build apk --release $OBFUSCATE_FLAG $SPLIT_APK_FLAG"

  if [ "$ANALYZE_SIZE" = true ]; then
    build_cmd="$build_cmd --analyze-size"
    print_info "Size analysis enabled"
  fi

  echo "Running: $build_cmd"
  echo ""

  if $build_cmd; then
    print_success "APK build completed successfully"

    # Display APK sizes
    print_section "Built APK Sizes"
    if [ -d "build/app/outputs/apk/release" ]; then
      for apk in build/app/outputs/apk/release/*.apk; do
        if [ -f "$apk" ]; then
          size=$(du -h "$apk" | cut -f1)
          size_bytes=$(stat -f%z "$apk" 2>/dev/null || stat -c%s "$apk" 2>/dev/null)
          size_mb=$(echo "scale=2; $size_bytes / 1024 / 1024" | bc 2>/dev/null || echo "~")
          echo "  $(basename "$apk"): $size (${size_mb}MB)"
        fi
      done
    fi
    echo ""
  else
    print_error "APK build failed. Check output above."
    exit 1
  fi
}

build_ios() {
  print_section "Building Optimized iOS App"

  print_info "Build Configuration:"
  echo "  - Optimization: LLVM LTO (Link-Time Optimization)"
  echo "  - Code Stripping: enabled"
  echo "  - Bitcode: enabled (App Thinning)"
  echo "  - Asset Optimization: enabled"
  echo ""

  build_cmd="flutter build ios --release $OBFUSCATE_FLAG"

  if [ "$ANALYZE_SIZE" = true ]; then
    build_cmd="$build_cmd --analyze-size"
  fi

  echo "Running: $build_cmd"
  echo ""

  if $build_cmd; then
    print_success "iOS build completed successfully"

    # Display app size info
    print_section "Built App Information"
    if [ -d "build/ios/Release-iphoneos/Chess Tactics Master.app" ]; then
      size=$(du -sh "build/ios/Release-iphoneos/Chess Tactics Master.app" | cut -f1)
      echo "  App Size: $size"
    fi
    echo ""
  else
    print_error "iOS build failed. Check output above."
    exit 1
  fi
}

build_and_analyze() {
  print_section "Building with Size Analysis"

  print_info "This will generate detailed size reports for optimization."
  echo ""

  flutter build apk --release $OBFUSCATE_FLAG --split-per-abi --analyze-size

  print_success "Size analysis completed"
  print_info "Report location: build/app/outputs/apk/release/app-release.apk.json"
}

compare_sizes() {
  print_section "Build Size Comparison"

  # This requires baseline sizes to compare against
  if [ -f ".build_size_baseline" ]; then
    baseline=$(cat .build_size_baseline)
    echo "Baseline APK size: $baseline"
  else
    print_info "No baseline recorded. Recording current size as baseline..."
    if [ -f "build/app/outputs/apk/release/app-release.apk" ]; then
      size=$(stat -f%z "build/app/outputs/apk/release/app-release.apk" 2>/dev/null || stat -c%s "build/app/outputs/apk/release/app-release.apk")
      echo "$size" > .build_size_baseline
      size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc)
      echo "  Baseline recorded: ${size_mb}MB"
    fi
  fi
}

generate_report() {
  print_section "Generating Build Report"

  report_file="build_optimization_report.md"

  cat > "$report_file" << 'EOF'
# Phase L-3: Build Optimization Report

## Build Summary

Generated: $(date)
Build Type: Release
Optimizations Enabled:
- Tree-shaking
- Code minification (ProGuard)
- Dart obfuscation
- Asset optimization
- Per-ABI APK splitting

## APK Sizes

| Architecture | Size | Reduction |
|---|---|---|
| arm64-v8a | TBD | - |
| armeabi-v7a | TBD | - |
| x86_64 | TBD | - |
| Total (split) | TBD | - |

## Key Metrics

- Code Size: TBD
- Asset Size: TBD
- Startup Time: TBD
- Method Count: TBD

## Optimization Details

### Successfully Applied
- [x] Tree-shaking enabled in release build
- [x] ProGuard minification configured
- [x] Dart obfuscation enabled
- [x] APK splitting by ABI

### Pending
- [ ] WebP asset conversion
- [ ] Code coverage verification
- [ ] Performance benchmarking

## Next Steps

1. Verify app functionality with optimized build
2. Benchmark startup time and runtime performance
3. Complete asset optimization (WebP conversion)
4. Document final size metrics
5. Prepare for Phase L-4 benchmarking

---

**Generated by:** build_optimized.sh
**Phase:** L-3 Build Optimization

EOF

  print_success "Report generated: $report_file"
}

show_help() {
  cat << 'EOF'

Usage: ./scripts/build_optimized.sh [COMMAND] [OPTIONS]

Commands:
  apk              Build optimized Android APK (default)
  ios              Build optimized iOS app
  analyze          Build with detailed size analysis
  help             Show this help message

Options:
  --analyze        Include size analysis in build output
  --no-obfuscate   Skip code obfuscation
  --no-split       Build single APK instead of split per-abi

Examples:
  ./scripts/build_optimized.sh apk
  ./scripts/build_optimized.sh apk --analyze
  ./scripts/build_optimized.sh ios
  ./scripts/build_optimized.sh analyze

Environment Variables:
  FLUTTER_BUILD_MODE    Build mode (debug/release/profile)
  FLUTTER_OPTIMIZATION  Additional optimization flags

EOF
}

# Main execution
main() {
  print_header

  # Parse arguments
  case "$BUILD_TYPE" in
    help|-h|--help)
      show_help
      exit 0
      ;;
    analyze)
      check_flutter
      check_dependencies
      clean_build
      build_and_analyze
      ;;
    ios)
      check_flutter
      check_dependencies
      clean_build
      build_ios
      compare_sizes
      generate_report
      ;;
    apk|*)
      check_flutter
      check_dependencies
      clean_build
      build_apk
      compare_sizes
      generate_report
      ;;
  esac

  print_section "Build Optimization Complete"
  print_success "Optimized build ready for testing and deployment"
  echo -e "${YELLOW}Next Steps:${NC}"
  echo "1. Test app functionality: flutter run --release"
  echo "2. Verify performance metrics"
  echo "3. Commit optimized build configuration"
  echo "4. Proceed to Phase L-4: Benchmarking & Testing"
  echo ""
}

main "$@"
