"""Pack Blender movement renders into runtime atlases and a review animation."""
import json
import os
import time
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CAST = ['rat', 'bird', 'cat', 'owl', 'snake', 'raccoon', 'fox', 'alpha_cat', 'junkyard_dog', 'barn_owl']
SIZE, FRAMES = 160, 8
OUT = ROOT / 'assets/sprites/movement'
REVIEW = ROOT / 'art/movement'
OUT.mkdir(parents=True, exist_ok=True)
REVIEW.mkdir(parents=True, exist_ok=True)
manifest = {}
for kind in CAST:
    atlas = Image.new('RGBA', (SIZE * 8, SIZE * (FRAMES + 1)))
    for frame in range(FRAMES + 1):
        for direction in range(8):
            sprite = Image.open(ROOT / 'build/movement-frames' / kind / f'{direction}_{frame}.png').convert('RGBA')
            # Clipped extremities are a build failure, not something to hide in-game.
            bounds = sprite.getchannel('A').getbbox()
            assert bounds and min(bounds[:2]) > 1 and max(bounds[2:]) < SIZE - 1, (kind, frame, direction, bounds)
            atlas.paste(sprite, (direction * SIZE, frame * SIZE))
    path = OUT / (kind + '.png')
    staging = ROOT / 'build/movement-frames' / (kind + '-atlas.png')
    atlas.save(staging, optimize=True)
    for attempt in range(30):
        try:
            os.replace(staging, path)
            break
        except OSError:
            if attempt == 29:
                raise
            time.sleep(.1)
    manifest[kind] = {'frames': FRAMES, 'directions': 8, 'cell_size': SIZE, 'rest_row': FRAMES, 'bytes': path.stat().st_size}
review_frames = []
for frame in range(FRAMES):
    canvas = Image.new('RGB', (1000, 440), '#181e27')
    draw = ImageDraw.Draw(canvas)
    for index, kind in enumerate(CAST):
        x, y = (index % 5) * 200, (index // 5) * 220
        sprite = Image.open(ROOT / 'build/movement-frames' / kind / f'1_{frame}.png').convert('RGBA')
        canvas.paste(sprite, (x + 20, y + 12), sprite)
        draw.text((x + 20, y + 180), kind.replace('_', ' ').upper(), fill='#eee2c7')
    review_frames.append(canvas)
review_frames[0].save(REVIEW / 'movement-preview.gif', save_all=True, append_images=review_frames[1:], duration=95, loop=0)
review_frames[0].save(REVIEW / 'movement-preview.png')
contact = Image.new('RGB', (960, 1800), '#181e27')
labels = ImageDraw.Draw(contact)
for row, kind in enumerate(CAST):
    labels.text((12, row * 180 + 80), kind.replace('_', ' ').upper(), fill='#eee2c7')
    for column, frame in enumerate([8, 0, 2, 4, 6]):
        sprite = Image.open(ROOT / 'build/movement-frames' / kind / f'2_{frame}.png').convert('RGBA')
        contact.paste(sprite, (160 + column * 160, row * 180), sprite)
contact.save(REVIEW / 'movement-poses.png')
(REVIEW / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
runtime_paths = sorted((ROOT / 'build/movement-runtime').glob('frame_*.png'))
if runtime_paths:
    runtime_frames = [Image.open(path).convert('RGB') for path in runtime_paths]
    runtime_frames[0].save(REVIEW / 'movement-runtime.gif', save_all=True,
                           append_images=runtime_frames[1:], duration=[70 if i % 4 == 3 else 60 for i in range(len(runtime_frames))], loop=0)
print('Packed movement atlases:', sum(v['bytes'] for v in manifest.values()), 'bytes')
