extends "res://addons/extended_kinematic_body/extended_kinematic_body.gd"

signal touched_by_body(p_body)


func send_touched_by_body(p_body):
	touched_by_body.emit(p_body)
