import bpy, math, os, json
from mathutils import Vector
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT,'assets','sprites')
CAST = ['rat','bird','cat','owl','snake','raccoon','fox','alpha_cat','junkyard_dog','barn_owl']
PROPS = ['cheese','rapid','triple','power','haste','shield','pierce','seed','feather','venom','bone','sonic','crumb','fizzy']
COLORS={'ink':'292133','cream':'fff0c5','pink':'e78396','red':'d84037','gold':'f6be32','green':'75ae35','metal':'8ca9ae','brown':'8d512d','rat':'888a98','bird':'258dc1','cat':'8852a8','owl':'996538','snake':'70a237','raccoon':'8a9298','fox':'e97824','alpha_cat':'b64079','junkyard_dog':'b58b5c','barn_owl':'dab67c'}
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
def eyes(z=1.95,y=-.54,size=.22):
    for s in [-1,1]:
        ball('Eye white',(s*.26,y,z),(size,.13,size*1.15),'cream')
        ball('Pupil',(s*.26+.04,y-.115,z-.025),(.078,.045,.12),'ink')
        ball('Glint',(s*.26+.065,y-.153,z+.025),(.022,.015,.032),'cream')
        rod('Crooked brow',(s*.09,y-.10,z+.23),(s*.47,y-.06,z+.30 if s<0 else z+.19),.065,'ink')
