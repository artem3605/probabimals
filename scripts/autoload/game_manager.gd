extends Node

const RunState := preload("res://scripts/map/run_state.gd")
const MapGeneratorRef := preload("res://scripts/map/map_generator.gd")
const MapNodeRef := preload("res://scripts/map/map_node.gd")
const RunOutcomeResolverRef := preload("res://scripts/run/run_outcome_resolver.gd")
const SaveDataCodecRef := preload("res://scripts/save/save_data_codec.gd")
const ShopPurchaseResolverRef := preload("res://scripts/shop/shop_purchase_resolver.gd")

enum Phase { MAIN_MENU, FLEA_MARKET, DICE_SELECT, COMBAT, MAP }

const SAVE_PATH := "user://save_game.json"
const APP_VERSION_SETTING := "application/config/version"
const DEFAULT_APP_VERSION := "v0.0.0"
const SAVE_FORMAT_VERSION := SaveDataCodecRef.SAVE_FORMAT_VERSION
const PLAYTEST_SURVEY_URL_SETTING := "playtest/survey_url"
const STARTING_COINS: int = 10

signal phase_changed(new_phase: Phase)
signal coins_changed(new_amount: int)
signal score_changed(new_score: int)

var current_phase: Phase = Phase.MAIN_MENU
var coins: int = STARTING_COINS
var dice_bag: DiceBag = DiceBag.new()
var modifiers: Array[Modifier] = []
var total_score: int = 0
var target_score: int = 150
var hands_per_round: int = 4
var rerolls_per_hand: int = 3
var selected_dice: Array[Die] = []
var current_round: int = 1
var current_run: RunState = null
var last_run_result: Dictionary = {}
const BASE_TARGET: int = 150
var save_path: String = SAVE_PATH
var _last_tutorial_completed: bool = false
var _last_tutorial_active: bool = false
var _run_outcome_resolver := RunOutcomeResolverRef.new()
var _save_data_codec := SaveDataCodecRef.new()
var _shop_purchase_resolver := ShopPurchaseResolverRef.new()


func _ready() -> void:
	_sync_tutorial_tracking()
	if not TutorialManager.state_changed.is_connected(_on_tutorial_state_changed):
		TutorialManager.state_changed.connect(_on_tutorial_state_changed)


func start_game(skip_tutorial_intro: bool = false) -> void:
	delete_save()
	_reset_run_state()
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
	if skip_tutorial_intro:
		TutorialManager.clear_active_tutorial()
	elif TutorialManager.should_auto_start_on_new_game():
		TutorialManager.start_first_run()
	else:
		TutorialManager.clear_active_tutorial()

	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()

	if TutorialManager.is_active() and TutorialManager.is_intro_step():
		_setup_intro_combat()
		_change_phase(Phase.COMBAT)
	else:
		_change_phase(Phase.MAP)


func start_tutorial_replay() -> void:
	delete_save()
	_reset_run_state()
	current_run = null
	last_run_result = {}
	TutorialManager.start_replay()
	_setup_intro_combat()
	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()
	_change_phase(Phase.COMBAT)


func skip_active_tutorial() -> void:
	if not TutorialManager.is_active():
		return
	_reset_run_state()
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
	TutorialManager.complete_tutorial()
	_change_phase(Phase.MAP)


func _setup_intro_combat() -> void:
	current_round = 0
	target_score = 60
	coins = 25
	selected_dice.clear()
	for die in dice_bag.get_all():
		selected_dice.append(die)


func _reset_run_state() -> void:
	clear_resolved_combat_result()
	coins = STARTING_COINS
	total_score = 0
	current_round = 1
	target_score = BASE_TARGET
	hands_per_round = 4
	rerolls_per_hand = 3
	modifiers.clear()
	dice_bag = DiceBag.new()
	for i in range(5):
		dice_bag.add_die(Die.new())
	selected_dice.clear()


func buy_item(item: Dictionary) -> bool:
	var result := _shop_purchase_resolver.purchase_item(self, item)
	if result.get("coins_changed", false):
		coins_changed.emit(coins)
	return result.get("success", false)


func buy_face_swap(die_index: int, face_index: int, new_face: DiceFace, cost: int) -> bool:
	var result := _shop_purchase_resolver.purchase_face_swap(self, die_index, face_index, new_face, cost)
	if result.get("coins_changed", false):
		coins_changed.emit(coins)
	return result.get("success", false)


func swap_face(die_index: int, face_index: int, new_face: DiceFace) -> void:
	_shop_purchase_resolver.swap_face(self, die_index, face_index, new_face)


