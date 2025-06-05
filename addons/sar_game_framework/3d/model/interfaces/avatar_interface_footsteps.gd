@tool
class_name SarAvatarInterfaceFootsteps
extends Node

enum DefaultHumanoidFootID {
	LEFT_FOOT = 0,
	RIGHT_FOOT = 1
}

signal footstep_requested(p_foot_id: int, p_attachment: BoneAttachment3D)

@export var left_foot_attachment: BoneAttachment3D = null
@export var right_foot_attachment: BoneAttachment3D = null

@export var left_footstep_audio_player: AudioStreamPlayer3D = null
@export var right_footstep_audio_player: AudioStreamPlayer3D = null

func left_footstep_down() -> void:
	footstep_requested.emit(DefaultHumanoidFootID.LEFT_FOOT, left_foot_attachment)
	
func right_footstep_down() -> void:
	footstep_requested.emit(DefaultHumanoidFootID.RIGHT_FOOT, right_foot_attachment)
