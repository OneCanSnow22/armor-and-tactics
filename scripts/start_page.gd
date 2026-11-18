extends CanvasLayer
const ORIGINAL = "ARMOR_AND_TACTICES"
@export var title:RichTextLabel
@export var load_button:PanelContainer
var glitch_timer: float = 0.0
var glitch_interval: float =0.2 # 每 0.05 秒换一次，越小越快
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if FileAccess.file_exists("user://savadata/save.tres"):
		load_button.apply_button()
	else:
		load_button._disable_button()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	glitch_timer += delta
	if glitch_timer >= glitch_interval:
		glitch_timer = 0.0
		_update_glitch()
	pass
func _update_glitch() -> void:
	# 把非下划线的字母单独提取出来
	var letters = []
	for ch in ORIGINAL:
		if ch != "_":
			letters.append(ch)
	# 打乱这些字母
	letters.shuffle()
	# 重新填回去，下划线位置不动
	var result = ""
	var idx = 0
	for ch in ORIGINAL:
		if ch == "_":
			result += "_"
		else:
			result += letters[idx]
			idx += 1
	title.text = result


func _on_start_new_button_is_pressed() -> void:
	Profile.start_new()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.


func _on_quit_game_button_is_pressed() -> void:
	if Profile.item!=null and Profile.player!=null:
		var saveData=SaveData.new()
		await saveData.save_data()
	get_tree().quit()
	pass # Replace with function body.


func _on_load_old_button_is_pressed() -> void:
	Profile.load_data()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.
