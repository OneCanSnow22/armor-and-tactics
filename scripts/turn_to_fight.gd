extends CanvasLayer
@export var danger_label:Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func becomeDanger():
	visible=true
	danger_label.text="[⚠️DANGER⚠️]"
	danger_label.visible_characters=0
	var speed:float=10
	var duration:float=danger_label.text.length()/speed
	var tween=create_tween()
	tween.tween_property(danger_label,"visible_characters",danger_label.text.length(),duration)
	tween.tween_interval(0.7)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/fight_menu.tscn")
func energy_is_exhausted():
	Profile.item.isAlive=false
	visible=true
	danger_label.text="[☠️MISSING☠️]"
	danger_label.visible_characters=0
	var speed:float=10
	var duration:float=danger_label.text.length()/speed
	var tween=create_tween()
	tween.tween_property(danger_label,"visible_characters",danger_label.text.length(),duration)
	tween.tween_interval(0.7)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/Final_report.tscn")
