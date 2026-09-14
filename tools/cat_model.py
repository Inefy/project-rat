"""Reference cat: authored mesh geometry, no external textures or add-ons.

Coordinates: front -Y, up +Z, ground Z=0. Three export materials use vertex
colors, so the editable sculpt and the GLB share exactly the same appearance.
"""
import math
import random
import bpy
from mathutils import Vector

IDENTITY = 'Black long-legged cat, charcoal face, green ring eyes, human hands, bloodied fangs and S-shaped knife tail'
PARTS = []
BLACK = (.006, .007, .008, 1)
FACE = (.039, .040, .041, 1)
SKIN = (.145, .091, .076, 1)
BLOOD = (.52, .006, .012, 1)
BONE = (.86, .86, .79, 1)
EYES = (.002, .62, .015, 1)


def material(name, roughness=.93, metallic=0, emission=0):
    name = 'CAT_' + name
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    p = nt.nodes.new('ShaderNodeBsdfPrincipled')
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    p.inputs['Specular IOR Level'].default_value = .08 if not metallic else .5
    c = nt.nodes.new('ShaderNodeVertexColor')
    c.layer_name = 'Color'
    nt.links.new(c.outputs['Color'], p.inputs['Base Color'])
    if emission:
        # glTF supports a constant emission color, not vertex-colored emission.
        p.inputs['Emission Color'].default_value = EYES
        p.inputs['Emission Strength'].default_value = emission
    nt.links.new(p.outputs['BSDF'], out.inputs['Surface'])
    return m


def colorize(obj, color, variation=0, skin=False):
    attr = obj.data.color_attributes.get('Color')
    if attr:
        obj.data.color_attributes.remove(attr)
    attr = obj.data.color_attributes.new(name='Color', type='BYTE_COLOR', domain='CORNER')
    colors = []
    for v in obj.data.vertices:
        p = v.co
        noise = math.sin(p.x*74 + p.y*39 + p.z*63)*.45 + math.sin(p.x*137-p.y*81)*.20
        factor = 1 + noise*variation
        if skin:
            # Dark fingers/palm crevices; subtly warm, mottled dorsal surface.
            factor *= .72 + .32*max(0, min(1, p.z/.34))
            factor *= 1 + .09*math.sin(p.y*21 + p.x*28)
        colors.append(tuple(max(0, min(1, c*factor)) for c in color[:3]) + (color[3],))
    for l in obj.data.loops:
        attr.data[l.index].color = colors[l.vertex_index]


def finish(obj, name, color=BLACK, mat=None, variation=0, skin=False):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mat or material('Surface'))
    colorize(obj, color, variation, skin)
    for p in obj.data.polygons:
        p.use_smooth = True
    PARTS.append(obj)
    return obj


def mesh(name, verts, faces, color=BLACK, mat=None):
    me = bpy.data.meshes.new(name + ' mesh')
    me.from_pydata(verts, [], faces)
    me.update()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj, name, color, mat)


def ball(name, at, scale, color=BLACK, segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=at)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, color)


def sample_path(points, steps=4):
    pts = [Vector(p) for p in points]
    result = []
    for i in range(len(pts)-1):
        a, b, c, d = pts[max(0,i-1)], pts[i], pts[i+1], pts[min(len(pts)-1,i+2)]
        for j in range(steps):
            t = j/steps
            result.append((2*b + (-a+c)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t)*.5)
    result.append(pts[-1])
    return result


def tube(name, points, radii, color=BLACK, sides=10, steps=4, flatten=1, mat=None):
    centers = sample_path(points, steps)
    verts, faces = [], []
    prior = None
    for i, c in enumerate(centers):
        tangent = (centers[min(i+1,len(centers)-1)]-centers[max(0,i-1)]).normalized()
        if prior is None:
            ref = Vector((0,0,1)) if abs(tangent.z)<.9 else Vector((0,1,0))
            normal = tangent.cross(ref).normalized()
        else:
            normal = (prior - tangent*prior.dot(tangent)).normalized()
        prior = normal
        other = tangent.cross(normal).normalized()
        t = min(len(radii)-1.000001, i/(len(centers)-1)*(len(radii)-1))
        r0, u = int(t), t-int(t)
        radius = radii[r0]*(1-u)+radii[min(r0+1,len(radii)-1)]*u
        for k in range(sides):
            a = k*math.tau/sides
            verts.append(c + radius*(math.cos(a)*normal + math.sin(a)*other*flatten))
        if i:
            for k in range(sides):
                p=(i-1)*sides+k; q=(i-1)*sides+(k+1)%sides
                faces.append((p,q,q+sides,p+sides))
    faces += [tuple(reversed(range(sides))), tuple((len(centers)-1)*sides+k for k in range(sides))]
    return mesh(name, verts, faces, color, mat)


