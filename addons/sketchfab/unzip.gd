extends SceneTree

const ARG_PREFIX = "--zip-to-unpack "

func _init():
	print("Unzipper started")

	var zip_path
	for arg in OS.get_cmdline_args():
		if arg.begins_with(ARG_PREFIX):
			zip_path = arg.right(arg.length() - ARG_PREFIX.length())
			break

	if zip_path == null:
		print("No file specified")
		return

	print("Unpacking %s..." % zip_path)

	if !ProjectSettings.load_resource_pack(zip_path):
		print("Package file not found")
		return

	var name_regex = RegEx.new()
	name_regex.compile("([^/\\\\]+)\\.zip")
	var base_name = name_regex.search(zip_path).get_string(1)

	var out_path = zip_path.left(zip_path.find(base_name)) + base_name + "/"
	unpack_dir("res://", out_path)

	print("Done!")

func unpack_dir(src_path, out_path):
	var dir = DirAccess.open("/")
	if !dir.dir_exists(out_path):
		dir.make_dir(out_path)
	
	print("Directory: %s -> %s" % [src_path, out_path])

	var dir2 = DirAccess.open(src_path)
	dir2.list_dir_begin()

	var file_name = dir2.get_next()
	while file_name != "":
		if dir2.current_is_dir():
			var new_src_path = "%s%s/" % [src_path, file_name]
			var new_out_path = "%s%s/" % [out_path, file_name]
			unpack_dir(new_src_path, new_out_path)
		else:
			var file_src_path = "%s%s" % [src_path, file_name]
			var file_out_path = "%s%s" % [out_path, file_name]
			print("File: %s -> %s" % [file_src_path, file_out_path])
			var read_file = FileAccess.open(file_src_path, FileAccess.READ)
			var data = read_file.get_buffer(read_file.get_length())
			
			var write_file = FileAccess.open(file_out_path, FileAccess.WRITE)
			write_file.store_buffer(data)
		file_name = dir2.get_next()
