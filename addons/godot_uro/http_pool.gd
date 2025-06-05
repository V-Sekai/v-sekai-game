# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# http_pool.gd
# SPDX-License-Identifier: MIT
@tool
extends Node
class_name HTTPPool

## TODO: cancelling doesn't work.

signal http_tick

var next_request: int = 0
var pending_requests: Dictionary = {}  # int -> Future

var http_client_pool: Array[HTTPClient]
var total_http_clients: int = 0


class Future:
	signal completed(http: HTTPClient)


class HTTPState:
	signal connection_finished(http_client: HTTPClient)
	signal request_finished(success: bool)
	signal download_progressed(bytes: int, total_bytes: int)

	const YIELD_PERIOD_MS = 50

	var out_path: String = ""

	var http_pool: Node
	var http: HTTPClient
	var cancelled: bool = false
	var terminated: bool = false

	var sent_request: bool = false
	var status: int
	var connect_err: int = OK

	var response_code: int
	var response_body: PackedByteArray
	var response_headers: Dictionary
	var file: FileAccess
	var bytes: int
	var total_bytes: int

	func _init(p_http_pool: Node, p_http_client: HTTPClient):
		self.http = p_http_client
		self.http_pool = p_http_pool

	func set_output_path(p_out_path: String) -> void:
		self.out_path = p_out_path

	func cancel() -> void:
		cancelled = true

	func term() -> void:
		terminated = true
		http.close()
		http = HTTPClient.new()

	func handle_connection_tick() -> void:
		if terminated:
			if file:
				file.close()
			connection_finished.emit(null)
			return

		var poll_error: Error = http.poll()
		if poll_error != OK:
			printerr("poll_error %s" % error_string(poll_error))
		status = http.get_status()

		if (
			status == HTTPClient.STATUS_CONNECTED
			or status == HTTPClient.STATUS_REQUESTING
			or status == HTTPClient.STATUS_BODY
		):
			connection_finished.emit(http)
			return

		if (
			status != HTTPClient.STATUS_CONNECTING
			and status != HTTPClient.STATUS_RESOLVING
			and status != HTTPClient.STATUS_CONNECTED
		):
			push_error(
				(
					"HTTPPool: could not connect to host: status = %s"
					% [str(http.get_status())]
				)
			)
			connection_finished.emit(null)
			return

	func handle_request_tick() -> void:
		var exit_result = null  # Can be true, false, or null (not exiting)

		status = http.get_status()

		if terminated:
			if file:
				file.close()
			exit_result = false
		elif status != HTTPClient.STATUS_REQUESTING and status != HTTPClient.STATUS_BODY:
			exit_result = false
		elif cancelled:
			if file:
				file.close()
			cancelled = false
			http.close()
			exit_result = false
		else:
			if status == HTTPClient.STATUS_REQUESTING:
				http.poll()
				if status == HTTPClient.STATUS_BODY:
					response_code = http.get_response_code()
					response_headers = http.get_response_headers_as_dictionary()

					bytes = 0
					if response_headers.has("Content-Length"):
						total_bytes = int(response_headers["Content-Length"])
					else:
						total_bytes = -1
					if not out_path.is_empty():
						file = FileAccess.open(out_path, FileAccess.WRITE)
						if file.is_null():
							status = HTTPClient.STATUS_CONNECTED
							exit_result = false

			# Only proceed if no exit yet
			if exit_result == null:
				var last_yield = Time.get_ticks_msec()
				var time: int = 0
				var should_yield := false

				while status == HTTPClient.STATUS_BODY and exit_result == null:
					var poll_error: int = http.poll()
					if poll_error != OK:
						printerr("poll_error %s" % error_string(poll_error))
						
					var chunk = http.read_response_body_chunk()
					response_code = http.get_response_code()
					
					if file:
						file.store_buffer(chunk)
					else:
						response_body.append_array(chunk)
					bytes += chunk.size()
					self.download_progressed.emit(bytes, total_bytes)

					time = Time.get_ticks_msec()

					status = http.get_status()
					if status == HTTPClient.STATUS_CONNECTION_ERROR and !terminated and !cancelled:
						if file:
							file.close()
						exit_result = false
					else:
						if status != HTTPClient.STATUS_BODY:
							exit_result = true
							if file:
								file.close()
						else:
							if time - last_yield > YIELD_PERIOD_MS:
								should_yield = true
								break

				if should_yield:
					return  # Yield without finishing

		# Emit result and exit if needed
		if exit_result != null:
			request_finished.emit(exit_result)
			return

	func http_tick() -> void:
		if not sent_request:
			handle_connection_tick()
		else:
			handle_request_tick()

	func connect_http(hostname: String, port: int, use_ssl: bool) -> HTTPClient:
		sent_request = false
		status = http.get_status()
		var connection = http.connection
		if use_ssl and status == HTTPClient.STATUS_CONNECTED:
			if connection is StreamPeerTLS:
				var underlying: StreamPeer = connection.get_stream()
				if underlying is StreamPeerTCP:
					if (
						status == HTTPClient.STATUS_CONNECTED
						and underlying.get_connected_host() == hostname
						and underlying.get_connected_port() == port
					):
						return http
				else:
					if status == HTTPClient.STATUS_CONNECTED:
						return http
		elif not use_ssl and status == HTTPClient.STATUS_CONNECTED:
			if connection is StreamPeerTCP:
				if (
					(not (connection is StreamPeerTLS))
					and status == HTTPClient.STATUS_CONNECTED
					and connection.get_connected_host() == hostname
					and connection.get_connected_port() == port
				):
					return http

		status = http.get_status()
		if status != HTTPClient.STATUS_DISCONNECTED and status != HTTPClient.STATUS_CONNECTED:
			http.close()
			http = HTTPClient.new()

		if status != HTTPClient.STATUS_CONNECTED:
			var tls_options: TLSOptions = TLSOptions.client(null)
			connect_err = http.connect_to_host(hostname, port, tls_options)
			if connect_err != OK:
				push_error(
					(
						"HTTPPool: could not connect to host: returned error %s"
						% str(connect_err)
					)
				)
				http.close()
				http = HTTPClient.new()
				return null

		http_pool.http_tick.connect(self.http_tick)
		var ret = await self.connection_finished
		http_pool.http_tick.disconnect(self.http_tick)
		return ret

	func wait_for_request():
		sent_request = true
		http_pool.http_tick.connect(self.http_tick)
		var ret = await self.request_finished
		call_deferred("release")
		return ret

	func release():
		if not http_pool:
			return
		if http_pool.http_tick.is_connected(self.http_tick):
			http_pool.http_tick.disconnect(self.http_tick)
		if self.http_pool != null and self.http != null:
			self.http_pool._release_client(self.http)
			self.http_pool = null
			self.http = null


func _process(_ts: float):
	WorkerThreadPool.add_task(Callable(self, "_http_tick_task"))


func _http_tick_task():
	call_thread_safe("emit_http_tick")


func emit_http_tick():
	http_tick.emit()


func _init(p_http_client_limit: int = 5):
	total_http_clients = p_http_client_limit
	for i in range(total_http_clients):
		http_client_pool.push_back(HTTPClient.new())


func new_http_state() -> HTTPState:
	var http_client: HTTPClient = await _acquire_client()
	return HTTPState.new(self, http_client)


func _acquire_client() -> HTTPClient:
	if not http_client_pool.is_empty():
		return http_client_pool.pop_back()
	var f = Future.new()
	pending_requests[next_request] = f
	next_request += 1
	return await f.completed


func _release_client(http: HTTPClient):
	var pending_key: Variant = null
	for pr in pending_requests:
		pending_key = pr
	if typeof(pending_key) != TYPE_NIL:
		var f: Future = pending_requests[pending_key]
		pending_requests.erase(pending_key)
		f.completed.emit(http)
	else:
		http_client_pool.push_back(http)
