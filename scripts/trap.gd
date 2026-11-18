extends CanvasLayer
@export var speaker:Speaker
@export var word:HBoxContainer#拿来吧你的显示
@export var coin_page:HBoxContainer
@export var energy_page:HBoxContainer
@export var card_page:HBoxContainer
@export var weapon_page:HBoxContainer
@export var money_label:Label
@export var energy_label:Label
@export var weapon_label:Label
@export var price_label:Label
var trap_cost:int
var used_card:Card=null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	speaker.set_expression("res://assets/character/monster_01/monster01_smile.png")
	word.visible=false
	hide_all_page()
	trap_now()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func hide_all_page():
	coin_page.visible=false
	energy_page.visible=false
	card_page.visible=false
	weapon_page.visible=false
func open_coin_page():#减少金币
	hide_all_page()
	coin_page.visible=true
	trap_cost=Profile.item.money*0.3
	money_label.text="%d$"%trap_cost
	money_label.visible_characters=0
	var speed:float=10
	var duration:float=money_label.text.length()/speed
	var tween=create_tween()
	tween.tween_property(money_label,"visible_characters",money_label.text.length(),duration)
	await tween.finished
	Profile.item.money-=trap_cost
func open_energy_page():#减少能量
	hide_all_page()
	energy_page.visible=true
	var max_energy_range=Profile.item.energy
	var energy_cost=Profile.rng.randi_range(min(2,max_energy_range),min(5,max_energy_range))
	energy_label.text="%dgrid_energy"%energy_cost
	energy_label.visible_characters=0
	var speed:float=10
	var duration:float=energy_label.text.length()/speed
	var tween=create_tween()
	tween.tween_property(energy_label,"visible_characters",energy_label.text.length(),duration)
	await tween.finished
	Profile.item.energy-=energy_cost
func open_card_page():#减少卡牌
	hide_all_page()
	card_page.visible=true
	used_card=Profile.Deck[0]
	for _i in Profile.Deck:#寻找使用次数最多的卡牌
		var card:Card=_i as Card
		if used_card.used_times<card.used_times:
			used_card=card
	if used_card!=null:
		card_page.add_child(used_card)
		used_card.apply_card()
		used_card.fresh_card()
		used_card.display()
		used_card.just_for_check=true
	Profile.Deck.erase(used_card)
	
func open_weapon_page():#减少武器
	hide_all_page()
	weapon_page.visible=true
	var weapons:Array
	for _i in Profile.item.meleeBag:
		if _i !=Profile.player.melee:
			weapons.append(_i)
	for _i in Profile.item.shootBag:
		if _i!=Profile.player.shoot:
			weapons.append(_i)
	for _i in Profile.item.shellingBag:
		if _i!=Profile.player.shelling:
			weapons.append(_i)
	var the_best:Attack
	if weapons.size()>=1:#抛开玩家装备的三件武器来选取最有价值的一件
		for _i in weapons:
			var w:Attack=_i as Attack
			if the_best==null or w.evaluate_price()>the_best.evaluate_price():
				the_best=w
	if the_best!=null:
		# 从对应背包中移除该武器
		if the_best is Melee:
			Profile.item.meleeBag.erase(the_best)
		elif the_best is Shoot:
			Profile.item.shootBag.erase(the_best)
		elif the_best is Shelling:
			Profile.item.shellingBag.erase(the_best)
		weapon_label.text=the_best.code
		price_label.text="PRICE:%d$"%the_best.evaluate_price()
		price_label.visible_characters=6
		var speed:float=10
		var duration:float=(price_label.text.length()-6)/speed
		var tween=create_tween()
		tween.tween_property(price_label,"visible_characters",price_label.text.length(),duration)
func randomIndex()->int:
	# 构建合法页面池
	var pool:Array[int]=[]
	# 0：金币页，任何情况都允许
	pool.append(0)
	# 1：能量页，能量 > 4 才允许
	if Profile.item.energy > 4:
		pool.append(1)
	# 2：卡牌页，Deck 不为空才允许
	if Profile.Deck.size() > 0:
		pool.append(2)
	# 3：武器页，三个 Bag 排除当前装备后仍有剩余才允许
	var extra_weapons:int = 0
	extra_weapons += Profile.item.meleeBag.size()
	extra_weapons += Profile.item.shootBag.size()
	extra_weapons += Profile.item.shellingBag.size()
	# 减去当前装备的三件（每件确认在对应 Bag 里才扣）
	if Profile.item.meleeBag.has(Profile.player.melee):
		extra_weapons -= 1
	if Profile.item.shootBag.has(Profile.player.shoot):
		extra_weapons -= 1
	if Profile.item.shellingBag.has(Profile.player.shelling):
		extra_weapons -= 1
	if extra_weapons > 0:
		pool.append(3)
	# 从合法池里随机选一个 ID
	return pool[Profile.rng.randi_range(0, pool.size() - 1)]
func randomPage():#根据id生成页面
	match randomIndex():
		0:
			print("失去金币")
			open_coin_page()
		1:
			print("失去能量")
			open_energy_page()
		2:
			print("失去卡牌")
			open_card_page()
		3:
			print("失去武器")
			open_weapon_page()
func trap_now():
	await speaker.start("拿来吧，你！")
	await get_tree().create_timer(0.2).timeout
	word.visible=true
	await get_tree().create_timer(1).timeout
	randomPage()


func _on_delete_pressed() -> void:
	if used_card!=null:
		used_card.queue_free()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.
