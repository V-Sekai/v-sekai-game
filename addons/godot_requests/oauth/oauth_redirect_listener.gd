extends Node
class_name OAuthRedirectListener

enum State { IDLE, LISTENING, READING, PARSING, RESPONDING, DONE, ERROR }

var state := State.IDLE
var header_deadline: int = 5000

# Maximum bytes to read
const MAX_BYTES: int = 1000
const MAX_CHUNK_SIZE: int = 100 # bytes

var port: int
var bind_address: String
var timeout_ms: int = 60000
var allowed_params: Array[String] = ["code", "state", "provider", "access_token", "expires_in", "client_id"]

var max_deadline_ms: int
var header_deadline_ms: int
var _server: TCPServer
var _peer: StreamPeerTCP
var _buffer: String = ""
var result: Dictionary = {}

signal oauth_redirect_success(params: Dictionary)
signal oauth_redirect_failure(error_msg: String)

func _init(p_port: int, p_bind_address: String = "127.0.0.1", p_timeout_ms: int = 60000) -> void:
	set_process(false)
	port = p_port
	bind_address = p_bind_address
	timeout_ms = p_timeout_ms

	_buffer = ""
	result = {}

	_server = TCPServer.new()

# Starts listening. Process handles one GET request, parses query params,
# responds with JSON and returns params with signals.
func start_listen() -> Error:
	var err = _server.listen(port, bind_address)
	if err != OK:
		_enter_error("Failed to listen on %s:%d (err %d)" % [bind_address, port, err])
		return err
	print("starting")
	var current_ticks = Time.get_ticks_msec()
	var header_timeout_ms = ceil(timeout_ms * 0.8)
	
	max_deadline_ms = current_ticks + timeout_ms
	header_deadline_ms = current_ticks + header_timeout_ms
	state = State.LISTENING
	set_process(true)
	return OK

func _process(delta):
	if Time.get_ticks_msec() > max_deadline_ms:
		_enter_error("Oauth Timeout reached.")
	
	match state:
		State.LISTENING:
			if _server.is_connection_available():
				_peer = _server.take_connection()
				_peer.set_no_delay(true)
				state = State.READING

		State.READING:
			if Time.get_ticks_msec() > header_deadline_ms:
				_enter_error("Timeout reading headers")
				return
			else:
				var avail: int = _peer.get_available_bytes()
				var chunk_size: int = min(avail, MAX_CHUNK_SIZE)
				if (_buffer.length() + chunk_size) > MAX_BYTES:
					_enter_error("Incoming request sent too many bytes.")
					return

				if avail > 0:
					var fragment: String = _peer.get_string(chunk_size)
					if is_string_us_ascii(fragment):
						_buffer += fragment
						fragment = ""
					else:
						_enter_error("Invalid characters in request data stream.")
						return

				# Read until end of headers (CRLF CRLF)
				if _buffer.find("\r\n\r\n") != -1:
					state = State.PARSING

		State.PARSING:
			var parse_result = _parse_buffer(_buffer, allowed_params)
			if parse_result.status != OK:
				_enter_error(parse_result.message)
				return
			result = parse_result.query_params
			state = State.RESPONDING

		State.RESPONDING:
			# Respond with JSON payload
			var json_msg = {"message": "OAuth completed"}
			var json_body = JSON.stringify(json_msg)
			var resp = ( "HTTP/1.1 200 OK\r\n" + \
					   "Content-Type: application/json\r\n" + \
					   "Content-Length: %s\r\n" + \
					   "Connection: close\r\n\r\n%s" ) % [
						   json_body.to_utf8_buffer().size(),
						   json_body
					   ]
			_peer.put_utf8_string(resp)
			_enter_done(result)

		State.ERROR, State.DONE:
			set_process(false)
			pass

func _enter_done(result: Dictionary):
	_stop_and_cleanup()
	state = State.DONE
	set_process(false)
	print(result)
	oauth_redirect_success.emit(result)

func _enter_error(msg: String):
	push_error(msg)
	state = State.ERROR
	_stop_and_cleanup()
	set_process(false)
	oauth_redirect_failure.emit(msg)

# Internal cleanup of connections and server
func _stop_and_cleanup() -> void:
	_buffer = ""
	# if _peer and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		# should disconnect?
		# _peer.disconnect_from_host()
	if _peer and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_peer.disconnect_from_host()
	if _server.is_listening():
		_server.stop()
		push_warning("TCP Server was terminated.")

func _parse_buffer(p_buffer: String, p_allowed_params: Array[String]) -> Dictionary:
	var error_response = {
		"status": FAILED,
		"message": "Unexpected error."
	}

	# Locate end of headers
	var separator := "\r\n\r\n"
	var sep_pos := p_buffer.find(separator)
	if sep_pos < 0:
		error_response.message = "Invalid HTTP header: missing separator."
		return error_response

	# Split header lines
	var header_part := p_buffer.substr(0, sep_pos)
	var lines := header_part.split("\r\n", false)
	if lines.size() < 1:
		error_response.message = "Invalid header received."
		return error_response

	# Parse request line
	var request_line := lines[0]
	var tokens := request_line.split(" ", false)
	if tokens.size() < 2:
		error_response.message = "Invalid request line."
		return error_response

	var method := tokens[0]
	var full_path := tokens[1]

	# Only GET supported
	if method != "GET":
		error_response.message = "Unsupported HTTP method: %s" % method
		return error_response

	# Extract and sanitize query parameters
	var query_params = _parse_unsafe_query_params(full_path, p_allowed_params)
	if query_params.status != OK:
		error_response.message = query_params.message
		return error_response

	return {
		"status": OK,
		"query_params": query_params.params
	}


# Splits unsafe "/path?key=val&foo=bar" into { key: val, foo: bar }
# Input is untrusted, return early on any mismatch
func _parse_unsafe_query_params(p_unsafe_path: String, p_allowed_params: Array[String]) -> Dictionary:
	var error_response = {
		"status": FAILED,
		"message": "Unexpected error."
	}

	var dict: Dictionary = {}
	var max_params: int = p_allowed_params.size()

	var qpos: int = p_unsafe_path.find("?")
	if qpos < 0:
		error_response.message = "Input path doesn't contain query string."
		return error_response

	var query_string: String = p_unsafe_path.substr(qpos + 1)
	var pairs_array: Array = query_string.split("&", false)
	if pairs_array.size() > max_params:
		error_response.message = "Input path is over maximum number of parameters"
		return error_response

	for pair in pairs_array:
		var key_val: Array = pair.split("=", false)
		if key_val.size() != 2:
			error_response.message = "Invalid query found, parse failed."
			return error_response
		
		var key = key_val[0].uri_decode()
		if key not in p_allowed_params:
			error_response.message = "Input path contains invalid query key"
			return error_response

		var val = key_val[1].uri_decode()
		if not is_string_us_ascii(val):
			error_response.message = "Input path contains invalid query value"
			return error_response
		dict[key] = val

	return {
		"status": OK,
		"params": dict
	}

func is_valid_us_ascii(data: PackedByteArray) -> bool:
	for b in data:
		if b > 0x7F:
			return false
	return true

func is_string_us_ascii(p_string: String) -> bool:
	for char in range(p_string.length()):
		var char_code = p_string.unicode_at(char)
		if char_code > 0x7F:
			return false
	return true
