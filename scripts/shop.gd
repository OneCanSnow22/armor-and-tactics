extends CanvasLayer
@export var expression:TextureRect
@export var word:Label
@export var money:RichTextLabel
@export var plate:PanelContainer
@export var duration:float=10
@export var hint:VBoxContainer
@export var energy_button:Button
enum Shop_type{
	Card_shop,
	Weapon_shop
}
var cards: Array[Card] = []  # 6张卡牌，由 open_card_shop 填充
var weapons: Array[Attack] = []  # 三种武器，由 open_weapon_shop 填充
var energy_cost:int
var energy:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hint.visible=false
	energy_button.visible=false
	refresh_money()
	welcome_to_shop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func shoper_speak(value:String):
	word.visible_characters=0
	word.text=value
	var time:float=value.length()/duration
	var tween=create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(word,"visible_characters",value.length(),time)
	await tween.finished

func refresh_money():
	money.text="当前剩余金额:[color=#FFD700]%d[/color]"%Profile.item.money

func open_card_shop():#打开卡牌商店，生成6张不重复加强稀有度卡牌
	var box=$PanelContainer/CardShop
	var hide_box=$PanelContainer/WeaponShop
	box.visible=true
	hide_box.visible=false
	var card_box=load("res://scenes/commodity/card_commodity.tscn")
	plate.position.y=4000
	# 清空旧卡牌
	if box.get_child_count()>0:
		for _i in box.get_children():
			box.remove_child(_i)
			_i.queue_free()
	# 生成6张不重复卡牌
	cards = Profile.random_cards_for_shop(6)
	# 添加到 UI 并显示
	var step=0
	for card in cards:
		var goods:Card_commodity=card_box.instantiate() as Card_commodity
		box.add_child(goods)
		goods.set_card(card)
		goods.card_is_clicked.connect(card_is_chosen)
		goods.card_is_hoverd.connect(card_is_hover)
		goods.cost_is_too_high.connect(say_no)
		goods.position=Vector2(136+240*step+randi_range(30,48),randi_range(60,400))
		step+=1
	refresh_money()
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(plate,"position",Vector2(5,226),0.2)
	await  tween.finished
	show_energy_button()
	for _i in box.get_children():
		_i.inertia()
func welcome_to_shop():
	plate.position.y=4000
	await shoper_speak("来，看看我的货。")
	if randi()%2==0:
		open_card_shop()
	else:
		open_weapon_shop()

func open_weapon_shop():#打开武器商店，生成三种类型的优质武器
	# 检查 WeaponShop 容器是否存在
	var box = $PanelContainer/WeaponShop
	var hide_box=$PanelContainer/CardShop
	if box == null:
		push_warning("shop.gd: WeaponShop 容器不存在，跳过武器商店")
		return
	box.visible=true
	hide_box.visible=false
	plate.position.y=4000
	# 清空旧武器
	if box.get_child_count()>0:
		for _i in box.get_children():
			box.remove_child(_i)
			_i.queue_free()
	# 生成三种武器
	weapons = Profile.random_weapons_for_shop()
	# 加载武器商品场景
	var weapon_commodity_scene = load("res://scenes/commodity/weapon_commodity.tscn")
	if weapon_commodity_scene == null:
		push_warning("shop.gd: weapon_commodity.tscn 场景不存在，跳过实例化")
		return
	var step: int = 0
	for weapon in weapons:
		var goods = weapon_commodity_scene.instantiate()
		box.add_child(goods)
		goods.weapon_is_selected.connect(weapon_is_cost)
		goods.set_weapon(weapon)
		goods.position = Vector2(242 + 519 * step, 166)
		step += 1
	refresh_money()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(plate, "position", Vector2(5, 226), 0.2)
	await tween.finished
	show_energy_button()
func card_is_chosen(card:Card):
	refresh_money()
func card_is_hover(card:Card):
	if card!=null:
		var j=0
		for _i in hint.get_children():
			_i.show_unit(card.function_list[j])
			j+=1
		hint.visible=true
		var mouse_screen_pos = get_viewport().get_mouse_position()
		hint.global_position=mouse_screen_pos+Vector2(10,10)
	else:
		hint.visible=false
func say_no():
	shoper_speak(random_reply())
func weapon_is_cost(value:int):
	if value>Profile.item.money:
		say_no()
	else:
		Profile.item.money-=value
		refresh_money()
func random_reply()->String:
	var gg=randi_range(0,3)
	if gg==0:
		return "再看看别的吧。"
	elif gg==1:
		return "我这价你可承担不起啊。"
	else:
		return "不景气啊，小老弟。"


func _on_delete_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.
func show_energy_button():
	energy_button.visible=true
	energy=randi_range(5,8)
	energy_cost=50
	energy_cost=energy_cost*(1+0.8*Profile.item.buy_energy_times)
	Profile.item.buy_energy_times+=1
	if Profile.item.energy<2:
		energy_cost*=0.1
	
	energy_button.text=str(energy)+"格能量：%d"%energy_cost


func _on_energy_button_pressed() -> void:
	if energy_cost>Profile.item.money:
		say_no()
	else:
		refresh_money()
		energy_button.disabled=true
		Profile.item.money-=energy_cost
		Profile.item.add_energy(energy_cost)
	pass # Replace with function body.
