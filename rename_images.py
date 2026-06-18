import os
import re

DIR = r"C:\Users\erenj\Pictures\Roblox"
IMAGE_EXT = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}

files = [f for f in os.listdir(DIR) if os.path.isfile(os.path.join(DIR, f))]
files = [f for f in files if os.path.splitext(f)[1].lower() in IMAGE_EXT]
files.sort()

for i, name in enumerate(files, start=1):
    ext = os.path.splitext(name)[1]
    new_name = f"{i:03d}{ext}"
    src = os.path.join(DIR, name)
    dst = os.path.join(DIR, new_name)
    if src != dst:
        os.rename(src, dst)
        print(f"{name} -> {new_name}")

input(f"\nDone. Press Enter to exit...")
