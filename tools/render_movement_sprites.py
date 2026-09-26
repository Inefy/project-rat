"""Render eight movement poses and a resting pose in eight directions.

blender --background --factory-startup --python tools/render_movement_sprites.py
python tools/pack_movement_sprites.py

The source studios remain untouched. Poses deform their original named meshes;
paint, eyes, outlines and skin details stay attached to the same moving surface.
"""
import argparse
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
CAST = ['rat', 'bird', 'cat', 'owl', 'snake', 'raccoon', 'fox', 'alpha_cat', 'junkyard_dog', 'barn_owl']
REFERENCE = {'bird', 'cat', 'owl', 'snake', 'fox'}
FRAMES = 8
SIZE = 160
OUT = ROOT / 'build' / 'movement-frames'


def rotate(points, pivot, angle, axis):
    result = points.copy()
    a, b = {'X': (1, 2), 'Y': (2, 0), 'Z': (0, 1)}[axis]
    x, y = points[:, a] - pivot[a], points[:, b] - pivot[b]
    result[:, a] = pivot[a] + x * math.cos(angle) - y * math.sin(angle)
    result[:, b] = pivot[b] + x * math.sin(angle) + y * math.cos(angle)
    return result


def pose(kind, name, base, phase, resting=False):
    if resting:
        return base.copy()
    p = base.copy()
    name = name.lower()
    center = (base.min(axis=0) + base.max(axis=0)) * .5
    if kind == 'bird':
        # This drawing was turned -90 degrees when installed in the studio.
        p = rotate(p, (0, 0, 0), math.pi / 2, 'Z')
        if 'swept' in name or 'upright' in name:
            side = -1 if 'swept' in name else 1
            pivot = (side * .2, .15, 2.8)
            p = rotate(p, pivot, side * (.32 * math.sin(phase)), 'Y')
            p = rotate(p, pivot, .16 * math.cos(phase), 'X')
        elif center[2] < .8:
            p[:, 0] += .12 * math.sin(phase + (math.pi if center[1] > .5 else 0))
            p[:, 2] += .10 * (1 + math.cos(phase))
        p = rotate(p, (0, 0, 0), -math.pi / 2, 'Z')
        p[:, 2] += .09 * math.sin(phase - .5)
        return p
    if kind == 'owl':
        if name.startswith(('left upper', 'right upper', 'left lower', 'right lower')):
            side = -1 if name.startswith('left') else 1
            upper = 'upper' in name
            pivot = (side * .55, 0, 3.39 if upper else 3.16)
            beat = phase + (0 if upper else .7)
            p = rotate(p, pivot, side * .32 * math.sin(beat), 'Y')
            p = rotate(p, pivot, .20 * math.cos(beat), 'X')
        p[:, 2] += .10 * math.sin(phase - .6)
        return p
    if kind == 'barn_owl':
        if 'flight feather' in name or 'feather hatch' in name:
            side = -1 if center[0] < 0 else 1
            p = rotate(p, (side * .55, .15, 2.65), side * (.30 + .45 * math.sin(phase)), 'Y')
        if center[2] < 1:
            p[:, 1] += .1 * math.sin(phase + center[0])
        p[:, 2] += .09 * math.sin(phase - .6)
        return p
    if kind == 'snake':
        # A continuous travelling wave also moves the painted bands and patches.
        p[:, 0] += .24 * np.sin(phase - base[:, 2] * .85 + base[:, 1] * .7)
        p[:, 1] += .08 * np.sin(phase + base[:, 2] * 1.1)
        p[:, 2] += .045 * np.sin(phase - base[:, 1])
        if 'tongue' in name or 'sinew' in name:
            p[:, 0] += .06 * np.sin(phase * 2 + base[:, 2] * 3) * np.clip((4.7 - base[:, 2]) / 1.5, 0, 1)
        return p

    leg_top, reach, lift = {
        'rat': (.90, .27, .17), 'cat': (1.85, .48, .25),
        'raccoon': (.82, .30, .15), 'fox': (.85, .24, .13),
        'alpha_cat': (1.99, .40, .23), 'junkyard_dog': (1.25, .36, .19),
    }[kind]
    tail = 'tail' in name and 'scarf' not in name
    cloth = 'cape' in name and 'clasp' not in name or 'scarf tails' in name
    hand_detail = any(token in name for token in ('palm', 'finger', 'thumb', 'nail', 'lifeline'))
    arm = kind in ('raccoon', 'alpha_cat') and ('arm' in name or hand_detail)
    if kind == 'raccoon' and center[0] > .55 and .6 < center[2] < 2.7:
        arm = True  # The lid, rivets, eye and gripping hand swing together.
    arm = arm and not tail and not cloth
    if tail:
        weight = np.clip(np.linalg.norm(base - np.array((0, .35, .8)), axis=1) / 1.5, 0, 1)
        p[:, 0] += .22 * np.sin(phase - base[:, 1] * 1.5 - base[:, 2] * .7) * weight
        p[:, 2] += .055 * np.cos(phase - base[:, 1]) * weight
    elif cloth:
        weight = np.clip((3.2 - base[:, 2]) / 2.6, 0, 1) if kind == 'alpha_cat' else np.clip(base[:, 0], 0, 1)
        p[:, 1] += .19 * np.sin(phase + base[:, 2] * 2) * weight
    elif arm:
        side = -1 if center[0] < 0 else 1
        pivot = (side * .45, 0, 3.1 if kind == 'alpha_cat' else 2.1)
        p = rotate(p, pivot, side * .16 * math.sin(phase), 'X')
    else:
        # Smooth weights bend the leg at its attachment, including joined meshes.
        weight = np.clip((leg_top - base[:, 2]) / (leg_top * .80), 0, 1)
        weight = weight * weight * (3 - 2 * weight)
        offset = np.where(base[:, 0] < 0, 0, math.pi)
        if kind in ('cat', 'junkyard_dog'):
            offset += np.where(base[:, 1] > .4, math.pi, 0)
        step = phase + offset
        p[:, 1] += reach * np.sin(step) * weight
        p[:, 2] += lift * np.maximum(0, np.cos(step)) * weight
    # Small torso counter-motion gives weight while the feet alternate.
    p[:, 0] += .035 * math.sin(phase) * np.clip(base[:, 2] / 3, 0, 1)
    p[:, 2] += (.025 if kind == 'cat' else .045) * (1 - math.cos(phase * 2))
    return p


