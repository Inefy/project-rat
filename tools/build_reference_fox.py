"""Build the reference fox, export GLB, and render production sprite facings.

blender --background --factory-startup --python tools/build_reference_fox.py
blender --background art/fox/reference-fox.blend --python tools/build_reference_fox.py -- --render
"""
import bpy
import json
import math
import os
import shutil
import sys
from mathutils import Vector, Matrix

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0,os.path.join(ROOT,'tools'))
from fox_model import build_fox, IDENTITY
OUT=os.path.join(ROOT,'art','fox')


def aim(obj, at):
    obj.rotation_euler=(Vector(at)-obj.location).to_track_quat('-Z','Y').to_euler()


def build():
    os.makedirs(OUT,exist_ok=True)
    scene=bpy.data.scenes.new('Reference Fox Studio')
    bpy.context.window.scene=scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=32
    scene.cycles.use_denoising=True
    scene.render.resolution_x=1000
    scene.render.resolution_y=1120
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast'
    world=bpy.data.worlds.new('Fox neutral studio')
    world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.12,.13,.15,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.40
    scene.world=world
    parts=build_fox()
    coll=bpy.data.collections.new('Reference Fox - editable parts')
    scene.collection.children.link(coll)
    root=bpy.data.objects.new('fox_root',None);coll.objects.link(root)
    for p in parts:
        for c in list(p.users_collection):c.objects.unlink(p)
        coll.objects.link(p);p.parent=root
    # Soft studio lighting keeps the orange body and sculpted skin readable.
    for name,at,energy,size,color in [
        ('Large soft key',(-4,-6,8),950,5,(1,.91,.82)),
        ('Soft face fill',(4,-5,4.5),430,4,(.83,.90,1)),
        ('Tail rim',(1,5,7),1150,4,(.91,.96,1))]:
        bpy.ops.object.light_add(type='AREA',location=at)
        light=bpy.context.object;light.name=name;light.data.energy=energy;light.data.shape='DISK';light.data.size=size;light.data.color=color;aim(light,(0,.4,2.5))
    bpy.ops.object.camera_add(location=(-7.5,-11.5,4.6))
    cam=bpy.context.object;cam.name='Reference three-quarter camera';cam.data.type='ORTHO';cam.data.ortho_scale=5.75
    aim(cam,(0,.35,2.43));scene.camera=cam
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.005))
    ground=bpy.context.object;ground.name='Studio floor - excluded from export'
    mat=bpy.data.materials.new('Studio charcoal');mat.use_nodes=True
    mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.038,.040,.044,1)
    mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.94
    ground.data.materials.append(mat)
    # Keep the supplied drawing in the editable file, excluded from export.
    ref=bpy.data.images.load(os.path.join(ROOT,'art','references','fox-design.png'),check_existing=True);ref.pack()
    empty=bpy.data.objects.new('Supplied reference drawing',None);scene.collection.objects.link(empty)
    empty.empty_display_type='IMAGE';empty.data=ref;empty.empty_display_size=5.1
    empty.location=(-4,1.0,2.55);empty.rotation_euler=(math.pi/2,0,0);empty.hide_render=True
    scene['reference']='User supplied fox-design.png. Rear anatomy inferred from the single view.'
    scene['runtime']='Top-down game uses eight 192px directional sprites. GLB retained for reuse with imported LODs. Static model with procedural game movement.'
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True);bpy.context.view_layer.objects.active=root
    for area in bpy.context.screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_distance=8.6
            area.spaces.active.region_3d.view_location=(0,.5,2.6)
            area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.region_3d.view_camera_zoom=0
            area.spaces.active.region_3d.view_camera_offset=(0,0)
            area.spaces.active.shading.type='MATERIAL'
            area.spaces.active.shading.use_scene_lights=True
            area.spaces.active.shading.use_scene_world=True
            area.spaces.active.overlay.show_overlays=False
            area.spaces.active.overlay.show_extras=False
            area.spaces.active.overlay.show_floor=False
            area.spaces.active.overlay.show_relationship_lines=False
    export_model(coll,root)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'reference-fox.blend'),compress=True)
    scene.render.filepath=os.path.join(OUT,'fox-preview.png')
    bpy.ops.render.render(write_still=True)
    print('REFERENCE_FOX_BUILD_COMPLETE',flush=True)


