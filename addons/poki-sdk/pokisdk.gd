extends Node

## Stub for the Poki SDK.
## Provides the same API surface so the game runs outside poki.com.
## Replace with the real plugin when deploying to Poki.

signal commercial_break_done
signal rewarded_break_done(success: bool)

func commercial_break() -> void:
	call_deferred("_emit_commercial_done")

func _emit_commercial_done() -> void:
	commercial_break_done.emit()

func rewarded_break() -> void:
	call_deferred("_emit_rewarded_done")

func _emit_rewarded_done() -> void:
	rewarded_break_done.emit(false)

func gameplay_start() -> void:
	pass

func gameplay_stop() -> void:
	pass

func happy_time(_intensity: float = 1.0) -> void:
	pass
