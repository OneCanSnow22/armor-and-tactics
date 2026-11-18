extends HBoxContainer
class_name Speaker
@export var speed:float=15
@export var context:Label
@export var expression:TextureRect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func start(value:String):
	context.text=value
	context.visible_characters=0
	var duration=value.length()/speed
	var tween=create_tween()
	tween.tween_property(context,"visible_characters",value.length(),duration)
	await tween.finished
func set_expression(value:String):
	expression.texture=load(value)
