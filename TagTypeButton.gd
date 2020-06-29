extends OptionButton


func _init():
	add_item('No Tag Type Selected', -1)
	add_item('Img = "#001"', 1)
	add_item('Img = "[img001]" - Not Presently Functional', 2)
	
	selected = 1
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
