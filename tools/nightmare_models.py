"""Five remaining cast designs and upgrade art, based on nightmare-cast/mockups.png.

Front -Y, ground Z=0. Flat vertex-colored paint meets shaded skin and eyes.
The named parts stay editable; no external textures or generated mesh services.
"""
import math
import bpy
from mathutils import Vector
from fox_model import linear, sample

CAST = ['rat', 'raccoon', 'alpha_cat', 'junkyard_dog', 'barn_owl']
PICKUPS = ['cheese', 'rapid', 'triple', 'power', 'haste', 'shield', 'pierce']
UPGRADES = ['light_trail', 'pinball', 'scurry_bomb', 'snack_orbit', 'split_acorns',
            'dash_refund', 'orbit_feast', 'quick_whiskers', 'heavy_seeds', 'fleet_feet',
            'thick_fur', 'long_teeth', 'big_paws', 'lucky_tail', 'extra_pocket', 'cheese_magnet']
IDENTITIES = {
    'rat': 'Gray paint rat, pink ears and worm tail, human eyes and fingers, blue vest, red scarf and seed blaster',
    'raccoon': 'Hunched gray bandit, ringed upright tail, tired human eyes, long fingers and eyeball bin lid',
    'alpha_cat': 'Towering black monarch, crooked gold crown, green ring eyes, huge human hands, ragged wine cape and blade tail',
    'junkyard_dog': 'Squat ochre bulldog, mismatched eyes, human lips and teeth, spiked red collar and human forehands',
    'barn_owl': 'Ivory heart-faced owl, mismatched human eyes, dark hatched wings, teal chest marks and hanging human fingers',
}
PARTS = []
INK = '15171b'
WHITE = 'eee6cf'
SKIN = 'ce9c88'
CREASE = '895950'


def material(kind):
    name = 'NIGHTMARE_' + kind
    if bpy.data.materials.get(name):
        return bpy.data.materials[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    out = nodes.new('ShaderNodeOutputMaterial')
    color = nodes.new('ShaderNodeVertexColor')
    color.layer_name = 'Color'
    if kind == 'Paint':
        emission = nodes.new('ShaderNodeEmission')
        links.new(color.outputs['Color'], emission.inputs['Color'])
        rays = nodes.new('ShaderNodeLightPath')
        diffuse = nodes.new('ShaderNodeBsdfDiffuse')
        diffuse.inputs['Color'].default_value = (0, 0, 0, 1)
        mix = nodes.new('ShaderNodeMixShader')
        links.new(rays.outputs['Is Camera Ray'], mix.inputs[0])
        links.new(diffuse.outputs[0], mix.inputs[1])
        links.new(emission.outputs[0], mix.inputs[2])
        links.new(mix.outputs[0], out.inputs['Surface'])
    else:
        shader = nodes.new('ShaderNodeBsdfPrincipled')
        links.new(color.outputs['Color'], shader.inputs['Base Color'])
        shader.inputs['Roughness'].default_value = {'Skin': .53, 'Eye': .22, 'Metal': .42}[kind]
        shader.inputs['Metallic'].default_value = .45 if kind == 'Metal' else 0
        if kind == 'Skin':
            shader.inputs['Subsurface Weight'].default_value = .04
            noise = nodes.new('ShaderNodeTexNoise')
            noise.inputs['Scale'].default_value = 90
            bump = nodes.new('ShaderNodeBump')
            bump.inputs['Strength'].default_value = .09
            bump.inputs['Distance'].default_value = .006
            links.new(noise.outputs['Fac'], bump.inputs['Height'])
            links.new(bump.outputs['Normal'], shader.inputs['Normal'])
        links.new(shader.outputs[0], out.inputs['Surface'])
    return mat


def finish(obj, name, color, kind='Paint'):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material(kind))
    attr = obj.data.color_attributes.new(name='Color', type='BYTE_COLOR', domain='CORNER')
    rgba = linear(color)
    for loop in obj.data.loops:
        p = obj.data.vertices[loop.vertex_index].co
        grain = 1 + .04 * math.sin(p.x * 71 + p.y * 63 + p.z * 97) if kind == 'Skin' else 1
        attr.data[loop.index].color = tuple(min(1, v * grain) for v in rgba[:3]) + (1,)
    for face in obj.data.polygons:
        face.use_smooth = True
    PARTS.append(obj)
    return obj


def mesh(name, verts, faces, color, kind='Paint'):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj, name, color, kind)


