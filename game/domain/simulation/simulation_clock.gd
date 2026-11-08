class_name SimulationClock
extends RefCounted
## Deterministic simulation clock. Time is stored as integer in-game minutes.

const MINUTES_PER_HOUR: int = 60
const MINUTES_PER_DAY: int = 1440
const MAX_MINUTE: int = 2147483647

var current_minute: int = 0


func _init(start_minute: int = 0) -> void:
	current_minute = maxi(start_minute, 0)


## Advances the clock by a non-negative number of minutes.
## Returns false without mutation when the request is invalid or would overflow.
func advance_time(minutes: int) -> bool:
	if minutes < 0 or current_minute > MAX_MINUTE - minutes:
		return false
	current_minute += minutes
	return true


func format_time() -> String:
	var day_number: int = int(current_minute / MINUTES_PER_DAY) + 1
	var minute_of_day: int = current_minute % MINUTES_PER_DAY
	var hour: int = int(minute_of_day / MINUTES_PER_HOUR)
	var minute: int = minute_of_day % MINUTES_PER_HOUR
	return "Day %d · %02d:%02d" % [day_number, hour, minute]
