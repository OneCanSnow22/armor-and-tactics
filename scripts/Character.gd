extends CharacterBody2D
class_name Character
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var place:Position#位置块
@export var explosion:CPUParticles2D
@export var dead_explosion:AnimatedSprite2D#死亡爆炸特效
@export var sprite:Sprite2D#角色图片
@export var damage_label:RichTextLabel#头顶伤害预览文本
var setting:Profile.Role
var flag:bool
var isAimed:bool#是否被选中
var viscosity:bool=false#角色移动锁定是否跟随
var buffs:Array[Buff] = []#角色持有的buff列表
signal I_is_aimed(character:Character)
signal Show_info(character:Character)
signal Ishitted(character:Character, damage:int)
signal Died(character:Character)
func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)
	dead_explosion.visible=false
	isAimed=false
	var sprite: Sprite2D = $character_shape
	if sprite != null and sprite.material != null:
		sprite.material = sprite.material.duplicate()
	pass
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("click") and flag:
		Show_info.emit(self)
		if !isAimed and setting is not Profile.Player:
			print("选中了"+str(name))
			isAimed=true
			I_is_aimed.emit(self)
	#test_hit()
	pass
func test_hit():
	if Input.is_action_just_pressed("click") and flag:
		ishitted(23)
func _on_viewport_resized() -> void:
	if place!=null:
		global_position=place.global_position+Vector2(70,-70)
func getIndex()->int:#输出初始位置
	if setting!=null:
		return setting.origin_place
	return -1
func stayGround():#正式确定角色所处位置
	if place!=null:
		print("位置块offset_x为"+str(place.offset_left))
		global_position=place.global_position+Vector2(70,-70)
	else:
		print("位置块是空的")
func ishitted(value:int):
	print("受到伤害")
	# 易伤检查：有易伤buff时伤害 ×1.1
	var fragile: Buff = get_buff("Fragile")
	if fragile != null:
		value = ceili(value * 1.5)
	setting.health -= value
	if setting.health < 0:
		setting.health = 0
	Ishitted.emit(self, value)
	if setting.health <= 0:
		await die()
		return
	var shake_target=$character_shape
	var shake_shader:ShaderMaterial
	if shake_target!=null:
		shake_shader=shake_target.material as ShaderMaterial
		if shake_shader==null:
			return
	Engine.time_scale = 0.5
	if explosion != null:
			explosion.emitting = true
	pop_damage(value)
	var tween=create_tween()
	tween.tween_property(shake_shader,"shader_parameter/hit_effect",1,0.1)
	tween.tween_property(shake_shader, "shader_parameter/hit_effect", 0.0, 0.3)
	tween.tween_callback(func():
		Engine.time_scale = 1.0
	)
	await tween.finished
## 射击判定，返回true=命中，false=未命中
func isShot(value:int,probability:int) -> bool:
	if Profile.last_round_missed:
		# 上回合有失误，本回合 100% 命中
		ishitted(value)
		return true
	var fateNum=Profile.rng.randi_range(0,100)
	if fateNum>=probability:
		pop_miss()
		Profile.miss_times+=1
		Profile.item.miss_time+=1
		return false
	ishitted(value)
	return true
func pop_damage(value:int):
	print("弹出文字: " + str(value))
	var text := preload("res://scenes/Effects/floating_text.tscn").instantiate()
	text.set_value(value)
	text.global_position = global_position + Vector2(0,-70)
	# 加到 Fight_Menu 而非自身，确保与角色在同一 CanvasLayer 下坐标一致
	var fight_menu := get_parent()
	while fight_menu != null and not fight_menu is CanvasLayer:
		fight_menu = fight_menu.get_parent()
	if fight_menu != null:
		fight_menu.add_child(text)
	else:
		add_child(text)
	print("已add_child")
func pop_miss():
	var text := preload("res://scenes/Effects/floating_text.tscn").instantiate()
	text.set_miss()
	text.global_position = global_position + Vector2(0,-70)
	# 加到 Fight_Menu 而非自身，确保与角色在同一 CanvasLayer 下坐标一致
	var fight_menu := get_parent()
	while fight_menu != null and not fight_menu is CanvasLayer:
		fight_menu = fight_menu.get_parent()
	if fight_menu != null:
		fight_menu.add_child(text)
	else:
		add_child(text)
func _on_area_2d_mouse_entered() -> void:
	print("鼠标移动到了"+str(name)+"上")
	flag=true
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	flag=false
	pass # Replace with function body.

## 显示头顶伤害预览文本（BBCode 浮动效果）
func show_damage_preview(value: int) -> void:
	if damage_label == null:
		return
	damage_label.bbcode_enabled = true
	damage_label.visible = true
	damage_label.text = "[center][wave amp=3 freq=2][color=#FF0000][font_size=42]🥊" + str(value) + "[/font_size][/color][/wave][/center]"
## 隐藏头顶伤害预览文本
func hide_damage_preview() -> void:
	if damage_label != null:
		damage_label.visible = false

## 角色死亡：播放爆炸帧动画 → 第4帧隐藏sprite → 动画播完删除自身
func die() -> void:
	set_process(false)
	set_physics_process(false)
	Died.emit(self)
	if dead_explosion != null:
		dead_explosion.visible = true
		dead_explosion.play()
		dead_explosion.frame_changed.connect(_on_dead_frame_changed, CONNECT_ONE_SHOT)
		dead_explosion.animation_finished.connect(_on_dead_animation_finished, CONNECT_ONE_SHOT)
	else:
		queue_free()
signal shoot_or_shell_need_fresh(character:Character)
func _on_dead_frame_changed() -> void:
	# 0-indexed 第3帧 = 显示上的第4帧，此时隐藏角色 sprite
	if dead_explosion != null and dead_explosion.frame >= 3:
		if sprite != null:
			sprite.visible = false
			if place!=null:
				shoot_or_shell_need_fresh.emit(self)
func _on_dead_animation_finished() -> void:
	
	queue_free()
## ============ BUFF 管理 ============
## 给角色添加一个buff，同类已存在则累加层数
func add_buff(buff: Buff) -> void:
	var buff_type: String = buff.get_buff_type()
	for existing_buff in buffs:
		if existing_buff.get_buff_type() == buff_type:
			existing_buff.level += buff.level
			existing_buff.refresh_display()
			return
	buffs.append(buff)
## 根据类型名移除指定buff
func remove_buff_by_type(buff_type: String) -> void:
	for i in range(buffs.size() - 1, -1, -1):
		if buffs[i].get_buff_type() == buff_type:
			buffs.remove_at(i)
			return
## 查找指定类型的buff，不存在返回null
func get_buff(buff_type: String) -> Buff:
	for b in buffs:
		if b.get_buff_type() == buff_type:
			return b
	return null
## 回合开始时调用，临时型buff层数-1，归0自动移除
## 返回是否有buff被移除（用于判断是否需要刷新UI）
func tick_buffs() -> bool:
	var changed: bool = false
	for i in range(buffs.size() - 1, -1, -1):
		if not buffs[i].is_permanent:
			if not buffs[i].on_turn_start():
				buffs.remove_at(i)
				changed = true
	return changed
## 战斗结束时清除所有临时型buff
func clear_temp_buffs() -> void:
	for i in range(buffs.size() - 1, -1, -1):
		if not buffs[i].is_permanent:
			buffs.remove_at(i)
## 检查常驻型buff是否满足移除条件
func check_permanent_buffs() -> void:
	for i in range(buffs.size() - 1, -1, -1):
		if buffs[i].is_permanent:
			var perm: Buff = buffs[i] as Buff
			if perm.check_removal():
				buffs.remove_at(i)
