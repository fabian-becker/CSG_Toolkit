<center>
<img src="addons/csg_toolkit/res/icon.png" width="128" />
</center>

# CSG Toolkit - Enhanced Blockout & Procedural Generation
A powerful Godot plugin that dramatically speeds up your blockout workflow and adds advanced procedural generation capabilities for level design and prototyping.
<br/><a href="https://godotengine.org/asset-library/asset/3057">>> Asset Library </a>

## Core Features
* **Quick Access Buttons:** Convenient buttons in the left toolbar for swiftly adding CSG nodes.
* **Efficient Child Node Addition:** Press SHIFT to instantly add the selected CSG as a child of the current CSG node.
* **Operation Presets:** Easily switch between different CSG operations (Union, Intersection, Subtraction).
* **Material Picker:** Quickly apply materials to CSG nodes with visual preview.
* **Shortcut Integration:** Context-aware shortcuts available when CSG nodes are selected.

## Advanced Procedural Nodes

### CSGRepeater3D - Pattern Generation System
Create complex repeating patterns with multiple layout options:

**Pattern Types:**
* **Grid Pattern:** Traditional XYZ grid layout with customizable spacing
* **Circular Pattern:** Objects arranged in circles with optional vertical layers  
* **Spiral Pattern:** Objects follow a configurable spiral path
* **Random Grid:** Grid positions with randomized placement order

**Advanced Controls:**
* **Variation Controls:** Random rotation, scale, and position jitter
* **Seed-Based Generation:** Reproducible random patterns

### CSGSpreader3D - Intelligent Object Distribution
Distribute objects within volumes or on scene surfaces with two placement modes:

**Placement Modes:**
* **Volume:** Scatter inside a movable area node (`CollisionShape3D` or any node containing one) -- gizmo-editable and visible in the viewport. Supports Box, Sphere, Cylinder, and Capsule shapes with mathematically correct uniform distribution.
* **Surface:** Raycast instances onto scene geometry (CSG, MeshInstance3D). Optional normal alignment, slope filtering, overhang detection, and surface offset. Works without physics collision via automatic mesh extraction.

**Smart Features:**
* **Collision Avoidance:** Spatial-hash-accelerated minimum-distance rejection (fast even at thousands of instances)
* **Density Threshold:** Control spawn probability with a single slider (volume mode)
* **Material Variations:** Random rotation, scaling options

## Quick Start Guide

1. **Enable the Plugin:** Project Settings > Plugins > CSG Toolkit ✓
2. **Add Nodes:** Create Node > CSGRepeater3D / CSGSpreader3D
3. **Set Template:** Assign a template node or scene to repeat/spread
4. **Configure Pattern:** Choose pattern type and adjust parameters

### Selecting a Repeater/Spreader shows the top toolbar with **Refresh** and **Bake**

Bake copies the generated instances into the scene with full undo support.

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

