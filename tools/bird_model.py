"""Reference bird: filled MS Paint body, many-eyed feather wings, human feet.

Authored in the drawing's X/Z plane, then turned to face game-forward (-Y).
The wing backs, second-sided eyes and body depth are inferred from one image.
"""
import math

import bpy
from mathutils import Matrix, Vector
from mathutils.geometry import tessellate_polygon
from fox_model import linear, sample

IDENTITY = 'Solid MS Paint orange bird, yellow beak, white feather wings covered in golden human eyes, and realistic human feet'
PARTS = []
ORANGE = linear('a94a00')
YELLOW = linear('ffb600')
BLACK = linear('000000')
SKIN = linear('cd977e')


def material(kind):
    name = 'BIRD_' + kind
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    color = nodes.new('ShaderNodeVertexColor')
    color.layer_name = 'Color'
    shader = nodes.get('Principled BSDF')
    if kind == 'Paint':
        nodes.remove(shader)
        emission = nodes.new('ShaderNodeEmission')
        links.new(color.outputs['Color'], emission.inputs['Color'])
        rays = nodes.new('ShaderNodeLightPath')
        shadow = nodes.new('ShaderNodeBsdfDiffuse')
        shadow.inputs['Color'].default_value = (0,0,0,1)
        mix = nodes.new('ShaderNodeMixShader')
        links.new(rays.outputs['Is Camera Ray'], mix.inputs[0])
        links.new(shadow.outputs[0], mix.inputs[1])
        links.new(emission.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], nodes.get('Material Output').inputs['Surface'])
    else:
        shader.inputs['Roughness'].default_value = {'Feather':.60,'Skin':.48,'Eye':.19}[kind]
        shader.inputs['Specular IOR Level'].default_value = .38 if kind == 'Eye' else .26
        shader.inputs['Subsurface Weight'].default_value = .055 if kind == 'Skin' else 0
        links.new(color.outputs['Color'], shader.inputs['Base Color'])
        if kind == 'Skin':
            noise = nodes.new('ShaderNodeTexNoise')
            noise.inputs['Scale'].default_value = 115
            noise.inputs['Detail'].default_value = 3
            bump = nodes.new('ShaderNodeBump')
            bump.inputs['Strength'].default_value = .08
            bump.inputs['Distance'].default_value = .003
            links.new(noise.outputs['Fac'], bump.inputs['Height'])
            links.new(bump.outputs['Normal'], shader.inputs['Normal'])
    return mat


def finish(obj, name, color, kind='Paint', colors=None):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material(kind))
    old = obj.data.color_attributes.get('Color')
    if old:
        obj.data.color_attributes.remove(old)
    attr = obj.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for loop in obj.data.loops:
        p = obj.data.vertices[loop.vertex_index].co
        c = colors[loop.vertex_index] if colors else color
        variation = 1+.045*math.sin(p.x*53+p.y*41+p.z*87) if kind == 'Skin' else 1
        attr.data[loop.index].color = tuple(min(1,max(0,v*variation)) for v in c[:3])+(1,)
    for face in obj.data.polygons:
        face.use_smooth = True
    PARTS.append(obj)
    return obj


def mesh(name, verts, faces, color, kind='Paint', colors=None):
    data = bpy.data.meshes.new(name+' mesh')
    data.from_pydata(verts,[],faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj,name,color,kind,colors)


def ball(name, at, scale, color, kind='Paint', segments=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=at)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,name,color,kind)


def tube(name, points, radii, color, kind='Paint', sides=8, steps=3, depth=1):
    centers = sample(points,steps)
    verts, faces = [], []
    for j,p in enumerate(centers):
        tangent = (centers[min(j+1,len(centers)-1)]-centers[max(0,j-1)]).normalized()
        normal = tangent.cross(Vector((0,1,0))).normalized()
        other = tangent.cross(normal).normalized()
        t = j/(len(centers)-1)*(len(radii)-1)
        k = min(int(t),len(radii)-2)
        radius = radii[k]*(1-t+k)+radii[k+1]*(t-k)
        for i in range(sides):
            angle = math.tau*i/sides
            verts.append(p+radius*(normal*math.cos(angle)+other*math.sin(angle)*depth))
        if j:
            for i in range(sides):
                a,b = (j-1)*sides+i,(j-1)*sides+(i+1)%sides
                faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(centers)-1)*sides+i for i in range(sides))]
    return mesh(name,verts,faces,color,kind)


