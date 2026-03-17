#!/bin/bash

# Convert PNG/JPEG to WebP with parallel processing
# Usage: ./convert_images.sh [PATH] [--quality N] [--overwrite]

# Parse arguments
SEARCH_DIR="./"
RGB_QUALITY=75
OVERWRITE=false

# Handle positional path argument (first argument if it's not a flag)
if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
    SEARCH_DIR="$1"
    shift
fi

for arg in "$@"; do
    case $arg in
        --quality)
            shift
            RGB_QUALITY="$1"
            ;;
        --overwrite)
            OVERWRITE=true
            ;;
        --help|-h)
            echo "Usage: $0 [PATH] [--quality N] [--overwrite] [--help]"
            echo "  PATH            Directory to search for images (default: ./)"
            echo "  --quality N     Set WebP quality (default: 75)"
            echo "  --overwrite     Convert all files, overwriting existing webp files"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
    esac
done

CORES=$(($(nproc) - 1))
[ "$CORES" -lt 1 ] && CORES=1

convert_file() {
    local file="$1"
    local filename=$(basename "$file")
    local webp_file="${file%.*}.webp"
    
    if [ -f "$webp_file" ] && [ "$OVERWRITE" = false ]; then
        echo "⏭ $filename (webp exists)"
        return 0
    fi
    
    local original_size=$(stat -c%s "$file")
    
    ffmpeg -y -i "$file" -preset picture -quality "$RGB_QUALITY" -f webp "$webp_file" 2>/dev/null && {
        local webp_size=$(stat -c%s "$webp_file")
        local reduction=$((original_size - webp_size))
        local percent=$(( (reduction * 100) / original_size ))
        if [ "$OVERWRITE" = true ] && [ -f "$webp_file" ]; then
            echo "↻ $filename (-${percent}%)"
        else
            echo "✓ $filename (-${percent}%)"
        fi
    } || echo "✗ $filename"
}

export -f convert_file
export SEARCH_DIR
export RGB_QUALITY
export OVERWRITE

find "$SEARCH_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | xargs -P "$CORES" -I {} bash -c 'convert_file "$@"' _ {}

echo "Done!"