func go_to_combat() -> void:
	_change_phase(Phase.COMBAT)


func go_to_flea_market() -> void:
	_change_phase(Phase.FLEA_MARKET)


func go_to_main_menu() -> void:
	_change_phase(Phase.MAIN_MENU)


func go_to_dice_select() -> void:
	_change_phase(Phase.DICE_SELECT)


func flea_market_continue() -> void:
	if current_run == null:
		_change_phase(Phase.DICE_SELECT)
		return
	var node: MapNodeRef = current_run.get_current_node()
	if node == null:
		push_warning("Unexpected Flea Market continue before selecting a map node.")
		_change_phase(Phase.MAP)
		return
	if node.type == MapNodeRef.NodeType.SHOP:
		complete_current_node()
		return
	push_warning("Unexpected Flea Market continue from non-shop map node %d." % node.id)
	_change_phase(Phase.MAP)


func end_combat(final_score: int, target_beaten: bool) -> void:
	PokiSDK.gameplay_stop()
	var result := _run_outcome_resolver.resolve_combat_result(self, TutorialManager, final_score, target_beaten)
	_apply_result_events(result)
	_apply_result_save_action(result)
	var destination := int(result.get("phase", Phase.MAIN_MENU))
	_change_phase(destination as Phase)


func resolve_combat_result_for_overlay(final_score: int, target_beaten: bool) -> Phase:
	var result := _run_outcome_resolver.resolve_combat_result_for_overlay(
		self, TutorialManager, final_score, target_beaten
	)
	if not bool(result.get("already_resolved", false)):
		PokiSDK.gameplay_stop()
	_apply_result_events(result)
	_apply_result_save_action(result)
	return int(result.get("phase", Phase.MAIN_MENU)) as Phase


func finish_resolved_combat_result() -> void:
	var destination := _run_outcome_resolver.finish_resolved_combat_result()
	if destination < 0:
		return
	_change_phase(destination as Phase)


func has_resolved_combat_result() -> bool:
	return _run_outcome_resolver.has_resolved_combat_result()


func clear_resolved_combat_result() -> void:
	_run_outcome_resolver.clear_resolved_combat_result()


func advance_round() -> void:
	var result := _run_outcome_resolver.advance_round(self)
	_apply_result_events(result)
	_apply_result_save_action(result)
	var destination := int(result.get("phase", Phase.FLEA_MARKET))
	_change_phase(destination as Phase)


func complete_current_node() -> void:
	var result := _run_outcome_resolver.complete_current_node(self)
	_apply_result_events(result)
	_apply_result_save_action(result)
	var destination := int(result.get("phase", -1))
	if destination >= 0:
		_change_phase(destination as Phase)


func enter_map_node(node_id: int) -> void:
	if current_run == null:
		push_warning("Cannot enter a map node without an active run.")
		return
	var available := current_run.available_node_ids()
	if not available.has(node_id):
		push_warning("Cannot enter unavailable map node %d." % node_id)
		return
	current_run.enter_node(node_id)
	var node: MapNodeRef = current_run.nodes[node_id]
	if node.type == MapNodeRef.NodeType.BOSS:
		var boss_multiplier := float(DataManager.get_map_config().get("boss_blind_multiplier", 1.5))
		target_score = int(floor(float(target_score) * boss_multiplier))
	match node.type:
		MapNodeRef.NodeType.COMBAT, MapNodeRef.NodeType.BOSS:
			_change_phase(Phase.DICE_SELECT)
		MapNodeRef.NodeType.SHOP:
			_change_phase(Phase.FLEA_MARKET)


func end_run(victory: bool) -> void:
	var result := _run_outcome_resolver.end_run(self, victory)
	_apply_result_events(result)
	_apply_result_save_action(result)
	_change_phase(Phase.MAIN_MENU)


func abandon_run() -> void:
	clear_resolved_combat_result()
	current_run = null
	last_run_result = {}
	delete_save()


func get_round_reward() -> int:
	return 10 + 5 * current_round


func _apply_result_save_action(result: Dictionary) -> void:
	match str(result.get("save_action", RunOutcomeResolverRef.SAVE_ACTION_NONE)):
		RunOutcomeResolverRef.SAVE_ACTION_SAVE:
			save_game()
		RunOutcomeResolverRef.SAVE_ACTION_DELETE:
			delete_save()


