"""Build the reference mouth trap, keyframe its jaws, and render runtime poses.

blender --background --factory-startup --python tools/mousetrap_model.py
"""
import math
import random
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/mousetrap'
FRAMES = ROOT / 'build/mousetrap-frames'
OUT.mkdir(parents=True, exist_ok=True)
FRAMES.mkdir(parents=True, exist_ok=True)
random.seed(41)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)


def material(name, color, roughness, grain):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Subsurface Weight'].default_value = .045
    noise = nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 32 if name == 'Ivory enamel' else 65
    noise.inputs['Detail'].default_value = 3.5
    ramp = nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color = tuple(c * .68 for c in color) + (1,)
    ramp.color_ramp.elements[1].color = tuple(min(1, c * 1.13) for c in color) + (1,)
    links.new(noise.outputs['Fac'], ramp.inputs['Fac'])
    links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    bump = nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = .23
    bump.inputs['Distance'].default_value = grain
    links.new(noise.outputs['Fac'], bump.inputs['Height'])
    links.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    return mat


lip = material('Burnt sienna outer lip', (.35, .105, .036), .56, .035)
gum = material('Rose gum tissue', (.29, .064, .053), .51, .023)
inside = material('Dark mouth lining', (.115, .023, .021), .57, .028)
pink = material('Tongue', (.48, .105, .123), .53, .016)
ivory = material('Ivory enamel', (.79, .68, .47), .4, .014)
crease = material('Tongue crease', (.24, .045, .05), .55, .01)


def finish(obj, name, mat, parent=None):
    obj.name = name
    obj.data.materials.append(mat)
    if hasattr(obj.data, 'polygons'):
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    if parent:
        obj.parent = parent
    return obj


def sphere(name, at, scale, mat, parent, tooth=False):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=at)
    obj = bpy.context.object
    for vertex in obj.data.vertices:
        v = vertex.co
        # Broad asymmetric lobes suggest molars, without uniform cone teeth.
        wobble = 1 + .075 * math.sin(v.x * 9 + v.z * 7) * math.cos(v.y * 11)
        if tooth:
            v.x *= wobble
            v.y *= 1 + .06 * math.sin(v.z * 12 + v.x * 3)
        else:
            v *= 1 + .018 * math.sin(v.x * 17 + v.y * 15 + v.z * 12)
    obj.scale = scale
    return finish(obj, name, mat, parent)