def loft(name, rings, sides=20, power=1, color=BLACK):
    # Ring tuples: center X, center Y, Z, half-width, half-depth.
    verts, faces = [], []
    for i,(x,y,z,w,d) in enumerate(rings):
        for k in range(sides):
            a=k*math.tau/sides
            co,si=math.cos(a),math.sin(a)
            verts.append((x + w*math.copysign(abs(co)**power,co), y+d*math.copysign(abs(si)**power,si), z))
        if i:
            for k in range(sides):
                p=(i-1)*sides+k; q=(i-1)*sides+(k+1)%sides
                faces.append((p,q,q+sides,p+sides))
    faces += [tuple(reversed(range(sides))), tuple((len(rings)-1)*sides+k for k in range(sides))]
    return mesh(name,verts,faces,color)


def union(parts, name, voxel, tris, color, variation=0, skin=False):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:
        p.select_set(True)
        if p in PARTS: PARTS.remove(p)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    remesh=obj.modifiers.new('Continuous sculpt surface','REMESH')
    remesh.mode='VOXEL'; remesh.voxel_size=voxel; remesh.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=obj.modifiers.new('Relax sculpt','SMOOTH'); smooth.factor=.55; smooth.iterations=3
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    obj.data.calc_loop_triangles()
    dec=obj.modifiers.new('Browser triangle budget','DECIMATE')
    dec.ratio=min(1,tris/max(1,len(obj.data.loop_triangles)))
    bpy.ops.object.modifier_apply(modifier=dec.name)
    return finish(obj,name,color,variation=variation,skin=skin)