def export_model(coll,root):
    # Export one mesh / three material primitives. The source retains named parts.
    bpy.ops.object.select_all(action='DESELECT')
    copies=[]
    for o in coll.objects:
        if o.type!='MESH':continue
        c=o.copy();c.data=o.data.copy();bpy.context.scene.collection.objects.link(c)
        c.matrix_world=o.matrix_world.copy();c.parent=None;c.select_set(True);copies.append(c)
    bpy.context.view_layer.objects.active=copies[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name='Fox_Game'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.calc_loop_triangles()
    triangles=len(obj.data.loop_triangles)
    path=os.path.join(ROOT,'art','models','fox.glb')
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_texcoords=False)
    runtime_path=os.path.join(ROOT,'assets','models','fox.glb')
    os.makedirs(os.path.dirname(runtime_path),exist_ok=True)
    shutil.copyfile(path,runtime_path)
    stats={'triangles':triangles,'vertices':len(obj.data.vertices),'materials':len(obj.data.materials),'glb_bytes':os.path.getsize(path),'textures':0,'rigged':False,'facings':8,'sprite_size':[192,192],'visual_identity':IDENTITY}
    with open(os.path.join(OUT,'fox-stats.json'),'w') as f:json.dump(stats,f,indent=2)
    manifest_path=os.path.join(ROOT,'art','asset-manifest.json')
    with open(manifest_path) as f:manifest=json.load(f)
    manifest['fox']={'directions':8,'collection':'fox','triangles':triangles,'visual_identity':IDENTITY,'source':'art/fox/reference-fox.blend','glb_bytes':stats['glb_bytes'],'materials':3}
    with open(manifest_path,'w') as f:json.dump(manifest,f,indent=2);f.write('\n')
    bpy.data.objects.remove(obj,do_unlink=True)
    print('FOX_STATS '+json.dumps(stats),flush=True)


def render():
    scene=bpy.data.scenes['Reference Fox Studio'];bpy.context.window.scene=scene
    root=bpy.data.objects['fox_root'];cam=scene.camera
    scene.render.engine='CYCLES';scene.cycles.samples=24
    scene.render.film_transparent=True
    bpy.data.objects['Studio floor - excluded from export'].hide_render=True
    scene.render.resolution_x=192;scene.render.resolution_y=192
    cam.location=(0,-9,7.0);target=Vector((0,.55,2.45));aim(cam,target)
    bpy.context.view_layer.update()
    right=cam.rotation_euler.to_matrix() @ Vector((1,0,0))
    up=cam.rotation_euler.to_matrix() @ Vector((0,1,0))
    extent=0
    coll=bpy.data.collections['Reference Fox - editable parts']
    for i in range(8):
        turn=Matrix.Rotation(math.pi/2-i*math.tau/8,4,'Z')
        for obj in coll.objects:
            if obj.type!='MESH':continue
            for corner in obj.bound_box:
                offset=turn @ obj.matrix_world @ Vector(corner)-target
                extent=max(extent,abs(offset.dot(right)),abs(offset.dot(up)))
    cam.data.ortho_scale=extent*2.14
    for i in range(8):
        root.rotation_euler.z=math.pi/2-i*math.tau/8
        scene.render.filepath=os.path.join(ROOT,'assets','sprites',f'fox_{i}.png')
        bpy.ops.render.render(write_still=True)
    print('FOX_SPRITES_COMPLETE',flush=True)


if __name__=='__main__':
    if '--render' in sys.argv:render()
    else:
        build()
        if '--all' in sys.argv:render()
