@tool
extends RefCounted

# Stopgap, used until 4.0

var pool_byte_array: PackedByteArray = PackedByteArray()


func _init(p_pool_byte_array: PackedByteArray):
	pool_byte_array = p_pool_byte_array
