"""
Run this script to generate Android launcher icons from your source image.
Usage: python scripts/generate_icons.py <path_to_your_icon.png>
Example: python scripts/generate_icons.py C:/Users/Hassan/Downloads/pakrentals_icon.png

Requires: pip install Pillow
"""

import sys
import os

try:
    from PIL import Image
except ImportError:
    print("Installing Pillow...")
    os.system("pip install Pillow")
    from PIL import Image

def generate_icons(source_path):
    sizes = {
        'mipmap-mdpi':    48,
        'mipmap-hdpi':    72,
        'mipmap-xhdpi':   96,
        'mipmap-xxhdpi':  144,
        'mipmap-xxxhdpi': 192,
    }

    img = Image.open(source_path).convert('RGBA')

    base = 'android/app/src/main/res'
    for folder, size in sizes.items():
        out_dir = os.path.join(base, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, 'ic_launcher.png')

        resized = img.resize((size, size), Image.LANCZOS)

        # Convert to RGB with white background (removes transparency for launcher)
        bg = Image.new('RGB', (size, size), (255, 255, 255))
        if resized.mode == 'RGBA':
            bg.paste(resized, mask=resized.split()[3])
        else:
            bg.paste(resized)

        bg.save(out_path, 'PNG', optimize=True)
        print(f'✓ {out_path} ({size}x{size})')

    print('\nAll icons generated! Run: flutter build apk --release')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python scripts/generate_icons.py <path_to_icon>")
        print("Example: python scripts/generate_icons.py C:/Users/Hassan/Downloads/icon.png")
        sys.exit(1)
    generate_icons(sys.argv[1])
