extends ColorRect

# Temperature from 0 (cold) to 1000 (white hot)
var temperature = 20.0
var max_temp = 1000.0

# Is the forge active?
var heating = false

func _ready():
	update_color()

func _process(delta):
	if heating:
		# Heat up when forge is active
		temperature += 100 * delta  # 100 degrees per second
		if temperature > max_temp:
			temperature = max_temp
	else:
		# Cool down naturally
		temperature -= 20 * delta  # Cools slower
		if temperature < 20:
			temperature = 20
	
	update_color()

func update_color():
	# Change color based on temperature
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
	
	# Update the label (ADD THIS PART)
	var label = get_parent().get_node("TemperatureLabel")
	label.text = "Temperature: " + str(int(temperature)) + "°C"
	# Change color based on temperature
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

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Check if clicked on the metal (FIXED VERSION)
		var rect = get_global_rect()
		if rect.has_point(event.position):
			heating = !heating  # Toggle heating
			if heating:
				print("Heating metal... Temperature: ", temperature)
			else:
				print("Stopped heating. Temperature: ", temperature)
