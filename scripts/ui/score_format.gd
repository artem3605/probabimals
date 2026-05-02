class_name ScoreFormat
extends RefCounted

const INTEGER_EPSILON := 0.001


static func multiplier(value: float) -> String:
	var rounded := roundf(value)
	if absf(value - rounded) <= INTEGER_EPSILON:
		return str(int(rounded))
	return "%.1f" % value


static func prefixed_multiplier(value: float) -> String:
	return "x%s" % multiplier(value)
