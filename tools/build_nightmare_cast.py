"""Rebuild only the five remaining characters, seven pickups and sixteen icons.

blender --background --factory-startup --python-exit-code 1 --python tools/build_nightmare_cast.py
Optional -- --only rat,raccoon or -- --icons; existing reference creatures are untouched.
"""
import bpy
import json
import math
import os
import shutil
import sys
import tempfile
import time
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import nightmare_models as models
from build_reference_bird import strip_sprite_metadata

OUT = ROOT / 'art' / 'nightmare-cast'
SPRITES = ROOT / 'assets' / 'sprites'
ICONS = ROOT / 'assets' / 'upgrades'


def enum(owner, prop, value):
    values = [i.identifier for i in owner.bl_rna.properties[prop].enum_items]
    if value not in values:
        # OCIO uses context-dependent enums; RNA can report only NONE. Ask
        # Blender for its actual choices without changing the current value.
        try:
            setattr(owner, prop, '__query_available_values__')
        except TypeError as exc:
            import re
            values = re.findall(r"'([^']+)'", str(exc))
        if value not in values:
            raise RuntimeError(f'{prop}: {value} unavailable; expected one of {values}')
    setattr(owner, prop, value)


def aim(obj, at):
    obj.rotation_euler = (Vector(at) - obj.location).to_track_quat('-Z', 'Y').to_euler()


def publish(source, destination):
    """Publish complete files; Windows asset watchers can briefly hold old files."""
    pending = destination.with_suffix(destination.suffix + '.tmp')
    shutil.copyfile(source, pending)
    for attempt in range(40):
        try:
            os.replace(pending, destination)
            return
        except OSError:
            if attempt == 39:
                raise
            time.sleep(.1)


def studio():
    scene = bpy.data.scenes.new('Nightmare Cast Studio')
    bpy.context.window.scene = scene
    try:
        scene.render.engine = 'CYCLES'
    except TypeError as exc:
        raise RuntimeError(f'Cycles is required for matching the reference creatures: {exc}')
    scene.cycles.samples = 24
    scene.cycles.use_denoising = False
    scene.cycles.diffuse_bounces = 0
    scene.render.film_transparent = True
    scene.render.dither_intensity = 0
    enum(scene.view_settings, 'view_transform', 'Standard')
    enum(scene.view_settings, 'look', 'None')
    enum(scene.render.image_settings, 'file_format', 'PNG')
    enum(scene.render.image_settings, 'color_mode', 'RGBA')
    scene.render.image_settings.compression = 100
    world = bpy.data.worlds.new('Nightmare neutral lighting')
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs['Color'].default_value = (.55, .55, .55, 1)
    bg.inputs['Strength'].default_value = .7
    scene.world = world
    for at, energy, size in [((-4, -6, 7), 350, 5), ((4, -2, 4), 190, 4), ((0, 4, 6), 240, 4)]:
        bpy.ops.object.light_add(type='AREA', location=at)
        obj = bpy.context.object
        obj.data.energy, obj.data.size = energy, size
        aim(obj, (0, 0, 1.7))
    bpy.ops.object.camera_add(location=(0, -10, 6))
    cam = bpy.context.object
    cam.name = 'Production sprite and portrait camera'
    enum(cam.data, 'type', 'ORTHO')
    scene.camera = cam
    return scene


def frame(scene, coll, target, orbit=True):
    bpy.context.view_layer.update()
    cam = scene.camera
    aim(cam, target)
    right = cam.rotation_euler.to_matrix() @ Vector((1, 0, 0))
    up = cam.rotation_euler.to_matrix() @ Vector((0, 1, 0))
    extent = 0
    for index in range(8 if orbit else 1):
        turn = Matrix.Rotation(math.pi / 2 - index * math.tau / 8, 4, 'Z') if orbit else Matrix.Identity(4)
        for obj in coll.objects:
            if obj.type != 'MESH':
                continue
            for corner in obj.bound_box:
                offset = turn @ obj.matrix_world @ Vector(corner) - Vector(target)
                extent = max(extent, abs(offset.dot(right)), abs(offset.dot(up)))
    cam.data.ortho_scale = extent * 2.18


