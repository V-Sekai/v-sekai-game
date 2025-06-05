class_name VSKResourceParser
extends RefCounted

static func get_unicode_string(f):
	var len: int = f.get_32()
	var utf8: PackedByteArray = f.get_buffer(len)
	return utf8.get_string_from_utf8()

const FORMAT_FLAG_NAMED_SCENE_IDS: int = 1
const FORMAT_FLAG_UIDS: int = 2
const FORMAT_FLAG_REAL_T_IS_DOUBLE: int = 4
const FORMAT_FLAG_HAS_SCRIPT_CLASS: int = 8
# Amount of reserved 32-bit fields in resource header
const RESERVED_FIELDS: int = 11
# We can only support specific formats which match the parsing logic of Godot.
const FORMAT_VERSION: int = 5

# Expects a resource whose header was rewritten to say "GCPF" or "GRPF" depending on if compressed or not
static func validate_resource(p_filename: String, p_whitelisted_resource_types: Dictionary, p_whitelisted_external_paths: Dictionary, p_force_revalidate: bool = true) -> bool:
	'''
	Validates a given resource file for embedded Resource types or references to external file paths.
	This does not validate Nodes within PackedScene or various properties within the resource (such as Animation tracks)
	But it does guarantee that ResourceLoader.load() may be invoked on p_filename without executing Script constructors,
	permitting futher valdiation to be done on the loaded Resource.
	'''
	var f: FileAccess
	f = FileAccess.open(p_filename, FileAccess.READ_WRITE)
	var check_buf: String = f.get_buffer(4).get_string_from_ascii()
	if check_buf == "RSRC" or check_buf == "RSCC":
		if p_force_revalidate:
			if check_buf == "RSCC":
				check_buf = "GCPF" # compressed
			else:
				check_buf = "GRPF" # uncompressed
			f.seek(0)
			f.store_string(check_buf)
		else:
			push_error("Attempted to validate a resource without a valid temporary header")
			# Should we assume we already validated this file in the past?
			return false
	if check_buf != "GRPF" and check_buf != "GCPF":
		return false # Not a header we placed at the beginning of the file.
	if check_buf == "GCPF":
		# It is compressed. Let's re-open as compressed, and Godot will consume the leading "GCPF".
		f.close()
		f = FileAccess.open_compressed(p_filename, FileAccess.READ) # Godot has its own header format
	var big_endian: bool = f.get_32() != 0
	var use_real64: bool = f.get_32() != 0
	f.set_big_endian(big_endian) #read big endian if saved as big endian
	var ver_major: int = f.get_32()
	var ver_minor: int = f.get_32()
	var ver_format: int = f.get_32()
	if (ver_format > FORMAT_VERSION || ver_major != Engine.get_version_info()["major"] || ver_minor > Engine.get_version_info()["minor"]):
		print("Format mismatch " + str(ver_format) + "/" + str(ver_major) + "." + str(ver_minor) + ": " + str(Engine.get_version_info()))
		return false # Version mismatch. VFail validation
	var typ = get_unicode_string(f)
	if not p_whitelisted_resource_types.has(typ):
		print("Unrecognized main type " + str(typ))
		return false
	print(typ)

	var importmd_ofs: int = f.get_64()
	var flags: int = f.get_32()
	var using_uids: bool = (flags & FORMAT_FLAG_UIDS) != 0
	var using_named_scene_ids: bool = (flags & FORMAT_FLAG_NAMED_SCENE_IDS) != 0
	var real_is_double: bool = (flags & FORMAT_FLAG_REAL_T_IS_DOUBLE) != 0
	var uid: int = f.get_64()
	if not using_uids:
		uid = -1
	var script_class: String = ""
	if (flags & FORMAT_FLAG_HAS_SCRIPT_CLASS) != 0:
		script_class = get_unicode_string(f)
	# VALIDATE script_class == "" ???
	print("Script class: " + script_class)
	if script_class != "":
		print("I do not support validating script_class " + str(script_class) + " for type " + str(typ))
		return false
	for i in range(RESERVED_FIELDS):
		f.get_32()
	var string_table_size: int = f.get_32()
	var string_map: PackedStringArray
	string_map.resize(string_table_size)
	for i in range(string_table_size):
		string_map[i] = get_unicode_string(f)
	var ext_resources_size: int = f.get_32()
	if ext_resources_size > 100000 or ext_resources_size < 0:
		print(str(ext_resources_size) + " is more than 100000 external resources. Fail validation.")
		return false
	for i in range(ext_resources_size):
		var er_type: String = get_unicode_string(f)
		var er_path: String = get_unicode_string(f)
		var er_uid_path: String
		if using_uids:
			var er_uid: int = f.get_64()
			if er_uid != -1:
				if ResourceUID.has_id(er_uid):
					er_uid_path = ResourceUID.get_id_path(er_uid)
					# VALDIATE er_uid_path
					if not p_whitelisted_external_paths.has(er_uid_path):
						print("Unrecognized subresource UID " + str(er_uid) + " at " + str(er_uid_path) + " type " + str(er_type) + " at " + str(er_path))
						return false
				else:
					print("Unrecognized UID " + str(er_uid) + " type " + str(er_type) + " at " + str(er_path) + ". Fail validation.")
					return false
					# Unrecognized UIDs could be exploited to link to future untrusted resources.
		print("Check ext_resource " + str(er_type) + " at " + str(er_path) + " or " + str(er_uid_path))
		# VALDIATE er_path
		if not p_whitelisted_external_paths.has(er_uid_path):
			print("Unrecognized subresource path " + str(er_path) + " type " + str(er_type) + " UID path " + str(er_uid_path))
			return false
	var int_resources_size: int = f.get_32()
	print(int_resources_size)
	if int_resources_size > 100000 or int_resources_size < 0:
		print(str(int_resources_size) + " is more than 100000 internal resources. Fail validation.")
		return false
	var int_resource_paths: PackedStringArray
	var int_resource_offsets: PackedInt64Array
	int_resource_offsets.resize(int_resources_size)
	int_resource_paths.resize(int_resources_size)
	for i in range(int_resources_size):
		int_resource_paths[i] = get_unicode_string(f)
		int_resource_offsets[i] = f.get_64()
	for i in range(int_resources_size):
		f.seek(int_resource_offsets[i])
		var ir_type = get_unicode_string(f)
		var ir_path = int_resource_paths[i]
		# VALIDATE ir_type (and perhaps ir_path)
		if not ir_path.begins_with("local://"):
			print("Unrecognized subresource path " + str(ir_path))
			return false
		if not p_whitelisted_resource_types.has(ir_type):
			print("Unrecognized subresource type " + str(ir_type) + " at " + str(ir_path))
			return false

		print("Check int_resource" + str(ir_type) + " at " + str(ir_path))

	#while true:
	#	var tmp_data = f.get_buffer(1024)
	#	if not tmp_data:
	#		break
	#	print(tmp_data)
	f.close()
	f = FileAccess.open(p_filename, FileAccess.READ_WRITE)
	if check_buf == "GCPF":
		f.store_string("RSCC") # compressed
	else:
		f.store_string("RSRC") # uncompressed
	f.close()
	return true
