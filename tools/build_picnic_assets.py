import bpy, math, os, json
import sys
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from character_designs import build_character, IDENTITIES
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT,'assets','sprites')
CAST = ['rat','bird','cat','owl','snake','raccoon','fox','alpha_cat','junkyard_dog','barn_owl']
PROPS = ['cheese','rapid','triple','power','haste','shield','pierce','seed','feather','venom','bone','sonic','crumb','fizzy']
COLORS={'ink':'292133','cream':'fff0c5','pink':'e78396','red':'d84037','gold':'f6be32','green':'75ae35','metal':'8ca9ae','brown':'8d512d','rat':'888a98','bird':'258dc1','cat':'8852a8','owl':'996538','snake':'70a237','raccoon':'8a9298','fox':'e97824','alpha_cat':'b64079','junkyard_dog':'b58b5c','barn_owl':'dab67c'}
COLORS.update({'denim':'304e81','navy':'26354b','lavender':'c18ddb','ochre':'c2914b',
               'lime':'d3db65','teal':'267f83','wine':'6e244b','raccoon':'637f86',
               'bird':'199dcc','cat':'914fba','snake':'64a83f','fox':'ef7825',
               'alpha_cat':'c8498d','barn_owl':'ead5a5'})
def material(key):
    name='RAT_'+key
    m=bpy.data.materials.get(name)
    if not m:
        m=bpy.data.materials.new(name); h=COLORS.get(key,key); c=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
        m.diffuse_color=(*c,1); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c),1); m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8
    return m
parts=[]
def finish(name,color,scale):
    o=bpy.context.object; o.name=name; o.scale=scale; o.data.materials.append(material(color)); parts.append(o); return o
def ball(name,at,scale,color):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=at); return finish(name,color,scale)
def box(name,at,scale,color):
    bpy.ops.mesh.primitive_cube_add(size=2,location=at); o=finish(name,color,scale); bevel=o.modifiers.new('Soft toy edges','BEVEL'); bevel.width=.09; bevel.segments=1; return o
def cone(name,at,scale,color):
    bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=1,radius2=0,depth=2,location=at); return finish(name,color,scale)
def rod(name,a,b,r,color):
    d=Vector(b)-Vector(a); bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=r,depth=d.length,location=(Vector(a)+Vector(b))/2); o=finish(name,color,(1,1,1)); o.rotation_euler=d.to_track_quat('Z','Y').to_euler(); return o
def ring(name,at,r,thick,color):
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,location=at,major_radius=r,minor_radius=thick); return finish(name,color,(1,1,1))
def character(k):
    extra_parts = build_character(k, ball, box, cone, rod, ring)
    if extra_parts:
        parts.extend(extra_parts)

def prop(k):
    if k=='cheese':
        mesh=bpy.data.meshes.new('Cheese wedge mesh')
        verts=[(-.62,y,.18) for y in [-.34,.34]]+[(.62,y,.18) for y in [-.34,.34]]+[(-.62,y,1.05) for y in [-.34,.34]]
        mesh.from_pydata(verts,[],[(0,2,4),(1,5,3),(0,1,3,2),(0,4,5,1),(2,3,5,4)])
        o=bpy.data.objects.new('Cheese wedge',mesh); bpy.context.scene.collection.objects.link(o); o.data.materials.append(material('gold')); parts.append(o)
        for x,z in [(-.38,.4),(-.37,.73),(.12,.30)]: ball('Cheese hole',(x,-.355,z),(.12,.025,.1),'brown')
    elif k=='rapid':
        for i in range(5): ball('Chili',(i*.10,0,.24+i*.18),(.12+i*.035,.18,.24),'red')
        rod('Stem',(.4,0,1.08),(.23,0,1.34),.065,'green')
    elif k=='triple':
        ball('Peapod',(0,.08,.38),(.76,.19,.24),'green')
        for x in [-.43,0,.43]: ball('Pea',(x,-.09,.49),(.23,.23,.23),'green')
    elif k in ['power','seed','crumb','venom']:
        c={'power':'brown','seed':'cream','crumb':'brown','venom':'green'}[k]
        ball(k,(0,0,.55),(.42,.34,.52),c)
        if k=='power': ball('Acorn cap',(0,0,.87),(.47,.37,.18),'brown'); rod('Stem',(0,0,.9),(.12,0,1.18),.07,'brown')
        if k=='seed':
            for x in [-.16,.16]: rod('Seed stripe',(x,-.3,.26),(x,-.31,.79),.045,'ink')
        if k=='crumb':
            rod('Fuse',(0,0,.95),(.22,0,1.3),.04,'ink'); cone('Spark',(.23,0,1.38),(.17,.1,.23),'gold')
        if k=='venom':
            for x in [-.3,0,.3]: ball('Drip',(x,-.12,.18),(.15,.17,.2),'green')
    elif k=='haste':
        box('Sugar cube',(0,0,.51),(.42,.4,.44),'cream')
        for x,z in [(-.24,.65),(.15,.35),(.21,.7)]: ball('Grain',(x,-.401,z),(.04,.02,.045),'metal')
    elif k in ['shield','sonic']:
        o=ring('Rim',(0,0,.58),.49,.075,'metal' if k=='shield' else 'gold'); o.rotation_euler.x=math.pi/2
        if k=='shield': ball('Lid',(0,.04,.58),(.48,.08,.48),'metal'); rod('Handle',(-.13,-.12,.58),(.13,-.12,.58),.08,'ink')
    elif k=='pierce': cone('Needle tooth',(0,0,.68),(.17,.15,.66),'cream')
    elif k=='feather':
        rod('Quill',(-.48,0,.18),(.4,0,1.01),.035,'cream')
        for i in range(6): ball('Vane',(-.27+i*.10,0,.38+i*.10),(.24,.055,.11),'metal')
    elif k=='bone':
        rod('Bone',(-.4,0,.5),(.4,0,.5),.13,'cream')
        for x in [-.44,.44]:
            for z in [.38,.62]: ball('Knuckle',(x,0,z),(.19,.18,.18),'cream')
    elif k=='fizzy':
        rod('Can',(0,0,.13),(0,0,1.15),.36,'red')
        for z in [.14,1.15]: ring('Can rim',(0,0,z),.34,.04,'metal')
        ball('Top',(0,0,1.15),(.33,.33,.025),'metal'); box('Exclamation',(0,-.355,.76),(.06,.025,.21),'cream'); ball('Dot',(0,-.36,.42),(.065,.025,.065),'cream')

