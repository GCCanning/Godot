extends CanvasLayer

class_name DayNightCycle

@export var cycle_duration: float = 600.0  # 10 minutes = 1 full day cycle
@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color(0.2, 0.2, 0.3)

var time_elapsed: float = 0.0
var color_rect: ColorRect
var current_hour: int = 6  # Start at 6 AM

signal time_changed(hour: int)
signal night_started
signal day_started

func _ready():
	color_rect = ColorRect.new()
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func _process(delta: float):
	time_elapsed += delta
	if time_elapsed > cycle_duration:
		time_elapsed = 0.0
	
	var cycle_progress = time_elapsed / cycle_duration
	var previous_hour = current_hour
	current_hour = int((6 + cycle_progress * 24) % 24)  # 6 AM to 6 AM next day
	
	if current_hour != previous_hour:
		time_changed.emit(current_hour)
		
		if current_hour == 18:
			night_started.emit()
		elif current_hour == 6:
			day_started.emit()
	
	# Calculate color based on time of day
	var color_factor = abs(sin(cycle_progress * PI))  # 0 at night, 1 at day
	var current_color = night_color.lerp(day_color, color_factor)
	
	color_rect.color = current_color

func get_time_of_day() -> int:
	return current_hour

func is_night() -> bool:
	return current_hour >= 18 or current_hour < 6

func get_time_string() -> String:
	var period = "AM" if current_hour < 12 else "PM"
	var hour = current_hour if current_hour <= 12 else current_hour - 12
	return "%02d:00 %s" % [hour, period]
