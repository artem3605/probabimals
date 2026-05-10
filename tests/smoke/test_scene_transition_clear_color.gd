extends GutTest

const PixelBg = preload("res://scripts/ui/pixel_bg.gd")
const DEFAULT_CLEAR_COLOR_SETTING := "rendering/environment/defaults/default_clear_color"


func test_viewport_clear_color_matches_screen_background() -> void:
	assert_true(ProjectSettings.has_setting(DEFAULT_CLEAR_COLOR_SETTING))
	var clear_color: Color = ProjectSettings.get_setting(DEFAULT_CLEAR_COLOR_SETTING)
	assert_true(clear_color.is_equal_approx(PixelBg.BG_COLOR))
