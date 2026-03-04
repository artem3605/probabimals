@tool
extends EditorPlugin


func _is_poki_added(cfg: ConfigFile) -> bool:
	for key in cfg.get_sections():
		if cfg.has_section_key(key, "name"):
			var preset_name: String = cfg.get_value(key, "name")
			if preset_name.begins_with("Poki"):
				return true
	return false


func _add_poki_export(cfg: ConfigFile) -> void:
	var num_exports := len(cfg.get_sections()) / 2
	var section := "preset.%d" % num_exports
	var options := section + ".options"

	cfg.set_value(section, "name", "Poki")
	cfg.set_value(section, "platform", "Web")
	cfg.set_value(section, "runnable", false)
	cfg.set_value(section, "custom_features", "")
	cfg.set_value(section, "export_filter", "all_resources")
	cfg.set_value(section, "include_filter", "")
	cfg.set_value(section, "exclude_filter", "")
	cfg.set_value(section, "script_export_mode", 2)

	cfg.set_value(options, "html/custom_html_shell", "res://addons/poki-sdk/poki-shell.html")
	cfg.set_value(options, "html/focus_canvas_on_start", true)
	cfg.set_value(options, "html/experimental_virtual_keyboard", false)


func _enter_tree() -> void:
	var cfg := ConfigFile.new()
	cfg.load("res://export_presets.cfg")

	if _is_poki_added(cfg):
		print("Poki export preset already exists")
	else:
		_add_poki_export(cfg)
		cfg.save("res://export_presets.cfg")

	add_autoload_singleton("PokiSDK", "res://addons/poki-sdk/pokisdk.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("PokiSDK")
