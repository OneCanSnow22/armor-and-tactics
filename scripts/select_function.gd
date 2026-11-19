extends Control
class_name Selected_function
@export var measure:function
@export var button:TextureButton
@export var locked:TextureRect
signal is_this_function(value:Selected_function)
signal is_back(value:function)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.disabled=true
	locked.visible=false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _set_function(value:function):
	button.disabled=false
	if value==null:
		measure.texture=load("res://assets/cards/blank.png")
		measure.id=0
		measure.mode=Profile.Function.Blank
		measure.point=0
		button.disabled=true
		return
	# 不替换measure引用（它会脱离场景树），而是更新现有子节点的属性
	if value is Card.Blank:
		measure.texture=load("res://assets/cards/blank.png")
		measure.id=value.id
		measure.mode=Profile.Function.Blank
		measure.point=value.point
		button.disabled=false
		return
	measure.texture=value.texture
	measure.id=value.id
	measure.mode=value.mode
	measure.point=value.point
	measure.context=value.context
	measure.title=value.title
	measure.animation_unit=value.animation_unit
	button.disabled=true

func _on_texture_button_pressed() -> void:
	if measure.mode==Profile.Function.Blank:
		is_this_function.emit(self)
	else:
		is_back.emit(measure)
	pass # Replace with function body.
