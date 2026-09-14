"""Four-wing reference owl: flat MS Paint color and a sculpted human navel.

Front is -Y, up is +Z. Feather outlines are geometry, not texture downloads.
The back and depth are inferred from the supplied single-view drawing.
"""
import math

import bpy
from mathutils import Vector
from fox_model import linear, sample

IDENTITY = 'MS Paint ochre owl, four outlined feather fans, blank white eyes, blue beak, stick legs and realistic human navel'
PARTS = []
OCHRE = linear('b65a00')
WING = linear('bd6204')
INK = linear('382306')
BLACK = linear('000000')
WHITE = linear('ffffff')
BLUE = linear('4b7796')
LEG = linear('d88c45')


def material(kind):
    name = 'OWL_' + kind
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
        lightpath = nodes.new('ShaderNodeLightPath')
        shadow = nodes.new('ShaderNodeBsdfDiffuse')
        shadow.inputs['Color'].default_value = (0, 0, 0, 1)
        mix = nodes.new('ShaderNodeMixShader')
        links.new(lightpath.outputs['Is Camera Ray'], mix.inputs[0])
        links.new(shadow.outputs[0], mix.inputs[1])
        links.new(emission.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], nodes.get('Material Output').inputs['Surface'])
    else:
        shader.inputs['Roughness'].default_value = .62
        shader.inputs['Specular IOR Level'].default_value = .24
        shader.inputs['Subsurface Weight'].default_value = .055
        links.new(color.outputs['Color'], shader.inputs['Base Color'])
        noise = nodes.new('ShaderNodeTexNoise')
        noise.inputs['Scale'].default_value = 125
        noise.inputs['Detail'].default_value = 3
        bump = nodes.new('ShaderNodeBump')
        bump.inputs['Strength'].default_value = .19
        bump.inputs['Distance'].default_value = .007
        links.new(noise.outputs['Fac'], bump.inputs['Height'])
        links.new(bump.outputs['Normal'], shader.inputs['Normal'])
    return mat


def mesh(name, verts, faces, color=OCHRE, kind='Paint', colors=None):
    data = bpy.data.meshes.new(name + ' mesh')
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    data.materials.append(material(kind))
    attr = data.color_attributes.new(name='Color', type='BYTE_COLOR', domain='CORNER')
    for loop in data.loops:
        attr.data[loop.index].color = colors[loop.vertex_index] if colors else color
    for face in data.polygons:
        face.use_smooth = True
    PARTS.append(obj)
    return obj


def ball(name, center, scale, color, segments=16, rings=10):
    verts, faces = [], []
    for j in range(rings+1):
        latitude = math.pi*j/rings
        for i in range(segments):
            a = math.tau*i/segments
            verts.append((center[0]+scale[0]*math.sin(latitude)*math.cos(a),
                          center[1]+scale[1]*math.sin(latitude)*math.sin(a),
                          center[2]+scale[2]*math.cos(latitude)))
            if j:
                p = (j-1)*segments+i
                q = (j-1)*segments+(i+1)%segments
                faces.append((p,p+segments,q+segments,q))
    return mesh(name, verts, faces, color)


def line(name, points, width, color=INK):
    """A thin ink ribbon in the drawing plane; only two triangles per segment."""
    verts, faces = [], []
    points = [Vector(p) for p in points]
    for i, p in enumerate(points):
        tangent = points[min(i+1,len(points)-1)]-points[max(0,i-1)]
        normal = Vector((-tangent.z,0,tangent.x)).normalized()*width/2
        verts.extend([p+normal,p-normal])
        if i:
            k = i*2
            faces.append((k-2,k-1,k+1,k))
    return mesh(name, verts, faces, color)


