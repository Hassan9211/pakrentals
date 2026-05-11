"""Convert JPEG files (with .png extension) to real PNG format"""
try:
    from PIL import Image
except ImportError:
    import os
    os.system("pip install Pillow")
    from PIL import Image

import os

files = [
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
]

for path in files:
    img = Image.open(path)
    # Convert to RGBA to preserve any transparency
    img = img.convert('RGBA')
    # Save as real PNG (overwrites the fake .png file)
    img.save(path, 'PNG')
    size = os.path.getsize(path)
    folder = path.split('/')[-2]
    print(f'{folder}: converted to PNG ({img.width}x{img.height}) - {size} bytes')

print('\nDone! All icons are now valid PNG files.')
