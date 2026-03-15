extends ColorRect

# Signals
signal heating_ready()

# Temperature system
var temperature = 20.0
var max_temp = 1000.0
var heating = false
var target_min = 700.0
var target_max = 900.0

# Drag and drop
var dragging = false
var drag_offset = Vector2.ZERO
var mouse_down_pos = Vector2.ZERO
var mouse_down_time = 0.0

# Current station
enum Station { FORGE, ANVIL, QUENCH }
var current_station = Station.FORGE

func _ready():
	update_color()
	z_index = 100  # Always draw on top

func _process(delta):
	# Temperature system - only heat if in forge and heating is active
	if current_station == Station.FORGE and heating:
		temperature += 100 * delta
		if temperature > max_temp:
			temperature = max_temp
	else:
		# Cool down when not heating
		temperature -= 20 * delta
		if temperature < 20:
			temperature = 20
	
	update_color()
	
	# Drag detection - if mouse moves while held, start dragging
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not dragging:
		var current_mouse = get_viewport().get_mouse_position()
		var distance = current_mouse.distance_to(mouse_down_pos)
		
		# If moved more than 15 pixels, start dragging
		if distance > 15:
			var rect = get_global_rect()
			if rect.has_point(mouse_down_pos):  # Check original click was on metal
				dragging = true
				drag_offset = mouse_down_pos - global_position
				heating = false  # Stop heating when dragging
				print("Started dragging metal bar")
	
	# Handle dragging movement
	if dragging:
		global_position = get_viewport().get_mouse_position() - drag_offset

func update_color():
	# Color based on temperature
	if temperature < 200:
		color = Color(0.3, 0.3, 0.3)  # Dark grey (cold)
	elif temperature < 400:
		color = Color(0.5, 0.2, 0.2)  # Dark red
	elif temperature < 600:
		color = Color(0.8, 0.2, 0.2)  # Cherry red
	elif temperature < 800:
		color = Color(1.0, 0.5, 0.0)  # Orange
	elif temperature < 950:
		color = Color(1.0, 0.9, 0.3)  # Yellow
	else:
		color = Color(1.0, 1.0, 0.9)  # White hot
	
	# Update temperature label if in forge
	if current_station == Station.FORGE:
		var forge_station = get_node_or_null("/root/Workshop/Station1_Forge")
		if forge_station:
			var label = forge_station.get_node_or_null("TempLabel")
			if label:
				label.text = "Temperature: " + str(int(temperature)) + "°C"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var rect = get_global_rect()
		
		if event.pressed and rect.has_point(event.position):
			# Mouse down - record position and time
			mouse_down_pos = event.position
			mouse_down_time = Time.get_ticks_msec()
		
		elif not event.pressed:
			if dragging:
				# Release while dragging - drop
				dragging = false
				check_drop_location()
				print("Stopped dragging")
			elif rect.has_point(event.position):
				# Quick click (not dragged)
				var time_held = Time.get_ticks_msec() - mouse_down_time
				var distance_moved = event.position.distance_to(mouse_down_pos)
				
				# If held briefly and didn't move much = click (toggle heat)
				if time_held < 200 and distance_moved < 10:
					if current_station == Station.FORGE:
						heating = !heating
						if heating:
							print("Heating metal... Click again to stop or drag to move.")
						else:
							print("Stopped heating")

func check_drop_location():
	# Get all station nodes
	var workshop = get_node("/root/Workshop")
	if not workshop:
		print("ERROR: Workshop not found!")
		return
	
	var forge = workshop.get_node_or_null("Station1_Forge")
	var anvil = workshop.get_node_or_null("Station2_Anvil")
	var quench = workshop.get_node_or_null("Station3_Quench")
	
	if not forge or not anvil or not quench:
		print("ERROR: Stations not found!")
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Check which station we're over
	if forge.get_global_rect().has_point(mouse_pos):
		snap_to_forge()
	elif anvil.get_global_rect().has_point(mouse_pos):
		snap_to_anvil()
	elif quench.get_global_rect().has_point(mouse_pos):
		snap_to_quench()
	else:
		# Return to current station
		return_to_station()

func snap_to_forge():
	print("Snapped to FORGE")
	current_station = Station.FORGE
	
	# Re-parent to forge
	var forge = get_node("/root/Workshop/Station1_Forge")
	if forge:
		reparent(forge)
		
		# Position: Your actual position
		position = Vector2(20, 110)

func snap_to_anvil():
	print("Snapped to ANVIL")
	current_station = Station.ANVIL
	heating = false  # Stop heating when moved
	
	# Re-parent to anvil
	var anvil = get_node("/root/Workshop/Station2_Anvil")
	if anvil:
		reparent(anvil)
		
		# CENTERED position (station size 400x250, metal ~200x30)
		# Center X: 400/2 = 200, minus half metal width (100) = 100
		# Center Y: 250/2 = 125, minus half metal height (15) = 110
		position = Vector2(70, 110)
		
		# Enable hammering
		var workshop = get_node("/root/Workshop")
		if workshop:
			workshop.start_hammering()

func snap_to_quench():
	print("Snapped to QUENCH")
	current_station = Station.QUENCH
	heating = false
	
	# Re-parent to quench
	var quench = get_node("/root/Workshop/Station3_Quench")
	if quench:
		reparent(quench)
		
		# CENTERED position (station size 400x250, metal ~200x30)
		# Center X: 400/2 = 200, minus half metal width (100) = 100
		# Center Y: 250/2 = 125, minus half metal height (15) = 110
		position = Vector2(70, 110)
		
		# Start quenching
		var workshop = get_node("/root/Workshop")
		if workshop:
			workshop.start_quenching()

func return_to_station():
	# Return to current station
	if current_station == Station.FORGE:
		snap_to_forge()
	elif current_station == Station.ANVIL:
		snap_to_anvil()
	elif current_station == Station.QUENCH:
		snap_to_quench()
