extends CanvasLayer
@export var page:TextureRect
@export var repair_number:int=30
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible=false
	page.is_not_on_map=true
	page.shut_screen.connect(back_to_map)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func open_page():
	visible=true
	Profile.player.health+=repair_number
	if Profile.player.health>Profile.player.max_health:
		Profile.player.health=Profile.player.max_health
	page.input_field.visible=false
	page.open_page("repair")
	page.start_dialogue([
		">>已恢复%d点生命值"%repair_number,
		">>目前生命值为%d"%Profile.player.health,
		">>按'enter'退出"
	])
func back_to_map():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
