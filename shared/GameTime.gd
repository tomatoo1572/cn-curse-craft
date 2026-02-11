extends Node

func now_msec() -> int:
	return Time.get_ticks_msec()

func now_sec() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