def character(k):
    bird=k in ['bird','owl','barn_owl']; snake=k=='snake'
    if snake:
        for i in range(18):
            a=i*.55; ball('Coil',(math.cos(a)*.56,math.sin(a)*.44,.25+i*.022),(.27,.27,.24),k)
        for i in range(6): ball('Neck',(.08,0,.65+i*.18),(.28,.27,.3),k)
    else:
        ball('Pear belly',(0,.08,.92),(.66 if k in ['cat','alpha_cat','junkyard_dog'] else .49,.40,.68),k)
        ball('Bib',(0,-.29,.91),(.37,.15,.46),'cream')
        for s in [-1,1]:
            ball('Big foot',(s*.33,-.19,.16),(.25,.35,.15),'gold' if bird else ('pink' if k=='rat' else k))
            arm=ball('Wing' if bird else 'Arm',(s*.56,0,1.02),(.21,.24,.52),k); arm.rotation_euler.y=s*.4
    ball('Oversized head',(0,-.05,1.78),(.59,.44,.53),k)
    if k in ['owl','barn_owl']:
        for s in [-1,1]: ball('Face disk',(s*.28,-.43,1.9),(.32,.12,.35),'cream')
    if k=='raccoon':
        for s in [-1,1]: ball('Bandit mask',(s*.27,-.47,1.95),(.28,.10,.26),'ink')
    eyes()
    if bird:
        beak=cone('Beak',(0,-.68,1.64),(.20,.21,.34),'gold'); beak.rotation_euler.x=math.pi/2
        if k=='bird':
            for i in range(3): cone('Pompadour',(-.22+i*.18,.03,2.43+i*.08),(.17,.19,.43),'gold')
        else:
            for s in [-1,1]: cone('Tuft',(s*.43,.03,2.28),(.16,.19,.32),k)
    else:
        ball('Smile',(0,-.46,1.53),(.36,.15,.19),'ink')
        for s in [-1,1]: ball('Muzzle',(s*.19,-.51,1.68),(.26,.23,.17),'cream')
        ball('Nose',(0,-.74,1.75),(.14,.11,.10),'pink' if k in ['rat','cat','alpha_cat'] else 'ink')
        for s in [-1,1]: box('Wonky tooth',(s*.10,-.62,1.47),(.075,.065,.14 if k=='rat' else .075),'cream')
        if not snake:
            for s in [-1,1]:
                if k=='rat':
                    ball('Giant ear',(s*.52,.02,2.25),(.34,.14,.43),k); ball('Ear pink',(s*.52,-.095,2.25),(.25,.045,.32),'pink')
                elif k=='junkyard_dog': ball('Floppy ear',(s*.57,.03,2.0),(.18,.20,.4),'brown')
                else:
                    cone('Pointed ear',(s*.43,.05,2.27),(.23,.20,.38),k); cone('Inner ear',(s*.43,-.10,2.28),(.12,.045,.23),'pink')
            for s in [-1,1]:
                for z in [1.62,1.70]: rod('Whisker',(s*.31,-.62,z),(s*.74,-.60,z+.08*s),.014,'ink')
    if k=='rat':
        ring('Scarf',(0,0,1.35),.38,.12,'red'); cone('Scarf flap',(-.60,.14,1.23),(.24,.09,.45),'red')
        for i in range(8): rod('Pink tail',(.06+i*.13,.32+i*.10,.37+math.sin(i*.6)*.12),(.19+i*.13,.42+i*.1,.37+math.sin((i+1)*.6)*.12),.06-i*.005,'pink')
        rod('Seed blaster',(.43,-.30,.99),(.43,-1.02,.99),.15,'brown'); rod('Barrel',(.43,-.9,.99),(.43,-1.1,.99),.18,'green'); ball('Bore',(.43,-1.105,.99),(.12,.025,.12),'ink')
    if k in ['fox','raccoon','cat','alpha_cat']:
        for i in range(5):
            color='cream' if k=='fox' and i>2 else ('ink' if k=='raccoon' and i%2 else k)
            ball('Tail',( .35+i*.14,.32+i*.14,.45+i*.20),(.26,.25,.32),color)
    if k=='raccoon':
        o=ring('Trash lid rim',(.65,-.50,.83),.43,.06,'metal'); o.rotation_euler.x=math.pi/2
        ball('Trash lid',(.65,-.48,.83),(.43,.09,.43),'metal'); rod('Lid handle',(.55,-.62,.83),(.75,-.62,.83),.06,'ink')
    if k=='alpha_cat':
        ring('Crown band',(0,0,2.34),.4,.09,'gold')
        for i in range(5):
            a=i*math.tau/5; cone('Crown point',(.38*math.cos(a),.38*math.sin(a),2.54),(.12,.12,.24),'gold')
    if k=='junkyard_dog':
        ring('Collar',(0,0,1.26),.47,.12,'red'); ball('Tongue',(.14,-.64,1.31),(.13,.08,.27),'pink')
        for s in [-1,1]: cone('Collar spike',(s*.43,-.28,1.35),(.10,.10,.22),'cream')
    if k=='barn_owl':
        box('Professor cap',(0,0,2.43),(.59,.48,.06),'ink'); rod('Tassel',(.52,0,2.47),(.62,-.05,2.03),.035,'gold')
    if snake:
        rod('Tongue',(0,-.65,1.5),(0,-1.02,1.46),.035,'red')
        for s in [-1,1]: rod('Fork',(0,-1.02,1.46),(s*.12,-1.17,1.48),.025,'red')
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
    with open(os.path.join(ROOT,'art','asset-manifest.json'),'w') as f: json.dump(manifest,f,indent=2)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art','picnic-cast.blend'))
    print('Built',len(manifest),'assets')

def render():
    scene=bpy.data.scenes['RAT Asset Studio']; bpy.context.window.scene=scene
    for k in CAST+PROPS:
        coll=bpy.data.collections[k]; coll.hide_render=False
        root=bpy.data.objects[k+'_root']; cam=scene.camera
        cam.data.ortho_scale=3.4 if k in CAST else 1.9
        target=Vector((0,0,1.25 if k in CAST else .65)); cam.location=(0,-6,4.5 if k in CAST else 3.9); cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        for i in range(8 if k in CAST else 1):
            root.rotation_euler.z=math.pi/2-i*math.tau/8 if k in CAST else -.25
            scene.render.filepath=os.path.join(OUT,k+'_'+str(i)+'.png'); bpy.ops.render.render(write_still=True)
        root.rotation_euler.z=0; coll.hide_render=True
    print('RAT_RENDER_COMPLETE')
if __name__=='__main__':
    if '--render' in __import__('sys').argv: render()
    else: build()
