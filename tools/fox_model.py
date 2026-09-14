"""The supplied orange fox, modeled in Blender with editable anatomical parts.

Front is -Y, up is +Z. Vertex colors preserve the skin folds and eye detail in
the compact, texture-free GLB. The unseen back is inferred from the drawing.
"""
import math

import bpy
from mathutils import Vector

IDENTITY = 'Orange upright fox, human ears, sleepy eyes with red bags, white muzzle and chest, pink tongue and curled white-tipped tail'
PARTS = []


def linear(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values) + (1,)


ORANGE = linear('ff7705')
WHITE = linear('fffaf5')
SKIN = linear('d88a73')
RIM = linear('edaa8a')
CREASE = linear('9e493c')
BAG = linear('99564b')
INK = linear('080705')
PINK = linear('ed168c')


def material(kind):
    name = 'FOX_' + kind
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    shader = nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value = {'Fur': .86, 'Skin': .48, 'Eyes and nose': .28}[kind]
    shader.inputs['Specular IOR Level'].default_value = .32 if kind != 'Fur' else .16
    if kind == 'Skin':
        shader.inputs['Subsurface Weight'].default_value = .065
    color = nodes.new('ShaderNodeVertexColor')
    color.layer_name = 'Color'
    mat.node_tree.links.new(color.outputs['Color'], shader.inputs['Base Color'])
    return mat


def finish(obj, name, color, kind='Fur', colors=None):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material(kind))
    old = obj.data.color_attributes.get('Color')
    if old:
        obj.data.color_attributes.remove(old)
    attr = obj.data.color_attributes.new(name='Color', type='BYTE_COLOR', domain='CORNER')
    for loop in obj.data.loops:
        p = obj.data.vertices[loop.vertex_index].co
        c = colors[loop.vertex_index] if colors else color
        # Restrained skin mottling, baked into vertex colors rather than textures.
        variation = 1 + .025 * math.sin(p.x * 81 + p.z * 97) if kind == 'Skin' else 1
        attr.data[loop.index].color = tuple(min(1, max(0, v * variation)) for v in c[:3]) + (1,)
    for face in obj.data.polygons:
        face.use_smooth = True
    PARTS.append(obj)
    return obj


def mesh(name, verts, faces, color, kind='Fur', colors=None):
    data = bpy.data.meshes.new(name + ' mesh')
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj, name, color, kind, colors)


def ball(name, at, scale, color, kind='Fur', segments=24, rings=14):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=at)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, color, kind)


def sample(points, steps=4):
    points = [Vector(p) for p in points]
    result = []
    for i in range(len(points) - 1):
        a, b, c, d = points[max(0, i - 1)], points[i], points[i + 1], points[min(len(points) - 1, i + 2)]
        for j in range(steps):
            t = j / steps
            result.append(.5 * (2*b + (-a+c)*t + (2*a-5*b+4*c-d)*t*t + (-a+3*b-3*c+d)*t*t*t))
    result.append(points[-1])
    return result


def tube(name, points, radii, color, kind='Fur', sides=12, steps=4, flatten=1):
    centers = sample(points, steps)
    verts, faces = [], []
    prior = None
    for i, center in enumerate(centers):
        tangent = (centers[min(i+1, len(centers)-1)] - centers[max(0, i-1)]).normalized()
        if prior is None:
            ref = Vector((0, 0, 1)) if abs(tangent.z) < .9 else Vector((0, 1, 0))
            normal = tangent.cross(ref).normalized()
        else:
            normal = (prior - tangent * prior.dot(tangent)).normalized()
        prior = normal
        other = tangent.cross(normal).normalized()
        t = i / (len(centers)-1) * (len(radii)-1)
        j, u = min(int(t), len(radii)-2), t - min(int(t), len(radii)-2)
        radius = radii[j] * (1-u) + radii[j+1] * u
        for k in range(sides):
            angle = k * math.tau / sides
            verts.append(center + radius * (math.cos(angle)*normal + math.sin(angle)*other*flatten))
        if i:
            for k in range(sides):
                a, b = (i-1)*sides+k, (i-1)*sides+(k+1)%sides
                faces.append((a, b, b+sides, a+sides))
    faces.extend([tuple(reversed(range(sides))), tuple((len(centers)-1)*sides+k for k in range(sides))])
    return mesh(name, verts, faces, color, kind)


