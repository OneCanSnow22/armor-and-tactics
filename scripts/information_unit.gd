extends PanelContainer
class_name Function_detail
@export var picture:TextureRect
@export var title:Label
@export var context:Label
@export var selected:TextureButton
signal sent_mode(value:function)
var mode:function
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selected.visible=false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
func show_unit(fu:function):
	if fu!=null:
		mode=fu
		fu.display()
		picture.texture=fu.texture
		title.text=fu.title
		context.text=fu.get_context()
	else:
		picture.texture=load("res://assets/cards/blank.png")
		title.text="N/A"
		context.text="无内容"


func _on_texture_button_pressed() -> void:
	sent_mode.emit(mode)
	pass # Replace with function body.
