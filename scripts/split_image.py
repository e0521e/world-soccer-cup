import cv2
import os

SRC = r"C:\Users\erenj\Pictures\G2\wcc.png"
OUT_DIR = r"C:\Users\erenj\Pictures\G2\images"
TILE_SIZE = 512

os.makedirs(OUT_DIR, exist_ok=True)

img = cv2.imread(SRC)
if img is None:
    raise SystemExit(f"Failed to load {SRC}")

h, w = img.shape[:2]
scale = TILE_SIZE / min(h, w)
new_w, new_h = int(w * scale), int(h * scale)
img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)

cols = new_w // TILE_SIZE
rows = new_h // TILE_SIZE

for r in range(rows):
    for c in range(cols):
        x, y = c * TILE_SIZE, r * TILE_SIZE
        tile = img[y:y+TILE_SIZE, x:x+TILE_SIZE]
        out_path = os.path.join(OUT_DIR, f"tile_{r}_{c}.png")
        cv2.imwrite(out_path, tile)

print(f"Done: {rows}x{cols} = {rows*cols} tiles → {OUT_DIR}")
