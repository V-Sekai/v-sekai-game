#	Copyright (c) 2019 Lawnjelly
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

extends Node3D

@export var target: NodePath:
	set = set_target,
	get = get_target

var _m_Target: Node3D

var _m_trCurr: Transform3D
var _m_trPrev: Transform3D

const SF_ENABLED: int = 1 << 0
const SF_TRANSLATE: int = 1 << 1
const SF_BASIS: int = 1 << 2
const SF_SLERP: int = 1 << 3
const SF_DIRTY: int = 1 << 4
const SF_INVISIBLE: int = 1 << 5

@export var flags: int = SF_ENABLED | SF_TRANSLATE | SF_BASIS:  # (int, FLAGS, "enabled", "translate", "basis", "slerp") = SF_ENABLED | SF_TRANSLATE | SF_BASIS
	set = _set_flags,
	get = _get_flags

##########################################################################################
# USER FUNCS

# Saracen: callback
signal transform_complete(p_delta)


# call this on e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport():
	var temp_flags = flags
	_SetFlags(SF_TRANSLATE | SF_BASIS)

	_RefreshTransform()
	_m_trPrev = _m_trCurr

	# do one frame update to make sure all components are updated
	_process(0)

	# resume old flags
	flags = temp_flags


func set_enabled(bEnable: bool):
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()


func is_enabled():
	return _TestFlags(SF_ENABLED)


##########################################################################################


func _ready():
	_m_trCurr = Transform3D()
	_m_trPrev = Transform3D()


func set_target(new_value: NodePath) -> void:
	target = new_value
	if is_inside_tree():
		_FindTarget()


func get_target() -> NodePath:
	return target


func _set_flags(new_value: int) -> void:
	flags = new_value
	# we may have enabled or disabled
	_SetProcessing()


func _get_flags() -> int:
	return flags


func _SetProcessing() -> void:
	var bEnable: bool = _TestFlags(SF_ENABLED)
	if _TestFlags(SF_INVISIBLE):
		bEnable = false

	set_process(bEnable)
	set_physics_process(bEnable)


func _enter_tree():
	# might have been moved
	_FindTarget()


func _notification(what):
	match what:
		# invisible turns off processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()


func _RefreshTransform() -> void:
	_ClearFlags(SF_DIRTY)

	if _HasTarget() == false:
		return

	_m_trPrev = _m_trCurr
	_m_trCurr = _m_Target.transform


func _FindTarget() -> void:
	_m_Target = null
	if target.is_empty():
		return

	_m_Target = get_node(target)

	if _m_Target is Node3D:
		return

	_m_Target = null
	#return false


func _HasTarget() -> bool:
	if _m_Target == null:
		return false

	# has not been deleted?
	if is_instance_valid(_m_Target):
		return true

	_m_Target = null
	return false


func _process(_delta):
	if _TestFlags(SF_DIRTY):
		_RefreshTransform()

	var f = Engine.get_physics_interpolation_fraction()

	var current_xform: Transform3D = Transform3D()

	# translate
	if _TestFlags(SF_TRANSLATE):
		var ptDiff = _m_trCurr.origin - _m_trPrev.origin
		current_xform.origin = _m_trPrev.origin + (ptDiff * f)

	# rotate
	if _TestFlags(SF_BASIS):
		if _TestFlags(SF_SLERP):
			current_xform.basis = _m_trPrev.basis.slerp(_m_trCurr.basis, f)
		else:
			current_xform.basis = _LerpBasis(_m_trPrev.basis, _m_trCurr.basis, f)
	transform = current_xform
	transform_complete.emit(_delta)


func _physics_process(_delta):
	# take care of the special case where multiple physics ticks
	# occur before a frame .. the data must flow!
	if _TestFlags(SF_DIRTY):
		_RefreshTransform()

	_SetFlags(SF_DIRTY)


func _LerpBasis(from: Basis, to: Basis, f: float) -> Basis:
	var res: Basis = Basis()
	res.x = from.x.lerp(to.x, f)
	res.y = from.y.lerp(to.y, f)
	res.z = from.z.lerp(to.z, f)
	return res


func _SetFlags(f: int) -> void:
	flags |= f


func _ClearFlags(f: int) -> void:
	flags &= ~f


func _TestFlags(f: int) -> bool:
	return (flags & f) == f


func _ChangeFlags(f: int, bSet: bool):
	if bSet:
		_SetFlags(f)
	else:
		_ClearFlags(f)
