"""Update the twelve redesigned assets in the existing editable cast library.

blender --background art/picnic-cast.blend --python-exit-code 1 --python tools/sync_nightmare_cast.py
"""
from pathlib import Path
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from nightmare_models import CAST, PICKUPS

studio = bpy.data.scenes['RAT Asset Studio']
gallery = bpy.data.scenes.get('Picnic Cast Gallery')
bpy.context.window.scene = studio
for kind in CAST + PICKUPS:
    transforms = []
    if gallery:
        for root in [o for o in gallery.objects if o.name.startswith(kind + '_root')]:
            transforms.append(root.matrix_world.copy())
            for child in list(root.children_recursive):
                bpy.data.objects.remove(child, do_unlink=True)
            bpy.data.objects.remove(root, do_unlink=True)
    old = bpy.data.collections.get(kind)
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    with bpy.data.libraries.load(str(ROOT / 'art/nightmare-cast/nightmare-cast.blend'), link=False) as (src, dst):
        dst.collections = [kind]
    coll = dst.collections[0]
    studio.collection.children.link(coll)
    coll.hide_render = True
    coll.hide_viewport = False
    root = next(o for o in coll.objects if o.type == 'EMPTY')
    root.name = kind + '_root'
    if gallery:
        heights = [(o.matrix_world @ Vector(c)).z for o in coll.objects if o.type == 'MESH' for c in o.bound_box]
        display_scale = 2.65 / (max(heights) - min(heights)) if kind in CAST else 1.0
        for transform in transforms:
            copies = {}
            for obj in coll.objects:
                copy = obj.copy()
                gallery.collection.objects.link(copy)
                copies[obj] = copy
            for obj, copy in copies.items():
                copy.parent = copies.get(obj.parent)
                if obj == root:
                    copy.matrix_world = transform
                    copy.scale = (display_scale,) * 3
if gallery:
    bpy.context.window.scene = gallery
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'art/picnic-cast.blend'), compress=True)
print('NIGHTMARE_LIBRARY_SYNC_COMPLETE')
