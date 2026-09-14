"""Reference snake: MS Paint green coil, human eyes and fleshy forked tongue.

Author in the reference's side-view plane, then rotate so forward is -Y.
The unseen side mirrors the eye and patches; the coil has inferred 3D depth.
"""
import math

import bpy
from mathutils import Matrix, Vector
from fox_model import linear, sample

IDENTITY = 'MS Paint green looped snake with black zigzag bands, worn white cross patches, realistic human eyes and glossy red forked tongue'
PARTS = []
GREEN = linear('197c36')
BLACK = linear('030704')
RED = linear('a51819')
FLESH = linear('bd372e')
CREAM = linear('eae5cc')


def material(kind):
    name = 'SNAKE_' + kind
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
        links.new(rays.outputs['Is Camera Ray'],mix.inputs[0])
        links.new(shadow.outputs[0],mix.inputs[1])
        links.new(emission.outputs[0],mix.inputs[2])
        links.new(mix.outputs[0],nodes.get('Material Output').inputs['Surface'])
    else:
        shader.inputs['Roughness'].default_value = .34 if kind == 'Flesh' else .17
        shader.inputs['Specular IOR Level'].default_value = .42
        shader.inputs['Subsurface Weight'].default_value = .075 if kind == 'Flesh' else 0
        links.new(color.outputs['Color'],shader.inputs['Base Color'])
        if kind == 'Flesh':
            noise = nodes.new('ShaderNodeTexNoise')
            noise.inputs['Scale'].default_value = 110
            noise.inputs['Detail'].default_value = 3
            bump = nodes.new('ShaderNodeBump')
            bump.inputs['Strength'].default_value = .10
            bump.inputs['Distance'].default_value = .006
            links.new(noise.outputs['Fac'],bump.inputs['Height'])
            links.new(bump.outputs['Normal'],shader.inputs['Normal'])
    return mat


def finish(obj,name,color,kind='Paint',colors=None):
    obj.name=name
    obj.data.materials.clear()
    obj.data.materials.append(material(kind))
    old=obj.data.color_attributes.get('Color')
    if old:obj.data.color_attributes.remove(old)
    attr=obj.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for loop in obj.data.loops:
        attr.data[loop.index].color=colors[loop.vertex_index] if colors else color
    for p in obj.data.polygons:p.use_smooth=True
    PARTS.append(obj)
    return obj


def mesh(name,verts,faces,color=GREEN,kind='Paint',colors=None):
    data=bpy.data.meshes.new(name+' mesh');data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj)
    return finish(obj,name,color,kind,colors)


def ball(name,at,scale,color,kind='Paint',segments=20,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=at)
    obj=bpy.context.object;obj.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(obj,name,color,kind)


def tube(name,points,radii,color=GREEN,kind='Paint',sides=12,steps=4,pattern=False):
    centers=sample(points,steps)
    verts,faces=[],[]
    radii_at=[]
    for i,c in enumerate(centers):
        tangent=(centers[min(i+1,len(centers)-1)]-centers[max(0,i-1)]).normalized()
        normal=tangent.cross(Vector((0,1,0))).normalized()
        if normal.length<.1:normal=Vector((1,0,0))
        other=tangent.cross(normal).normalized()
        t=i/(len(centers)-1)*(len(radii)-1)
        j=min(int(t),len(radii)-2);u=t-j
        radius=radii[j]*(1-u)+radii[j+1]*u
        radii_at.append(radius)
        for k in range(sides):
            a=k*math.tau/sides
            ripple=1+.018*math.sin(i*1.4+k*2.3) if pattern else 1
            verts.append(c+radius*ripple*(normal*math.cos(a)+other*math.sin(a)))
        if i:
            for k in range(sides):
                a,b=(i-1)*sides+k,(i-1)*sides+(k+1)%sides
                faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(centers)-1)*sides+k for k in range(sides))]
    obj=mesh(name,verts,faces,color,kind)
    if pattern:
        # Paint whole faces to keep bold hard edges, avoiding blended stripes.
        attr=obj.data.color_attributes['Color']
        for face in obj.data.polygons:
            angle=(int(face.vertices[0])%sides+.5)*math.tau/sides
            ink=abs(math.sin(angle))<.16
            for index in face.loop_indices:attr.data[index].color=BLACK if ink else GREEN
    return obj,centers,radii_at