def ball(name, at, scale, color, kind='Paint'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, location=at)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, color, kind)


def tube(name, points, radii, color, kind='Paint', sides=8, steps=3):
    centers = sample(points, steps)
    verts, faces = [], []
    prior = None
    for i, center in enumerate(centers):
        tangent = (centers[min(i + 1, len(centers) - 1)] - centers[max(0, i - 1)]).normalized()
        if prior is None:
            ref = Vector((0, 1, 0)) if abs(tangent.y) < .9 else Vector((1, 0, 0))
            normal = tangent.cross(ref).normalized()
        else:
            normal = (prior - tangent * prior.dot(tangent)).normalized()
        prior = normal
        other = tangent.cross(normal)
        t = i / (len(centers) - 1) * (len(radii) - 1)
        k = min(int(t), len(radii) - 2)
        radius = radii[k] * (1 - t + k) + radii[k + 1] * (t - k)
        for j in range(sides):
            angle = math.tau * j / sides
            verts.append(center + radius * (normal * math.cos(angle) + other * math.sin(angle)))
        if i:
            for j in range(sides):
                a, b = (i - 1) * sides + j, (i - 1) * sides + (j + 1) % sides
                faces.append((a, b, b + sides, a + sides))
    faces += [tuple(reversed(range(sides))), tuple((len(centers) - 1) * sides + j for j in range(sides))]
    return mesh(name, verts, faces, color, kind)


def stroke(name, points, color=INK, width=.026):
    return tube(name, points, [width, width * .8], color, sides=6, steps=2)


def shape(name, points, depth, color, y=0, outline=True):
    """A thick, irregular brush silhouette with closed front, back and side walls."""
    count = len(points)
    verts = [(x, y - depth, z) for x, z in points] + [(x, y + depth, z) for x, z in points]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    obj = mesh(name, verts, faces, color)
    for face in obj.data.polygons:
        face.use_smooth = False
    if outline:
        for side in [-1, 1]:
            stroke(name + ' brush edge', [(x, y + side * (depth + .012), z) for x, z in points + points[:1]])
    return obj


def oval_line(name, at, rx, rz, color=INK, width=.025):
    x, y, z = at
    return stroke(name, [(x + rx * math.cos(t * math.tau / 32), y, z + rz * math.sin(t * math.tau / 32)) for t in range(33)], color, width)


def eye(at, radius, iris='a1874b', tired=False):
    x, y, z = at
    ball('Human eye socket', (x, y + .035, z), (radius * 1.16, radius * .50, radius * 1.08), CREASE, 'Skin')
    ball('Human sclera', at, (radius, radius * .53, radius * .91), 'f4eee0', 'Eye')
    ball('Colored iris', (x + radius * .08, y - radius * .50, z), (radius * .48, radius * .07, radius * .51), iris, 'Eye')
    for i in range(18):
        a = math.tau * i / 18
        stroke('Iris radial fiber', [(x + radius * .08 + math.cos(a) * radius * .29, y - radius * .57, z + math.sin(a) * radius * .30),
                                    (x + radius * .08 + math.cos(a) * radius * .44, y - radius * .545, z + math.sin(a) * radius * .46)], '655636', radius * .018)
    ball('Dark pupil', (x + radius * .08, y - radius * .584, z), (radius * .25, radius * .035, radius * .29), '080a0d', 'Eye')
    ball('Eye catchlight', (x - radius * .10, y - radius * .62, z + radius * .19), (radius * .11, radius * .035, radius * .105), 'ffffff')
    if tired:
        tube('Heavy human upper lid', [(x - radius, y - .015, z + radius * .29), (x, y - radius * .50, z + radius * .30), (x + radius, y - .015, z + radius * .18)], [radius * .15, radius * .15], SKIN, 'Skin')
    else:
        oval_line('Eyelid rim', (x, y - radius * .23, z), radius, radius * .91, SKIN, radius * .065)


