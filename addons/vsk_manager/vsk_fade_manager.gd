# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_fade_manager.gd
# SPDX-License-Identifier: MIT

@tool
extends Node

########################
# V-Sekai Fade Manager #
########################

##
## The fade manager is a class soley responsible for executing and providing
## callbacks for crossfades.
##

##################
# Fade constants #
##################

##  How long a default fade should occur
const FADE_TIME = 0.25
##  What a fade should fade in to
const FADE_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
##  What a fade should fade out to
const UNFADE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.0)
##  Is a fade currently being executed
var is_fading = false
##  Emitted when a fade is complete
signal fade_complete(p_fade_skipped)


##
## Callback function which emitted when a crossfade is completed.
## Emits the fade_complete signal and disables the input blocker on
## the main menu.
## p_fade_skipped tells whether the crossfade was manually skipped by the user.
##
func _fade_complete(p_fade_skipped: bool) -> void:
	is_fading = false

	fade_complete.emit(p_fade_skipped)

	VSKMenuManager.get_menu_root().set_input_blocking(false)


##
## Called to execute a crossfade usually used to denotate transitions between
## game states. Also sets an input blocker on the main menu to prevent
## clicking on UI elements from pressed during a crossfade.
## p_fade_in denotes that the fade should a fade-in if true and
## a fade out if false.
##
func execute_fade(p_fade_in: bool) -> Node:
	is_fading = true

	VSKMenuManager.get_menu_root().set_input_blocking(true)

	if p_fade_in:
		FadeManager.call_deferred("execute_fade", FADE_COLOR, UNFADE_COLOR, FADE_TIME)
	else:
		FadeManager.call_deferred("execute_fade", UNFADE_COLOR, FADE_COLOR, FADE_TIME)

	return self


########
# Node #
########


func setup() -> void:
	if !Engine.is_editor_hint():
		var game_viewport: SubViewport = VSKGameFlowManager.game_viewport
		# Setup the VR fader
		var vr_fader: ColorRect = VRManager.vr_fader
		vr_fader.set_color(Color(0.0, 0.0, 0.0, 0.0))
		vr_fader.set_name("Fader")
		vr_fader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
		vr_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if VRManager.vr_fader.is_inside_tree():
			VRManager.vr_fader.get_parent().remove_child(VRManager.vr_fader)

		game_viewport.add_child(VRManager.vr_fader, true)

		if FadeManager.fade_complete.connect(self._fade_complete) != OK:
			printerr("Could not connect fade_complete")
