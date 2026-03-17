#!/bin/bash

# Convert images to WebP format with significant file size reduction
# Optimizes PNG, JPEG, BMP, and GIF images for web use with parallel processing
# Supports custom quality settings and optional original file deletion
# Usage: ./convert_images.sh [PATH] [--quality N] [--overwrite] [--delete-original]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Defaults
SEARCH_DIR="./"
RGB_QUALITY=75
OVERWRITE=false
DELETE_ORIGINAL=false

# Parse arguments
if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    SEARCH_DIR="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --quality|-q) RGB_QUALITY="$2"; shift 2 ;;
        --overwrite|-o) OVERWRITE=true; shift ;;
        --delete-original|-d) DELETE_ORIGINAL=true; shift ;;
        --help|-h)
            echo "Usage: $0 [PATH] [--quality|-q N] [--overwrite|-o] [--delete-original|-d]"
            echo "  PATH            Directory to search (default: ./)"
            echo "  --quality, -q   WebP quality (default: 75)"
            echo "  --overwrite, -o  Overwrite existing webp files"
            echo "  --delete-original, -d  Delete original files after successful conversion"
            exit 0
            ;;
    esac
done

CORES=$(($(nproc)-1))
[ "$CORES" -lt 1 ] && CORES=1

convert_file() {
    local file="$1"
    local filename=$(basename "$file")
    local webp_file="${file%.*}.webp"
    
    [ -f "$webp_file" ] && [ "$OVERWRITE" = false ] && {
        echo -e "${YELLOW}⏭${NC} $filename ${BLUE}(webp exists)${NC}"
        return 0
    }
    
    local original_size=$(stat -c%s "$file")
    
    ffmpeg -y -i "$file" -preset picture -quality "$RGB_QUALITY" -f webp "$webp_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        local webp_size=$(stat -c%s "$webp_file")
        local percent=$(( (original_size - webp_size) * 100 / original_size ))
        local icon=$([ "$OVERWRITE" = true ] && echo "↻" || echo "✓")
        echo -e "${GREEN}$icon${NC} $filename ${BLUE}(-${percent}%)${NC}"
        [ "$DELETE_ORIGINAL" = true ] && rm "$file"
    else
        echo -e "${RED}✗${NC} $filename ${BLUE}(failed)${NC}"
    fi
}

export -f convert_file
export RGB_QUALITY OVERWRITE DELETE_ORIGINAL
export RED GREEN YELLOW BLUE NC

find "$SEARCH_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.bmp" -o -iname "*.gif" \) |
    xargs -P "$CORES" -I {} bash -c 'convert_file "$@"' _ {}

echo -e "${GREEN}Done!${NC}"
