# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# bone_selection_dialog.gd
# SPDX-License-Identifier: MIT

@tool
extends ConfirmationDialog

const DIALOG_WIDTH = 800
const DIALOG_HEIGHT = 600

signal selected(p_bone_name)

var skeleton: Skeleton3D = null

var vbox_container: VBoxContainer = null

var filter: String = ""

var tree: Tree = null
var filter_lineedit: LineEdit = null

var clear_icon: Texture = null
var bone_icon: Texture = null


func set_skeleton(p_skeleton: Skeleton3D) -> void:
	skeleton = p_skeleton


func _cancel() -> void:
	hide()


func _select() -> void:
	var tree_item: TreeItem = tree.get_selected()
	if tree_item:
		selected.emit(tree_item.get_metadata(0))
		hide()


func _confirmed() -> void:
	_select()


func _filter_changed(p_filter: String) -> void:
	filter = p_filter
	update()


func is_bone_name_valid(p_bone_name: String) -> bool:
	if filter == "":
		return true
	else:
		if filter in p_bone_name:
			return true

	return false


func update_tree(p_tree: Tree, p_skeleton: Skeleton3D) -> void:
	if p_tree and p_skeleton:
		var skeleton_bones = []
		skeleton_bones.resize(p_skeleton.get_bone_count())

		p_tree.clear()
		p_tree.set_hide_root(true)
		var root: TreeItem = p_tree.get_root()
		var my_root: TreeItem = tree.create_item(root)

		for i in range(p_skeleton.get_bone_count()):
			skeleton_bones[i] = null

			if is_bone_name_valid(p_skeleton.get_bone_name(i)):
				var parent_id: int = p_skeleton.get_bone_parent(i)
				while 1:
					if parent_id != -1:
						if skeleton_bones[parent_id] != null:
							skeleton_bones[i] = tree.create_item(skeleton_bones[parent_id])
							break
						else:
							parent_id = p_skeleton.get_bone_parent(parent_id)
					else:
						skeleton_bones[i] = tree.create_item(my_root)
						break

				if skeleton_bones[i]:
					skeleton_bones[i].set_icon(0, bone_icon)
					skeleton_bones[i].set_text(0, p_skeleton.get_bone_name(i))
					skeleton_bones[i].set_metadata(0, p_skeleton.get_bone_name(i))


func update() -> void:
	update_tree(tree, skeleton)


func _about_to_popup() -> void:
	filter_lineedit.text = ""
	_filter_changed("")


func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			filter_lineedit.grab_focus()


func _init(p_bone_icon: Texture, p_clear_icon: Texture):
	about_to_popup.connect(self._about_to_popup)
	confirmed.connect(self._confirmed)

	set_title("Select bone...")
	set_size(Vector2(DIALOG_WIDTH, DIALOG_HEIGHT))

	bone_icon = p_bone_icon
	clear_icon = p_clear_icon

	unresizable = false

	vbox_container = VBoxContainer.new()
	add_child(vbox_container)

	filter_lineedit = LineEdit.new()
	filter_lineedit.set_h_size_flags(LineEdit.SIZE_EXPAND_FILL)
	filter_lineedit.set_placeholder("Filter bones")
	filter_lineedit.add_theme_constant_override("minimum_spaces", 0)
	filter_lineedit.text_changed.connect(self._filter_changed)
	vbox_container.add_child(filter_lineedit)

	tree = Tree.new()
	tree.set_v_size_flags(Tree.SIZE_EXPAND_FILL)
	tree.item_activated.connect(self._select)
	vbox_container.add_child(tree)
