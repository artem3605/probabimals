extends Node

## Poki SDK integration via JavaScriptBridge.
## Falls back to no-op stubs when running outside the browser.

signal commercial_break_done
signal rewarded_break_done(success: bool)

var _sdk_handle = null
var _cb_commercial_break: JavaScriptObject = null
var _cb_reward_break: JavaScriptObject = null


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_sdk_handle = JavaScriptBridge.get_interface("PokiSDK")
	if _sdk_handle:
		_cb_commercial_break = JavaScriptBridge.create_callback(_on_commercial_break)
		_cb_reward_break = JavaScriptBridge.create_callback(_on_reward_break)


func commercial_break() -> void:
	if _sdk_handle:
		_sdk_handle.commercialBreak().then(_cb_commercial_break)
	else:
		call_deferred("_emit_commercial_done")


func _emit_commercial_done() -> void:
	commercial_break_done.emit()


func _on_commercial_break(_args: Array) -> void:
	commercial_break_done.emit()


func rewarded_break() -> void:
	if _sdk_handle:
		_sdk_handle.rewardedBreak().then(_cb_reward_break)
	else:
		call_deferred("_emit_rewarded_done")


func _emit_rewarded_done() -> void:
	rewarded_break_done.emit(false)


func _on_reward_break(args: Array) -> void:
	rewarded_break_done.emit(bool(args[0]) if args.size() > 0 else false)


func gameplay_start() -> void:
	if _sdk_handle:
		_sdk_handle.gameplayStart()


func gameplay_stop() -> void:
	if _sdk_handle:
		_sdk_handle.gameplayStop()


func happy_time(intensity: float = 1.0) -> void:
	if _sdk_handle:
		_sdk_handle.happyTime(intensity)