def feather(name, start, tip, width, color=WING, outline=True):
    """Closed slender feather with a rounded tip and a hard ink border."""
    a, b = Vector(start), Vector(tip)
    direction = (b-a).normalized()
    across = Vector((-direction.z,0,direction.x)).normalized()
    length = (b-a).length
    cap = min(width,length*.25)
    outer = [a-across*width*.22,a+direction*length*.10-across*width*.74,
             a+direction*length*.35-across*width]
    for i in range(9):
        angle = -math.pi/2+i*math.pi/8
        outer.append(a+direction*(length-cap+cap*math.cos(angle))+across*width*math.sin(angle))
    outer += [a+direction*length*.35+across*width,a+direction*length*.10+across*width*.74,a+across*width*.22]
    center = (a+b)*.5
    inner = [center+direction*(p-center).dot(direction)*max(.7,1-.04/length)
             +across*(p-center).dot(across)*.89+Vector((0,-.001,0)) for p in outer]
    verts = outer+inner+[center+Vector((0,-.002,0))]+[p+Vector((0,.055,0)) for p in outer]
    n = len(outer)
    colors = [INK if outline else color]*n+[color]*(n+1)+[color]*n
    faces = []
    for i in range(n):
        j = (i+1)%n
        faces.append((i,j,n+j,n+i))
        faces.append((n+i,n+j,n*2))
        faces.append((i,n*2+1+i,n*2+1+j,j))
    faces.append(tuple(reversed(range(n*2+1,n*3+1))))
    obj = mesh(name, verts, faces, color, colors=colors)
    return obj


def wing(side, upper):
    label = ('Left' if side < 0 else 'Right') + (' upper' if upper else ' lower')
    if upper:
        bases = sample([(.53,0,3.39),(.98,0,3.62),(1.35,0,4.10),(1.61,0,4.68)], 4)
        tips = [(1.40,3.60),(1.83,3.71),(2.20,3.84),(2.53,4.04),(2.74,4.29),(2.85,4.56),
                (2.87,4.84),(2.84,5.10),(2.78,5.34),(2.67,5.57),(2.55,5.79),(2.40,5.98)]
        depth = .10
    else:
        bases = sample([(.55,0,3.16),(.98,0,3.02),(1.30,0,3.17),(1.58,0,3.40)], 4)
        tips = [(1.22,1.96),(1.52,2.03),(1.84,2.15),(2.13,2.32),(2.40,2.51),
                (2.62,2.73),(2.79,2.96),(2.88,3.20),(2.91,3.43),(2.85,3.64)]
        depth = .18
    # Upper-left fan is a little taller, matching the drawing's irregularity.
    def posed(x,z,y):
        # Upper wings sweep back, lower wings forward. The supplied front
        # silhouette stays intact, and horizontal game facings remain visible.
        sweep = (.67 if upper else -.53)*(x-.6)
        return Vector((side*x, y+sweep, z + (.065*(x-.6) if side < 0 and upper else 0)))
    for i, (tx,tz) in enumerate(tips):
        t = i/(len(tips)-1)
        base = bases[round(t*(len(bases)-1))]
        a = posed(base.x,base.z,depth)
        b = posed(tx,tz,depth)
        feather(label + ' primary %02d'%i, a, b, .109 if upper else .116)
        d = b-a
        normal = Vector((-d.z,0,d.x)).normalized()
        front = Vector((0,-.009,0))
        line(label + ' quill %02d'%i, [a+d*.34+front,a+d*.94+front], .012)
        # Hand-drawn barbs, deliberately fewer than the reference at game size.
        for j in range(4):
            p = a+d*(.49+j*.095)+front
            for s in [-1,1]:
                line(label + ' barb %02d-%d-%d'%(i,j,s), [p,p+d*.055+normal*(s*.075)], .005)
        # Two tiers of rounded coverts overlap the long flight feathers.
        feather(label + ' middle covert %02d'%i, a+Vector((0,-.06,0)), a+d*.45+Vector((0,-.06,0)), .12)
        feather(label + ' small covert %02d'%i, a+Vector((0,-.12,0)), a+d*.22+Vector((0,-.12,0)), .085)
    # A narrow solid brush stroke joins the three feather tiers to the shoulder.
    spine = [posed(p.x,p.z,depth-.17) for p in bases]
    line(label + ' wing arm outline', spine, .18, INK)
    line(label + ' wing arm', [p+Vector((0,-.003,0)) for p in spine], .145, OCHRE)


