class_name RunOutcomeResolver
extends RefCounted

const MapNodeRef := preload("res://scripts/map/map_node.gd")

const SAVE_ACTION_NONE := "none"
const SAVE_ACTION_SAVE := "save"
const SAVE_ACTION_DELETE := "delete"

var _pending_combat_result_phase: int = -1


func resolve_combat_result(manager, tutorial_manager, final_score: int, target_beaten: bool) -> Dictionary:
	manager.total_score = final_score
	var events := {"score_changed": manager.total_score}

	if tutorial_manager.is_active() and tutorial_manager.is_intro_step():
		if target_beaten:
			events.merge(_apply_round_advance(manager), true)
			return _outcome(manager.Phase.FLEA_MARKET, SAVE_ACTION_NONE, false, events)
		return _outcome(manager.Phase.MAIN_MENU, SAVE_ACTION_NONE, false, events)

	if manager.current_run != null:
		if manager.current_run.current_node_id == -1:
			if target_beaten:
				return _outcome(manager.Phase.MAP, SAVE_ACTION_NONE, false, events)
			return _with_events(_end_run(manager, false), events)
		if target_beaten:
			return _with_events(complete_current_node(manager), events)
		return _with_events(_end_run(manager, false), events)

	if target_beaten:
		events.merge(_apply_round_advance(manager), true)
		return _outcome(manager.Phase.FLEA_MARKET, SAVE_ACTION_NONE, false, events)
	return _outcome(manager.Phase.MAIN_MENU, SAVE_ACTION_NONE, false, events)


func resolve_combat_result_for_overlay(manager, tutorial_manager, final_score: int, target_beaten: bool) -> Dictionary:
	if _pending_combat_result_phase >= 0:
		return _outcome(_pending_combat_result_phase, SAVE_ACTION_NONE, true)

	var result := resolve_combat_result(manager, tutorial_manager, final_score, target_beaten)
	var destination := int(result.get("phase", manager.Phase.MAIN_MENU))
	_pending_combat_result_phase = destination
	var save_action := SAVE_ACTION_DELETE if destination == manager.Phase.MAIN_MENU else SAVE_ACTION_SAVE
	result["save_action"] = save_action
	result["already_resolved"] = false
	return result


func complete_current_node(manager) -> Dictionary:
	if manager.current_run == null:
		push_warning("Cannot complete a map node without an active run.")
		return _outcome(-1)
	var node: MapNodeRef = manager.current_run.get_current_node()
	if node == null:
		push_warning("Cannot complete a map node before one is selected.")
		return _outcome(-1)
	match node.type:
		MapNodeRef.NodeType.COMBAT:
			manager.current_run.complete_current_node()
			return _outcome(manager.Phase.MAP, SAVE_ACTION_NONE, false, _apply_round_advance(manager))
		MapNodeRef.NodeType.SHOP:
			manager.current_run.complete_current_node()
			return _outcome(manager.Phase.MAP)
		MapNodeRef.NodeType.BOSS:
			manager.current_run.complete_current_node()
			var events := _apply_round_reward(manager)
			manager.selected_dice.clear()
			return _with_events(_end_run(manager, true), events)
	return _outcome(-1)


func end_run(manager, victory: bool) -> Dictionary:
	return _end_run(manager, victory)


func advance_round(manager) -> Dictionary:
	return _outcome(manager.Phase.FLEA_MARKET, SAVE_ACTION_NONE, false, _apply_round_advance(manager))


func finish_resolved_combat_result() -> int:
	if _pending_combat_result_phase < 0:
		return -1
	var destination := _pending_combat_result_phase
	_pending_combat_result_phase = -1
	return destination


func has_resolved_combat_result() -> bool:
	return _pending_combat_result_phase >= 0


func clear_resolved_combat_result() -> void:
	_pending_combat_result_phase = -1


func get_pending_combat_result_phase() -> int:
	return _pending_combat_result_phase


func _apply_round_advance(manager) -> Dictionary:
	var events := _apply_round_reward(manager)
	manager.current_round += 1
	manager.target_score = int(floor(manager.BASE_TARGET * pow(1.5, manager.current_round - 1)))
	manager.selected_dice.clear()
	return events


func _apply_round_reward(manager) -> Dictionary:
	manager.coins += manager.get_round_reward()
	return {"coins_changed": manager.coins}


func _end_run(manager, victory: bool) -> Dictionary:
	manager.last_run_result = {
		"victory": victory,
		"round": manager.current_round,
		"total_score": manager.total_score,
		"coins": manager.coins,
	}
	manager.current_run = null
	return _outcome(manager.Phase.MAIN_MENU, SAVE_ACTION_DELETE)


func _with_events(result: Dictionary, events: Dictionary) -> Dictionary:
	if events.is_empty():
		return result
	var merged_events := {}
	var existing_events: Variant = result.get("events", {})
	if existing_events is Dictionary:
		merged_events = existing_events.duplicate()
	merged_events.merge(events, true)
	result["events"] = merged_events
	return result


func _outcome(
	phase: int, save_action: String = SAVE_ACTION_NONE, already_resolved: bool = false, events: Dictionary = {}
) -> Dictionary:
	var result := {
		"phase": phase,
		"save_action": save_action,
		"already_resolved": already_resolved,
	}
	return _with_events(result, events)
