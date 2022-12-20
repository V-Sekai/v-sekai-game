## Install CoACD
# scoop install ninja cmake
# mkdir build
# cd build
# cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release
# Use univrm to export to a glb.
# Have blender use fbxbundler to export to a input folder
# Create an output folder
# Make sure the scale is in meters and if a hut. in human scale
# Apply all transforms.
# set the pivot at 0,0,0
# elixir .\batch_convert.exs
# Use blender fbxbundle to import the output folder back into the scene
# Rename the mesh to have a suffix of `-convcolonly` using Edit ‣ Batch Rename
# hyperfine 'elixir batch_convert.exs'

defmodule BatchConvertHutWithCoACD do
  def run_coacd(path, output) do
    System.cmd("coacd.exe", ["--input", path, "--output", output, "--no-manifold-plus", "-pr", "20000", "-t", "0.04"], into: IO.stream())
  end
end

input_objs = Path.wildcard("input/**/*.obj")
for x <- input_objs do
  input = Path.basename(x)
  BatchConvertHutWithCoACD.run_coacd("input/" <> input, "output/" <> input)
end