def cord(name, points, radius, mat, parent):
    curve = bpy.data.curves.new(name, 'CURVE')
    curve.dimensions = '3D'
    curve.resolution_u = 12
    curve.bevel_depth = radius
    curve.bevel_resolution = 4
    spline = curve.splines.new('POLY')
    spline.points.add(len(points) - 1)
    for p, xyz in zip(spline.points, points):
        p.co = (*xyz, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    return finish(obj, name, mat, parent)


def edge(t, side):
    return (2.55 * math.cos(t), side * 1.28 * math.sin(t) * (.55 + .72 * abs(math.cos(t))),
            .23 + .035 * math.sin(t * 5))


jaws = []
for side, name in [(1, 'Upper'), (-1, 'Lower')]:
    jaw = bpy.data.objects.new(name + ' jaw hinge', None)
    bpy.context.collection.objects.link(jaw)
    jaws.append(jaw)
    # The two shell halves fold around a central longitudinal hinge.
    verts, faces = [], []
    rings, steps = 12, 64
    for r in range(rings + 1):
        factor = r / rings
        for i in range(steps + 1):
            x, y, z = edge(i * math.pi / steps, side)
            verts.append((x * factor, y * factor, .04 + (z - .04) * factor ** 3))
    for r in range(rings):
        for i in range(steps):
            a = r * (steps + 1) + i
            face = (a, a + 1, a + steps + 2, a + steps + 1)
            faces.append(face if side > 0 else tuple(reversed(face)))
    mesh = bpy.data.meshes.new(name + ' palate mesh')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    shell = bpy.data.objects.new(name + ' fleshy palate', mesh)
    bpy.context.collection.objects.link(shell)
    finish(shell, shell.name, inside, jaw)
    solid = shell.modifiers.new('Soft tissue thickness', 'SOLIDIFY')
    solid.thickness = .12
    rim = [edge(i * math.pi / 96, side) for i in range(97)]
    cord(name + ' terracotta lip', rim, .16, lip, jaw)
    cord(name + ' gum ridge', [(x * .985, y * .90, z + .045) for x, y, z in rim], .125, gum, jaw)
    for i in range(10):
        t = .12 + (math.pi - .24) * i / 9
        x, y, z = edge(t, side)
        sx = random.uniform(.16, .215)
        sy = random.uniform(.15, .195)
        height = random.uniform(.235, .325)
        tooth = sphere(f'{name} tooth {i+1:02}', (x * .986, y * .91, z + height * .57),
                       (sx, sy, height), ivory, jaw, True)
        tooth.rotation_euler = (side * -.14, random.uniform(-.19, .19), random.uniform(-.13, .13))
    # A few low soft ridges give the mouth cavity an organic floor.
    for i in range(5):
        x = -.4 + i * .43
        cord(name + f' palate fold {i}', [(x-.14, side*.1, .052), (x, side*.29, .067), (x+.1, side*.49, .087)], .023, gum, jaw)

tongue = sphere('Broad tongue at left end', (-1.35, -.08, .17), (.75, .51, .16), pink, jaws[1])
tongue.rotation_euler.z = -.08
cord('Tongue central groove', [(-1.97, -.06, .235), (-1.64, -.03, .318), (-1.28, -.015, .327), (-.91, .005, .285)], .011, crease, jaws[1])

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
try:
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    for device in prefs.devices:
        device.use = device.type != 'CPU'
    if any(d.use for d in prefs.devices):
        scene.cycles.device = 'GPU'
except Exception:
    pass
scene.world.color = (.22, .22, .22)
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.view_settings.view_transform = 'AgX'
scene.render.resolution_percentage = 100


def area(name, at, energy, size, tint):
    bpy.ops.object.light_add(type='AREA', location=at)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = 'DISK'
    light.data.size = size
    light.data.color = tint
    light.rotation_euler = (Vector((0, 0, .2)) - light.location).to_track_quat('-Z', 'Y').to_euler()


area('Large warm key', (-3, -4, 8), 850, 6, (1, .87, .75))
area('Soft cool fill', (3, 1, 6), 650, 5, (.78, .88, 1))
area('Lip edge light', (0, 4, 3), 350, 4, (1, .7, .55))
bpy.ops.object.camera_add(location=(0, -6, 11))
camera = bpy.context.object
camera.name = 'Game orthographic camera'
camera.rotation_euler = (Vector((0, 0, .25)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 6.1
scene.camera = camera

# Editable clamp action: open, tense, snap closed, hold, reopen.
for frame, angle in [(1, 0), (7, 0), (10, 8), (12, 28), (14, 54), (16, 77), (24, 77), (32, 0), (42, 0)]:
    for side, jaw in zip([1, -1], jaws):
        jaw.rotation_euler.x = side * math.radians(angle)
        jaw.keyframe_insert(data_path='rotation_euler', frame=frame)
scene.frame_start, scene.frame_end = 1, 42
scene.render.fps = 30
scene.frame_set(1)
scene.render.resolution_x = scene.render.resolution_y = 1024
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'mouth-trap.blend'))
scene.render.filepath = str(OUT / 'open-preview.png')
bpy.ops.render.render(write_still=True)
scene.frame_set(16)
scene.render.filepath = str(OUT / 'clamped-preview.png')
bpy.ops.render.render(write_still=True)
scene.render.resolution_x = scene.render.resolution_y = 320
for index, frame in enumerate([1, 10, 12, 14, 15, 16]):
    scene.frame_set(frame)
    scene.render.filepath = str(FRAMES / f'{index}.png')
    bpy.ops.render.render(write_still=True)
print('Mouth trap modeled, animated, and rendered.')
