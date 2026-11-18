extends CanvasLayer
@export var Picture:TextureRect
@export var title:Label
@export var context:Label
@export var chip:PanelContainer
var weapon:Attack

func _ready() -> void:
	visible=false

func _process(delta: float) -> void:
	pass

func random_weapon():
	weapon = Profile.random_weapon()
	title.text = weapon.code
	change_texture(weapon)
	show_text(weapon)

func change_texture(mode:Attack):
	if mode is Melee:
		Picture.texture=load("res://assets/statebar/melee_mode.png")
	elif mode is Shoot:
		Picture.texture=load("res://assets/statebar/shoot_mode.png")
	elif mode is Shelling:
		Picture.texture=load("res://assets/statebar/shelling.png")

func show_text(mode:Attack):
	context.text="攻击力："+str(mode.damage)+"\n"
	if mode is Melee:
		context.text+="攻击范围："+str(mode.range)+"\n"
	elif mode is Shoot:
		context.text+="命中率："+str(mode.probability)+"%\n"
		if mode is Through_shoot:
			context.text+="贯穿等级：Level"+str(mode.level)+"\n"
	elif mode is Shelling:
		if mode.firebomb.isCanBeUsed:
			context.text+="-燃烧弹可装备\n"
		if mode.flashbang.isCanBeUsed:
			context.text+="-闪光弹可装备\n"
		if mode.flare.isCanBeUsed:
			context.text+="-干扰弹可装备\n"
		if mode is Multi_target_missile:
			context.text+="可打击多个目标\n"
		elif mode is Sputtering_type_artillery:
			context.text+="溅射范围："+str(mode.sputter_range)+"\n"
		context.text+="需要等待的回合数："+str(mode.max_time)+"\n"
	context.text+="价值："+str(weapon.evaluate_price())

func show_chip():
	visible=true
	chip.position=Vector2(821,-200)
	random_weapon()
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(chip,"position",Vector2(821,207),0.2)

func _on_button_pressed() -> void:
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(chip,"position",Vector2(2000,207),0.2)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_button_2_pressed() -> void:
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(chip,"position",Vector2(821,600),0.2)
	await tween.finished
	if weapon is Melee:
		Profile.item.meleeBag.append(weapon)
	elif weapon is Shoot:
		Profile.item.shootBag.append(weapon)
	elif weapon is Shelling:
		Profile.item.shellingBag.append(weapon)
	get_tree().change_scene_to_file("res://scenes/map.tscn")
