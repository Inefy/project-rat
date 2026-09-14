"""Build the reference bird, export GLB, and render production sprite facings.

blender --background --factory-startup --python tools/build_reference_bird.py
blender --background art/bird/reference-bird.blend --python tools/build_reference_bird.py -- --render
"""
import bpy
import json
import math
import os
import shutil
import struct
import sys
import tempfile
import time
from mathutils import Vector, Matrix

ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0,os.path.join(ROOT,'tools'))
from bird_model import build_bird, IDENTITY
OUT=os.path.join(ROOT,'art','bird')


def aim(obj, at):
    obj.rotation_euler=(Vector(at)-obj.location).to_track_quat('-Z','Y').to_euler()


def build():
    os.makedirs(OUT,exist_ok=True)
    scene=bpy.data.scenes.new('Reference Bird Studio')
    bpy.context.window.scene=scene
    scene.render.engine='CYCLES'
    scene.cycles.samples=32
    scene.cycles.use_denoising=True
    scene.cycles.diffuse_bounces=0
    scene.render.resolution_x=1440
    scene.render.resolution_y=1080
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.render.image_settings.compression=100
    scene.render.dither_intensity=0
    scene.view_settings.view_transform='Standard'
    scene.view_settings.look='None'
    world=bpy.data.worlds.new('Bird neutral studio')
    world.use_nodes=True
    world.node_tree.nodes['Background'].inputs['Color'].default_value=(.12,.13,.15,1)
    world.node_tree.nodes['Background'].inputs['Strength'].default_value=.40
    scene.world=world
    parts=build_bird()
    coll=bpy.data.collections.new('Reference Bird - editable parts')
    scene.collection.children.link(coll)
    root=bpy.data.objects.new('bird_root',None);coll.objects.link(root)
    for p in parts:
        for c in list(p.users_collection):c.objects.unlink(p)
        coll.objects.link(p);p.parent=root
    # Soft studio lighting keeps the orange outline and sculpted skin readable.
    for name,at,energy,size,color in [
        ('Large soft key',(-4,-6,8),950,5,(1,.91,.82)),
        ('Soft face fill',(4,-5,4.5),430,4,(.83,.90,1)),
        ('Tail rim',(1,5,7),1150,4,(.91,.96,1)),
        ('Human foot fill',(-4,1,2.1),180,3,(1,.94,.88))]:
        bpy.ops.object.light_add(type='AREA',location=at)
        light=bpy.context.object;light.name=name;light.data.energy=energy*.75;light.data.shape='DISK';light.data.size=size;light.data.color=color;aim(light,(0,.4,2.5))
    bpy.ops.object.camera_add(location=(-13,-2,6.5))
    cam=bpy.context.object;cam.name='Reference three-quarter camera';cam.data.type='ORTHO';cam.data.ortho_scale=8.0
    aim(cam,(0,.15,2.85));scene.camera=cam
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,.005))
    ground=bpy.context.object;ground.name='Studio floor - excluded from export'
    mat=bpy.data.materials.new('Studio charcoal');mat.use_nodes=True
    mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.038,.040,.044,1)
    mat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.94
    ground.data.materials.append(mat)
    # Keep the supplied drawing in the editable file, excluded from export.
    ref=bpy.data.images.load(os.path.join(ROOT,'art','references','bird-design.png'),check_existing=True);ref.pack()
    empty=bpy.data.objects.new('Supplied reference drawing',None);scene.collection.objects.link(empty)
    empty.empty_display_type='IMAGE';empty.data=ref;empty.empty_display_size=5.1
    empty.location=(-4,1.0,2.55);empty.rotation_euler=(math.pi/2,0,0);empty.hide_render=True
    scene['reference']='User supplied bird-design.png. Rear anatomy inferred from the single view.'
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
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'reference-bird.blend'),compress=True)
    scene.render.filepath=os.path.join(OUT,'bird-preview.png')
    bpy.ops.render.render(write_still=True)
    print('REFERENCE_BIRD_BUILD_COMPLETE',flush=True)


