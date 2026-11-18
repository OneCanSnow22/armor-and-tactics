extends CanvasLayer
@export var money_label:Label
@export var energy_label:Label
@export var money_page:VBoxContainer
@export var energy_page:VBoxContainer
@export var card_page:VBoxContainer
@export var weapon_page:VBoxContainer
@export var fun_list:VBoxContainer
@export var chest:TextureButton
@export var treasure_list:PanelContainer
@export var context:Label
@export var weapon_title:Label
@export var weapon_pic:TextureRect
var card:Card
var weapon:Attack
var money:int
var energy:int
var type:Type_treasure
enum Type_treasure{
	Energy_treasure,
	Money_treasure,
	Card_treasure,
	Weapon_treasure,
	Empty_treasure
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	treasure_list.visible=false
	treasure_list.scale=Vector2(0,0)
	type=Type_treasure.Empty_treasure
	random_treasure()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_pressed() -> void:
	chest.disabled=true
	treasure_list.visible=true
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(treasure_list,"scale",Vector2(1,1),0.2)
	pass # Replace with function body.
func over():
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(treasure_list,"position",treasure_list.position+Vector2(0,400),0.2)
	await tween.finished
	if type==Type_treasure.Energy_treasure:
		Profile.item.add_energy(energy)
	elif type==Type_treasure.Money_treasure:
		Profile.item.add_money(money)
	elif type==Type_treasure.Card_treasure:
		if card!=null:
			Profile.Deck.append(card)
	elif type==Type_treasure.Weapon_treasure:
		if weapon!=null:
			Profile.item.add_weapon(weapon)
	get_tree().change_scene_to_file("res://scenes/map.tscn")
func _on_ignore_pressed() -> void:
	type=Type_treasure.Empty_treasure
	over()
	pass # Replace with function body.


func _on_take_pressed() -> void:
	over()
	pass # Replace with function body.
func show_text(mode:Attack):
	context.text="攻击力："+str(mode.damage)+"\n"
	if mode is Melee:
		context.text+="攻击范围："+str(mode.max_range)+"\n"
	elif mode is Shoot:
		context.text+="命中率："+str(mode.max_probability)+"%\n"
		if mode is Through_shoot:
			context.text+="贯穿等级：Level"+str(mode.level)+"\n"
	elif mode is Shelling:
		if mode.firebomb.isCanBeUsed:
			context.text+="燃烧弹可装备\n"
		if mode.flashbang.isCanBeUsed:
			context.text+="闪光弹可装备\n"
		if mode.flare.isCanBeUsed:
			context.text+="干扰弹可装备\n"
		if mode is Multi_target_missile:
			context.text+="可打击多个目标\n"
		elif mode is Sputtering_type_artillery:
			context.text+="溅射范围："+str(mode.sputter_range)+"\n"
		context.text+="需要等待的回合数："+str(mode.max_time)+"\n"
	context.text+="价值："+str(mode.evaluate_price())
func change_texture(mode:Attack):
	if mode is Melee:
		weapon_pic.texture=load("res://assets/statebar/melee_mode.png")
	elif mode is Shoot:
		weapon_pic.texture=load("res://assets/statebar/shoot_mode.png")
	elif mode is Shelling:
		weapon_pic.texture=load("res://assets/statebar/shelling.png")
func close_all_page():
	money_page.visible=false
	card_page.visible=false
	energy_page.visible=false
	weapon_page.visible=false
func open_energy_page():
	close_all_page()
	energy_page.visible=true
	energy=Profile.rng.randi_range(4,8)
	energy_label.text="%d-grid_energy"%energy
	type=Type_treasure.Energy_treasure
func open_money_page():
	close_all_page()
	money_page.visible=true
	var rd=Profile.rng.randi_range(0,100)
	if rd<3:
		money=Profile.rng.randi_range(200,400)
	elif rd<40:
		money=Profile.rng.randi_range(90,150)
	else:
		money=Profile.rng.randi_range(30,70)
	money_label.text="%d$"%money
	type=Type_treasure.Money_treasure
func open_card_page():
	close_all_page()
	card_page.visible=true
	card=Profile.random_card_for_shop()
	var step=0
	for _i in fun_list.get_children():
		_i.show_unit(card.function_list[step])
		step+=1
	type=Type_treasure.Card_treasure
func open_weapon_page():
	close_all_page()
	weapon_page.visible=true
	var randomType=randi_range(0,3)
	if randomType==0:
		weapon=Profile._random_shoot_for_shop()
	elif randomType==1:
		weapon=Profile._random_shelling_for_shop()
	else:
		weapon=Profile._random_melee_for_shop()
	if weapon==null:
		print("武器是空的")
		return
	weapon_title.text=weapon.code
	change_texture(weapon)
	show_text(weapon)
	type=Type_treasure.Weapon_treasure
func random_treasure():
	if Profile.item.energy<=3:
		open_energy_page()
	else:
		var randomIndex=Profile.rng.randi_range(0,3)
		if randomIndex==0:
			open_money_page()
		elif randomIndex==1:
			open_energy_page()
		elif randomIndex==2:
			open_card_page()
		elif randomIndex==3:
			open_weapon_page()
