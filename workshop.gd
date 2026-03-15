extends Control

# Station references
@onready var forge = $Station1_Forge
@onready var anvil = $Station2_Anvil
@onready var quench = $Station3_Quench

# Anvil components
@onready var hit_zone = $Station2_Anvil/HitZone
@onready var progress_bar = $Station2_Anvil/ShapeProgress
@onready var progress_label = $Station2_Anvil/ProgressLabel

# Hammering state
var hammering_active = false
var shape_progress = 0.0
var hits_required = 10
var successful_hits = 0

# Hit zone positions (relative to anvil center) - adjust these to fit your anvil
var zone_positions = [
	Vector2(60, 75),
	Vector2(160, 75),
	Vector2(260, 75),
	Vector2(110, 100),
	Vector2(210, 100)
]

# Quenching state
var quenching_active = false
var quench_temperature = 0.0
var ideal_quench_temp = 600.0  # Ideal temperature for quenching
var quench_window = 100.0  # +/- range for good quench
var quench_speed = 50.0  # How fast temp drops per second

func _ready() -> void:
	hit_zone.visible = false

func _process(delta):
	# Handle quenching temperature countdown
	if quenching_active:
		quench_temperature -= quench_speed * delta
		if quench_temperature < 20:
			quench_temperature = 20
		
		# Update display
		var quench_label = $Station3_Quench/QuenchLabel
		quench_label.text = "Press SPACE to Quench!\nTemp: " + str(int(quench_temperature)) + "°C"
		
		# Pulse the indicator when near ideal temp
		var indicator = $Station3_Quench/QuenchIndicator
		if indicator:
			var temp_diff = abs(quench_temperature - ideal_quench_temp)
			
			if temp_diff <= quench_window:
				# In the good zone - pulse green
				var pulse = abs(sin(Time.get_ticks_msec() / 200.0))  # Pulse effect
				indicator.color = Color(0.0, 1.0, 0.0, 0.3 + pulse * 0.4)
			else:
				# Outside zone - red
				indicator.color = Color(1.0, 0.0, 0.0, 0.2)

func _input(event):
	# Restart key
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	
	# Quenching input
	if quenching_active and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		perform_quench()
	
	# Hammering input
	if hammering_active and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var zone_rect = hit_zone.get_global_rect()
		
		if zone_rect.has_point(event.position):
			on_successful_hit()
		else:
			# Check if clicked within anvil (miss penalty)
			var anvil_rect = anvil.get_global_rect()
			if anvil_rect.has_point(event.position):
				on_missed_hit()

func start_hammering():
	print("Started hammering!")
	hammering_active = true
	
	# Only reset if this is the first time (progress is 0)
	if shape_progress == 0.0:
		successful_hits = 0
	
	hit_zone.visible = true
	move_hit_zone()
	update_progress_ui()

func stop_hammering():
	hammering_active = false
	hit_zone.visible = false

func on_successful_hit():
	successful_hits += 1
	shape_progress = (float(successful_hits) / float(hits_required)) * 100.0
	
	print("HIT! Progress: ", shape_progress, "%")
	
	# Flash effect on metal bar
	var metal = $Station2_Anvil/MetalBar
	if metal:
		var original_color = metal.color
		metal.color = Color(1.5, 1.5, 1.0)  # Bright flash
		await get_tree().create_timer(0.05).timeout
		metal.color = original_color
	
	# Move hit zone
	move_hit_zone()
	update_progress_ui()
	
	# Check completion
	if shape_progress >= 100:
		on_hammering_complete()

func on_missed_hit():
	print("MISS!")
	
	# Flash red on miss
	var metal = $Station2_Anvil/MetalBar
	if metal:
		var original_color = metal.color
		metal.color = Color(1.0, 0.0, 0.0)  # Red flash
		await get_tree().create_timer(0.1).timeout
		metal.color = original_color

func move_hit_zone():
	var random_pos = zone_positions[randi() % zone_positions.size()]
	hit_zone.position = random_pos

func update_progress_ui():
	progress_bar.value = shape_progress
	progress_label.text = "Progress: " + str(int(shape_progress)) + "%"

func on_hammering_complete():
	print("Hammering complete!")
	stop_hammering()
	progress_label.text = "Complete! Drag to Quench →"

func start_quenching():
	print("Started quenching!")
	quenching_active = true
	
	# Get the metal bar's current temperature
	var metal_bar = get_node_or_null("Station3_Quench/MetalBar")
	if metal_bar:
		quench_temperature = metal_bar.temperature
		print("Metal temperature: ", quench_temperature, "°C")
	else:
		# Fallback if metal bar not found
		quench_temperature = 800.0
	
	# Update quench label to show instructions
	var quench_label = $Station3_Quench/QuenchLabel
	quench_label.text = "Press SPACE to Quench!\nTemp: " + str(int(quench_temperature)) + "°C"

func perform_quench():
	print("QUENCHED at ", quench_temperature, "°C")
	quenching_active = false
	
	# Calculate quality based on how close to ideal temp
	var temp_diff = abs(quench_temperature - ideal_quench_temp)
	var quench_quality = 0.0
	
	if temp_diff <= quench_window:
		# Perfect or good quench
		quench_quality = 100.0 - (temp_diff / quench_window * 30.0)  # 70-100%
		print("EXCELLENT QUENCH! Quality: ", quench_quality, "%")
	else:
		# Poor quench
		quench_quality = max(0, 70.0 - temp_diff)
		print("Poor quench. Quality: ", quench_quality, "%")
	
	# Update label with result
	var quench_label = $Station3_Quench/QuenchLabel
	if quench_quality >= 80:
		quench_label.text = "PERFECT QUENCH!\nQuality: " + str(int(quench_quality)) + "%"
	elif quench_quality >= 60:
		quench_label.text = "Good Quench\nQuality: " + str(int(quench_quality)) + "%"
	else:
		quench_label.text = "Poor Quench\nQuality: " + str(int(quench_quality)) + "%"
	
	# Show final results after 2 seconds
	await get_tree().create_timer(2.0).timeout
	show_final_results(quench_quality)

func show_final_results(quench_quality):
	print("=== CRAFTING COMPLETE ===")
	print("Hammer Progress: ", shape_progress, "%")
	print("Quench Quality: ", quench_quality, "%")
	
	# Calculate overall quality
	var overall_quality = (shape_progress + quench_quality) / 2.0
	
	# Show completion
	var quench_label = $Station3_Quench/QuenchLabel
	quench_label.text = "Item Complete!\nOverall Quality: " + str(int(overall_quality)) + "%\n(Press R to restart)"

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