def hand(at, size=1, side=1, hanging=True):
    start = len(PARTS)
    ball('Human palm', (0, 0, 0), (.22, .12, .32), SKIN, 'Skin')
    for i in range(4):
        x = (i - 1.5) * .127
        length = [.52, .70, .65, .48][i]
        tube('Articulated human finger', [(x, -.015, -.19), (x * 1.25, -.035, -.42), (x * 1.30, -.10, -length), (x * 1.12, -.16, -length - .06)], [.082, .069, .044], SKIN, 'Skin')
        ball('Finger nail', (x * 1.12, -.202, -length + .015), (.048, .018, .075), 'e0bbaa', 'Skin')
        stroke('Finger crease', [(x * 1.23 - .042, -.11, -.39), (x * 1.23 + .044, -.115, -.405)], CREASE, .008)
    tube('Opposing thumb', [(.17, .015, .12), (.35, -.03, -.06), (.39, -.12, -.28), (.32, -.15, -.34)], [.115, .085, .05], SKIN, 'Skin')
    stroke('Palm lifeline', [(.13, -.123, .16), (.06, -.135, .03), (.07, -.133, -.12)], CREASE, .008)
    for obj in PARTS[start:]:
        for v in obj.data.vertices:
            p = obj.matrix_world @ v.co
            p.x *= side
            if not hanging:
                p = Vector((p.x, p.z, -p.y))
            v.co = Vector(at) + p * size
        obj.location = (0, 0, 0)


def tooth(at, width=.13, length=.43):
    x, y, z = at
    return shape('Ivory tooth', [(x - width, z), (x + width, z + .025), (x + width * .6, z - length), (x - width * .5, z - length * .94)], .07, WHITE, y)


def rat():
    # Rounded back/head and deep ears keep the player readable in profile.
    ball('Rounded rat haunch', (0, .31, 1.20), (.43, .55, .62), '777c82')
    ball('Rounded rat cranium', (0, .27, 2.78), (.47, .51, .50), '777c82')
    shape('Uneven gray rat', [(-.42, .7), (-.5, 1.6), (-.30, 2.15), (-.55, 2.5), (-.4, 3.0), (-.17, 3.20), (.08, 3.11), (.35, 3.23), (.52, 2.8), (.4, 2.3), (.55, 1.35), (.35, .72)], .25, '777c82')
    for s in [-1, 1]:
        ball('Round ink ear', (s * .56, .17, 3.37), (.41, .31, .55), INK)
        ball('Pink paint ear', (s * .56, .08, 3.37), (.37, .28, .49), 'd799a0')
        stroke('Ear fold', [(s * .64, -.19, 3.66), (s * .40, -.20, 3.52), (s * .46, -.20, 3.16)], CREASE)
        tube('Kinked rat shin', [(s * .26, .05, .85), (s * .50, -.05, .5), (s * .32, -.17, .18)], [.14, .09], '777c82')
        hand((s * .34, -.22, .13), .35, s, False)
    shape('Torn blue waistcoat', [(-.4, 2.03), (-.6, 1.82), (-.5, .82), (-.30, 1.01), (-.10, .82), (.05, 1.07), (.33, .91), (.47, 1.36), (.4, 1.97)], .282, '277f92')
    eye((-.26, -.28, 2.82), .19, '839783')
    eye((.27, -.29, 2.90), .28, 'a36c5d')
    ball('Long rat muzzle', (0, -.45, 2.51), (.31, .38, .21), '9b9d99')
    ball('Rat nose', (0, -.80, 2.53), (.13, .09, .10), 'c58a91', 'Skin')
    tooth((-.095, -.56, 2.39), .085, .34)
    tooth((.095, -.56, 2.39), .084, .37)
    for s in [-1, 1]:
        for i in range(3):
            stroke('Scribbled whisker', [(s * .17, -.72, 2.5 - i * .06), (s * .56, -.62, 2.54 - i * .09), (s * .78, -.63, 2.58 - i * .13)], width=.014)
        tube('Thin gray arm', [(s * .39, -.01, 1.95), (s * .62, -.16, 1.5), (s * .36, -.46, 1.49)], [.12, .085], '777c82')
        hand((s * .35, -.54, 1.56), .42, s)
    tube('Red scarf', [(-.42, -.21, 2.1), (0, -.38, 1.98), (.42, -.17, 2.14)], [.11, .12], 'b43b31')
    shape('Scarf tails', [(.31, 2.12), (.86, 2.3), (.65, 1.86), (.83, 1.53), (.5, 1.69)], .05, 'b43b31', .15)
    tube('Pink worm tail', [(.21, .62, .81), (.74, 1.02, .65), (1.05, 1.10, .24), (.82, .55, .08), (.22, -.16, .08), (-.28, -.45, .09)], [.115, .105, .055, .015], 'd799a0')
    tube('Seed blaster', [(.32, -.43, 1.53), (.32, -1.05, 1.53)], [.21, .24], '6d8739')
    ball('Blaster bore', (.32, -1.064, 1.53), (.15, .025, .15), INK)
    for z in [1.44, 1.64]:
        stroke('Blaster scrape', [(.11, -.72, z), (.13, -.94, z + .03)], WHITE, .013)