def paint_fill(name, points, depth, steps):
    """Close the brush silhouette with a lightweight, solid orange extrusion."""
    border = sample(points,steps)[:-1]
    # The cap follows exactly the same curve as the existing brush stroke.
    cap = [Vector((p.x,-depth,p.z)) for p in border]
    verts = cap + [Vector((p.x,depth,p.z)) for p in border]
    count = len(cap)
    faces = []
    for triangle in tessellate_polygon([cap]):
        a,b,c = triangle
        if (cap[b]-cap[a]).cross(cap[c]-cap[a]).y > 0:
            b,c = c,b
        faces.extend([(a,b,c),(c+count,b+count,a+count)])
    for i in range(count):
        j = (i+1)%count
        faces.append((i,j,j+count,i+count))
    return mesh(name,verts,faces,ORANGE)


def rounded_bill():
    """A single closed, rounded yellow bill that stays whole while turning."""
    # X, height of center, half-width, half-height. The raised base and broad,
    # gently tapered tip follow the reference's hand-painted yellow dab.
    profile=[(2.44,3.18,.10,.09),(2.51,3.20,.28,.145),
             (2.61,3.23,.34,.19),(2.76,3.19,.33,.17),
             (2.94,3.14,.26,.125),(3.08,3.09,.16,.075),
             (3.15,3.08,.07,.048)]
    centers=sample([(x,0,z) for x,z,w,h in profile],2)
    radii=sample([(x,w,h) for x,z,w,h in profile],2)
    verts,faces=[],[]
    sides=16
    for j,(center,radius) in enumerate(zip(centers,radii)):
        for i in range(sides):
            angle=math.tau*i/sides
            verts.append(center+Vector((0,radius.y*math.cos(angle),radius.z*math.sin(angle))))
        if j:
            for i in range(sides):
                a=(j-1)*sides+i;b=(j-1)*sides+(i+1)%sides
                faces.append((a,b,b+sides,a+sides))
    rear=len(verts);verts.append(Vector((2.42,0,3.18)))
    tip=len(verts);verts.append(Vector((3.19,0,3.08)))
    last=(len(centers)-1)*sides
    for i in range(sides):
        next_i=(i+1)%sides
        faces.extend([(rear,next_i,i),(tip,last+i,last+next_i)])
    return mesh('Continuous rounded yellow bill',verts,faces,YELLOW)


def painted_body():
    body = [(-3.00,0,.50),(-2.79,0,.96),(-2.28,0,1.36),(-1.77,0,1.80),
            (-1.03,0,2.28),(-.32,0,2.65),(.45,0,2.76),(1.15,0,2.76),
            (1.29,0,2.34),(1.27,0,1.84),(.80,0,1.57),(.04,0,1.38),
            (-.75,0,1.39),(-1.40,0,1.15),(-1.81,0,.99),(-2.14,0,.87),
            (-2.54,0,.86),(-3.00,0,.50)]
    paint_fill('Solid orange body',body,.18,3)
    tube('Orange body brush edge',body,[.084,.071,.082,.090,.072,.087],ORANGE,sides=10,steps=3,depth=3.0)
    head = [(1.15,0,2.76),(1.54,0,3.18),(1.94,0,3.57),(2.35,0,3.58),
            (2.51,0,3.39),(2.54,0,3.19),(2.47,0,3.06),(2.26,0,3.03),
            (1.83,0,2.99),(1.15,0,2.76)]
    paint_fill('Solid orange head',head,.165,4)
    tube('Orange head brush edge',head,[.085,.077,.086,.076],ORANGE,sides=10,steps=4,depth=2.7)
    for side in [-1,1]:
        ball('MS Paint black eye dot',(2.20,side*.178,3.35),(.105,.025,.105),BLACK)
    # One continuous rounded bill covers the orange snout on both sides.
    # The previous overlapping spheres left a crescent where the head cut
    # through them. Keep the reference's broad, hand-painted yellow shape.
    rounded_bill()
    for x,y in [(-1.65,-.20),(.12,.16)]:
        tube('Orange stick leg',[(x+.30,y,1.18 if x<0 else 1.41),(x+.08,y,.98),(x-.23,y,.64)],
             [.070,.067,.080],ORANGE,sides=10,steps=3)


