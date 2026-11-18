extends CanvasLayer
@export var page:TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible=true
	page.is_not_on_map=true
	page.shut_screen.connect(back_to_map)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func open_page():
	visible=true
	var battery=randi()%4+3
	Profile.item.add_energy(battery)
	if Profile.item.energy>Profile.max_energy:
		Profile.item.energy=Profile.max_energy
	page.open_page("charger")
	page.start_dialogue([
		">>已获得%d格能量"%battery,
		">>目前可用能量为%d格"%Profile.item.energy,
		">>按'enter'退出"
	])
func back_to_map():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
