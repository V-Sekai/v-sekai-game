@tool
extends Object

const OAUTH_HOSTNAME = "sketchfab.com"
const API_HOSTNAME = "api.sketchfab.com"
const USE_SSL = true
const BASE_PATH = "/v3"
const CLIENT_ID = "IUO8d5VVOIUCzWQArQ3VuXfbwx5QekZfLeDlpOmW"

enum SymbolicErrors {
	NOT_AUTHORIZED,
}

static func get_token():
	if Engine.get_main_loop().has_meta("__sketchfab_token"):
		return Engine.get_main_loop().get_meta("__sketchfab_token")
	else:
		return null

static func set_token(token):
	Engine.get_main_loop().set_meta("__sketchfab_token", token)

const Requestor = preload("res://addons/sketchfab/Requestor.gd")
var Result = Requestor.Result

var requestor = Requestor.new(API_HOSTNAME, USE_SSL)
var busy = false

func term():
	requestor.term()

func cancel():
	await requestor.cancel()

func login(username, password):
	var query = {
		"username": username,
		"password": password,
	}

	busy = true
	var requestor = Requestor.new(OAUTH_HOSTNAME, USE_SSL)
	requestor.request(
		"/oauth2/token/?grant_type=password&client_id=%s" % CLIENT_ID, query,
		{ "method": HTTPClient.METHOD_POST, "encoding": "form" }
	)

	var result = await requestor.completed
	requestor.term()
	busy = false

	var data = _handle_result(result)
	if data && typeof(data) == TYPE_DICTIONARY && data.has("access_token"):
		var token = data["access_token"]
		set_token(token)
		return token
	else:
		set_token(null)
		return null

func get_my_info():
	busy = true
	requestor.request("%s/me" % BASE_PATH, null, { "token": get_token() })
	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func get_categories():
	busy = true
	requestor.request("%s/categories" % BASE_PATH)

	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func get_model_detail(uid):
	busy = true
	requestor.request("%s/models/%s" % [BASE_PATH, uid])

	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func request_download(uid):
	busy = true
	requestor.request("%s/models/%s/download" % [BASE_PATH, uid], null, { "token": get_token() })

	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func search_models(q, categories, animated, staff_picked, min_face_count, max_face_count, sort_by, domain_suffix):

	var query = {}

	if q:
		query.q = q
	if categories:
		query.categories = categories
	
	if animated:
		query.animated = "true"
	else:
		query.animated = "false"
	
	if staff_picked:
		query.staffpicked = "true"
	else:
		query.staffpicked = "false"
	
	if min_face_count:
		query.min_face_count = min_face_count
	if max_face_count:
		query.max_face_count = max_face_count
	if sort_by:
		query.sort_by = sort_by

	busy = true

	var search_domain = BASE_PATH + domain_suffix
	requestor.request(search_domain, query, { "token": get_token() })

	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func fetch_next_page(url):
	# Strip protocol + domain
	var uri = url.right(url.find(API_HOSTNAME) + API_HOSTNAME.length())

	busy = true
	requestor.request(uri)

	var result = await requestor.completed
	busy = false

	return _handle_result(result)

func _handle_result(result):
	# Request canceled
	if !result:
		return null

	# General connectivity error
	if !result.ok:
		OS.alert('Network operation failed. Try again later.', 'Error')
		return null

	# HTTP error
	var kind = result.code / 100
	if kind == 4:
		return SymbolicErrors.NOT_AUTHORIZED
	elif kind == 5:
		OS.alert('Server error. Try again later.', 'Error')
		return null

	return result.data