def build():
    scene=bpy.data.scenes.new('RAT Asset Studio'); bpy.context.window.scene=scene
    scene.render.engine='BLENDER_EEVEE'; scene.render.film_transparent=True
    scene.render.resolution_x=192; scene.render.resolution_y=192; scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'
    scene.world=bpy.data.worlds.new('RAT Studio World'); scene.world.color=(.28,.28,.28)
    scene.view_settings.view_transform='AgX'; scene.view_settings.look='AgX - Medium High Contrast'
    for name,at,power,size in [('Key',(-3,-4,6),650,5),('Fill',(4,-2,4),450,4),('Rim',(0,3,5),700,3)]:
        bpy.ops.object.light_add(type='AREA',location=at); o=bpy.context.object; o.name=name; o.data.energy=power*.65; o.data.shape='DISK'; o.data.size=size; o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add(location=(0,-6,4.5)); cam=bpy.context.object; cam.name='Sprite camera'; cam.data.type='ORTHO'; cam.data.ortho_scale=3.4; scene.camera=cam; cam.rotation_euler=(Vector((0,0,1.25))-cam.location).to_track_quat('-Z','Y').to_euler()
    manifest={}
    for k in CAST+PROPS:
        parts.clear(); character(k) if k in CAST else prop(k)
        coll=bpy.data.collections.new(k); scene.collection.children.link(coll)
        root=bpy.data.objects.new(k+'_root',None); coll.objects.link(root)
        for o in parts:
            for c in list(o.users_collection): c.objects.unlink(o)
            coll.objects.link(o); o.parent=root
        coll.hide_render=True
        manifest[k]={'directions':8 if k in CAST else 1,'collection':k,'triangles':sum(len(o.data.polygons)*2 for o in parts)}
        if k in IDENTITIES: manifest[k]['visual_identity']=IDENTITIES[k]
    with open(os.path.join(ROOT,'art','asset-manifest.json'),'w') as f: json.dump(manifest,f,indent=2)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art','picnic-cast.blend'))
    print('Built',len(manifest),'assets')

def render():
    scene=bpy.data.scenes['RAT Asset Studio']; bpy.context.window.scene=scene
    for k in CAST+PROPS:
        coll=bpy.data.collections[k]; coll.hide_render=False
        # Preserve the mixed MS Paint / human appearance on a full cast render.
        scene.view_settings.view_transform='Standard' if k in ['bird','fox','owl','snake'] else 'AgX'
        scene.view_settings.look='None' if k in ['bird','fox','owl','snake'] else 'AgX - Medium High Contrast'
        scene.render.dither_intensity=0 if k in ['bird','fox','owl','snake'] else 1
        root=bpy.data.objects[k+'_root']; cam=scene.camera
        cam.data.ortho_scale=3.6 if k in CAST else 1.9
        target=Vector((0,0,1.25 if k in CAST else .65)); cam.location=(0,-6,4.5 if k in CAST else 3.9); cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        if k in ['cat', 'fox']:
            target=Vector((0,.55,2.45)); cam.location=(0,-9,7)
            cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        elif k=='owl':
            target=Vector((0,0,3.0)); cam.location=(0,-10,7.3)
            cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        elif k=='snake':
            target=Vector((0,.35,2.75)); cam.location=(0,-10,7.3)
            cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        elif k=='bird':
            target=Vector((0,.15,2.8)); cam.location=(0,-10,7.3)
            cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        if k in CAST:
            # One stable frame per character, fitted over every facing. Crowns,
            # quiffs and tails must never hit the sprite border during a turn.
            bpy.context.view_layer.update()
            right=cam.rotation_euler.to_matrix() @ Vector((1,0,0))
            up=cam.rotation_euler.to_matrix() @ Vector((0,1,0))
            extent=0.0
            for i in range(8):
                turn=Matrix.Rotation(math.pi/2-i*math.tau/8,4,'Z')
                for obj in coll.objects:
                    if obj.type != 'MESH': continue
                    for corner in obj.bound_box:
                        offset=turn @ obj.matrix_world @ Vector(corner)-target
                        extent=max(extent,abs(offset.dot(right)),abs(offset.dot(up)))
            cam.data.ortho_scale=max(3.6,extent*2.12)
        for i in range(8 if k in CAST else 1):
            root.rotation_euler.z=math.pi/2-i*math.tau/8 if k in CAST else -.25
            scene.render.filepath=os.path.join(OUT,k+'_'+str(i)+'.png'); bpy.ops.render.render(write_still=True)
        root.rotation_euler.z=0; coll.hide_render=True
    print('RAT_RENDER_COMPLETE')
if __name__=='__main__':
    if '--render' in __import__('sys').argv: render()
    else: build()