func _apply_result_events(result: Dictionary) -> void:
	var events: Variant = result.get("events", {})
	if not (events is Dictionary):
		return
	var event_dict: Dictionary = events
	if event_dict.has("score_changed"):
		score_changed.emit(int(event_dict["score_changed"]))
	if event_dict.has("coins_changed"):
		coins_changed.emit(int(event_dict["coins_changed"]))


func get_app_version() -> String:
	var version := str(ProjectSettings.get_setting(APP_VERSION_SETTING, DEFAULT_APP_VERSION))
	if version.is_empty():
		return DEFAULT_APP_VERSION
	return version


func get_playtest_survey_url() -> String:
	return str(ProjectSettings.get_setting(PLAYTEST_SURVEY_URL_SETTING, "")).strip_edges()


func has_playtest_survey_url() -> bool:
	return not get_playtest_survey_url().is_empty()


func open_playtest_survey() -> bool:
	var url := get_playtest_survey_url()
	if url.is_empty():
		return false
	return OS.shell_open(url) == OK


func _change_phase(new_phase: Phase) -> void:
	var old_phase := current_phase
	current_phase = new_phase
	phase_changed.emit(new_phase)
	if new_phase != Phase.MAIN_MENU:
		save_game()
	clear_resolved_combat_result()

	if new_phase == Phase.MAIN_MENU and old_phase != Phase.MAIN_MENU:
		AudioManager.pause_for_ad()
		PokiSDK.commercial_break()
		await PokiSDK.commercial_break_done
		AudioManager.resume_after_ad()

	match new_phase:
		Phase.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		Phase.FLEA_MARKET:
			get_tree().change_scene_to_file("res://scenes/flea_market/flea_market_screen.tscn")
			PokiSDK.gameplay_start()
		Phase.DICE_SELECT:
			get_tree().change_scene_to_file("res://scenes/dice_select/dice_select_screen.tscn")
		Phase.COMBAT:
			get_tree().change_scene_to_file("res://scenes/combat/combat_screen.tscn")
			PokiSDK.gameplay_start()
		Phase.MAP:
			get_tree().change_scene_to_file("res://scenes/map/map_screen.tscn")


# -- Save / Load ---------------------------------------------------------------


func has_save(path_override: String = "") -> bool:
	return FileAccess.file_exists(_resolve_save_path(path_override))


func can_load_save(path_override: String = "") -> bool:
	return not _save_data_codec.normalize_save_data(_read_save_data(path_override), get_app_version()).is_empty()


func build_save_data() -> Dictionary:
	return _save_data_codec.build_save_data(
		self, TutorialManager, get_app_version(), _run_outcome_resolver.get_pending_combat_result_phase()
	)


func apply_save_data(data: Dictionary) -> Phase:
	var restored_phase := _save_data_codec.apply_save_data(
		self, TutorialManager, data, current_phase, get_app_version()
	)
	return restored_phase as Phase


func save_game(path_override: String = "") -> void:
	var file := FileAccess.open(_resolve_save_path(path_override), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(build_save_data()))


func load_game(path_override: String = "") -> void:
	var data := _read_save_data(path_override)
	var normalized := _save_data_codec.normalize_save_data(data, get_app_version())
	if normalized.is_empty():
		return
	var phase_to_load := _save_data_codec.apply_normalized_save_data(self, TutorialManager, normalized)

	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()

	_change_phase(phase_to_load as Phase)


func delete_save(path_override: String = "") -> void:
	var resolved_path := _resolve_save_path(path_override)
	if FileAccess.file_exists(resolved_path):
		DirAccess.remove_absolute(resolved_path)


func _resolve_save_path(path_override: String) -> String:
	if not path_override.is_empty():
		return path_override
	return save_path


func _on_tutorial_state_changed() -> void:
	var just_completed := TutorialManager.completed and not _last_tutorial_completed
	var just_cleared_active := _last_tutorial_active and not TutorialManager.is_active()
	if current_phase != Phase.MAIN_MENU and just_completed:
		_ensure_post_tutorial_run()
	_sync_tutorial_tracking()
	if current_phase != Phase.MAIN_MENU and (just_completed or just_cleared_active):
		save_game()


func _ensure_post_tutorial_run() -> void:
	if current_run != null:
		return
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}


func _sync_tutorial_tracking() -> void:
	_last_tutorial_completed = TutorialManager.completed
	_last_tutorial_active = TutorialManager.is_active()


func _read_save_data(path_override: String = "") -> Dictionary:
	var file := FileAccess.open(_resolve_save_path(path_override), FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var raw: Variant = json.data
	if raw is Dictionary:
		return raw.duplicate(true)
	return {}
