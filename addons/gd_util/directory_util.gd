# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# directory_util.gd
# SPDX-License-Identifier: MIT

@tool

enum DirectorySearchOptions { SEARCH_ALL_DIRS, SEARCH_LOCAL_DIR_ONLY }


static func get_files_in_directory_path(p_path: String) -> Array:
	var files: Array = []
	var dir: DirAccess = DirAccess.open(p_path)
	if dir == null:
		printerr("Failed to open directory.")
		return files

	if dir.list_dir_begin() != OK:
		printerr("Failed to list directory.")
		return files

	while true:
		var file: String = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and not dir.current_is_dir():
			files.append(file)

	dir.list_dir_end()
	return files


static func get_files(p_directory: DirAccess, current_dir_path: String, p_search_pattern: String, p_search_options: int) -> Array:
	if p_directory.list_dir_begin() != OK:
		printerr("Failed to list directory.")
		return []

	var current_file_name: String = ""
	var valid_files: Array = []
	current_file_name = p_directory.get_next()

	while not current_file_name.is_empty():
		if p_directory.current_is_dir():
			if current_file_name != "." and current_file_name != "..":
				match p_search_options:
					DirectorySearchOptions.SEARCH_ALL_DIRS:
						var sub_directory: DirAccess = DirAccess.open(current_file_name)
						if sub_directory != null:
							var appendable_files: Array = get_files(sub_directory, current_dir_path + "/" + current_file_name, p_search_pattern, p_search_options)
							if appendable_files.size() > 0:
								valid_files.append(appendable_files)
		else:
			if p_directory.file_exists(current_dir_path + "/" + current_file_name):
				valid_files.append(current_dir_path + "/" + current_file_name)

		current_file_name = p_directory.get_next()

	return valid_files


static func delete_dir_and_contents(p_directory: DirAccess, current_dir_path: String, p_delete_root: bool) -> int:
	if p_directory.list_dir_begin() != OK:
		printerr("Failed to list directory.")
		return FAILED

	var current_file_name: String = ""
	var all_deleted: int = OK
	current_file_name = p_directory.get_next()

	while not current_file_name.is_empty():
		if p_directory.current_is_dir():
			if current_file_name != "." and current_file_name != "..":
				var sub_directory: DirAccess = DirAccess.open(current_file_name)
				if sub_directory != null:
					if delete_dir_and_contents(p_directory, current_dir_path + "/" + current_file_name, false) == FAILED:
						all_deleted = FAILED
					else:
						all_deleted = FAILED
		else:
			if p_directory.file_exists(current_dir_path + "/" + current_file_name):
				if p_directory.remove(current_dir_path + "/" + current_file_name) == FAILED:
					all_deleted = FAILED

		current_file_name = p_directory.get_next()

	if p_delete_root:
		if all_deleted == OK:
			if p_directory.remove(current_dir_path) == FAILED:
				all_deleted = FAILED

	return all_deleted