def raccoon():
    shape('Hunched slate body', [(-.7, .55), (-.88, 1.15), (-.73, 2.30), (-.52, 2.9), (-.25, 3.17), (.17, 3.3), (.46, 3.12), (.7, 2.62), (.76, 1.04), (.56, .49)], .42, '6f7880')
    for s in [-1, 1]:
        shape('Pointed bandit ear', [(s * .36, 2.7), (s * .85, 3.19), (s * .74, 2.55)], .12, INK, -.16)
        shape('White ear slash', [(s * .46, 2.76), (s * .76, 3.03), (s * .68, 2.70)], .035, WHITE, -.31, False)
    ball('Mask', (0, -.43, 2.43), (.71, .12, .43), INK)
    eye((-.29, -.56, 2.44), .245, '746d4c', True)
    eye((.29, -.56, 2.48), .22, '746d4c', True)
    ball('White muzzle', (0, -.57, 2.07), (.33, .21, .21), 'c6c9c0')
    ball('Bandit nose', (0, -.77, 2.13), (.13, .06, .085), INK)
    tail_points = [(-.35, .30, .68), (-.97, .42, 1.01), (-1.12, .36, 1.79), (-1.09, .3, 2.6), (-1.18, .27, 3.4)]
    tube('Upright ringed tail', tail_points, [.23, .29, .20, .10], INK)
    for i in range(5):
        z = 1.26 + i * .40
        ball('Gray tail band', (-1.10, .32, z), (.255 - i * .02, .25 - i * .02, .115), '9b9d96')
    for s in [-1, 1]:
        tube('Little black leg', [(s * .37, 0, .7), (s * .43, -.05, .16)], [.14, .07], INK)
        stroke('Forked foot', [(s * .60, -.24, .06), (s * .42, -.14, .14), (s * .27, -.35, .07)], width=.04)
    tube('Long reaching arm', [(-.65, -.1, 1.95), (-.88, -.2, 1.40), (-.95, -.30, .98)], [.19, .1], '6f7880')
    hand((-.97, -.35, .97), .73, -1)
    ball('Battered lid', (.96, -.42, 1.52), (.60, .12, .84), '859097', 'Metal')
    oval_line('Black shield edge', (.96, -.47, 1.52), .60, .84, INK, .045)
    oval_line('Silver shield rim', (.96, -.51, 1.52), .55, .78, 'd6d9cc', .031)
    for i in range(8):
        a = math.tau * i / 8
        ball('Lid rivet', (.96 + math.cos(a) * .48, -.54, 1.52 + math.sin(a) * .69), (.039, .025, .039), 'd6d9cc', 'Metal')
    eye((.96, -.57, 1.60), .32, '828b52')
    hand((1.43, -.52, 2.21), .47, 1)


