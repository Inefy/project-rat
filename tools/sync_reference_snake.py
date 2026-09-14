"""Replace just the snake in the existing cast library from its editable source.

blender --background art/picnic-cast.blend --python tools/sync_reference_snake.py
"""
import bpy
import os

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
studio=bpy.data.scenes['RAT Asset Studio']
gallery=bpy.data.scenes.get('Picnic Cast Gallery')
bpy.context.window.scene=studio
gallery_transforms=[]
if gallery:
    old_roots=[o for o in gallery.objects if o.name.startswith('snake_root')]
    for root in old_roots:
        gallery_transforms.append(root.matrix_world.copy())
        for child in list(root.children_recursive):
            bpy.data.objects.remove(child,do_unlink=True)
        bpy.data.objects.remove(root,do_unlink=True)
old=bpy.data.collections.get('snake')
if old:
    for obj in list(old.objects):bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.collections.remove(old)
path=os.path.join(ROOT,'art','snake','reference-snake.blend')
with bpy.data.libraries.load(path,link=False) as (src,dst):
    dst.collections=['Reference Snake - editable parts']
coll=dst.collections[0];coll.name='snake'
studio.collection.children.link(coll)
coll.hide_render=True
root=next(o for o in coll.objects if o.type=='EMPTY')
root.name='snake_root'
if gallery:
    for transform in gallery_transforms:
        copies={}
        for obj in coll.objects:
            copy=obj.copy();gallery.collection.objects.link(copy);copies[obj]=copy
        for obj,copy in copies.items():
            copy.parent=copies.get(obj.parent)
            if obj==root:
                # Gallery models share a display scale, not physical dimensions.
                copy.matrix_world=transform
                copy.scale=(.47,.47,.47)
    bpy.context.window.scene=gallery
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art','picnic-cast.blend'),compress=True)
print('REFERENCE_SNAKE_LIBRARY_SYNC_COMPLETE')
