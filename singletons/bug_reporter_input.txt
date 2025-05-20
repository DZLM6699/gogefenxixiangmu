class_name BugReporterInput
extends CanvasItem

signal cancelled
signal submitted(issue_id)

export (NodePath) var tooltip_path

var _screen_image: Image

onready var _feedback_input = $FeedbackInput as TextEdit
onready var _status_label = $StatusLabel as Label
onready var _send_button = $"%SendButton" as Button
onready var _cancel_button = $"%CancelButton" as Button
onready var _tooltip = get_node(tooltip_path)

onready var _http_request: HTTPRequest = $HTTPRequest

const SUBMIT_URL: = "https://bug-reports.blobfishgames.com/api/submit"


func open() -> void :
	_set_visible(true)


func _set_visible(v: bool) -> void :
	if v:
		
		_screen_image = _capture_screen()

	_set_buttons_disabled(false)
	_status_label.visible = false
	visible = v
	if v:
		_feedback_input.call_deferred("grab_focus")
		if not CrashReporter.previous_crash_message.empty() and CrashReporter.previous_crashed_mod.empty():
			_feedback_input.text = "My game crashed with this error:\n\n" + CrashReporter.previous_crash_message
			CrashReporter.previous_crash_message = ""


func _capture_screen() -> Image:
	var image: = get_tree().get_root().get_texture().get_data()
	image.flip_y()
	return image


func _set_buttons_disabled(v: bool) -> void :
	_send_button.disabled = v
	_send_button.release_focus()
	_cancel_button.disabled = v
	_cancel_button.release_focus()


func _show_status_label(text: String) -> void :
	_status_label.text = text
	_status_label.visible = true


func _send_report() -> void :
	var salt: = "salt-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

	var boundary: = "--------------------------" + str(OS.get_unix_time())
	var form_data: = PoolByteArray()

	form_data.append_array(_add_multipart_field("text", _feedback_input.text, boundary))
	form_data.append_array(_add_multipart_field("user_agent", _get_user_agent(), boundary))
	form_data.append_array(_add_multipart_field("app", _get_application_name(), boundary))
	form_data.append_array(_add_multipart_field("version", ProgressData.VERSION, boundary))

	var log_path: String = ProjectSettings.get_setting("logging/file_logging/log_path")
	var log_directory_path: = ProjectSettings.globalize_path(log_path).get_base_dir()
	var log_file_directory_paths = CrashReporter.get_directory_file_paths(log_directory_path)
	var log_file_paths: = []
	for path in log_file_directory_paths:
		if path.get_extension() == "log":
			log_file_paths.append(path)
	if log_file_paths.empty():
		_print_error("Failed to collect logs in " + log_directory_path)
	for path in log_file_paths:
		form_data.append_array(_add_multipart_file("log", path, "text/plain", boundary, salt))

	var save_directory_path: = ProjectSettings.globalize_path(ProgressData.SAVE_PATH).get_base_dir()
	var save_directory_file_paths = CrashReporter.get_directory_file_paths(save_directory_path)
	var save_file_paths: = []
	for path in save_directory_file_paths:
		if path.get_extension() == "json" or path.ends_with(".json.bak") or path.ends_with(".txt"):
			save_file_paths.append(path)
	if save_file_paths.empty():
		_print_error("Failed to collect save files in " + log_directory_path)
	for path in save_file_paths:
		form_data.append_array(
			_add_multipart_file("file", path, "application/json", boundary, salt)
		)

	var current_progress_data = to_json(ProgressData.get_current_save_object()).to_utf8()
	form_data.append_array(
		_add_multipart_file_data("file", "current_progress_data.json", current_progress_data, "application/json", boundary)
	)

	var screen_image_png: = _screen_image.save_png_to_buffer() if _screen_image else PoolByteArray()
	form_data.append_array(
		_add_multipart_file_data("file", "screenshot.png", screen_image_png, "image/png", boundary)
	)

	
	form_data.append_array(("--" + boundary + "--\n").to_utf8())

	var custom_headers: = ["Content-Type: multipart/form-data; boundary=" + boundary]
	var ssl_validate_domain: = true
	var error = _http_request.request_raw(
		SUBMIT_URL, custom_headers, ssl_validate_domain, HTTPClient.METHOD_POST, form_data
	)

	if error != OK:
		var msg: = "Failed to send HTTP request"
		_print_error(msg)
		_show_status_label(msg)