def alpha_cat():
    shape('Ragged royal cape', [(-.35, 3.36), (-.97, 3.02), (-1.18, .64), (-.9, .88), (-.70, .53), (-.47, .82), (0, .55), (.53, .77), (.91, .53), (1.09, .88), (.85, 3.07), (.36, 3.35)], .11, '702c39', .38)
    for s in [-1, 1]:
        stroke('Cape folds', [(s * .37, .245, 3.06), (s * .74, .245, 2.3), (s * .70, .245, .86)], 'b64c57', .031)
        tube('Long black leg', [(s * .25, .04, 1.99), (s * .37, .03, .85), (s * .4, -.1, .12)], [.22, .14, .15], '202227')
        ball('Cat foot', (s * .4, -.28, .17), (.23, .33, .13), '202227')
        tube('Long black arm', [(s * .39, -.02, 3.1), (s * .64, -.17, 2.11), (s * .91, -.24, 1.22)], [.22, .16, .11], '202227')
        hand((s * .93, -.28, 1.15), .97, s)
    shape('Tall black torso', [(-.32, 1.29), (-.51, 2.46), (-.36, 3.29), (.36, 3.29), (.47, 2.37), (.30, 1.29)], .25, '202227')
    shape('Cat face and long ears', [(-.30, 3.11), (-.65, 3.48), (-.86, 4.38), (-.35, 4.01), (.23, 4.02), (.85, 4.40), (.64, 3.47), (.26, 3.08)], .23, '25272b', -.04)
    for x, z, r in [(-.29, 3.71, .20), (.31, 3.80, .155)]:
        ball('Green ring eye', (x, -.298, z), (r, .055, r * .94), '98e435')
        ball('Black eye center', (x, -.35, z), (r * .62, .025, r * .65), '080a0d')
        ball('Ring eye glint', (x - .035, -.377, z + .055), (.036, .009, .033), 'ffffff')
    for x in [-.17, .17]:
        shape('Long ivory fang', [(x - .10, 3.46), (x + .09, 3.43), (x + .035, 3.03)], .06, WHITE, -.35)
    ball('Black nose', (0, -.39, 3.49), (.13, .05, .072), '050709')
    shape('Crooked crown', [(-.42, 4.01), (-.54, 4.60), (-.23, 4.33), (-.06, 4.82), (.12, 4.34), (.42, 4.67), (.34, 4.00)], .20, 'd6a62b', -.07)
    for x, z in [(-.54, 4.6), (-.06, 4.82), (.42, 4.67)]:
        ball('Crown knob', (x, -.08, z), (.055, .055, .066), 'f1cd58')
    ball('Cape clasp', (0, -.30, 3.02), (.16, .04, .16), 'd6a62b')
    ball('Clasp black center', (0, -.35, 3.02), (.095, .022, .10), INK)
    tube('Raised blade tail', [(.37, .29, .71), (1.23, .5, .75), (1.58, .32, 1.52), (1.44, .15, 2.31)], [.10, .1, .07], '202227')
    shape('Ivory tail blade', [(1.37, 2.22), (1.41, 2.75), (1.20, 3.19), (1.56, 2.91), (1.72, 2.55), (1.59, 2.20)], .06, WHITE, .14)


def junkyard_dog():
    shape('Low broad dog', [(-1.03, .76), (-1.09, 1.68), (-.84, 2.2), (-.32, 2.5), (.56, 2.40), (1.08, 1.86), (1.01, .76)], .58, 'b39339')
    shape('Square dog head', [(-.76, 1.54), (-.95, 2.05), (-.78, 2.95), (-.46, 3.14), (.40, 3.12), (.81, 2.88), (.91, 1.94), (.6, 1.5)], .38, 'b39339', -.32)
    shape('Crooked left ear', [(-.71, 2.85), (-1.16, 3.09), (-.65, 3.43), (-.43, 3.03)], .1, '8d7636')
    shape('Folded right ear', [(.54, 3.05), (1.10, 3.12), (1.14, 2.69), (.92, 2.78)], .11, '8d7636')
    eye((-.40, -.735, 2.66), .24, '807845', True)
    eye((.39, -.736, 2.61), .165, '8d9c9c')
    ball('Nose', (0, -.92, 2.45), (.22, .13, .13), INK)
    ball('Open mouth', (0, -.75, 2.02), (.52, .20, .40), '1b151a')
    tube('Human upper lip', [(-.5, -.9, 2.09), (-.30, -1.0, 2.34), (-.09, -1.015, 2.33), (0, -1.02, 2.29), (.16, -1.015, 2.33), (.41, -.98, 2.23), (.5, -.9, 2.05)], [.095, .11, .09], 'bb807b', 'Skin')
    tube('Human lower lip', [(-.48, -.91, 2.0), (-.31, -1.01, 1.79), (0, -1.06, 1.78), (.31, -1.01, 1.8), (.48, -.91, 2.0)], [.10, .16, .10], 'bd8580', 'Skin')
    for i in range(5):
        tooth(((i - 2) * .15, -.962, 2.24), .065, .19 + (i % 2) * .05)
    tube('Red heavy collar', [(-.93, -.34, 1.86), (-.75, -.65, 1.47), (0, -.77, 1.37), (.75, -.65, 1.47), (.93, -.34, 1.86)], [.16, .17], 'a63c35')
    for i in range(7):
        x = (i - 3) * .28
        z = 1.35 + abs(x) * .34
        shape('Collar ivory spike', [(x - .10, z), (x + .11, z), (x + .03, z - .35)], .06, WHITE, -.74)
    for s in [-1, 1]:
        tube('Short thick foreleg', [(s * .86, -.27, 1.32), (s * 1.0, -.40, .44)], [.30, .24], 'b39339')
        hand((s * 1.01, -.57, .26), 1.03, s, False)
        tube('Black stick hind leg', [(s * .71, .49, .95), (s * .87, .62, .16)], [.07, .055], INK)
        stroke('Splayed hind toes', [(s * .68, .36, .06), (s * .87, .61, .14), (s * 1.10, .38, .06)], width=.044)
    for s in [-1, 1]:
        stroke('Scratched brow', [(s * .15, -.728, 2.94), (s * .40, -.73, 3.0), (s * .57, -.73, 2.92)], '6f5b2f', .025)