def brush_bands(centers,radii):
    """Continuous crooked ink ribbons following the body, without checker edges."""
    distances=[0.0]
    for i in range(1,len(centers)):
        distances.append(distances[-1]+(centers[i]-centers[i-1]).length)

    def surface(distance,angle):
        distance=max(0,min(distances[-1],distance))
        j=next((i for i in range(len(distances)-1) if distances[i+1]>=distance),len(distances)-2)
        t=(distance-distances[j])/max(.00001,distances[j+1]-distances[j])
        center=centers[j].lerp(centers[j+1],t)
        tangent=(centers[min(j+2,len(centers)-1)]-centers[max(0,j-1)]).normalized()
        normal=tangent.cross(Vector((0,1,0))).normalized()
        other=tangent.cross(normal).normalized()
        radius=radii[j]*(1-t)+radii[j+1]*t+.013
        return center+radius*(normal*math.cos(angle)+other*math.sin(angle))

    count=int(distances[-1]/.56)
    for band in range(count):
        base=.22+band*.56
        verts,faces=[],[]
        for j in range(41):
            angle=j/40*math.tau
            zigzag=2/math.pi*math.asin(math.sin(angle*2+band*1.73))
            center=base+.16*zigzag+.022*math.sin(angle*7+band)
            width=.049+.012*math.sin(angle*3+band*.9)
            verts.extend([surface(center-width,angle),surface(center+width,angle)])
            if j:faces.append((j*2-2,j*2-1,j*2+1,j*2))
        mesh('Uneven black brush band %d'%band,verts,faces,BLACK)
        if band%2==0:
            verts,faces=[],[]
            for j in range(15):
                t=j/14;angle=.8+band*1.12+t*1.75
                distance=base+.50*t
                verts.extend([surface(distance-.034,angle),surface(distance+.034,angle)])
                if j:faces.append((j*2-2,j*2-1,j*2+1,j*2))
            mesh('Hand-drawn connecting stroke %d'%band,verts,faces,BLACK)