def build_hands():
    hand_start=len(PARTS)
    palm=[]
    palm.append(ball('Palm volume',(0,-.03,.22),(.255,.34,.14),SKIN))
    palm.append(ball('Heel of palm',(0,.16,.29),(.19,.18,.20),SKIN))
    palm.append(tube('Wrist',[(0,.19,.31),(0,.24,.46),(.005,.24,.59)],[.15,.13,.11],SKIN))
    fingers=[]
    for i,(x,l,splay) in enumerate([(-.18,.44,-.10),(-.06,.54,-.015),(.07,.52,.06),(.19,.40,.14)]):
        # Splayed load-bearing human fingers: high knuckle, bent middle joint,
        # grounded fingertip, distinct phalanges, not animal toes.
        points=[(x,-.19,.27),(x+splay*.25,-.34,.28),(x+splay*.67,-.34-l*.48,.215),(x+splay,-.34-l,.088)]
        r=.079 if i<3 else .068
        palm.append(tube('Finger sculpt',points,[r*1.19,r*1.06,r*.82,r*.66],SKIN,sides=10,steps=3))
        palm.append(ball('Knuckle sculpt',points[1],(r*1.1,r*.94,r*.91),SKIN,12,8))
        palm.append(ball('Tip sculpt',points[-1],(r*.70,r*.91,r*.63),SKIN,12,8))
        fingers.append((points,r))
    thumb=[(-.17,.055,.24),(-.30,-.10,.18),(-.37,-.26,.105),(-.38,-.38,.078)]
    palm.append(tube('Opposable thumb sculpt',thumb,[.1,.091,.074,.052],SKIN,steps=4))
    palm.append(ball('Thumb tip sculpt',thumb[-1],(.058,.073,.056),SKIN,12,8))
    hand=union(palm,'Human hand skin',.018,1150,SKIN,variation=.46,skin=True)
    # Nails follow the finger tips, with a dark rim and a small rounded plate.
    for i,(points,r) in enumerate(fingers+[(thumb,.073)]):
        tip=Vector(points[-1]); prev=Vector(points[-2]); direction=(tip-prev).normalized()
        center=tip-direction*.018+Vector((0,0,.057))
        border=ball('Nail bed',center,(r*.59,r*.80,.010),(.035,.019,.017,1),10,6)
        border.rotation_euler.z=-math.atan2(direction.x,-direction.y)
        border.rotation_euler.x=.48
        nail=ball('Dull human nail',center+Vector((0,-.007,.008)),(r*.47,r*.68,.008),(.15,.093,.070,1),10,6)
        nail.rotation_euler.z=border.rotation_euler.z
        nail.rotation_euler.x=.48
        # Transverse skin folds across the bent joints.
        for t in [.0,.045]:
            q=Vector(points[1])+direction*t
            tube('Finger crease',[(q.x-r*.64,q.y,.331-t*.30),(q.x,q.y-.007,.350-t*.30),(q.x+r*.64,q.y,.331-t*.30)], [.003,.004,.003],(.055,.033,.028,1),sides=5,steps=2)
    # Dorsal tendons and branching veins are intentionally modest geometry.
    for i,x in enumerate([-.16,-.055,.065,.17]):
        tube('Hand tendon',[(x*.30,.23,.409),(x*.70,.065,.369),(x,-.09,.339),(x,-.24,.342)], [.010,.013,.010,.004],(.175,.115,.097,1),sides=5,steps=2)
    for pts in [[(-.10,.20,.393),(-.13,.09,.362),(-.09,-.035,.355),(-.15,-.14,.323)],[(.065,.21,.397),(.1,.06,.369),(.055,-.035,.366),(.07,-.15,.342)],[(.09,.07,.37),(.17,.012,.344),(.2,-.065,.302)]]:
        tube('Dorsal vein',pts,[.006,.007,.006,.003],(.095,.069,.059,1),sides=5,steps=2)
    # Wrist folds; each is a short curved crease around the front of the wrist.
    for z,y in [(.44,.19),(.47,.21),(.5,.225)]:
        tube('Wrist fold',[(-.11,y-.063,z),(-.055,y-.11,z+.009),(.055,y-.11,z+.006),(.11,y-.055,z)], [.005,.006,.006,.004],(.05,.03,.025,1),sides=5,steps=2)
    prototypes=list(PARTS[hand_start:])
    places=[(-.64,-1.01,0,-.10),(.64,-1.01,0,.13),(-.64,1.37,0,-.12),(.64,1.37,0,.16)]
    for idx,(x,y,z,angle) in enumerate(places):
        for orig in prototypes:
            o=orig if idx==0 else orig.copy()
            if idx:
                o.data=orig.data.copy(); bpy.context.scene.collection.objects.link(o); PARTS.append(o)
            # Prototypes carry primitive locations. Transform all vertices via
            # an explicit matrix before the original is moved for other copies.
    # Rebuild transforms from snapshots so duplicate hands stay identical.
    from mathutils import Matrix
    snapshots=[(p,p.matrix_world.copy()) for p in prototypes]
    all_hands=PARTS[hand_start:]
    for idx,(x,y,z,angle) in enumerate(places):
        transform=Matrix.Translation((x,y,z)) @ Matrix.Rotation(angle,4,'Z')
        for j,(_,original_matrix) in enumerate(snapshots):
            o=all_hands[idx*len(prototypes)+j]
            o.matrix_world=transform @ original_matrix
            o.name=f'{"Front" if idx<2 else "Rear"} {"left" if idx%2==0 else "right"} {o.name}'


