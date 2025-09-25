#!/bin/bash

# Create app icon for Pasteman
# This script generates a simple icon using macOS built-in tools

RESOURCES_DIR="Pasteman/Resources"
ICON_NAME="AppIcon"

echo "🎨 Creating Pasteman app icon..."

# Create icon directory structure
mkdir -p "${RESOURCES_DIR}/${ICON_NAME}.iconset"

# For simplicity, we'll use the system clipboard icon as base and modify it
# Create a simple 1024x1024 PNG using a system command
cat > "${RESOURCES_DIR}/create_icon.py" << 'EOF'
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    # Create a 1024x1024 image
    size = 1024
    img = Image.new('RGBA', (size, size), (37, 99, 235, 255))  # Blue background
    draw = ImageDraw.Draw(img)
    
    # Draw clipboard background
    clipboard_x, clipboard_y = 128, 96
    clipboard_w, clipboard_h = 768, 640
    draw.rounded_rectangle(
        [clipboard_x, clipboard_y, clipboard_x + clipboard_w, clipboard_y + clipboard_h],
        radius=32, fill=(255, 255, 255, 255)
    )
    
    # Draw clipboard clip
    clip_x, clip_y = 384, 64
    clip_w, clip_h = 256, 96
    draw.rounded_rectangle(
        [clip_x, clip_y, clip_x + clip_w, clip_y + clip_h],
        radius=16, fill=(107, 114, 128, 255)
    )
    draw.rounded_rectangle(
        [clip_x + 32, clip_y + 16, clip_x + clip_w - 32, clip_y + clip_h - 16],
        radius=8, fill=(255, 255, 255, 255)
    )
    
    # Draw clipboard slots
    slot_x, slot_y = 192, 240
    slot_w, slot_h = 640, 32
    slot_spacing = 80
    
    for i in range(5):
        y = slot_y + i * slot_spacing
        draw.rounded_rectangle(
            [slot_x, y, slot_x + slot_w, y + slot_h],
            radius=4, fill=(37, 99, 235, 255)
        )
        
        # Draw slot numbers
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
        except:
            font = ImageFont.load_default()
        
        number_x = slot_x - 64
        number_y = y + 8
        draw.text((number_x, number_y), str(i + 1), fill=(148, 163, 184, 255), font=font, anchor="mm")
    
    return img

if __name__ == "__main__":
    try:
        icon = create_icon()
        icon.save("icon_1024.png")
        print("Icon created successfully!")
    except ImportError:
        print("PIL not available, creating simple icon...")
        # Fallback: create a simple colored square
        import subprocess
        subprocess.run([
            'sips', '-s', 'format', 'png',
            '-Z', '1024',
            '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ClippingText.icns',
            'icon_1024.png'
        ])
        print("Fallback icon created!")
EOF

cd "${RESOURCES_DIR}"
python3 create_icon.py || {
    echo "Python icon creation failed, using system icon..."
    # Fallback: extract and modify system clipboard icon
    sips -s format png -Z 1024 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ClippingText.icns icon_1024.png 2>/dev/null || {
        # Ultimate fallback: create a simple colored square
        echo "Creating simple colored icon..."
        python3 -c "
from PIL import Image
img = Image.new('RGB', (1024, 1024), (37, 99, 235))
img.save('icon_1024.png')
" 2>/dev/null || {
            # If PIL not available, use sips to create simple icon
            sips -s format png --out icon_1024.png -Z 1024 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns
        }
    }
}

# Create different sizes for iconset
sizes=(16 32 64 128 256 512 1024)
cd "${ICON_NAME}.iconset"

for size in "${sizes[@]}"; do
    sips -z $size $size ../icon_1024.png --out "icon_${size}x${size}.png"
    if [ $size -ne 1024 ]; then
        sips -z $((size*2)) $((size*2)) ../icon_1024.png --out "icon_${size}x${size}@2x.png"
    fi
done

# Create .icns file
cd ..
iconutil -c icns "${ICON_NAME}.iconset"

echo "✅ Icon created: ${RESOURCES_DIR}/${ICON_NAME}.icns"

# Clean up
rm -f create_icon.py icon_1024.png
rm -rf "${ICON_NAME}.iconset"