def barn_owl():
    shape('Ivory owl body', [(-.52, .79), (-.74, 1.58), (-.57, 2.97), (-.21, 3.52), (.37, 3.34), (.67, 2.46), (.53, .76), (.11, .98)], .36, 'c5baa0')
    for s in [-1, 1]:
        for i in range(6):
            x = s * (.51 + i * .105)
            z = 2.66 - i * .13
            end_x = s * (.69 + i * .125)
            end_z = .80 - i * .09
            shape('Long ink flight feather', [(x - s * .14, z + .3), (x + s * .16, z), (end_x + s * .12, end_z + .10), (end_x, end_z - .10), (end_x - s * .15, end_z + .27)], .09, '292a29', .11 + i * .07)
            for j in range(3):
                z0 = z - .28 - j * .42
                stroke('Ivory feather hatch', [(x, -.002 + i * .07, z0), (x + s * .13, -.005 + i * .07, z0 - .28)], 'bbb399', .022)
        tube('Hidden owl arm', [(s * .58, -.2, 2.37), (s * .68, -.31, 1.53)], [.11, .065], WHITE)
        hand((s * .68, -.35, 1.48), .60, s)
        tube('Forked owl leg', [(s * .25, .02, .86), (s * .32, -.04, .23)], [.055, .045], INK)
        for x in [s * .11, s * .52]:
            stroke('Owl toes', [(s * .32, -.04, .23), (x, -.28, .065)], width=.045)
    shape('Dark heart mask edge', [(0, 3.59), (-.43, 3.81), (-.77, 3.54), (-.71, 3.08), (-.34, 2.70), (0, 2.49), (.38, 2.75), (.75, 3.13), (.70, 3.60), (.36, 3.8)], .20, '655f4d', -.30)
    shape('White skewed heart face', [(0, 3.48), (-.39, 3.70), (-.64, 3.48), (-.61, 3.11), (-.29, 2.79), (0, 2.61), (.33, 2.83), (.64, 3.16), (.59, 3.54), (.33, 3.68)], .065, 'f1ead5', -.525)
    eye((-.27, -.619, 3.30), .32, 'c39737')
    eye((.34, -.620, 3.18), .115, '69726a')
    shape('Long ink beak', [(0, 3.12), (.14, 3.09), (.045, 2.72), (-.06, 3.01)], .10, '16191c', -.58)
    for i in range(5):
        x = (i % 3 - 1) * .22
        z = 2.42 - i * .22
        stroke('Teal chest brush', [(x, -.375, z), (x + .03, -.392, z - .18), (x - .04, -.376, z - .30)], '397d80', .055)


