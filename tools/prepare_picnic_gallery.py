import bpy, os, json, math, contextlib, io
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
keys=json.load(open(os.path.join(ROOT,'art','asset-manifest.json')))
studio=bpy.data.scenes['RAT Asset Studio']; bpy.context.window.scene=studio
# Export only objects belonging to each model, never the user's other scenes.
with contextlib.redirect_stdout(io.StringIO()):
    for k in keys:
        for o in bpy.data.objects: o.select_set(False)
        for o in bpy.data.collections[k].objects: o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'art','models',k+'.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
gallery=bpy.data.scenes.new('Picnic Cast Gallery'); bpy.context.window.scene=gallery
gallery.world=studio.world; gallery.render.engine='BLENDER_EEVEE'
for i,k in enumerate(keys):
    shift=Vector(((i%5-2)*3.2, -(i//5)*3.5,0))
    originals=list(bpy.data.collections[k].objects); copies={}
    for o in originals:
        c=o.copy(); gallery.collection.objects.link(c); copies[o]=c
    for o,c in copies.items():
        c.parent=copies.get(o.parent)
        if o.parent is None:
            c.location+=shift; c.rotation_euler.z=-.35
            if k in ['cat', 'fox']: c.scale=(.54,.54,.54)
    bpy.ops.object.text_add(location=shift+Vector((0,-.95,.03)),rotation=(math.pi/2,0,0))
    label=bpy.context.object; label.data.body=k.replace('_',' ').upper(); label.data.align_x='CENTER'; label.data.size=.23; label.data.extrude=.003
    label.data.materials.append(bpy.data.materials['RAT_cream'])
for o in studio.objects:
    if o.type=='LIGHT':
        c=o.copy(); c.data=o.data.copy(); c.data.energy*=8; c.data.size=12; c.location.z=12; gallery.collection.objects.link(c)
bpy.ops.object.camera_add(location=(5,-24,23)); cam=bpy.context.object; cam.rotation_euler=(Vector((0,-6,.5))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=21; gallery.camera=cam
gallery.view_settings.view_transform='AgX'; gallery.view_settings.look='AgX - Medium High Contrast'
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_distance=16
        area.spaces.active.region_3d.view_location=(0,-1.8,1.1)
        area.spaces.active.region_3d.view_rotation=(Vector((0,-1.8,1.1))-Vector((3,-16,12))).to_track_quat('-Z','Y')
        area.spaces.active.shading.color_type='MATERIAL'
        area.spaces.active.overlay.show_relationship_lines=False
        area.spaces.active.overlay.show_extras=False
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art','picnic-cast.blend'))
print('Saved editable gallery and 24 GLBs')