def export(coll, key):
    bpy.ops.object.select_all(action='DESELECT')
    copies = []
    for obj in coll.objects:
        if obj.type != 'MESH':
            continue
        copy = obj.copy()
        copy.data = obj.data.copy()
        bpy.context.scene.collection.objects.link(copy)
        copy.parent = None
        copy.matrix_world = obj.matrix_world.copy()
        copy.select_set(True)
        copies.append(copy)
    bpy.context.view_layer.objects.active = copies[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = key + '_Game'
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.data.calc_loop_triangles()
    path = ROOT / 'art' / 'models' / (key + '.glb')
    with tempfile.TemporaryDirectory(prefix='rat-nightmare-glb-') as temporary:
        staging = Path(temporary) / path.name
        bpy.ops.export_scene.gltf(filepath=str(staging), export_format='GLB', use_selection=True,
                                  use_active_scene=True, export_animations=False,
                                  export_cameras=False, export_lights=False, export_texcoords=False)
        publish(staging, path)
        publish(staging, ROOT / 'assets' / 'models' / path.name)
    stats = {'triangles': len(obj.data.loop_triangles), 'materials': len(obj.data.materials),
             'glb_bytes': path.stat().st_size, 'textures': 0, 'rigged': False}
    bpy.data.objects.remove(obj, do_unlink=True)
    return stats


def render_file(scene, path, size=192):
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    with tempfile.TemporaryDirectory(prefix='rat-nightmare-render-') as temporary:
        staging = Path(temporary) / path.name
        scene.render.filepath = str(staging)
        bpy.ops.render.render(write_still=True)
        strip_sprite_metadata(staging)
        publish(staging, path)


def run():
    OUT.mkdir(exist_ok=True)
    ICONS.mkdir(exist_ok=True)
    scene = studio()
    # The saved studio contains only the changed assets, plus the packed mockup.
    reference = bpy.data.images.load(str(OUT / 'mockups.png'), check_existing=True)
    reference.pack()
    reference.use_fake_user = True
    scene['design_reference'] = 'mockups.png generated with built-in imagegen; exact prompt in mockup-prompt.txt'
    scene['runtime'] = '192px RGBA Blender sprites. Eight directions per character; static GLBs retained for reuse.'
    selected = None
    if '--only' in sys.argv:
        selected = sys.argv[sys.argv.index('--only') + 1].split(',')
    keys = [] if '--icons' in sys.argv else (selected or models.CAST + models.PICKUPS)
    manifest_path = ROOT / 'art' / 'asset-manifest.json'
    manifest = json.loads(manifest_path.read_text())
    stats_path = OUT / 'stats.json'
    stats = json.loads(stats_path.read_text()) if stats_path.exists() else {}
    for key, icon in [(k, False) for k in keys] + ([(k, True) for k in models.UPGRADES] if not selected else []):
        name = 'upgrade_' + key if icon else key
        parts = models.build(key, icon)
        coll = bpy.data.collections.new(name)
        scene.collection.children.link(coll)
        root = bpy.data.objects.new(name + '_root', None)
        coll.objects.link(root)
        for obj in parts:
            for old in list(obj.users_collection):
                old.objects.unlink(obj)
            coll.objects.link(obj)
            obj.parent = root
        bpy.context.view_layer.update()
        character = key in models.CAST and not icon
        corners = [obj.matrix_world @ Vector(c) for obj in parts for c in obj.bound_box]
        center_z = (min(p.z for p in corners) + max(p.z for p in corners)) / 2
        target = Vector((0, 0, center_z))
        # Presentation view is saved as actual Blender output beside the concept.
        scene.camera.location = (6, -13, center_z + 4.0) if character else (2.0, -12, center_z + 3.0)
        frame(scene, coll, target, orbit=False)
        if not icon:
            scene.cycles.samples = 48
            scene.cycles.use_denoising = True
            render_file(scene, OUT / (key + '-preview.png'), 640 if character else 320)
            scene.cycles.samples = 32
            scene.cycles.use_denoising = False
            stats[key] = export(coll, key)
        # All eight facings share one fit, so they do not jump in apparent size.
        scene.camera.location = (0, -10, center_z + (5.2 if character else 3.2))
        frame(scene, coll, target, orbit=character)
        for i in range(8 if character else 1):
            root.rotation_euler.z = math.pi / 2 - i * math.tau / 8 if character else -.12
            path = ICONS / (key + '.png') if icon else SPRITES / f'{key}_{i}.png'
            render_file(scene, path)
        root.rotation_euler.z = 0
        if not icon:
            stats[key].update({'facings': 8 if character else 1, 'sprite_size': [192, 192],
                              'sprite_bytes': sum((SPRITES / f'{key}_{i}.png').stat().st_size for i in range(8 if character else 1))})
            manifest[key] = {'directions': 8 if character else 1, 'collection': key,
                             'source': 'art/nightmare-cast/nightmare-cast.blend', **stats[key]}
            if character:
                manifest[key]['visual_identity'] = models.IDENTITIES[key]
        coll.hide_render = True
        print('NIGHTMARE_ASSET_COMPLETE ' + name, flush=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    stats_path.write_text(json.dumps(stats, indent=2) + '\n')
    # Only a complete run replaces the full editable source library.
    if not selected and '--icons' not in sys.argv:
        scene.camera.location = (6, -13, 5.7)
        aim(scene.camera, (0, 0, 2))
        scene.camera.data.ortho_scale = 5.7
        bpy.data.collections['rat'].hide_render = False
        for coll in scene.collection.children:
            coll.hide_viewport = coll.name != 'rat'
        bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'nightmare-cast.blend'), compress=True)
    print('NIGHTMARE_BUILD_COMPLETE', flush=True)


if __name__ == '__main__':
    run()