def union(objects, name, color, budget, voxel=.035):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:
        obj.select_set(True)
        PARTS.remove(obj)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    modifier = obj.modifiers.new('Continuous sculpt', 'REMESH')
    modifier.mode = 'VOXEL'
    modifier.voxel_size = voxel
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    modifier = obj.modifiers.new('Relax surface', 'SMOOTH')
    modifier.factor, modifier.iterations = .65, 4
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.calc_loop_triangles()
    modifier = obj.modifiers.new('Game mesh budget', 'DECIMATE')
    modifier.ratio = min(1, budget / len(obj.data.loop_triangles))
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return finish(obj, name, color)


def ear(side):
    label = 'Left' if side < 0 else 'Right'
    center = Vector((side * .43, -.045, 4.43))
    # Lobule, helix, scapha and concha are separate editable anatomical forms.
    outline = [(.01,-.39),(-.12,-.31),(-.18,-.12),(-.19,.10),(-.13,.31),
               (-.015,.43),(.12,.40),(.19,.22),(.18,.02),(.115,-.19),(.11,-.32),(.01,-.39)]
    boundary = sample([(u, v, 0) for u, v in outline], 4)[:-1]

    def point(u, depth, z):
        return center + Vector((side * (u * 1.25 + z * .10), depth, z * .88))

    verts, faces, colors = [], [], []
    rings = [(0.025,.085),(.25,.080),(.5,.025),(.73,-.055),(.9,-.10),(1,-.035)]
    n = len(boundary)
    for j, (radius, depth) in enumerate(rings):
        for p in boundary:
            verts.append(point(p.x*radius, depth, p.y*radius))
            colors.append([CREASE, CREASE, SKIN, SKIN, RIM, SKIN][j])
        if j:
            for k in range(n):
                a, b = (j-1)*n+k, (j-1)*n+(k+1)%n
                faces.append((a, a+n, b+n, b))
    faces.append(tuple(reversed(range(n))))
    # Close the back: this is a volumetric ear, not a reference-facing plane.
    back = len(verts)
    verts.append(point(0, .155, 0))
    colors.append(SKIN)
    for k in range(n):
        faces.append(((len(rings)-1)*n+k, (len(rings)-1)*n+(k+1)%n, back))
    if side > 0:
        faces = [tuple(reversed(f)) for f in faces]
    mesh(label + ' human ear shell', verts, faces, SKIN, 'Skin', colors)
    helix = [point(p.x*.90, -.102, p.y*.90) for p in boundary]
    helix.append(helix[0])
    tube(label + ' rolled helix', helix, [.032,.040,.033], RIM, 'Skin', sides=10, steps=1)
    fold = [point(u, d, z) for u, d, z in [(0,-.075,-.24),(.067,-.082,-.12),(.06,-.060,.025),(-.055,-.05,.145),(-.057,-.065,.27)]]
    tube(label + ' antihelix', fold, [.025,.039,.028,.018,.008], SKIN, 'Skin')
    tube(label + ' upper ear fork', [fold[2], point(.055,-.06,.16), point(.095,-.065,.27)], [.027,.026,.008], RIM, 'Skin')
    ball(label + ' tragus', point(-.079,-.115,-.115), (.059,.048,.070), SKIN, 'Skin', 16, 10)
    ball(label + ' soft lobule', point(.025,-.065,-.315), (.086,.07,.098), RIM, 'Skin', 20, 12)


def eye(side):
    label = 'Left' if side < 0 else 'Right'
    x, y, z = side * .265, -.505, 3.83
    width = .225
    ball(label + ' tired under-eye bag', (x, y+.035, z-.105), (.237,.105,.146), BAG, 'Skin')
    verts, faces, colors = [], [], []
    upper, lower = [], []
    columns, rows = 32, 10
    for i in range(columns+1):
        t = i / columns
        dx = (2*t-1)*width
        arch = math.sin(math.pi*t)
        top = z + .024*arch - side*dx*.04
        bottom = z - .13*arch - side*dx*.04
        upper.append((x+dx, y-.056*arch, top))
        lower.append((x+dx, y-.056*arch, bottom))
        for j in range(rows+1):
            v = j / rows
            zz = bottom*(1-v)+top*v
            yy = y - arch*(.056 + .054*math.sin(math.pi*v))
            verts.append((x+dx, yy, zz))
            iris_r = math.sqrt((dx-.012)**2 + (zz-(z-.018))**2)
            if iris_r < .034:
                color = INK
            elif iris_r < .083:
                angle = math.atan2(zz-z+.018, dx-.012)
                color = linear('726d50' if math.sin(angle*25) > 0 else '555740')
                if iris_r > .073:
                    color = linear('38392e')
            else:
                color = linear('dfd5c9')
            colors.append(color)
            if i and j:
                a = (i-1)*(rows+1)+j-1
                faces.append((a, a+rows+1, a+rows+2, a+1))
    mesh(label + ' half-lidded eye with iris', verts, faces, WHITE, 'Eyes and nose', colors)
    tube(label + ' lower wet eyelid', lower, [.008,.027,.030,.024,.008], linear('c7796e'), 'Skin', sides=10, steps=1)
    tube(label + ' heavy upper eyelid', upper, [.012,.030,.033,.028,.008], linear('9e6247'), 'Skin', sides=10, steps=1)
    crease = [(a, b+.035, c-.067*math.sin(i/columns*math.pi)) for i,(a,b,c) in enumerate(lower)]
    tube(label + ' under-eye crease', crease, [.006,.011,.009,.006], CREASE, 'Skin', sides=8, steps=1)


