<center>
<img src="addons/csg_toolkit/res/icon.png" width="128" />
</center>

# CSG Toolkit - Enhanced Blockout & Procedural Generation
A powerful Godot plugin that dramatically speeds up your blockout workflow and adds advanced procedural generation capabilities for level design and prototyping.
<br/><a href="https://godotengine.org/asset-library/asset/3057">>> Asset Library </a>

## Core Features
* **Quick Access Buttons:** Convenient sidebar buttons for swiftly adding CSG primitives (Box, Sphere, Cylinder, Torus, Mesh, Polygon)
* **Smart Insertion Modes:** Default sibling/child behavior with ALT key inversion for flexible hierarchy control
* **Operation Switching:** Quickly cycle through CSG operations (Union, Intersection, Subtraction) with keyboard shortcuts (SHIFT + 1/2/3)
* **Material Picker:** Visual material preview and quick application to CSG nodes
* **Keyboard Shortcuts:** Context-aware shortcuts - SHIFT + B/S/C/T/M/P for instant shape creation
* **Auto-Hide Sidebar:** Optional automatic visibility based on CSG node selection
* **ProjectSettings Integration:** All configuration stored in Godot's native settings system

## Advanced Procedural Nodes

### CSGRepeater3D - Pattern Generation System
Create complex repeating patterns with multiple layout options:

**Pattern Types:**
* **Grid Pattern:** Traditional XYZ grid layout with automatic template size detection and custom spacing
* **Circular Pattern:** Objects arranged in circles with optional vertical layers  
* **Spiral Pattern:** Objects follow a configurable spiral path with height and rotation controls
* **Noise Pattern:** Procedural distribution using FastNoiseLite - creates organic, natural-looking patterns with customizable noise types (Simplex, Perlin, Cellular, etc.)

**Advanced Controls:**
* **Automatic Template Sizing:** Intelligently uses template AABB to calculate proper spacing (toggle with `use_template_size`)
* **Template Visibility Control:** Hide template node while keeping repeated instances visible with `hide_template` option
* **Variation Controls:** Per-axis random rotation, scale, and position jitter with configurable variance
* **Seed-Based Generation:** Fully reproducible random patterns using seeds
* **Pattern-Specific Settings:** Each pattern type has unique parameters (radius, height, bounds, noise threshold, etc.)

### CSGSpreader3D - Intelligent Object Distribution
Distribute objects naturally within 3D shapes with smart placement:

**Supported Shapes:**
* **Box, Sphere, Cylinder, Capsule:** Standard primitive shapes
* **HeightMap:** Surface-following distribution
* **Convex/Concave Polygons:** Complex geometry support
* **World Boundary:** Large area distribution

**Smart Features:**
* **Collision Avoidance:** Prevent object overlap with configurable minimum distances and placement attempts
* **Noise Threshold:** Control density and distribution patterns for organic variation
* **Advanced Random Distribution:** Mathematically correct uniform distribution in spheres, cylinders, and complex shapes
* **Rotation & Scale Variations:** Optional randomization for natural-looking distributions
* **Template Visibility:** Automatic template hiding with visible instances
* **Runtime Support:** Works both in-editor and during gameplay

### Basic Setup
1. **Enable the Plugin:** Project Settings > Plugins > CSG Toolkit ✓
2. **Configure Settings:** Access via sidebar config button or Project > Project Settings > Addons > CSG Toolkit
3. **Use Quick Creation:** Select a CSG node, hold SHIFT, press B/S/C/T/M/P to create shapes

### Using CSGRepeater3D
1. **Add Repeater:** Create Node > CSGRepeater3D
2. **Set Template:** Assign a child node path or PackedScene as template
3. **Choose Pattern:** Create a new pattern resource (GridPattern, CircularPattern, SpiralPattern, or NoisePattern)
4. **Adjust Settings:** Configure pattern-specific parameters (counts, spacing, radius, etc.)
5. **Fine-tune:** Enable variations for rotation, scale, or position jitter

### Using CSGSpreader3D
1. **Add Spreader:** Create Node > CSGSpreader3D
2. **Set Template:** Assign template node from scene tree
3. **Define Area:** Set spread_area_3d to a Shape3D resource
4. **Configure Distribution:** Adjust max_count, noise_threshold, and collision settings
5. **Add Variation:** Enable rotation/scale randomization for natural lookModifier3D
3. **Set Template:** Assign a template node or scene to repeat/spread
4. **Configure Pattern:** Choose pattern type and adjust parameters

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