def head():
    volumes=[ball('Head volume',(-.48,0,5.09),(.72,.34,.43),GREEN),
             ball('Long blunt muzzle',(-1.03,0,4.98),(.51,.26,.265),GREEN),
             ball('Rounded lower snout',(-1.32,0,4.88),(.22,.22,.17),GREEN)]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in volumes:obj.select_set(True);PARTS.remove(obj)
    bpy.context.view_layer.objects.active=volumes[0];bpy.ops.object.join()
    obj=bpy.context.object
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    remesh=obj.modifiers.new('Continuous head','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.034
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smooth=obj.modifiers.new('Rounded brush outline','SMOOTH');smooth.factor=.65;smooth.iterations=3
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    obj.data.calc_loop_triangles()
    dec=obj.modifiers.new('Compact game head','DECIMATE');dec.ratio=min(1,1600/len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=dec.name)
    finish(obj,'Green head with ink outline',GREEN)
    for face in obj.data.polygons:
        color=BLACK if abs(face.normal.y)<.22 else GREEN
        for i in face.loop_indices:obj.data.color_attributes['Color'].data[i].color=color
    for side in [-1,1]:
        ball('Nostril dot',(-1.37,side*.215,4.98),(.047,.019,.047),BLACK,segments=16,rings=8)


def eye(side):
    label='Visible human eye' if side<0 else 'Opposite human eye'
    x,y,z=-.78,side*.307,5.16
    width=.245;columns,rows=40,12
    verts,faces,colors=[],[],[]
    upper,lower=[],[]
    for i in range(columns+1):
        t=i/columns;dx=(2*t-1)*width;arch=math.sin(math.pi*t)
        top=z+.143*arch+.020*dx
        bottom=z-.103*arch+.020*dx
        upper.append((x+dx,y+side*.043*arch,top))
        lower.append((x+dx,y+side*.043*arch,bottom))
        for j in range(rows+1):
            v=j/rows;zz=bottom*(1-v)+top*v
            yy=y+side*arch*(.043+.047*math.sin(math.pi*v))
            verts.append((x+dx,yy,zz))
            r=math.sqrt((dx+.018)**2+(zz-z-.009)**2)
            a=math.atan2(zz-z-.009,dx+.018)
            if r<.041:c=linear('080c0b')
            elif r<.100:
                c=linear('8f8055' if math.sin(a*37+r*120)>.1 else '535c4b')
                if r>.091:c=linear('343b31')
            else:
                amount=abs(dx)/width
                c=linear('d6b2a1' if amount>.8 else 'e8d7c6')
            colors.append(c)
            if i and j:
                a=(i-1)*(rows+1)+j-1
                face=(a,a+rows+1,a+rows+2,a+1)
                faces.append(face if side<0 else tuple(reversed(face)))
    mesh(label+' almond and iris',verts,faces,kind='Eye',colors=colors)
    tube(label+' upper skin fold',upper[::2],[.008,.027,.035,.026,.009],linear('76332b'),'Flesh',sides=8,steps=1)
    tube(label+' lower eyelid',lower[::2],[.007,.019,.024,.018,.006],linear('b45b50'),'Flesh',sides=8,steps=1)
    # Short curved lashes retain the human eye without heavy texture maps.
    for is_upper,edge,count in [(True,upper,11),(False,lower,7)]:
        for i in range(count):
            t=(i+1)/(count+1);p=Vector(edge[round(t*columns)])
            length=.055+.035*math.sin(t*math.pi)
            outward=Vector(((t-.5)*.08,side*.025,length*(1 if is_upper else -.55)))
            tube(label+' eyelash',[p,p+outward*.55,p+outward],[.006,.004,.0008],linear('30221c'),'Flesh',sides=5,steps=1)
    for dx in [-.19,.17]:
        for dz in [-.025,.025]:
            tube(label+' fine scleral vessel',[(x+dx,y+side*.042,z+dz),(x+dx*.81,y+side*.064,z+dz*.45)],
                 [.0026,.0012],linear('b95f58'),'Flesh',sides=5,steps=1)
    ball(label+' corneal glint',(x-.047,y+side*.099,z+.051),(.012,.006,.015),linear('fff3df'),'Eye',12,8)


def patch(body,center,side,index):
    def project(u,v,lift=.050):
        origin=Vector((center[0]+u,side*10,center[2]+v))
        hit,point,normal,_=body.ray_cast(origin,Vector((0,-side,0)))
        assert hit, 'Cross patch must lie on the body'
        return point+normal*lift

    radius=.175
    verts=[project(0,0)]
    colors=[CREAM]
    for i in range(32):
        a=math.tau*i/32
        r=radius*(1+.045*math.sin(i*2.1)+.04*math.cos(i*3.2))
        verts.append(project(r*math.cos(a),r*math.sin(a)))
        colors.append(linear(['eee8d0','d8d0b3','a5a48c','f2ecd7','e2ddc6'][i%5]))
    faces=[]
    for i in range(32):
        f=(0,i+1,(i+1)%32+1)
        faces.append(f if side<0 else tuple(reversed(f)))
    mesh('Worn white patch %d %d'%(index,side),verts,faces,colors=colors)
    # Slightly crooked painted red cross, kept upright as in the drawing.
    outline=[(-.032,.144),(.026,.147),(.028,.035),(.100,.028),(.098,-.025),
             (.029,-.028),(.021,-.144),(-.025,-.146),(-.031,-.025),(-.103,-.028),
             (-.107,.027),(-.030,.033)]
    points=[project(0,0,.061)]+[project(u,v,.061) for u,v in outline]
    faces=[]
    for i in range(len(outline)):
        f=(0,i+1,(i+1)%len(outline)+1)
        faces.append(f if side<0 else tuple(reversed(f)))
    mesh('Red painted cross %d %d'%(index,side),points,faces,RED)


def tongue():
    trunk=[(-1.46,0,4.80),(-1.63,-.015,4.57),(-1.76,-.01,4.26),(-1.98,-.02,4.03)]
    tube('Glossy muscular tongue',trunk,[.070,.077,.064,.075],FLESH,'Flesh',sides=16,steps=6)
    forks=[ [trunk[-1],(-2.18,-.018,3.84),(-2.28,-.007,3.59),(-2.31,0,3.42)],
            [trunk[-1],(-1.91,-.03,3.83),(-1.96,-.022,3.57),(-1.95,-.01,3.31)] ]
    for i,points in enumerate(forks):
        tube('Tapered tongue fork %d'%i,points,[.060,.044,.023,.004],FLESH,'Flesh',sides=12,steps=5)
        tip=points[-1]
        ball('Red tongue droplet %d'%i,(tip[0],tip[1],tip[2]-.045),(.019,.019,.040),linear('bb170f'),'Flesh',16,10)
    # Longitudinal ridges and red folds read as flesh against the flat body.
    for side in [-1,1]:
        ridge=[(x+.015,side*.068,z) for x,y,z in trunk]
        tube('Tongue sinew ridge',ridge,[.004,.009,.010,.004],linear('e58169'),'Flesh',sides=6,steps=5)
        for points in forks:
            ridge=[(x+.008,y+side*r,z) for (x,y,z),r in zip(points,[.057,.042,.021,.005])]
            tube('Fork sinew ridge',ridge,[.006,.006,.003,.001],linear('de725e'),'Flesh',sides=6,steps=4)


def build_snake():
    PARTS.clear()
    points=[(.07,0,4.99),(.23,0,4.60),(.25,0,4.12),(.04,0,3.61),(-.18,0,3.04),
            (-.23,.015,2.53),(-.13,-.02,2.06),(.10,-.08,1.58)]
    radii=[.24,.28,.28,.27,.26,.25,.27,.29]
    for degrees in [195,225,255,285,315,345,15,45,75,105,135,165]:
        a=math.radians(degrees)
        points.append((1.20+1.04*math.cos(a),.60*math.sin(a),1.35+1.00*math.sin(a)))
        radii.append(.32)
    points += [(.25,-.10,1.38),(.63,-.20,1.25),(.98,-.27,1.22),(1.12,-.29,1.39),(.99,-.28,1.51)]
    radii += [.28,.25,.20,.12,.025]
    body,centers,radii_at=tube('Green curled body with black zigzag paint',points,radii,pattern=True,sides=24,steps=4)
    brush_bands(centers,radii_at)
    head()
    for side in [-1,1]:eye(side)
    targets=[(.23,4.25),(.04,3.53),(-.21,2.81),(.93,2.31),(2.19,1.12),(.54,.62)]
    for i,(x,z) in enumerate(targets):
        j=min(range(len(centers)),key=lambda k:(centers[k].x-x)**2+(centers[k].z-z)**2)
        c=centers[j]
        for side in [-1,1]:patch(body,c,side,i)
    tongue()
    # Engine convention: the snout and tongue point forward along -Y.
    turn=Matrix.Rotation(math.pi/2,4,'Z')
    for obj in PARTS:obj.matrix_world=turn@obj.matrix_world
    return list(PARTS)
