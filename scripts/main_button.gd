extends PanelContainer
@export var space:Control
@export var button_text:Label
@export var title:String
@export var button:TextureButton
@export var switch:bool
signal button_is_pressed()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	space.custom_minimum_size.x=0
	button_text.text=title
	if switch:
		apply_button()
	else:
		_disable_button()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_mouse_entered() -> void:
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(1, 1, 1)
	add_theme_stylebox_override("panel", style)
	button_text.add_theme_color_override("font_color",Color(1, 1, 1))
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(space,"custom_minimum_size",Vector2(40,0),0.2)
	
	pass # Replace with function body.


func _on_texture_button_mouse_exited() -> void:
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(0.65, 0.88, 0.18, 1)
	add_theme_stylebox_override("panel", style)
	button_text.add_theme_color_override("font_color",Color(0.65, 0.88, 0.18, 1))
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(space,"custom_minimum_size",Vector2(0,0),0.2)
	pass # Replace with function body.


func _on_texture_button_pressed() -> void:
	button_is_pressed.emit()
	pass # Replace with function body.
func _disable_button():
	button.visible=false
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(0.188, 0.188, 0.188, 1.0)
	add_theme_stylebox_override("panel", style)
	button_text.add_theme_color_override("font_color",Color(0.188, 0.188, 0.188, 1.0))
func apply_button():
	button.visible=true
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = Color(0.65, 0.88, 0.18, 1)
	add_theme_stylebox_override("panel", style)
	button_text.add_theme_color_override("font_color",Color(0.65, 0.88, 0.18, 1))