def export_model(coll,root):
    # Export one mesh / four material primitives. The source retains named parts.
    bpy.ops.object.select_all(action='DESELECT')
    copies=[]
    for o in coll.objects:
        if o.type!='MESH':continue
        c=o.copy();c.data=o.data.copy();bpy.context.scene.collection.objects.link(c)
        c.matrix_world=o.matrix_world.copy();c.parent=None;c.select_set(True);copies.append(c)
    bpy.context.view_layer.objects.active=copies[0]
    bpy.ops.object.join()
    obj=bpy.context.object;obj.name='Bird_Game'
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    obj.data.calc_loop_triangles()
    triangles=len(obj.data.loop_triangles)
    path=os.path.join(ROOT,'art','models','bird.glb')
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_texcoords=False)
    runtime_path=os.path.join(ROOT,'assets','models','bird.glb')
    os.makedirs(os.path.dirname(runtime_path),exist_ok=True)
    shutil.copyfile(path,runtime_path)
    stats={'triangles':triangles,'vertices':len(obj.data.vertices),'materials':len(obj.data.materials),'glb_bytes':os.path.getsize(path),'textures':0,'rigged':False,'facings':8,'sprite_size':[192,192],'visual_identity':IDENTITY}
    with open(os.path.join(OUT,'bird-stats.json'),'w') as f:json.dump(stats,f,indent=2)
    manifest_path=os.path.join(ROOT,'art','asset-manifest.json')
    with open(manifest_path) as f:manifest=json.load(f)
    manifest['bird']={'directions':8,'collection':'bird','triangles':triangles,'visual_identity':IDENTITY,'source':'art/bird/reference-bird.blend','glb_bytes':stats['glb_bytes'],'materials':4}
    with open(manifest_path,'w') as f:json.dump(manifest,f,indent=2);f.write('\n')
    bpy.data.objects.remove(obj,do_unlink=True)
    print('BIRD_STATS '+json.dumps(stats),flush=True)


def strip_sprite_metadata(path):
    """Keep PNG pixels and color information, omit Blender render metadata."""
    with open(path,'rb') as f:data=f.read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    output=bytearray(data[:8])
    offset=8
    keep={b'IHDR',b'PLTE',b'tRNS',b'IDAT',b'IEND',b'sRGB',b'iCCP',b'gAMA',b'cHRM'}
    while offset < len(data):
        length=struct.unpack_from('>I',data,offset)[0]
        end=offset+12+length
        if data[offset+4:offset+8] in keep:
            output.extend(data[offset:end])
        offset=end
    with open(path,'wb') as f:f.write(output)


def render():
    scene=bpy.data.scenes['Reference Bird Studio'];bpy.context.window.scene=scene
    root=bpy.data.objects['bird_root'];cam=scene.camera
    scene.render.engine='CYCLES';scene.cycles.samples=64
    # Dithering/denoising would add noise to the intentionally solid paint fill.
    scene.cycles.use_denoising=False
    scene.render.film_transparent=True
    bpy.data.objects['Studio floor - excluded from export'].hide_render=True
    scene.render.resolution_x=192;scene.render.resolution_y=192
    cam.location=(0,-10,7.3);target=Vector((0,.15,2.8));aim(cam,target)
    bpy.context.view_layer.update()
    right=cam.rotation_euler.to_matrix() @ Vector((1,0,0))
    up=cam.rotation_euler.to_matrix() @ Vector((0,1,0))
    extent=0
    coll=bpy.data.collections['Reference Bird - editable parts']
    for i in range(8):
        turn=Matrix.Rotation(math.pi/2-i*math.tau/8,4,'Z')
        for obj in coll.objects:
            if obj.type!='MESH':continue
            for corner in obj.bound_box:
                offset=turn @ obj.matrix_world @ Vector(corner)-target
                extent=max(extent,abs(offset.dot(right)),abs(offset.dot(up)))
    cam.data.ortho_scale=extent*2.14
    # Render outside Godot's watched asset folder, then replace completed PNGs.
    # Windows file watchers can briefly hold an existing sprite open.
    with tempfile.TemporaryDirectory(prefix='rat-bird-sprites-') as staging:
        for i in range(8):
            root.rotation_euler.z=math.pi/2-i*math.tau/8
            scene.render.filepath=os.path.join(staging,f'bird_{i}.png')
            bpy.ops.render.render(write_still=True)
            strip_sprite_metadata(scene.render.filepath)
            destination=os.path.join(ROOT,'assets','sprites',f'bird_{i}.png')
            pending=destination+'.tmp'
            shutil.copyfile(scene.render.filepath,pending)
            for attempt in range(20):
                try:
                    os.replace(pending,destination)
                    break
                except PermissionError:
                    if attempt==19:raise
                    time.sleep(.1)
    stats_path=os.path.join(OUT,'bird-stats.json')
    with open(stats_path) as f:stats=json.load(f)
    stats['sprite_bytes']=sum(os.path.getsize(os.path.join(ROOT,'assets','sprites',f'bird_{i}.png')) for i in range(8))
    stats['paint_material']='KHR_materials_unlit'
    with open(stats_path,'w') as f:json.dump(stats,f,indent=2);f.write('\n')
    print('BIRD_SPRITES_COMPLETE',flush=True)


if __name__=='__main__':
    if '--render' in sys.argv:render()
    else:
        build()
        if '--all' in sys.argv:render()