def body():
    # Width, depth and height. The lopsided belly flows into the owl's head.
    profile = sample([(.16,.17,1.69),(.51,.32,1.79),(.71,.43,2.09),(.78,.48,2.54),
        (.69,.43,3.03),(.49,.36,3.49),(.59,.37,3.77),(.73,.40,4.19),
        (.71,.36,4.60),(.52,.29,4.94),(.30,.20,5.06),(.07,.04,5.11)], 3)
    verts, faces = [], []
    sides = 24
    for j,(w,d,z) in enumerate(profile):
        lean = -.23+.115*(z-1.7)
        for i in range(sides):
            a = math.tau*i/sides
            wobble = .018*math.sin(17*z+3*a)+.014*math.cos(10*z-2*a)
            verts.append((lean+(w+wobble)*math.cos(a),.02+d*math.sin(a),z))
        if j:
            for i in range(sides):
                p,q = (j-1)*sides+i,(j-1)*sides+(i+1)%sides
                faces.append((p,q,q+sides,p+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(profile)-1)*sides+i for i in range(sides))]
    mesh('Uneven ochre body', verts, faces)
    # Ear tufts are painted points, not human ears on this character.
    feather('Left crooked ear tuft',(-.25,.035,4.85),(-.43,.015,5.36),.11,OCHRE,False)
    feather('Right crooked ear tuft',(.49,.03,4.80),(.87,.02,5.14),.12,OCHRE,False)


def navel():
    """Skin-colored cavity with an irregular lip and radial puckered folds."""
    center = Vector((-.18,-.535,2.30))
    rings = [(0.0,.060),(.035,.054),(.062,.016),(.088,-.020),(.115,-.028),
             (.142,-.015),(.18,-.009),(.215,-.004),(.255,0)]
    shades = ['281005','492008','75310d','b15d26','c87937','b96b2c','b05d1e','a65310','9f4c04']
    sides = 48
    verts, faces, colors = [], [], []
    for j,(r,depth) in enumerate(rings):
        for i in range(sides):
            angle = math.tau*i/sides
            wrinkle = (.008*math.sin(angle*17+r*85)+.004*math.cos(angle*27-r*41))*math.sin(math.pi*j/(len(rings)-1))
            # Vertical central slit with off-center creases like a human innie.
            u = r*(.40+.34*min(1,r/.18))*math.cos(angle)
            u += .011*math.sin(angle*2+1)*math.sin(math.pi*j/(len(rings)-1))
            v = r*math.sin(angle)
            verts.append(center+Vector((u,depth+wrinkle,v)))
            c = linear(shades[j])
            variation = 1+.075*math.sin(angle*17+r*80)
            colors.append(tuple(min(1,v*variation) for v in c[:3])+(1,))
            if j:
                a,b=(j-1)*sides+i,(j-1)*sides+(i+1)%sides
                faces.append((a,a+sides,b+sides,b))
    mesh('Sculpted human belly button', verts, faces, kind='Skin', colors=colors)


def build_owl():
    PARTS.clear()
    for side in [-1,1]:
        wing(side, True)
        wing(side, False)
    body()
    ball('Left blank white eye',(-.22,-.347,4.68),(.17,.045,.17),WHITE,20,12)
    ball('Right blank white eye',(.42,-.353,4.62),(.17,.045,.17),WHITE,20,12)
    feather('Slate blue beak',(.12,-.407,4.39),(.035,-.427,4.00),.095,BLUE,False)
    ball('Small black mouth',(-.07,-.390,3.86),(.071,.026,.071),BLACK)
    navel()
    # One central, forked stick-leg motif, as drawn in the supplied image.
    feather('Upper leg stroke',(-.22,.015,1.72),(-.22,.015,.73),.065,LEG,False)
    feather('Lower leg stroke',(-.22,.014,.65),(-.22,.014,.08),.074,LEG,False)
    for z in [1.69,.70]:
        ball('Round stick joint',(-.22,-.006,z),(.084,.076,.065),LEG)
    for side in [-1,1]:
        feather('Upper stick fork',(-.22,.013,1.52),(-.22+side*.44,.013,1.29),.055,LEG,False)
        feather('Splayed stick foot',(-.22,.013,.21),(-.22+side*.46,.013,.015),.070,LEG,False)
    return list(PARTS)
