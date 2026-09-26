"""Pack Blender's six transparent jaw poses into the runtime sprite atlas."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
frames = [Image.open(ROOT / f'build/mousetrap-frames/{i}.png').convert('RGBA') for i in range(6)]
atlas = Image.new('RGBA', (1920, 320))
for i, frame in enumerate(frames):
    atlas.paste(frame, (i * 320, 0))
destination = ROOT / 'assets/sprites/hazards/mouth_trap.png'
destination.parent.mkdir(parents=True, exist_ok=True)
atlas.save(destination)
print(f'Packed {destination}')
