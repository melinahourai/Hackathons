extends Node

# --- UI Node References ---

@onready var customer_img: TextureRect = $CustomerSection/CustomerCard/CustomerImage
@onready var customer_info: Label = $CustomerSection/CustomerCard/CustomerInfo
@onready var message_box: Label = $Control/MessageBox
@onready var scan_button: Button = $Control/ScanButton # Path updated here

@export var pause_menu_scene: PackedScene
var pause_menu_instance: CanvasLayer

var dish_buttons: Array[TextureButton] = []

# --- Game Data ---
var customers = [
	{
		"image": "res://Sprites/boy_customer.png", 
		"preferences": ["This customer is vegetarian.", "They like sandwiches."],
		"correct_dish_index": 0
	},
	{
		"image": "res://Sprites/girl_customer.png",
		"preferences": ["They want something sweet.", "They're a breakfast person."],
		"correct_dish_index": 3
	},
	{
		"image": "res://Sprites/boy_customer1.png", # Reusing this image
		"preferences": ["They want protein,", "but no carbs."],
		"correct_dish_index": 5
	},
	{
		"image": "res://girl_customer1.png",
		"preferences": ["They want something with meat.", "Something easy to take on the go."],
		"correct_dish_index": 4
	},
	{
		"image": "res://Sprites/girl_customer.png",
		"preferences": ["This customer likes bananas!", "They want something sweet and simple."],
		"correct_dish_index": 1
	},
	{
		"image": "res://Sprites/boy_customer1.png",
		"preferences": ["They are a student and in a hurry.", "They want a quick sweet snack."],
		"correct_dish_index": 2
	}
]

var dishes = [
	{"name": "Cheese Sandwich", "tags": ["cheese", "bread", "vegetarian"], "image": "res://Sprites/Dish/Cheese_Sandwich.png"},
	{"name": "Banana Bread", "tags": ["banana", "bread", "sweet"], "image": "res://Sprites/Dish/Banana_Bread.png"},
	{"name": "Muffin", "tags": ["sweet", "muffin"], "image": "res://Sprites/Dish/Quiche.png"},
	{"name": "Pancakes", "tags": ["sweet", "breakfast"], "image": "res://Sprites/Dish/Pancakes.png"},
	{"name": "Salami Sandwich", "tags": ["salami", "meat", "bread"], "image": "res://Sprites/Dish/Salami_Sandwich.png"},
	{"name": "Egg", "tags": ["egg"], "image": "res://Sprites/Dish/Sunny_Side_Up_Egg.png"}
]

var current_customer = null

# --- Main Game Loop ---
func _ready():
	
	var button_grid = $Control/ButtonGrid
	if button_grid:
		for child in button_grid.get_children():
			if child is TextureButton:
				dish_buttons.append(child)
				child.connect("pressed", Callable(self, "_on_option_pressed").bind(dish_buttons.size() - 1))
	
	_show_next_customer()

	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance) 	
	pause_menu_instance.hide()


func _show_next_customer():
	# Pick a random customer from the list
	var random_index = randi() % customers.size()
	current_customer = customers[random_index]

	# Update UI elements with the new customer's info
	customer_img.texture = load(current_customer.image) if load(current_customer.image) else null
	customer_info.text = "" # Clear previous scan info

	# Enable the scan button and hide the food options
	scan_button.show()
	scan_button.disabled = false
	scan_button.text = "SCAN CUSTOMER"
	if not dish_buttons.is_empty():
		for button in dish_buttons:
			button.hide()
			button.disabled = true
			

	message_box.text = "Ready for the next customer! Scan them to begin."
	
# --- Player Actions ---

func _on_scan_button_pressed():
	# The player has pressed the scan button
	scan_button.disabled = true
	scan_button.text = "SCANNING CUSTOMER..."
	message_box.text = ""  # This line clears the message box after scanning starts

	# Use a timer to simulate a scanning process before revealing info
	await get_tree().create_timer(1.0).timeout
	
	customer_info.text = "Scan results: " + " ".join(current_customer.preferences)
	scan_button.hide()
	
	
	# Show the dish options and enable them
	# We use a shuffled array of dishes for the player to choose from
	var shuffled_dishes = dishes.duplicate()
	shuffled_dishes.shuffle()
	
	var correct_dish = dishes[current_customer.correct_dish_index]
	var option_dishes = []
	
	# Ensure the correct dish is in the list of options
	option_dishes.append(correct_dish)
	
	# Add two random incorrect dishes to the options
	for dish in shuffled_dishes:
		if option_dishes.size() < 3 and dish != correct_dish:
			option_dishes.append(dish)

	option_dishes.shuffle()
	
	if not dish_buttons.is_empty():
		for i in range(dish_buttons.size()):
			# Set the button's texture to the dish image
			dish_buttons[i].texture_normal = load(option_dishes[i]["image"])
			dish_buttons[i].show()
			dish_buttons[i].disabled = false
	else:
		print("Error: Dish buttons array is empty.")

func _on_option_pressed(index: int):
	# The player has chosen a dish
	if not dish_buttons.is_empty():
		for button in dish_buttons:
			button.disabled = true
	else:
		print("Error: Dish buttons array is empty.")
	
	var message = ""
	
	# Find the selected dish based on its texture
	var selected_dish_texture = dish_buttons[index].texture_normal
	var correct_dish_texture = load(dishes[current_customer.correct_dish_index]["image"])
	
	if selected_dish_texture == correct_dish_texture:
		message = "Correct! Prepare for the next customer."
		
	else:
		message = "Incorrect. That's not what they wanted. Try again on the next round."
		
		
	message_box.text = message
	customer_info.text = ""
	
	# Wait a moment before showing the next customer
	await get_tree().create_timer(3.0).timeout
	_show_next_customer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		pause_menu_instance.hide()
	else:
		get_tree().paused = true
		pause_menu_instance.show()
