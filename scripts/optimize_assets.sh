#!/bin/bash

# Phase L-3: Asset Optimization Script
# Converts images to WebP format for size reduction
# Usage: ./scripts/optimize_assets.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WEBP_QUALITY=80
INPUT_DIR="assets/images"
OUTPUT_DIR="assets/images_webp"
BACKUP_DIR="assets/images_backup"

# Functions
print_header() {
  echo -e "${YELLOW}=== Phase L-3: Asset Optimization ===${NC}"
  echo -e "${YELLOW}Target: Convert PNG/JPEG to WebP for 25-35% size reduction${NC}\n"
}

check_tools() {
  echo "Checking for required tools..."

  if ! command -v cwebp &> /dev/null; then
    echo -e "${RED}❌ cwebp not found. Install with:${NC}"
    echo "   macOS: brew install webp"
    echo "   Ubuntu/Debian: sudo apt-get install webp"
    echo "   Windows: https://developers.google.com/speed/webp/download"
    exit 1
  fi

  echo -e "${GREEN}✓ cwebp found${NC}\n"
}

backup_originals() {
  echo "Creating backup of original images..."

  if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$INPUT_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created at $BACKUP_DIR${NC}\n"
  else
    echo -e "${YELLOW}ℹ Backup directory already exists, skipping${NC}\n"
  fi
}

create_output_dir() {
  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo -e "${GREEN}✓ Created output directory: $OUTPUT_DIR${NC}\n"
  fi
}

convert_images() {
  echo "Converting images to WebP format (quality: $WEBP_QUALITY)..."

  local count=0
  local total=0
  local total_original=0
  local total_webp=0

  # Count total images
  total=$(find "$INPUT_DIR" -maxdepth 1 \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | wc -l)

  if [ "$total" -eq 0 ]; then
    echo -e "${YELLOW}ℹ No images found in $INPUT_DIR${NC}\n"
    return
  fi

  echo "Found $total image(s) to convert\n"

  for file in "$INPUT_DIR"/*.png "$INPUT_DIR"/*.jpg "$INPUT_DIR"/*.jpeg; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      ext="${filename##*.}"
      basename_no_ext="${filename%.*}"
      output_file="$OUTPUT_DIR/$basename_no_ext.webp"

      # Get original file size
      original_size=$(du -b "$file" | cut -f1)
      total_original=$((total_original + original_size))

      # Convert using cwebp
      cwebp -q "$WEBP_QUALITY" "$file" -o "$output_file" 2>/dev/null

      # Get WebP file size
      webp_size=$(du -b "$output_file" | cut -f1)
      total_webp=$((total_webp + webp_size))

      # Calculate reduction
      reduction=$((original_size - webp_size))
      reduction_percent=$((reduction * 100 / original_size))

      count=$((count + 1))

      echo "  [$count/$total] $filename"
      printf "         Original: %.2f KB → WebP: %.2f KB (-%d%% reduction)\n" \
        "$(echo "scale=2; $original_size / 1024" | bc)" \
        "$(echo "scale=2; $webp_size / 1024" | bc)" \
        "$reduction_percent"
    fi
  done

  echo ""

  # Summary
  if [ "$total_original" -gt 0 ]; then
    total_reduction=$((total_original - total_webp))
    total_reduction_percent=$((total_reduction * 100 / total_original))

    echo -e "${GREEN}Conversion Summary:${NC}"
    printf "  Total original size:  %.2f MB\n" "$(echo "scale=2; $total_original / 1024 / 1024" | bc)"
    printf "  Total WebP size:      %.2f MB\n" "$(echo "scale=2; $total_webp / 1024 / 1024" | bc)"
    printf "  Total reduction:      %.2f MB (-%d%%)\n\n" \
      "$(echo "scale=2; $total_reduction / 1024 / 1024" | bc)" \
      "$total_reduction_percent"
  fi
}

generate_file_mapping() {
  echo "Generating file mapping for code updates..."

  local mapping_file="scripts/webp_mapping.txt"

  > "$mapping_file"
  echo "# WebP File Mapping" >> "$mapping_file"
  echo "# Original → WebP conversion mapping" >> "$mapping_file"
  echo "" >> "$mapping_file"

  for file in "$OUTPUT_DIR"/*.webp; do
    if [ -f "$file" ]; then
      basename_webp=$(basename "$file")
      basename_no_ext="${basename_webp%.webp}"

      echo "assets/images/$basename_no_ext.png → assets/images_webp/$basename_webp" >> "$mapping_file"
      echo "assets/images/$basename_no_ext.jpg → assets/images_webp/$basename_webp" >> "$mapping_file"
    fi
  done

  echo -e "${GREEN}✓ File mapping saved to $mapping_file${NC}\n"
}

print_next_steps() {
  echo -e "${YELLOW}Next Steps:${NC}"
  echo "1. Review converted WebP images in $OUTPUT_DIR"
  echo "2. Update pubspec.yaml asset paths:"
  echo "   - Replace 'assets/images/' with 'assets/images_webp/'"
  echo "3. Update Image.asset() calls in Dart code:"
  echo "   - Use file mapping in scripts/webp_mapping.txt"
  echo "4. Run: flutter clean && flutter pub get"
  echo "5. Test the app: flutter run"
  echo "6. Build release: flutter build apk --release"
  echo "7. Compare sizes and commit changes\n"
}

# Main execution
main() {
  print_header
  check_tools
  backup_originals
  create_output_dir
  convert_images
  generate_file_mapping
  print_next_steps

  echo -e "${GREEN}=== Asset Optimization Complete ===${NC}\n"
}

main