def pickup(kind):
    if kind == 'cheese':
        shape('Cheese wedge', [(-.65, .15), (.62, .15), (-.48, 1.13), (-.65, 1.08)], .29, 'efbd46')
        for x, z, r in [(-.4, .77, .12), (-.36, .35, .14), (.12, .34, .10)]:
            ball('Deep cheese hole', (x, -.30, z), (r, .025, r * .85), '916728')
            stroke('Hole highlight', [(x - r * .5, -.329, z - r * .5), (x + r * .4, -.329, z - r * .5)], 'ffe293', .018)
    elif kind == 'rapid':
        shape('Red chili claw', [(-.38, 1.03), (-.09, 1.15), (.25, 1.02), (.35, .78), (.17, .44), (-.26, .13), (-.62, .12), (-.30, .41), (-.22, .65)], .15, 'd84a40')
        tube('Green chili stem', [(-.10, 0, 1.12), (-.1, 0, 1.30), (.10, 0, 1.40)], [.085, .048], '78965b')
        stroke('White chili brush', [(.1, -.17, .96), (.14, -.17, .77), (-.07, -.17, .48)], WHITE, .035)
    elif kind == 'triple':
        ball('Open pea pod', (0, .07, .55), (.79, .19, .32), '385a42')
        oval_line('Pod ink edge', (0, -.03, .55), .79, .30, INK, .032)
        for i, x in enumerate([-.47, 0, .47]):
            ball('Bright pea', (x, -.13, .59), (.23, .19, .23), '9abe61')
            ball('Pea eye', (x, -.305, .61), (.065, .025, .079), 'f2ead8')
            ball('Pea pupil', (x + .012, -.332, .61), (.027, .008, .045), INK)
    elif kind == 'power':
        ball('Ink acorn', (0, 0, .53), (.43, .30, .53), INK)
        ball('Acorn kernel', (0, -.025, .53), (.385, .30, .485), 'bf793b')
        ball('Dark acorn cap', (0, 0, .87), (.48, .33, .21), '754b31')
        tube('Acorn stem', [(0, 0, .99), (.04, 0, 1.23), (.19, 0, 1.28)], [.055, .04], '754b31')
        for i in range(4):
            stroke('Acorn scoring', [(-.34 + i * .18, -.285, .87), (-.24 + i * .18, -.303, .97)], 'c29a69', .023)
        stroke('Acorn highlight', [(-.18, -.291, .30), (-.24, -.31, .49), (-.20, -.29, .66)], 'f1c06b', .037)
    elif kind == 'haste':
        shape('Sugar rush cube', [(-.44, .20), (.43, .20), (.43, 1.08), (-.44, 1.08)], .34, 'eee9d7')
        for x, z in [(-.25, .37), (.2, .85), (-.16, .83), (.17, .38)]:
            stroke('Sugar grain', [(x, -.36, z), (x + .04, -.36, z + .055)], 'b7bdb3', .022)
        shape('Sugar lightning', [(.05, .95), (-.19, .60), (.01, .6), (-.12, .33), (.25, .68), (.05, .69)], .014, 'b0ad39', -.37)
    elif kind == 'shield':
        ball('Steel lid', (0, 0, .65), (.56, .09, .56), '8c9da5', 'Metal')
        oval_line('Lid ink edge', (0, -.045, .65), .56, .56, INK, .04)
        oval_line('Lid silver rim', (0, -.09, .65), .49, .49, 'd3dfda', .035)
        tube('Lid handle', [(-.16, -.105, .62), (-.16, -.23, .66), (.16, -.23, .66), (.16, -.105, .62)], [.052, .052], INK)
        for i in range(5):
            a = math.tau * i / 5
            ball('Lid rivet', (math.cos(a) * .41, -.096, .65 + math.sin(a) * .41), (.034, .016, .034), 'e4e7d8')
    elif kind == 'pierce':
        shape('Long curved fang', [(-.24, 1.15), (.17, 1.14), (.22, .78), (.13, .41), (-.25, .10), (-.09, .64)], .14, 'eee6cf')
        stroke('Tooth enamel highlight', [(.055, -.158, 1.01), (.07, -.158, .74), (-.04, -.158, .42)], 'ffffff', .036)
        stroke('Root crease', [(-.23, -.15, 1.08), (.15, -.15, 1.10)], 'a8997d', .026)


def move_parts(start, offset=(0, 0, 0), scale=1):
    for obj in PARTS[start:]:
        for v in obj.data.vertices:
            v.co = (obj.matrix_world @ v.co) * scale + Vector(offset)
        obj.location = (0, 0, 0)


def seed(at, scale=.25):
    x, y, z = at
    ball('Ivory seed', at, (scale * .63, scale * .5, scale), WHITE)
    stroke('Seed stripe', [(x, y - scale * .51, z - scale * .67), (x + scale * .08, y - scale * .52, z + scale * .64)], INK, scale * .11)


def bomb():
    ball('Ink crumb bomb', (0, 0, .57), (.43, .32, .43), INK)
    ball('Red bomb body', (0, -.045, .57), (.385, .31, .385), 'bb4a43')
    stroke('Lit fuse', [(0, 0, .93), (.06, 0, 1.20), (.28, 0, 1.27)], WHITE, .034)
    for i in range(5):
        a = math.tau * i / 5
        stroke('Fuse spark', [(.28, 0, 1.27), (.28 + math.cos(a) * .16, 0, 1.27 + math.sin(a) * .16)], 'efc665', .021)
    eye((0, -.35, .61), .18, 'd3a441')


