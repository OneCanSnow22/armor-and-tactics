extends CanvasLayer
@export var out_page:TextureButton
@export var report_page:PanelContainer
@export var context:Label
@export var title:Label
func page_out():
	out_page.position=Vector2(129,-500)
	var tween=create_tween()
	tween.tween_property(out_page,"position",Vector2(129,0),1)
	await tween.finished
	out_page.disabled=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	report_page.visible=false
	out_page.disabled=true
	page_out()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_mouse_entered() -> void:
	if out_page.disabled==false:
		out_page.scale=Vector2(0.45,0.45)
	pass # Replace with function body.


func _on_texture_button_mouse_exited() -> void:
	if out_page.disabled==false:
		out_page.scale=Vector2(0.4,0.4)
	pass # Replace with function body.


func _on_texture_button_pressed() -> void:
	var start_pos:Vector2 = out_page.position
	var target_pos:Vector2 = Vector2(129, 240)
	var tween = create_tween()
	# 1. 蓄力：先向上微抬（蓄力感）
	tween.tween_property(out_page, "position", start_pos + Vector2(0, -18), 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 2. 猛冲：快速砸向目标下方（超冲20px，力量感）
	tween.tween_property(out_page, "position", target_pos + Vector2(0, 20), 0.12)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	# 3. 回弹：弹回目标位置
	tween.tween_property(out_page, "position", target_pos - Vector2(0, 8), 0.08)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 4. 稳住
	tween.tween_property(out_page, "position", target_pos, 0.06)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	report_page.visible = true
	if Profile.item.isAlive:
		open_victory_page()
	else:
		open_death_page()
func show_text():
	context.text=""
	if Profile.item.enemy_kill>0:
		context.text+="击杀敌人：%d\n"%Profile.item.enemy_kill
	if Profile.item.move_step>0:
		context.text+="移动步数：%d\n"%Profile.item.move_step
	if Profile.item.attack_times>0:
		context.text+="攻击次数：%d\n"%Profile.item.attack_times
	if Profile.item.miss_time>0:
		context.text+="失误次数：%d\n"%Profile.item.miss_time
	context.text+="游戏时长："+Profile.time.get_time()
func open_death_page():
	title.text="Death_report"
	title.add_theme_color_override("font_color",Color(225,0,0))
	show_text()
func open_victory_page():
	title.text="Mission_compeleted"
	title.add_theme_color_override("font_color",Color(0,120,0))
	show_text()


func _on_button_pressed() -> void:
	DirAccess.remove_absolute("user://savadata/save.tres")
	get_tree().change_scene_to_file("res://scenes/Start.tscn")
