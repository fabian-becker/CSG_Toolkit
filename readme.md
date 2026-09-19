<center>
<img src="addons/csg_toolkit/res/icon.png" width="128" />
</center>

# CSG Toolkit - Enhanced Blockout & Procedural Generation

A powerful Godot plugin that dramatically speeds up your blockout workflow and adds advanced procedural generation capabilities for level design and prototyping.

- Compatible with **Godot 4.7+** (Forward Plus / Mobile / Compatibility)
- No project settings or autoloads are added to your project — everything lives in Editor Settings
<br/><a href="https://godotengine.org/asset-library/asset/3057">>> Asset Library </a>

## Core Features

* **Quick Access Buttons:** Convenient buttons in the left toolbar for swiftly adding CSG nodes.
* **Efficient Child Node Addition:** Hold the action key (default `Shift`) to add the new CSG as a child of the selected node; hold the secondary key (default `Alt`) to invert the behavior.
* **Operation Presets:** Switch between Union / Intersection / Subtraction with the toolbar buttons or `Shift+1/2/3`, cycle with `Shift+'`.
* **Operation State Visibility:** The active operation is highlighted on the toolbar and persists across editor restarts — as does your last picked material.
* **Material Picker:** Quickly apply materials to CSG nodes with visual preview.
* **Per-User Settings:** Action keys, default behavior and auto-hide live in **Editor → Editor Settings → CsgToolkit** (per-user, shared across projects) and are editable from the sidebar's config window.

## Advanced Procedural Nodes

Both generator nodes share the same architecture (auto-refresh on template/pattern/property edits with debouncing, a live preview, optional freeze-to-mesh for very large generations, hide-able template, and a non-destructive bake).

### CSGRepeater3D - Pattern Generation System

Create complex repeating patterns with multiple layout options:

**Pattern Types:**
* **Grid Pattern:** XYZ grid layout with customizable spacing, optionally based on the template's measured size
* **Circular Pattern:** Objects arranged in circles with optional vertical layers
* **Spiral Pattern:** Configurable spiral path with radius curve support (`total_height = 0` gives a flat spiral)
* **Noise Pattern:** FastNoiseLite-driven placement within 3D bounds

**Advanced Controls:**
* **Variation Controls:** Independent per-axis random rotation, scale, and position jitter (each its own toggle group)
* **Seed-Based Generation:** Reproducible random patterns
* **Template as Scene:** Use any node, or a `PackedScene` fallback when the path doesn't resolve

### CSGSpreader3D - Intelligent Object Distribution

Distribute objects within volumes or on scene surfaces with two placement modes:

**Placement Modes:**
* **Volume:** Scatter inside a movable area node (`CollisionShape3D` or any node containing one) — gizmo-editable and its wireframe is visible in the viewport. Supports Box, Sphere, Cylinder, and Capsule shapes with volume-correct uniform distribution.
* **Surface:** Raycast instances onto scene geometry (CSG combiners, `MeshInstance3D`). Optional normal alignment, slope filtering (`max_slope_degrees`), overhang detection, and surface offset. Works on plain CSG blockouts without enabling physics collision — meshes are extracted automatically.

**Smart Features:**
* **Collision Avoidance:** Spatial-hash-accelerated minimum-distance rejection (fast even at thousands of instances)
* **Density Threshold:** Control spawn probability with a single slider (volume mode)
* **Variations:** Random yaw/normal-aligned rotation and scaling
* **Nested Generators:** Use a spreader as a repeater's template — copies stay inert snapshots

## Performance

* **Debounced regeneration:** dragging properties rebuilds once on input settle, not per frame
* **Freeze-to-mesh:** at/above `freeze_threshold` (default 200) instances the preview collapses into a single mesh — orbit and edit at full speed; unfreeze from the toolbar to go back to live CSG copies
* **Bake:** commits the current preview into a `Baked_<Generator>` container node under the scene root (fully undoable), so it persists in the scene and the generator stays free to keep previewing. Use *Save Branch as Scene* on the container if you want a standalone `.tscn`.

## Quick Start Guide

1. **Enable the Plugin:** Project Settings > Plugins > CSG Toolkit ✓
2. **Add Nodes:** Create Node > CSGRepeater3D / CSGSpreader3D
3. **Set Template:** Assign a template node (or scene) to repeat/spread
4. **Configure:** Choose a pattern / placement mode and adjust parameters — everything refreshes automatically
5. **Iterate or Commit:** Keep tweaking live, then press **Bake** to commit the current result into the scene

**Top toolbar (visible when a generator is selected):** **Refresh** rebuilds now, **Bake** commits, **Freeze/Unfreeze** toggles the fast mesh preview.

### Installation Note

After installing the plugin, reload your project and enable it in Project Settings > Plugins.
<br />
<img src="addons/csg_toolkit/res/demo-image.png">

<br />
<br />
Made with coffee and ♥
<a href="https://ko-fi.com/luckyteapot" target="_blank">
<img src="https://storage.ko-fi.com/cdn/brandasset/kofi_button_dark.png?_gl=1*1la7pqo*_gcl_aw*R0NMLjE3MTc5MzYwNjIuQ2owS0NRandwWld6QmhDMEFSSXNBQ3ZqV1JPSFZ2RTVYN1ZuZ0xhTHFrZko2eXNEX2FTeGF2Yzl1ekc4bTZiVWRHZjFzaS01VTIxUGFIa2FBaUQzRUFMd193Y0I.*_gcl_au*ODYyMTE3ODkyLjE3MTc5MzYzNTI.*_ga*MTkwMjk0ODAxNy4xNzE3OTM2MzE2*_ga_M13FZ7VQ2C*MTcxNzkzNjMxNi4xLjEuMTcxNzkzNjYyOC40OC4wLjA.">
</a>