def wing_frame(which):
    if which == 'swept':
        def posed(x,z):
            return Vector((x,.12-.60*(x+.2)+.12*(z-2.7),z))
        normal = Vector((-.60,-1,.12)).normalized()
    else:
        def posed(x,z):
            return Vector((x,.18+.40*(x-.2)-.65*(z-2.8),z))
        normal = Vector((.40,-1,-.65)).normalized()
    return posed, normal


def ribbon(name, points, width, normal, color, kind='Feather'):
    verts,faces = [],[]
    for j,p in enumerate(points):
        direction = points[min(j+1,len(points)-1)]-points[max(0,j-1)]
        across = normal.cross(direction).normalized()*width/2
        verts.extend([p-across,p+across])
        if j:
            a = j*2
            faces.append((a-2,a-1,a+1,a))
    return mesh(name,verts,faces,color,kind)


def feather(name, a, b, width, normal, index):
    direction = b-a
    across = normal.cross(direction).normalized()
    verts, faces, colors = [],[],[]
    times = [0,.13,.29,.46,.63,.78,.90,.965,1]
    palette = ['ece9df','fff9ed','e5e2d9','f4f1e8']
    for j,t in enumerate(times):
        w = width*math.sin(math.pi*t)**.65*(.9+.10*math.sin(j*3.7+index))
        center = a+direction*t
        for side in [-1,0,1]:
            p = center+across*w*side+normal*(.029*math.sin(math.pi*t)*(1-abs(side)))
            verts.append(p)
            colors.append(linear(palette[(index+abs(side))%len(palette)]))
        if j:
            for k in range(2):
                q=(j-1)*3+k
                faces.append((q,q+1,q+4,q+3))
    mesh(name,verts,faces,linear('f5f1e7'),'Feather',colors)
    ridge = normal*.033
    ribbon(name+' gold quill',[a+direction*.12+ridge,a+direction*.95+ridge],.009,normal,linear('c9b9a2'))
    for j in range(4):
        t=.30+j*.135
        for side in [-1,1]:
            p=a+direction*t+ridge
            q=a+direction*(t+.11)+across*(side*width*.74)+normal*.010
            ribbon(name+' fine barb',[p,q],.005,normal,linear('ded7ca'))


def wing(which):
    posed,normal = wing_frame(which)
    if which == 'swept':
        border=[(-.15,2.74),(-.75,2.63),(-1.40,2.72),(-2.1,2.91),(-2.83,3.30),
                (-3.60,4.04),(-3.0,4.21),(-2.1,4.17),(-1.35,4.00),(-.78,3.65),(-.38,3.14)]
        bases = sample([(-.15,0,2.77),(-.48,0,3.48),(-1.00,0,3.94),(-1.90,0,4.10)],3)
        tips = [(-.83,2.66),(-1.24,2.63),(-1.66,2.73),(-2.07,2.88),(-2.41,3.04),
                (-2.71,3.22),(-3.01,3.43),(-3.25,3.64),(-3.54,3.86),(-3.66,4.04),(-3.34,4.16),(-2.98,4.27)]
    else:
        border=[(.20,2.79),(.78,3.12),(1.20,3.67),(1.44,4.34),(1.40,4.96),
                (1.20,5.62),(.71,5.05),(.48,4.65),(.18,4.04),(.08,3.42)]
        bases = sample([(.20,0,2.79),(.09,0,3.50),(.28,0,4.34),(.72,0,5.00)],3)
        tips = [(.61,2.98),(.91,3.17),(1.13,3.48),(1.33,3.83),(1.45,4.17),
                (1.50,4.53),(1.53,4.84),(1.42,5.18),(1.38,5.45),(1.19,5.71),(.98,5.37),(.74,5.15)]
    # A feathered underwing connects the layered flight feathers into a fan.
    verts=[posed(x,z)-normal*.012 for x,z in border]
    triangles=tessellate_polygon([verts])
    faces=[tuple(tri) for tri in triangles]
    mesh(which+' ivory underwing',verts,faces,linear('e5dfd3'),'Feather')
    for i,(x,z) in enumerate(tips):
        base=bases[round(i/(len(tips)-1)*(len(bases)-1))]
        a,b=posed(base.x,base.z),posed(x,z)
        feather(which+' long flight feather %02d'%i,a,b,.20,normal,i)
        for tier,length,width in [(1,.62,.19),(2,.34,.14)]:
            offset=normal*(tier*.047)
            feather(which+' layered covert %02d-%d'%(i,tier),a+offset,a+(b-a)*length+offset,width,normal,i+tier)
    for i in range(len(bases)-1):
        p,q=bases[i],bases[i+1]
        a,b=posed(p.x,p.z),posed(q.x,q.z)
        direction=(b-a).normalized()
        feather(which+' leading covert %02d'%i,a+normal*.135,b+direction*.30+normal*.135,.16,normal,i)
    return posed,normal


