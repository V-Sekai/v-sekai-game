@tool
extends Node3D
class_name SarAnchorPivot3D

## This helper node is intended for when given an 'anchor node',
## which is an ancestor of this node. It will attempt to rotate
## the anchor node's parent node in such a way that the anchor's
## position relative to this node is maintained while applying
## the same transform to it in local space. Intended for situations
## where we want to give perception of rotating a node we can't rotate
## directly, such as an XRCamera when XR mode is enabled.

## Emitted with the delta rotational different when rotated in local space.
signal delta_rotated(p_basis: Basis)

## The node which we are anchoring around. It should be an ancestor
## of the current node and have at least one Node3D node between this
## and it.
@export var anchor_node: Node3D:
	set(p_anchor_node):
		anchor_node = p_anchor_node
		
## Flag to determine whether we should rotate the anchor's parent node or not.
@export var modify_anchor_parent: bool = false

var _previous_transform: Transform3D

func _notification(p_what: int) -> void:
	match p_what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			# Calculate delta transform and apply inverse to anchor parent.
			if modify_anchor_parent:
				# Question, should we be using inverse() or affine_inverse in this context?
				# I think affine_inverse will be more precise in the contexts we're using this
				# for.
				var anchor_parent: Node3D = anchor_node.get_parent()
				if anchor_parent and anchor_parent != self:
					# Fun inverse matrix math incoming:
					var delta: Transform3D = _previous_transform.affine_inverse() * transform
					anchor_parent.transform = (delta.affine_inverse() * anchor_parent.transform) \
					* (anchor_node.transform \
						* Transform3D(anchor_node.basis, Vector3()).affine_inverse() \
						* Transform3D(delta.basis, Vector3()) \
						* Transform3D(anchor_node.basis, Vector3()) \
						* anchor_node.transform.affine_inverse())
						
					anchor_parent.scale = Vector3.ONE
					
					# Now emit a signal with rotational delta so nodes can respond.
					delta_rotated.emit(Transform3D(delta.basis, Vector3()))
					
			_previous_transform = transform

func _ready() -> void:
	_previous_transform = transform
	set_notify_local_transform(true)
