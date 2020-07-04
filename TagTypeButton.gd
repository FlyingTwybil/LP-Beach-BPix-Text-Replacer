extends OptionButton

var tagtype_extraidentifier : Control

func _init():
	add_item('No Tag Type Selected', -1)
	add_item('1. Img = "#001"', 1)
	add_item('2. Img = "[img001]" - Not Implemented', 2)
	add_item('3. Img = "[Filename]" - Bracket Style', 3)
	selected = 1
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_OptionButton_item_selected(id):

	pass # Replace with function body.