def wing_eye(which,x,z,size,angle,index):
    posed,front=wing_frame(which)
    horizontal=Vector((1,-.60 if which=='swept' else .40,0)).normalized()
    vertical=front.cross(horizontal).normalized()
    u=horizontal*math.cos(angle)+vertical*math.sin(angle)
    v=-horizontal*math.sin(angle)+vertical*math.cos(angle)
    # Both surfaces use the same golden iris motif, inferred for turning sprites.
    for side in [-1,1]:
        n=front*side
        center=posed(x,z)+n*(.19 if side>0 else .045)
        cols,rows=(24,8) if size>.23 else (12,4)
        verts,faces,colors=[],[],[]
        top,bottom=[],[]

        def surface(dx,dy,lift=0):
            arch=math.cos(math.pi/2*dx/size)
            high=size*.54*arch;low=-size*.44*arch
            w=(dy-low)/max(.00001,high-low)
            height=size*arch*(.10+.18*math.sin(math.pi*w))
            return center+u*dx+v*dy+n*(height+lift)

        for i in range(cols+1):
            t=i/cols;dx=(2*t-1)*size;arch=math.sin(math.pi*t)
            high=size*.54*arch;low=-size*.44*arch
            top.append(center+u*dx+v*high+n*size*.10*arch)
            bottom.append(center+u*dx+v*low+n*size*.10*arch)
            for j in range(rows+1):
                w=j/rows;dy=low*(1-w)+high*w
                verts.append(surface(dx,dy))
                colors.append(linear('decbbc' if abs(dx)/size>.77 else 'f1e9dd'))
                if i and j:
                    q=(i-1)*(rows+1)+j-1
                    f=(q,q+rows+1,q+rows+2,q+1)
                    faces.append(f if side>0 else tuple(reversed(f)))
        label='%s golden human eye %02d side %d'%(which,index,side)
        mesh(label,verts,faces,linear('ffffff'),'Eye',colors)
        # Radial topology gives a round pupil even on the smallest eyes.
        verts,faces,colors=[],[],[]
        segments=40 if size>.23 else 20
        rings=[0,.18,.20,.34,.425,.45]
        for j,r in enumerate(rings):
            for i in range(segments):
                a=math.tau*i/segments
                verts.append(surface(size*r*math.cos(a),size*r*math.sin(a),size*.025))
                if j<2:c=linear('080906')
                elif j==5:c=linear('685034')
                else:c=linear(['c2943d','e3bc68','a0732e','d9af59','9b6a2a'][i%5])
                colors.append(c)
                if j:
                    q=(j-1)*segments+i;k=(j-1)*segments+(i+1)%segments
                    f=(q,k,k+segments,q+segments)
                    faces.append(f if side>0 else tuple(reversed(f)))
        mesh(label+' round gold iris',verts,faces,linear('c89c49'),'Eye',colors)
        glint=surface(-size*.13,size*.17,size*.045)
        mesh(label+' corneal highlight',[glint-u*size*.055-v*size*.05,glint+u*size*.055-v*size*.05,
             glint+u*size*.055+v*size*.05,glint-u*size*.055+v*size*.05],[(0,1,2,3)],linear('ffffff'),'Eye')
        for edge,name in [(top,'upper'),(bottom,'lower')]:
            ribbon(label+' pink lid '+name,edge[::2],size*.078,n,linear('aa8070'),'Skin')
            out=[center+(p-center)*1.15+n*.008 for p in edge[::2]]
            ribbon(label+' ivory fold '+name,out,size*.11,n,linear('e7ddcd'),'Feather')


