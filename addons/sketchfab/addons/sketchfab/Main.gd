@tool
extends Control

const CONFIG_FILE_PATH = "user://sketchfab.ini"

const FACE_COUNT_OPTIONS = [
	# Label, face_count, max_face_count
	["Any", null, null],
	["Up to 10k", null, 10000],
	["10k to 50k", 10000, 50000],
	["50k to 100k", 50000, 100000],
	["100k to 250k", 100000, 250000],
	["More than 250k", 250000, null],
]

const SORT_BY_OPTIONS = [
	["Relevance", null],
	["Recent", "-publishedAt"],
	["Likes", "-likeCount"],
	["Views", "-viewCount"],
]

const SEARCH_DOMAIN = [
	["Whole site", "/search?type=models&downloadable=true"],
	["Own models (PRO)", "/me/search?type=models&downloadable=true"],
	["Purchased models", "/me/models/purchases?"],
]

const SORT_BY_DEFAULT_INDEX = 1
const DEFAULT_DOMAIN = 0

const SafeData = preload("res://addons/sketchfab/SafeData.gd")
const Utils = preload("res://addons/sketchfab/Utils.gd")
const Api = preload("res://addons/sketchfab/Api.gd")
var api = Api.new()

@onready var search_text = get_node("Search/_/_/Text")
@onready var search_categories = get_node("Search/_/_3/_/_3/Categories")
@onready var search_animated = get_node("Search/_/_3/_/Animated")
@onready var search_staff_picked = get_node("Search/_/_3/_/StaffPicked")
@onready var search_face_count = get_node("Search/_/_3/_/_2/FaceCount")
@onready var search_sort_by = get_node("Search/_/_3/_/_/SortBy")
@onready var search_domain = get_node("Search/_/_/SearchDomain")
@onready var cta_button = get_node("_2/Paginator/_/Trailer/CTA")
@onready var trailer = get_node("_2/Paginator/_/Trailer")
@onready var paginator = get_node("_2/Paginator")

@onready var not_logged = get_node("Header/_/NotLogged")
@onready var login_name = get_node("Header/_/NotLogged/UserName")
@onready var login_password = get_node("Header/_/NotLogged/Password")
@onready var login_button = get_node("Header/_/NotLogged/Login")

@onready var logged = get_node("Header/_/Logged")
@onready var logged_name = get_node("Header/_/Logged/_/MainBlock/UserName")
@onready var logged_plan = get_node("Header/_/Logged/_/MainBlock/Plan")
@onready var logged_avatar = get_node("Header/_/Logged/_/Avatar")

var editor_interface :EditorInterface
var cfg
var can_search
var must_start_up = true
var is_ready = false

func _enter_tree():
	cfg = ConfigFile.new()
	cfg.load(CONFIG_FILE_PATH)

func _ready():
	paginator.editor_interface = editor_interface
	var editor_scale = 1.0
	logged_avatar.custom_minimum_size *= editor_scale
	not_logged.custom_minimum_size *= editor_scale
	get_node("Header/_/Logged/_/MainBlock").custom_minimum_size *= editor_scale
	is_ready = true
	
func _exit_tree():
	cfg.save(CONFIG_FILE_PATH)

func _notification(what):
	if is_ready:
		if what != NOTIFICATION_VISIBILITY_CHANGED:
			return
		if !visible || !must_start_up:
			return

		must_start_up = false

		logged_avatar.max_size = logged_avatar.custom_minimum_size.y
		can_search = false

		search_categories.get_popup().add_check_item("All")
		search_categories.get_popup().index_pressed.connect(_on_Categories_index_pressed)

		for item in FACE_COUNT_OPTIONS:
			search_face_count.add_item(item[0])
		_commit_face_count(0)

		for item in SORT_BY_OPTIONS:
			search_sort_by.add_item(item[0])
		_commit_sort_by(SORT_BY_DEFAULT_INDEX)

		for item in SEARCH_DOMAIN:
			search_domain.add_item(item[0])
		_commit_domain(DEFAULT_DOMAIN)
		search_domain.hide()
		cta_button.hide()

		logged.visible = false
		not_logged.visible = false
		login_name.text = cfg.get_value("api", "user", "")

		if cfg.has_section_key("api", "token"):
			api.set_token(cfg.get_value("api", "token"))
			await _populate_login()
		else:
			not_logged.visible = true

		await _load_categories()
		_commit_category(0)

		can_search = true
		_search()

##### UI

func _on_any_login_text_changed(new_text):
	_refresh_login_button()

func _on_UserName_text_entered(new_text):
	login_password.grab_focus()

func _on_Password_text_entered(new_text):
	_login()

func _on_Login_pressed():
	_login()

func _on_Logout_pressed():
	_logout()

func _on_any_search_trigger_changed():
	_search()

func _on_Categories_index_pressed(index):
	_commit_category(index)
	_search()

