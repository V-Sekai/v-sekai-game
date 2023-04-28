@tool
extends AcceptDialog


func set_info_text(p_text: String) -> void:
	$InfoLabel.set_text(p_text)

	set_size(Vector2())