def build_cat():
    PARTS.clear()
    body=[]
    body.append(ball('Long black ribcage',(0,.43,2.14),(.61,1.23,.48)))
    body.append(ball('Raised shoulders',(0,-.55,2.39),(.60,.69,.58)))
    body.append(ball('Haunches',(0,1.28,2.02),(.60,.48,.55)))
    body.append(loft('Tall flat skull and neck',[(0,-.86,1.89,.40,.28),(0,-.88,2.30,.62,.40),(0,-.87,2.90,.69,.43),(0,-.86,3.45,.71,.44),(0,-.83,3.85,.72,.42),(0,-.8,4.01,.51,.32)],power=.72))
    # Thin, slightly crooked triangular ears; the eye line stays well below them.
    for s in [-1,1]:
        body.append(loft('Tall pointed ear',[(s*.53,-.80,3.76,.30,.29),(s*.67,-.79,4.13,.23,.20),(s*.82,-.77,4.52,.13,.11),(s*(.89 if s<0 else .87),-.77,4.77,.023,.025)],sides=12,power=.9))
    for s in [-1,1]:
        body.append(tube('Long front leg',[(s*.53,-.76,2.42),(s*.61,-.75,1.92),(s*.62,-.73,1.45),(s*.62,-.79,.92),(s*.64,-.77,.51)],[.22,.165,.108,.092,.115],sides=12,steps=4))
        body.append(tube('Long rear leg',[(s*.45,1.15,2.13),(s*.62,1.30,1.73),(s*.61,1.58,1.18),(s*.64,1.66,.85),(s*.64,1.61,.49)],[.24,.17,.106,.088,.117],sides=12,steps=4))
    body_obj=union(body,'Cat continuous black body',.032,3900,BLACK,variation=.1)
    for v in body_obj.data.vertices:
        if v.co.z>3.75 and abs(v.co.x)<.58:
            v.co.z-=.13*(1-abs(v.co.x)/.58)*min(1,(v.co.z-3.75)/.18)
    # Charcoal face and bib form a shallow convex patch on the solid head.
    outline=[(-.59,3.86),(-.71,4.26),(-.82,4.53),(-.72,3.73),(-.60,3.37),(-.62,2.91),(-.61,2.44),(-.51,1.78),(-.45,1.47),(-.34,1.99),(-.19,2.20),(-.07,2.24),(.11,2.09),(.25,1.91),(.42,1.45),(.51,1.88),(.60,2.44),(.61,3.02),(.65,3.40),(.61,3.61),(.71,3.96),(.75,4.42),(.61,4.14),(.47,3.87),(.27,3.77),(-.05,3.75),(-.30,3.83)]
    def face_y(x,z):
        return -1.315 + .087*(abs(x)/.72)**2 + max(0,z-3.9)*.62 + max(0,2.3-z)*.09
    from mathutils.geometry import tessellate_polygon
    # Subdivide a triangulated outline to allow convex facial shading.
    verts=[(x,face_y(x,z)-.018,z) for x,z in outline]
    vectors=[Vector((v[0],0,v[2])) for v in verts]
    triangles=tessellate_polygon([vectors])
    faces=[tuple(v if isinstance(v,int) else vectors.index(v) for v in t) for t in triangles]
    patch=mesh('Charcoal face with pointed chest bib',verts,faces,FACE)
    import bmesh
    bm=bmesh.new();bm.from_mesh(patch.data)
    bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=5,use_grid_fill=True)
    for v in bm.verts:
        v.co.y=face_y(v.co.x,v.co.z)-.022
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(patch.data);bm.free()
    bpy.context.view_layer.objects.active=patch
    bpy.ops.object.select_all(action='DESELECT'); patch.select_set(True)
    sol=patch.modifiers.new('Bib thickness','SOLIDIFY'); sol.thickness=.035
    bpy.ops.object.modifier_apply(modifier=sol.name)
    for p in patch.data.polygons:p.use_smooth=True
    colorize(patch,FACE)
    # Round, fluorescent green annuli with black circular pupils.
    for s in [-1,1]:
        x=s*.345; z=3.54; y=-1.344
        ball('Black eye socket',(x,y+.013,z),(.118,.026,.118),(.002,.003,.002,1),24,10)
        vs,fs=[],[]
        for radius in [.050,.094]:
            for i in range(28):
                a=i*math.tau/28; vs.append((x+radius*math.cos(a),y-.022,z+radius*math.sin(a)))
        for i in range(28): fs.append((i,(i+1)%28,(i+1)%28+28,i+28))
        mesh('Emerald ring iris',vs,fs,EYES,material('Eyes',.55,emission=.25))
        ball('Round black pupil',(x,y-.025,z),(.050,.01,.050),(.001,.002,.001,1),20,8)
    ball('Small black nose',(0,-1.385,3.19),(.078,.048,.047),(.001,.001,.001,1),16,8)
    for s in [-1,1]:
        ball('Nose nostril',(s*.052,-1.398,3.163),(.041,.028,.030),(.001,.001,.001,1),12,6)
    tube('Quiet curved mouth',[(-.29,-1.352,2.78),(-.16,-1.357,2.758),(0,-1.36,2.722),(.18,-1.357,2.75),(.34,-1.35,2.81)],[.025,.026,.027,.024,.020],(.001,.001,.001,1),sides=8,steps=4)
    for s in [-1,1]:
        tube('Irregular white fang',[(s*.23,-1.375,2.777),(s*.245,-1.385,2.706),(s*.28,-1.40,2.613),(s*.30,-1.396,2.57)],[.061,.048,.034,.008],BONE,sides=9,steps=3)
        tube('Blood on fang',[(s*.238,-1.425,2.739),(s*.258,-1.43,2.68),(s*.286,-1.43,2.637)],[.015,.020,.012],BLOOD,sides=6,steps=3)
    marks=[([(-.018,3.143),(-.034,3.048),(-.044,2.93)],.017),([(.035,3.15),(.045,3.079)],.014),([(-.43,2.747),(-.49,2.64)],.018),([(-.44,2.52),(-.34,2.50)],.017),([(-.20,2.59),(-.17,2.50)],.016),([(-.04,2.70),(-.031,2.63)],.017),([(.095,2.63),(.075,2.57),(.046,2.51)],.016),([(.36,2.63),(.38,2.60)],.017),([(.43,2.54),(.40,2.45)],.017),([(.20,2.47),(.23,2.38),(.29,2.31)],.018),([(-.29,2.34),(-.34,2.27),(-.38,2.20)],.019),([(.06,2.23),(.12,2.18),(.14,2.12)],.018),([(-.29,2.04),(-.34,1.94)],.019),([(.34,2.15),(.42,1.98),(.45,1.87),(.42,1.79)],.018)]
    for coords,width in marks:
        tube('Red dripped marking',[(x,face_y(x,z)-.049,z) for x,z in coords],[width]*len(coords),BLOOD,sides=6,steps=3)
    # Tall smooth S tail, preserving both reverse bends of the drawing.
    curves=[
        [(.10,1.50,2.0),(.65,2.02,2.12),(.67,2.08,2.57),(.24,1.85,2.91)],
        [(.24,1.85,2.91),(-.15,1.64,3.23),(.16,2.09,3.42),(.58,2.46,3.67)],
        [(.58,2.46,3.67),(.97,2.80,3.99),(.45,2.20,4.18),(.10,1.91,4.35)],
        [(.10,1.91,4.35),(-.30,1.56,4.58),(.01,1.99,4.90),(.47,2.45,4.99)],
    ]
    tail_pts=[]
    for curve in curves:
        a,b,c,d=[Vector(p) for p in curve]
        for i in range(16):
            t=i/16
            p=(1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d
            tail_pts.append((p.x,p.y,2+(p.z-2)*.89))
    tail_pts.append((.47,2.45,2+(4.99-2)*.89))
    tube('S-shaped black tail',tail_pts,[.21,.18,.18,.17,.155,.14,.125,.105],sides=12,steps=1)
    # The blade lies in the tail's vertical plane and has a beveled steel edge.
    start=Vector(tail_pts[-1]); along=Vector((.73,.68,0)); normal=Vector((-.68,.73,0))
    outline=[(0,-.12),(.30,-.055),(.53,.095),(.69,.28),(.34,.18),(0,.10)]
    vs=[]
    for depth in [-.025,.025]:
        vs.extend(start+along*u+Vector((0,0,z))+normal*depth for u,z in outline)
    vs.extend([start+along*.22+Vector((0,0,.066))+normal*d for d in [-.046,.046]])
    fs=[]
    for side in range(2):
        for i in range(6):
            f=(side*6+i,side*6+(i+1)%6,12+side)
            fs.append(f if side else tuple(reversed(f)))
    fs.extend((i,(i+1)%6,(i+1)%6+6,i+6) for i in range(6))
    blade=mesh('Curved pointed steel tail blade',vs,fs,(.43,.47,.48,1),material('Steel',.28,metallic=.85))
    for p in blade.data.polygons:p.use_smooth=False
    colorize(blade,(.46,.48,.48,1),variation=.25)
    rng=random.Random(121)
    for side in [-1,1]:
        for i in range(17):
            u=rng.uniform(.025,.25); z=rng.uniform(-.075,.105)
            if z < -.12+.24*u:
                continue
            c=start+along*u+Vector((0,0,z))+normal*(side*.048)
            radius=rng.uniform(.012,.033)
            # Flat opaque blood spots follow the blade plane, with no textures.
            v=[c+along*math.cos(a*math.tau/7)*radius+Vector((0,0,math.sin(a*math.tau/7)*radius*.8)) for a in range(7)]
            mesh('Blood stain on steel',v,[tuple(range(7))],(.20+rng.random()*.10,.005,.008,1))
    build_hands()
    # Fine marks do not need the tessellation used while authoring them. Keep
    # silhouette geometry and hand anatomy intact, simplify small surface parts.
    for obj in PARTS:
        ratio=1
        if 'Charcoal' in obj.name:ratio=.25
        elif 'Nail' in obj.name or 'nail' in obj.name:ratio=.30
        elif 'pupil' in obj.name or 'eye socket' in obj.name:ratio=.35
        elif any(s in obj.name for s in ['crease','tendon','vein','fold','Red dripped']):ratio=.50
        if ratio<1:
            bpy.context.view_layer.objects.active=obj
            dec=obj.modifiers.new('Small detail simplification','DECIMATE');dec.ratio=ratio
            bpy.ops.object.modifier_apply(modifier=dec.name)
    return list(PARTS)