func _add_multipart_field(name: String, data: String, boundary: String) -> PoolByteArray:
	var field_data: = PoolByteArray()
	field_data.append_array(("--" + boundary + "\n").to_utf8())
	field_data.append_array(
		("Content-Disposition: form-data; name=\"" + name + "\"\n\n").to_utf8()
	)
	field_data.append_array((data + "\n").to_utf8())
	return field_data


func _add_multipart_file(
	name: String, file_path: String, content_type: String, boundary: String, salt: String
) -> PoolByteArray:
	var file: = File.new()
	if file.open(file_path, File.READ) != OK:
		_print_error("Failed to read file %s" % file_path)
		return PoolByteArray()

	var file_content: = anonymize_text(file.get_as_text(), salt, false).to_utf8()
	file.close()

	
	var filename: = anonymize_text(file_path, salt, true).replace("/", "__")
	
	filename = filename.replace(".json.bak", "_bak.json")
	return _add_multipart_file_data(name, filename, file_content, content_type, boundary)


func _add_multipart_file_data(
	name: String, filename: String, file_data: PoolByteArray, content_type: String, boundary: String
) -> PoolByteArray:
	var content_disposition: = (
		"Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"\n"
		% [name, filename]
	)
	var header: = (
		"--%s\n%sContent-Type: %s\n\n"
		% [boundary, content_disposition, content_type]
	)

	var multipart_data: = PoolByteArray()
	multipart_data.append_array(header.to_utf8())
	multipart_data.append_array(file_data)
	multipart_data.append_array("\n".to_utf8())

	return multipart_data


func anonymize_text(text: String, salt: String, for_filename: bool) -> String:
	
	text = _hash_user_ids(text, salt)

	
	var user_path: = ProjectSettings.globalize_path("user://")
	text = text.replace(user_path, "user/" if for_filename else "<user://>")

	return text


func _hash_user_ids(text: String, salt: String) -> String:
	var regex: = RegEx.new()
	var error = regex.compile(Platform.get_user_id())
	if error != OK:
		var msg: = "Failed to compile regex pattern"
		_print_error(msg)
		return msg

	var results: = regex.search_all(text)
	var replaced: Dictionary = {}
	for result in results:
		var user_id: String = result.get_string()
		if not replaced.has(user_id):
			text = text.replace(user_id, _hash_user_id(user_id, salt))
			replaced[user_id] = true

	return text


func _hash_user_id(user_id: String, salt: String) -> String:
	var ctx: = HashingContext.new()
	var _e = ctx.start(HashingContext.HASH_SHA1)
	_e = ctx.update(salt.to_utf8())
	_e = ctx.update(user_id.to_utf8())
	var hash_result: = ctx.finish()
	return hash_result.hex_encode()


func _get_user_agent() -> String:
	var app_name: = _get_application_name()
	var app_version = ProgressData.VERSION
	var godot_version: String = Engine.get_version_info().string
	var os_name: = OS.get_name()
	var platform_type: = _get_platform_type()
	return "%s/%s (Godot Engine v%s; %s, %s)" % [app_name, app_version, godot_version, os_name, platform_type]


func _get_application_name() -> String:
	return ProjectSettings.get_setting("application/config/name").to_lower()


func _get_platform_type() -> String:
	if OS.has_feature("steam"):
		return "steam"
	if OS.has_feature("epic"):
		return "epic"
	return "no-platform"


func _print_error(msg: String) -> void :
	push_error("BugReporter: " + msg)


func _on_CancelButton_pressed() -> void :
	_feedback_input.text = ""
	emit_signal("cancelled")


func _on_DataButton_mouse_exited() -> void :
	_tooltip.visible = false


func _on_DataButton_mouse_entered() -> void :
	_tooltip.visible = true
	_tooltip.text = tr("BUG_REPORT_DATA_MESSAGE")


func _on_DataButton_pressed() -> void :
	var path: = ProjectSettings.globalize_path(ProgressData.SAVE_DIR)
	if path and not path.empty():
		var _error = OS.shell_open(path)


func _on_SendButton_pressed() -> void :
	_set_buttons_disabled(true)
	_send_report()


func _on_HTTPRequest_request_completed(
	_result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray
) -> void :
	_set_buttons_disabled(false)
	var error_msg: = ""
	if response_code != 200:
		error_msg = "Error submitting report (%s)" % response_code
	else:
		var parsed = JSON.parse(body.get_string_from_utf8())
		if parsed.error != OK:
			error_msg = "Error parsing json (%s)" % parsed.error_string
		else:
			var issue_id = parsed.result["prefix"]
			_feedback_input.text = ""
			emit_signal("submitted", issue_id)
			return
	_print_error(error_msg)
	_show_status_label(error_msg)
