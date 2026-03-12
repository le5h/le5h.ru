#!/bin/bash

# Convert PNG/JPEG to WebP with parallel processing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTFOLIO_DIR="$SCRIPT_DIR/../portfolio"

RGB_QUALITY=75

CORES=$(($(nproc) - 1))
[ "$CORES" -lt 1 ] && CORES=1

convert_file() {
    local file="$1"
    local webp_file="${file%.*}.webp"
    local original_size=$(stat -c%s "$file")
    
    ffmpeg -y -i "$file" -preset picture -quality "$RGB_QUALITY" -f webp "$webp_file" 2>/dev/null && {
        local webp_size=$(stat -c%s "$webp_file")
        local reduction=$((original_size - webp_size))
        local percent=$(( (reduction * 100) / original_size ))
        echo "✓ $file (-${percent}%)"
    } || echo "✗ $file"
}

export -f convert_file
export PORTFOLIO_DIR
export RGB_QUALITY

find "$PORTFOLIO_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | xargs -P "$CORES" -I {} bash -c 'convert_file "$@"' _ {}

echo "Done!"