def upgrade(kind):
    mapping = {'quick_whiskers': 'rapid', 'heavy_seeds': 'power', 'fleet_feet': 'haste', 'long_teeth': 'pierce', 'extra_pocket': 'triple'}
    if kind in mapping:
        pickup(mapping[kind])
        if kind in ['quick_whiskers', 'fleet_feet']:
            for i in range(3):
                stroke('Speed stroke', [(-.80, 0, .35 + i * .30), (-.51, 0, .42 + i * .30)], 'e7d492', .033)
    elif kind in ['scurry_bomb', 'dash_refund']:
        bomb()
        if kind == 'dash_refund':
            stroke('Recharge arc', [(math.cos(a * math.pi / 15) * .69, .1, .68 + math.sin(a * math.pi / 15) * .69) for a in range(26)], 'a5c195', .045)
            shape('Recharge arrow', [(-.49, .03), (-.15, .08), (-.32, .34)], .03, 'a5c195')
    elif kind in ['snack_orbit', 'orbit_feast']:
        oval_line('Orbit track', (0, 0, .76), .66, .61, '928eac', .032)
        eye((0, -.05, .76), .22, 'b8a175')
        for i in range(5 if kind == 'orbit_feast' else 3):
            a = math.tau * i / (5 if kind == 'orbit_feast' else 3)
            seed((math.sin(a) * .66, -.07, .76 + math.cos(a) * .61), .18)
    elif kind in ['pinball', 'split_acorns']:
        stroke('Bounce trail', [(-.66, 0, 1.1), (-.15, 0, .25), (.55, 0, 1.03)], '91bc8b', .053)
        stroke('Fence line', [(-.45, 0, .15), (.27, 0, .15)], WHITE, .035)
        seed((.56, 0, 1.14), .22)
        if kind == 'split_acorns':
            stroke('Split path', [(-.15, 0, .25), (-.15, 0, 1.08)], '91bc8b', .041)
            seed((-.15, 0, 1.23), .18)
    elif kind == 'light_trail':
        for i in range(3):
            stroke('Long luminous wake', [(-.68, i * .06, .12 + i * .13), (-.22, i * .06, .26 + i * .14), (.13, i * .06, .72 + i * .11), (.59, i * .06, 1.10 + i * .1)], ['a88b46', 'e5bf64', 'fff2b1'][i], .075 - i * .015)
        seed((.61, -.02, 1.30), .17)
    elif kind == 'thick_fur':
        shape('Stitched heart', [(0, 1.04), (-.28, 1.28), (-.60, 1.12), (-.63, .78), (0, .11), (.63, .78), (.60, 1.12), (.28, 1.28)], .16, 'c35560')
        stroke('Heart seam', [(-.1, -.18, 1.09), (.07, -.18, .72), (-.13, -.18, .39)], 'f6d5bc', .023)
        for i in range(4):
            z = .48 + i * .15
            stroke('Heart stitch', [(-.16, -.19, z), (.13, -.19, z + .08)], INK, .018)
    elif kind == 'big_paws':
        hand((0, 0, 1.0), .96, 1)
        seed((-.06, -.18, 1.19), .35)
    elif kind == 'lucky_tail':
        tube('Lucky hooked tail', [(-.48, 0, 1.23), (-.59, 0, .73), (-.34, 0, .26), (.16, 0, .25), (.54, 0, .67), (.40, 0, 1.25)], [.105, .13, .105], 'c999a2')
        for x in [-.47, .41]:
            stroke('Tail stripes', [(x - .085, -.085, 1.13), (x + .08, -.09, 1.10)], INK, .02)
        shape('Luck star', [(-.05, 1.13), (.03, .92), (.25, .87), (.07, .76), (.04, .53), (-.09, .73), (-.31, .76), (-.13, .89)], .045, 'ecc86f')
    elif kind == 'cheese_magnet':
        tube('U shaped magnet', [(-.53, 0, 1.20), (-.53, 0, .48), (0, 0, .23), (.53, 0, .48), (.53, 0, 1.20)], [.115, .115], 'c75f63')
        for x in [-.53, .53]:
            tube('Ivory magnet tip', [(x, 0, 1.02), (x, 0, 1.24)], [.12, .12], WHITE)
        start = len(PARTS)
        pickup('cheese')
        move_parts(start, (0, -.05, .65), .38)


def build(kind, icon=False):
    PARTS.clear()
    if icon:
        upgrade(kind)
    elif kind in CAST:
        globals()[kind]()
    else:
        pickup(kind)
    return list(PARTS)
