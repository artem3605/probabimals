extends GutTest

const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")
const PIXEL_FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")


func test_overlay_places_explanation_panel_outside_multi_target_highlights() -> void:
	var root := Control.new()
	root.size = Vector2(2048, 1117)
	add_child_autofree(root)

	var score_panel := ColorRect.new()
	score_panel.position = Vector2(720, 300)
	score_panel.size = Vector2(520, 72)
	root.add_child(score_panel)

	var combo_row := ColorRect.new()
	combo_row.position = Vector2(680, 392)
	combo_row.size = Vector2(620, 92)
	root.add_child(combo_row)

	var combo_dialog := ColorRect.new()
	combo_dialog.position = Vector2(560, 260)
	combo_dialog.size = Vector2(780, 520)
	root.add_child(combo_dialog)

	var overlay := TutorialOverlay.new()
	root.add_child(overlay)
	autoqfree(overlay)
	overlay.size = root.size
	overlay.setup(PIXEL_FONT)
	(
		overlay
		. show_step(
			"HOW COMBOS SCORE",
			"The highlighted row is the combo you match. The score panel shows what you would bank if you ended the turn now.",
			combo_row,
			true,
			"NEXT",
			combo_dialog
		)
	)
	await wait_process_frames(2)

	var highlight_bounds := overlay._get_avoid_bounds()
	var panel_rect := Rect2(overlay._panel.position, overlay._panel.size)

	assert_false(panel_rect.intersects(highlight_bounds))


func test_overlay_can_show_skip_tutorial_button() -> void:
	var root := Control.new()
	root.size = Vector2(960, 540)
	add_child_autofree(root)

	var overlay := TutorialOverlay.new()
	root.add_child(overlay)
	autoqfree(overlay)
	overlay.size = root.size
	overlay.setup(PIXEL_FONT)

	watch_signals(overlay)
	overlay.show_step("WELCOME!", "Intro text.", null, true, "NEXT", null, true, "SKIP TUTORIAL")
	await wait_process_frames(2)

	assert_true(overlay._skip_btn_wrapper.visible)
	assert_eq(overlay._skip_btn.text, "SKIP TUTORIAL")

	overlay._skip_btn.emit_signal("pressed")
	await wait_process_frames(1)

	assert_signal_emitted(overlay, "skip_pressed")

	overlay.show_step("NEXT STEP", "No skip here.", null, true)
	await wait_process_frames(1)

	assert_false(overlay._skip_btn_wrapper.visible)
