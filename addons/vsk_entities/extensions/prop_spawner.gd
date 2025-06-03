@tool
#extends "res://addons/entity_manager/node_3d_simulation_logic.gd"

extends Node

var prop_rpc_table_path = preload("res://addons/vsk_entities/extensions/prop_spawner_rpc_table.gd")
var prop_rpc_table = null

const interactable_prop_const = preload("res://addons/vsk_entities/vsk_interactable_prop.tscn")

@export var spawn_model: PackedScene
@export var rpc_table: NodePath = NodePath()

var spawn_key_pressed_last_frame: bool = false

var prop_pending: bool = false
var prop_cb = null

func get_prop_list() -> Array:
	var return_dict: Dictionary = {"error": FAILED, "message": ""}
	var prop_list : Array = []

	var async_result : Dictionary = await GodotUro.godot_uro_api.get_avatars_async()
	if GodotUro.godot_uro_helper_const.requester_result_is_ok(async_result):
		if async_result.has("output"):
			if (async_result["output"].has("data") and async_result["output"]["data"].has("avatars")):
				return_dict["error"] = OK
				prop_list = async_result["output"]["data"]["avatars"]

	if return_dict["error"] == FAILED:
		push_error("Network request for /props failed")
		return []
	elif typeof(prop_list) != TYPE_ARRAY:
		push_error("Invalid type in return dictionaryfor /props")
		return []
	return prop_list

func get_random_prop_url() -> String:
	var prop_list : Array = await get_prop_list()
	if prop_list.size() == 0:
		push_error("No prop available on server")
		return ""
	var random_prop : Dictionary = prop_list[randi() % prop_list.size()]
	print(typeof(random_prop))
	var prop_url : String = ""
	if random_prop.has("user_content_data"):
		prop_url = GodotUro.get_base_url() + random_prop["user_content_data"]
	else:
		push_error("Error: 'user_content_data' key not found in return dictionary")
	return prop_url

func _prop_load_finished() -> void:
	#VSKPropManager.prop_download_started.disconnect(self._prop_download_started)
	VSKPropManager.prop_load_callback.disconnect(self._prop_load_callback)
	#VSKPropManager.prop_load_update.disconnect(self._prop_load_update)

	prop_pending = false

func _prop_load_succeeded(p_url, p_packed_scene: PackedScene) -> void:
	if prop_cb:
		prop_cb.call(p_packed_scene)
		prop_cb = null
	_prop_load_finished()

func _prop_load_callback(p_url: String, p_err: int, p_packed_scene: PackedScene) -> void:
	if p_err == VSKAssetManager.ASSET_OK:
		push_error("Prop load ok", p_url)
		_prop_load_succeeded(p_url, p_packed_scene)
	else:
		push_error("Prop load failed", p_url, p_err)
		_prop_load_finished()
		#_prop_load_failed(p_url, p_err)

func load_prop_url(prop_url : String, callback : Callable) -> bool:
	if (prop_url.strip_edges() == ""):
		push_error("Prop load failed: no url provided") #, p_url)
		return false

	if !prop_pending:
		prop_pending = true
		if VSKPropManager.prop_load_callback.connect(self._prop_load_callback) != OK:
			push_error("Could not connect signal 'VSKPropManager.prop_load_callback'")
			return false

	prop_cb = callback

	# TODO: use whitelist function with false,false
	VSKPropManager.call_deferred(
		"request_prop", prop_url, true, true
	)
	return true

func spawn_prop_create(p_requester_id, _entity_callback_id: int, prop_scene) -> void:
	var requester_player_entity: RefCounted = VSKNetworkManager.get_player_instance_ref(p_requester_id)  # EntityRef
	#var requester_player_entity2 = VSKNetworkManager.get_player_instance_ref(NetworkManager.get_current_peer_id())
	
	var spawn_model = prop_scene
	if requester_player_entity:
		var requester_transform = requester_player_entity.get_last_transform()

		# TODO: User-set spawn point, currently we add some units away from player
		requester_transform.origin.z += 4 + randi_range(0, 5)

		print(requester_player_entity.get_last_transform())
		print(str(spawn_model))
		if (
			(EntityManager.spawn_entity(
				interactable_prop_const,
				{"transform": requester_transform, "model_scene": spawn_model},
				"NetEntity",
				p_requester_id
			))
			== null
		):
			printerr("Could not spawn prop!")

func spawn_prop_master(p_requester_id, _entity_callback_id: int, prop_scene_url : String) -> void:
	print("Spawn prop master from ", prop_scene_url)
	var prop_spawner = func(prop_scene):
		spawn_prop_create(p_requester_id, _entity_callback_id, prop_scene)
		push_error("prop spawned succx")
	load_prop_url(prop_scene_url, prop_spawner)

func spawn_prop_puppet(_entity_callback_id: int, prop_scene_url : String) -> void:
	print("Spawn prop puppet from ", prop_scene_url)

func spawn_prop_test() -> void:
	var url_path = await get_random_prop_url()
	prop_rpc_table.nm_rpc_id(0, "spawn_prop", [0, url_path])


static var previous_frame_time
func test_spawning() -> void:
	print("test spawning")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var current_seconds = int(Time.get_unix_time_from_system()) % 60
	var current_frame_time: float = Time.get_ticks_msec() / 1000.0
	if current_frame_time - previous_frame_time >= 4.0:
		print("More than 4 seconds have elapsed since the last check!")
		previous_frame_time = current_frame_time
		var url_test = "res://vsk_default/scenes/prefabs/beachball.tscn"
		# Comment out line below to test prop physics
		url_test = await get_random_prop_url()

		prop_rpc_table.nm_rpc_id(0, "spawn_prop", [0, url_test])

	if InputManager.ingame_input_enabled():
		var spawn_key_pressed_this_frame: bool = Input.is_key_pressed(KEY_P)
		if !spawn_key_pressed_last_frame:
			if spawn_key_pressed_this_frame:
				spawn_prop_test()

		spawn_key_pressed_last_frame = spawn_key_pressed_this_frame

# TODO: Rework with game ready signal
@export var tester = false

func _process(_delta: float):
	if !Engine.is_editor_hint():
		if tester == true:
			test_spawning()


func _ready() -> void:
	if !Engine.is_editor_hint():
		prop_rpc_table = prop_rpc_table_path.new()
		add_child(prop_rpc_table)

		previous_frame_time = Time.get_ticks_msec() / 1000.0
		if (prop_rpc_table.session_master_spawn.connect(self.spawn_prop_master) != OK):
			push_error("Could not connect signal 'session_master_spawn' at VSKPropSpawner")
			return
		if (prop_rpc_table.session_puppet_spawn.connect(self.spawn_prop_puppet) != OK):
			push_error("Could not connect signal 'session_puppet_spawn' at VSKPropSpawner")
			return
