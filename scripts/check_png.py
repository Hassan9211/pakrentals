import os

PNG_SIG = b'\x89PNG\r\n\x1a\n'
JPEG_SIG = b'\xff\xd8\xff'

files = [
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
]

for f in files:
    with open(f, 'rb') as fp:
        header = fp.read(8)
    folder = f.split('/')[-2]
    if header[:8] == PNG_SIG:
        print(folder + ': VALID PNG')
    elif header[:3] == JPEG_SIG:
        print(folder + ': JPEG (needs conversion)')
    else:
        print(folder + ': UNKNOWN format - ' + header.hex())