def body_shape():
    profile = sample([(.34,.24,.04),(.49,.34,.12),(.54,.38,.38),(.53,.39,.9),
        (.50,.38,1.6),(.46,.34,2.25),(.38,.30,2.65),(.33,.31,2.99),
        (.43,.38,3.25),(.55,.46,3.55),(.57,.48,3.85),(.52,.39,4.09),
        (.40,.28,4.23),(.08,.07,4.28)], 4)
    verts, faces = [], []
    sides = 32
    for i, (width, depth, z) in enumerate(profile):
        cy = .06 - .055 * max(0, min(1, z-2.8))
        for k in range(sides):
            angle = k * math.tau/sides
            verts.append((width*math.cos(angle), cy+depth*math.sin(angle), z))
        if i:
            for k in range(sides):
                a,b = (i-1)*sides+k, (i-1)*sides+(k+1)%sides
                faces.append((a,b,b+sides,a+sides))
    faces += [tuple(reversed(range(sides))),tuple((len(profile)-1)*sides+k for k in range(sides))]
    return mesh('Unbroken upright silhouette', verts, faces, ORANGE)


def build_fox():
    PARTS.clear()
    body = [body_shape(),
        ball('Long muzzle bridge', (0,-.49,3.43), (.42,.50,.22), ORANGE),
        ball('Pointed muzzle', (0,-.88,3.42), (.24,.37,.18), ORANGE),
    ]
    for side in [-1, 1]:
        body.append(ball('Subtle orange foot', (side*.265,-.09,.12), (.23,.32,.10), ORANGE))
    union(body, 'Continuous orange body and long snout', ORANGE, 5600)
    # White lower muzzle follows the irregular broad painted marking.
    lip = [ball('White lower jaw', (0,-.685,3.275), (.34,.43,.103), WHITE)]
    for side in [-1,1]:
        lip.append(ball('White cheek corner', (side*.245,-.535,3.285), (.13,.22,.105), WHITE))
    union(lip, 'White muzzle marking', WHITE, 850, .024)
    ball('Small black button nose', (0,-1.219,3.45), (.104,.040,.090), INK, 'Eyes and nose')
    tongue = ball('Hanging magenta tongue', (-.10,-.846,3.17), (.080,.056,.123), PINK, 'Skin')
    tongue.rotation_euler.y = -.24
    # A continuous white bib laid just over the torso surface.
    bib = tube('Long white chest marking', [(0,-.267,2.60),(.025,-.288,2.34),(.018,-.305,2.03),
         (-.008,-.316,1.72),(.012,-.322,1.45)], [.095,.133,.148,.13,.09], WHITE, sides=20, steps=6, flatten=.45)
    end = ball('Rounded bib end', (.012,-.322,1.45), (.09,.044,.115), WHITE)
    union([bib,end], 'Continuous white chest marking', WHITE, 700, .018)
    # Tail sweeps back and down like the supplied drawing, with a chunky tip.
    tail_points = [(0,.30,.86),(-.10,.70,.91),(-.28,1.13,.76),(-.40,1.48,.47),
        (-.44,1.66,.33),(-.45,1.81,.27),(-.43,1.96,.24),(-.34,2.08,.25),(-.31,2.11,.27)]
    tail = tube('Curled tail with white tip', tail_points, [.22,.30,.34,.31,.26,.22,.16,.10,.018], ORANGE, sides=20, steps=5)
    for loop in tail.data.loops:
        p = tail.data.vertices[loop.vertex_index].co
        tail.data.color_attributes['Color'].data[loop.index].color = WHITE if p.y > 1.63 else ORANGE
    for side in [-1, 1]:
        ear(side)
        eye(side)
    return list(PARTS)