def render_character(kind):
    reference = kind in REFERENCE
    path = ROOT / 'art' / kind / ('reference-' + kind + '.blend') if reference else ROOT / 'art/nightmare-cast/nightmare-cast.blend'
    bpy.ops.wm.open_mainfile(filepath=str(path))
    scene = bpy.data.scenes['Reference ' + kind.title() + ' Studio' if reference else 'Nightmare Cast Studio']
    bpy.context.window.scene = scene
    coll = bpy.data.collections['Reference ' + kind.title() + ' - editable parts' if reference else kind]
    coll.hide_render = False
    # Hidden studio collections have unevaluated object matrices until enabled.
    coll.hide_viewport = False
    root = bpy.data.objects[kind + '_root']
    root.rotation_euler.z = 0
    objects = [o for o in coll.objects if o.type == 'MESH']
    for obj in scene.objects:
        if obj.type == 'MESH':
            obj.hide_render = obj not in objects
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.cycles.diffuse_bounces = 0
    scene.render.film_transparent = True
    scene.render.dither_intensity = 0
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.compression = 70
    bpy.context.view_layer.update()
    records = []
    for obj in objects:
        raw = np.empty(len(obj.data.vertices) * 3, dtype=np.float32)
        obj.data.vertices.foreach_get('co', raw)
        matrix = np.array(obj.matrix_world)
        base = raw.reshape(-1, 3) @ matrix[:3, :3].T + matrix[:3, 3]
        records.append((obj, base, np.linalg.inv(matrix)))
    all_points = np.concatenate([r[1] for r in records])
    targets = {'cat': (0, .55, 2.45), 'fox': (0, .55, 2.45), 'bird': (0, .15, 2.8), 'owl': (0, 0, 3), 'snake': (0, .35, 2.75)}
    target = Vector(targets.get(kind, (0, 0, (all_points[:, 2].min() + all_points[:, 2].max()) * .5)))
    camera = scene.camera
    camera.location = (0, -9, 7) if kind in ('cat', 'fox') else ((0, -10, 7.3) if reference else (0, -10, target.z + 5.2))
    camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    right = np.array(camera.rotation_euler.to_matrix() @ Vector((1, 0, 0)))
    up = np.array(camera.rotation_euler.to_matrix() @ Vector((0, 1, 0)))
    poses = [[pose(kind, o.name, base, frame * math.tau / FRAMES, frame == FRAMES) for o, base, _ in records] for frame in range(FRAMES + 1)]
    extent = 0
    for pieces in poses:
        points = np.concatenate(pieces)
        for direction in range(8):
            turned = rotate(points, (0, 0, 0), math.pi / 2 - direction * math.tau / 8, 'Z') - np.array(target)
            extent = max(extent, float(np.max(np.abs(turned @ right))), float(np.max(np.abs(turned @ up))))
    camera.data.ortho_scale = extent * 2.16
    destination = OUT / kind
    destination.mkdir(parents=True, exist_ok=True)
    for frame, pieces in enumerate(poses):
        for (obj, _, inverse), points in zip(records, pieces):
            local = points @ inverse[:3, :3].T + inverse[:3, 3]
            obj.data.vertices.foreach_set('co', local.astype(np.float32).ravel())
            obj.data.update()
        for direction in range(8):
            root.rotation_euler.z = math.pi / 2 - direction * math.tau / 8
            scene.render.filepath = str(destination / f'{direction}_{frame}.png')
            bpy.ops.render.render(write_still=True)
        print(f'MOVEMENT_POSE {kind} {frame + 1}/{FRAMES + 1}', flush=True)
    print('MOVEMENT_COMPLETE ' + kind, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--only', default=','.join(CAST))
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    for character in args.only.split(','):
        render_character(character)
