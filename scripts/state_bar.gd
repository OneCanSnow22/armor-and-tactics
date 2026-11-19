extends Control
class_name State_bar
@export var decreaseBar:ColorRect
@export var healthBar:ColorRect
@export var health_label:Label
@export var mode_bar:TextureProgressBar
@export var mode_label:Label
@export var buff_basket:HFlowContainer
@export var Imode:TextureRect
const Max_size:float=873
var max_health:int
var current_health:int
var attack_mode:Attack
var mode_pic:Dictionary
var index:int=1
var current_role:Character
signal characterIsDead(character:Character)#角色死亡信号
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mode_pic={
		0:"res://assets/statebar/melee_mode.png",
		1:"res://assets/statebar/shoot_mode.png",
		2:"res://assets/statebar/shelling.png",
		3:"res://assets/statebar/hot_shelling.png",
		4:"res://assets/statebar/flash_shelling.png",
		5:"res://assets/statebar/flare.png"
	}
	buff_basket=$Buff
	pass # Replace with function body.
func show_information(character:Character):
	if character!=null:
		current_role=character
		if attack_mode!=character.setting.attack_mode:
			change_mode(character.setting.attack_mode)
			print("更改攻击模式")
		fresh_mode(character.setting.attack_mode, character)
		max_health=character.setting.max_health
		current_health=character.setting.health
		var length:float=Max_size*(float(current_health)/float(max_health))
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(healthBar,"size",Vector2(length,43),0.2)
		tween.tween_property(decreaseBar,"size",Vector2(length,43),0.2)
		health_label.text=str(current_health)+"/"+str(max_health)
		refresh_buff_basket(character)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func fresh_mode(mode:Attack, role:Character=null):
	var display_role: Character = role if role != null else current_role
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	if mode is Melee:
		mode_bar.texture_progress=load("res://assets/statebar/bar10.png")
		mode_bar.max_value=mode.max_range
		mode_label.text="目前攻击距离为"+str(mode.range)+"单位"
		tween.tween_property(mode_bar,"value",mode.range,0.2)
		await tween.finished
	elif mode is Shoot:
		mode_bar.texture_progress=load("res://assets/statebar/bar11.png")
		mode_bar.max_value=mode.max_probability
		mode_label.text="目前命中率为"+str(mode.probability)+"%"
		tween.tween_property(mode_bar,"value",mode.probability,0.2)
		await tween.finished
	elif mode is Shelling:
		mode_bar.texture_progress=load("res://assets/statebar/bar12.png")
		mode_bar.max_value=mode.max_time
		refresh_shelling_mode_label(display_role)
		tween.tween_property(mode_bar,"value",mode.time,0.2)
		await tween.finished
func refresh_shelling_mode_label(role:Character) -> void:
	if role==null or role!=current_role:
		return
	var mode:Attack=role.setting.attack_mode
	if mode is not Shelling:
		return
	var shelling:Shelling=mode as Shelling
	var dud:Buff=role.get_buff(Buff.TYPE_DUD)
	var lock:Buff=role.get_buff(Buff.TYPE_LOCK)
	var remaining_time:int=shelling.time
	if lock!=null:
		remaining_time=lock.level
	if dud!=null:
		remaining_time+=dud.level
	mode_label.text="目标锁定所需时间为"+str(remaining_time)+"回合"
func _get_mode_index(mode:Attack)->int:
	if mode is not Shelling:
		if mode is Melee:
			return 0
		elif mode is Shoot:
			return 1
	else:
		if mode.current_missile==null:
			return 2
		else:
			if mode.current_missile is Firebomb:
				return 3
			elif mode.current_missile is FlashBang:
				return 4
			elif mode.current_missile is Flare:
				return 5
	return -1
func change_mode(mode:Attack):
	var new_index=_get_mode_index(mode)
	if new_index!=-1:
		if index!=new_index:
			index=new_index
			var mat: ShaderMaterial = Imode.material as ShaderMaterial
			if mat==null:
				Imode.texture = load(mode_pic[new_index])
				attack_mode = mode
				return
			attack_mode = mode
			# 翻转动画：0→0.5 原图压扁，0.5→1 目标图展开
			mat.set_shader_parameter("target_texture", load(mode_pic[new_index]))
			mat.set_shader_parameter("transition", 0.0)
			var tween := create_tween()
			tween.tween_property(mat, "shader_parameter/transition", 1.0, 0.3)
			tween.tween_callback(func():
				Imode.texture = load(mode_pic[new_index])
				mat.set_shader_parameter("transition", 0.0)
			)
			await tween.finished
func decrease_health(value:int):#角色血条UI更新
	var isDead:bool=false
	current_role.setting.health=max(0,current_role.setting.health)
	current_health=current_role.setting.health
	if current_health==0:#角色死亡
		isDead=true
	if max_health!=0:
		var length:float=Max_size*(float(current_health)/float(max_health))
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.1)
		tween.tween_callback(func():
			healthBar.size.x=length
			health_label.text=str(current_health)+"/"+str(max_health)
			)
		tween.tween_interval(1)
		tween.tween_property(decreaseBar,"size",Vector2(length,43),0.2)
		await tween.finished
		characterIsDead.emit(current_role)
## 根据角色的buff列表刷新buff_basket显示
func refresh_buff_basket(character:Character) -> void:
	if buff_basket==null:
		return
	# 清空现有显示
	for child in buff_basket.get_children():
		child.queue_free()
	# 根据角色buff数据重新创建UI
	for b in character.buffs:
		var buff_ui: Buff = preload("res://scenes/buff.tscn").instantiate() as Buff
		buff_ui.setup_by_type(b.get_buff_type())
		buff_ui.level = b.level
		buff_ui.refresh_display()
		buff_basket.add_child(buff_ui)
