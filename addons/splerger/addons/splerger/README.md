# godot-splerger
Mesh Grid splitting and merging script for Godot 4. The splerger trades increased draw calls for culling guarantees. 

## Installation
Either install as an addon, or simply copy splerger.gd to your project, and it should be available to use.

## Instructions
All functionality is inside the Splerger class. You must create a splerger object before doing anything else:
```
var splerger = Splerger.new()
```
## Merging
```
func merge_meshinstances(var mesh_array,
var attachment_node : Node,
var use_local_space : bool = false,
var delete_originals : bool = true):
```
* mesh_array is an array of MeshInstances to be merged
* attachment node is where you want the merged MeshInstance to be added
* use_local_space will not change the coordinate space of the meshes, however it assumes they all share the same local transform as the first mesh instance in the array
* delete_originals - determines whether the original mesh instances will be deleted

e.g.
```
	var splerger = Splerger.new()
	
	var mergelist = []
	mergelist.push_back($Level/Level/Sponza_15_roof_00)
	mergelist.push_back($Level/Level/Sponza_15_roof_10)
	mergelist.push_back($Level/Level/Sponza_15_roof_20)
	mergelist.push_back($Level/Level/Sponza_15_roof_30)
	mergelist.push_back($Level/Level/Sponza_15_roof_40)
	mergelist.push_back($Level/Level/Sponza_15_roof_50)
	mergelist.push_back($Level/Level/Sponza_15_roof_60)
	splerger.merge_meshinstances(mergelist, $Level)
```
_Note only supports single surface meshes so far._
## Splitting by Surface
If a MeshInstance contains more than one surface (material), you can split it into constituent meshes by surface.
```
func split_by_surface(orig_mi : MeshInstance,
attachment_node : Node,
use_local_space : bool = false):
```
## Splitting by Grid
Meshes that are large cannot be culled well, and will either by rendered in their entirety or not at all. Sometimes it is more efficient to split large meshes by their location. Splerger can do this automatically by applying a 3d grid, with a grid size specified for the x and z coordinates, and separately for the y coordinate (height).
```
func split(mesh_instance : MeshInstance,
attachment_node : Node,
grid_size : float,
grid_size_y : float,
use_local_space : bool = false,
delete_orig : bool = true):
```
For instance, on the x axis, if using world space (`use_local_space` set to false), if the AABB of the object is 10 units, and you set the grid size to 1.0, it will attempt approx 10 splits on that axis. If it reports not enough splits, then the grid_size is too large to split the AABB of the object.

## Splitting many meshes by Grid
You can also split multiple MeshInstance with one command:
```
func split_branch(node : Node,
attachment_node : Node,
grid_size : float,
grid_size_y : float = 0.0,
use_local_space : bool = false):
```
This will search recursively and find all the MeshInstances in the scene graph that are children / grandchildren of 'node', and perform a split by grid on them.

# Whole scene functions

## Recursive find mesh siblings with matching materials and merge them
```
func merge_suitable_meshes_recursive(var node : Node):
```

## Recursive find meshes with matching materials and merge (even in different branches)
```
func merge_suitable_meshes_across_branches(var root : Spatial):
```

# Saving
Although this script will perform splitting and merging, because the process can be slow, it is recommended that you apply this as a preprocess and save the resulting MeshInstances for use in game.
```
func save_scene(var node : Node, var filename):
```
This function will save the branch you pass as a tscn file (e.g. use "myscene.tscn" as filename).

See here for more details on saving scenes:

https://godotengine.org/qa/903/how-to-save-a-scene-at-run-time

# Notes

When splitting by grid, the grid origin is the origin of the AABB bound in world space. The grid sizes are in world space. Note that split by grid does not split faces, and large faces than span more than one grid square will be assigned to only one grid square. There is also no duplication of faces, so the number of faces rendered when all the sub meshes are rendered is the same as the number in the original mesh.

We want to make a room that is comfortable and easy to use. To do this, we need to think about how much space people need to move around and not bump their heads.

We decided to use a smaller space between each level, which is 0.9 meters (90 centimeters). This gives more room for taller people and makes it easier to move around.

Now, let's see how many times 0.9 meters fits into the total height of the room, which is 2.4 meters:

 ```
 2.4 meters (total height) / 0.9 meters (space between levels) ≈ 2.67
 ```

With a 0.9-meter space between levels, we can fit about 2.67 levels in the 2.4-meter tall room. But we can't have a part of a level, so we can either have 2 full levels or 3 full levels, depending on what we need for our design.

In short, using a 0.9-meter space between levels makes the room more comfortable and easy to use while still making good use of the available height. -->