func _on_FaceCount_item_selected(index):
	_commit_face_count(index)
	_search()

func _on_SortBy_item_selected(index):
	_commit_sort_by(index)
	_search()

func _on_SearchDomain_item_selected(index):
	_commit_domain(index)
	_search()

func _on_SearchButton_pressed():
	_search()

func _on_SearchText_text_entered(new_text):
	_search()

##### Actions

func _login():
	if api.busy:
		return

	cfg.set_value("api", "user", login_name.text)

	_set_login_disabled(true)
	var token = await api.login(login_name.text, login_password.text)
	_set_login_disabled(false)

	if token:
		cfg.set_value("api", "token", token)
		cfg.save(CONFIG_FILE_PATH)
		await _populate_login()
	else:
		OS.alert('Please check username and password and try again.', 'Cannot login')
		_logout()

	cfg.save(CONFIG_FILE_PATH)

func _populate_login():

	search_domain.show()

	_set_login_disabled(true)
	var user = await api.get_my_info()
	_set_login_disabled(false)

	if user == null || typeof(user) != TYPE_DICTIONARY:
		_logout()
		return

	if !user.has("username") || !user.has("account"):
		_logout()
		return

	not_logged.visible = false
	logged.visible = true

	logged_name.text = "User: %s" % user["username"]

	var plan_name
	if user["account"] == "plus":
		plan_name = "PLUS"
	elif user["account"] == "pro":
		plan_name = "PRO"
	elif user["account"] == "prem":
		plan_name = "PREMIUM"
	elif user["account"] == "biz":
		plan_name = "BUSINESS"
	elif user["account"] == "ent":
		plan_name = "ENTERPRISE"
	else:
		plan_name = "BASIC";

	logged_plan.text = "Plan: %s" % plan_name

	var avatar = SafeData.dictionary(user, "avatar")
	var images = SafeData.array(avatar, "images")
	var image = SafeData.dictionary(images, 0)
	logged_avatar.url = SafeData.string(image, "url")

func _logout():
	Api.set_token(null)
	cfg.set_value("api", "token", null)
	cfg.save(CONFIG_FILE_PATH)
	not_logged.visible = true
	logged.visible = false
	logged_avatar.url = null
	search_domain.hide()
	cta_button.hide()
	trailer.modulate.a = 0.0
	search_domain.set_meta("__suffix", SEARCH_DOMAIN[0][1])

func _load_categories():
	var result = await api.get_categories()
	if typeof(result) != TYPE_DICTIONARY:
		return

	var categories = SafeData.array(result, "results")
	var i = 0
	var popup = search_categories.get_popup()
	for category in categories:
		popup.add_check_item(SafeData.string(category, "name"))
		popup.set_item_metadata(i + 1, SafeData.string(category, "slug"))
		i += 1

func _search():
	if !can_search:
		return

	paginator.search(
		search_text.text,
		search_categories.get_meta("__slugs"),
		search_animated.button_pressed,
		search_staff_picked.button_pressed,
		search_face_count.get_meta("__data")[1],
		search_face_count.get_meta("__data")[2],
		search_sort_by.get_meta("__key"),
		search_domain.get_meta("__suffix")
	)

##### Helpers

func _commit_category(index):
	var popup = search_categories.get_popup()
	var checked = !popup.is_item_checked(index)
	popup.set_item_checked(index, checked)

	var all = false

	if index == 0:
		for i in range(popup.get_item_count()):
			popup.set_item_checked(i, checked)
	else:
		if !checked:
			popup.set_item_checked(0, false)

	var n = 0
	var label
	var some = []
	for i in range(popup.get_item_count()):
		if popup.is_item_checked(i):
			if i == 0:
				label = "All"
				all = true
				n = -1
				break
			if n == 0:
				label = popup.get_item_text(i)
				some.append(popup.get_item_metadata(i))
				n += 1
			elif n >= 1:
				label = "<Multiple>"
				some.append(popup.get_item_metadata(i))
				n += 1

	if n == 0:
		all = true
	elif n == popup.get_item_count() - 1:
		popup.set_item_checked(0, true)
		all = true
	search_categories.text = "All" if all else label

	if all:
		search_categories.set_meta("__slugs", [])
	else:
		search_categories.set_meta("__slugs", some)

func _commit_face_count(index):
	search_face_count.set_meta("__data", FACE_COUNT_OPTIONS[index])

func _commit_sort_by(index):
	search_sort_by.set_meta("__key", SORT_BY_OPTIONS[index][1])

func _commit_domain(index):
	search_domain.set_meta("__suffix", SEARCH_DOMAIN[index][1])

func _set_login_disabled(disabled):
	login_name.editable = !disabled
	login_password.editable = !disabled
	if disabled:
		login_button.disabled = true
	else:
		_refresh_login_button()

func _refresh_login_button():
	login_button.disabled = !(login_name.text.length() > 0 && login_password.text.length() > 0)
