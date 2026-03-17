#!/bin/bash

# Convert PNG/JPEG to WebP with parallel processing
# Usage: ./convert_images.sh [PATH] [--quality N] [--overwrite]

# Defaults
SEARCH_DIR="./"
RGB_QUALITY=75
OVERWRITE=false

# Parse arguments
if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
    SEARCH_DIR="$1"
    shift
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --quality) RGB_QUALITY="$2"; shift 2 ;;
        --overwrite) OVERWRITE=true; shift ;;
        --help|-h)
            echo "Usage: $0 [PATH] [--quality N] [--overwrite]"
            echo "  PATH            Directory to search (default: ./)"
            echo "  --quality N     WebP quality (default: 75)"
            echo "  --overwrite     Overwrite existing webp files"
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
        echo "⏭ $filename (webp exists)"
        return 0
    }
    
    local original_size=$(stat -c%s "$file")
    
    ffmpeg -y -i "$file" -preset picture -quality "$RGB_QUALITY" -f webp "$webp_file" 2>/dev/null && {
        local webp_size=$(stat -c%s "$webp_file")
        local percent=$(( (original_size - webp_size) * 100 / original_size ))
        local icon=$([ "$OVERWRITE" = true ] && echo "↻" || echo "✓")
        echo "$icon $filename (-${percent}%)"
    } || echo "✗ $filename"
}

export -f convert_file
export SEARCH_DIR RGB_QUALITY OVERWRITE

find "$SEARCH_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) |
    xargs -P "$CORES" -I {} bash -c 'convert_file "$@"' _ {}

echo "Done!"