def foot(at,index):
    start=len(PARTS)
    volumes=[ball('Heel volume',(-.24,.015,.18),(.22,.185,.17),SKIN,'Skin'),
             ball('Arch and instep',(-.015,.005,.22),(.33,.16,.16),SKIN,'Skin'),
             ball('Forefoot volume',(.25,0,.14),(.24,.22,.12),SKIN,'Skin'),
             ball('Human ankle',(-.23,.025,.43),(.15,.14,.31),SKIN,'Skin')]
    for side in [-1,1]:
        volumes.append(ball('Ankle bone',(-.20,side*.13,.29),(.075,.062,.077),SKIN,'Skin',12,8))
    toes=[]
    for i,(y,length,radius) in enumerate([(-.19,.29,.072),(-.04,.26,.055),(.075,.21,.050),(.17,.16,.044),(.245,.105,.034)]):
        tip=(.34+length,y,.10)
        points=[(.25,y*.80,.14),(.38,y,.14),tip]
        volumes.append(tube('Human toe sculpt',points,[radius*1.10,radius,radius*.78],SKIN,'Skin',sides=10,steps=3))
        volumes.append(ball('Toe pad',tip,(radius*.85,radius*.85,radius*.72),SKIN,'Skin',12,8))
        toes.append((tip,radius))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in volumes:
        obj.select_set(True);PARTS.remove(obj)
    bpy.context.view_layer.objects.active=volumes[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    remesh=obj.modifiers.new('Continuous human foot','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.012
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=obj.modifiers.new('Soften skin','SMOOTH');smooth.factor=.55;smooth.iterations=3
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    obj.data.calc_loop_triangles()
    dec=obj.modifiers.new('Compact foot anatomy','DECIMATE');dec.ratio=min(1,1700/len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=dec.name)
    finish(obj,'Sculpted human foot',SKIN,'Skin')
    for i,(tip,r) in enumerate(toes):
        nail=ball('Human toenail', (tip[0]-.021,tip[1],tip[2]+r*.69),(.049 if i==0 else .035,r*.70,.013),linear('ead0bc'),'Skin',12,6)
        for offset in [.0,.032]:
            p=(.36-offset,tip[1],.171 if i<3 else .158)
            tube('Toe skin crease',[(p[0],p[1]-r*.65,p[2]-.008),p,(p[0],p[1]+r*.65,p[2]-.008)],
                 [.002,.003,.002],linear('9d6c56'),'Skin',sides=5,steps=1)
    for y in [-.12,-.025,.08]:
        tube('Foot tendon',[(-.19,y*.4,.38),(-.06,y*.6,.36),(.11,y*.8,.28),(.30,y,.225)],
             [.006,.010,.009,.003],linear('dfb29b'),'Skin',sides=6,steps=3)
    tube('Achilles tendon',[(-.34,.02,.64),(-.385,.02,.39),(-.41,.02,.20)],
         [.023,.024,.015],linear('bb856d'),'Skin',sides=7,steps=3)
    for y in [-.025,.06]:
        tube('Subtle dorsal foot vein',[(-.14,y,.363),(-.05,y+.02,.358),(.09,y-.02,.282),(.21,y+.01,.250)],
             [.003,.004,.003,.001],linear('9b8d78'),'Skin',sides=5,steps=2)
    for obj in PARTS[start:]:
        anchor=Vector((-.23,.025,0))
        turn=Matrix.Translation(Vector(at)+anchor)@Matrix.Rotation(-.22,4,'Z')@Matrix.Translation(-anchor)
        obj.matrix_world=turn@obj.matrix_world
        obj.name=('Left' if index==0 else 'Right')+' '+obj.name


def build_bird():
    PARTS.clear()
    painted_body()
    for which in ['swept','upright']:
        wing(which)
    eyes = {
        'swept':[(-2.13,3.64,.29,.14),(-2.91,4.01,.12,.05),(-2.76,3.77,.12,.08),
                 (-2.59,3.46,.115,.25),(-2.04,3.15,.11,.25),(-1.57,3.89,.13,-.35),
                 (-1.49,3.25,.145,.18),(-.94,3.54,.14,-.48),(-.91,3.04,.13,.23),(-.53,2.92,.085,-.25)],
        'upright':[(.91,4.69,.29,1.06),(.97,5.12,.14,.94),(.54,4.77,.10,1.0),
                   (.32,3.87,.17,.87),(1.00,4.21,.13,.62),(1.13,4.61,.10,.80),
                   (.88,3.91,.12,.5),(.59,3.53,.11,.57),(.49,3.25,.08,.73),(.71,4.33,.075,.80)]}
    for which,positions in eyes.items():
        for i,(x,z,size,angle) in enumerate(positions):
            wing_eye(which,x,z,size,angle,i)
    foot((-1.65,-.20,0),0)
    foot((.12,.16,0),1)
    turn=Matrix.Rotation(-math.pi/2,4,'Z')
    for obj in PARTS:
        obj.matrix_world=turn@obj.matrix_world
    return list(PARTS)
