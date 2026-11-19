extends Node
const CardScript = preload("res://scripts/card.gd")
var rng:RandomNumberGenerator#随机生成器
var player:Player
var enemy:Array[Role]
var item:Item
var time:TimeRecorder
const max_energy:int=15
## 卡牌配方定义：[function类型, 数量]
## 创建卡组时根据配方表批量生成，不用再写重复代码
enum Function{
	Forward,
	Backward,
	Discard_one,
	Discard_two,
	Draw_one,
	Draw_two,
	Draw_three,
	Load,
	Replace,
	Swipe,
	Turn,
	One_off,
	Consume,
	Lock,
	Blank
}
var Func_picture:Dictionary={
	Function.Forward:"res://assets/cards/forward.png",
	Function.Backward:"res://assets/cards/backward.png",
	Function.Discard_one:"res://assets/cards/discard_one.png",
	Function.Discard_two:"res://assets/cards/discard_two.png",
	Function.Draw_one:"res://assets/cards/draw_one.png",
	Function.Draw_two:"res://assets/cards/draw_two.png",
	Function.Draw_three:"res://assets/cards/draw_three.png",
	Function.Load:"res://assets/cards/load.png",
	Function.Replace:"res://assets/cards/replace.png",
	Function.Swipe:"res://assets/cards/swipe.png",
	Function.Turn:"res://assets/cards/turn.png",
	Function.One_off:"res://assets/cards/one_off.png",
	Function.Consume:"res://assets/cards/consume.png",
	Function.Lock:"res://assets/cards/lock.png",
	Function.Blank:"res://assets/cards/blank.png"
}
var Deck:Array[Card]=[]
var CharacterArray:Array[Role]
var miss_times:int=0
var last_round_missed:bool
class AnimationUnit:
	func play(main:Main_menu):
		print("不实现任何东西")
class Forward_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		print("Forward_animation.play() 被调用")
		var player:Character = main.CharacterArray[0] as Character
		if player != null:
			await main.move_character(player, 1)
		print("Forward_animation.play() 结束")
		#await main.move_character(main.CharacterArray[0], 1) 
class Backward_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		var player:Character = main.CharacterArray[0] as Character
		if player != null:
			await main.move_character(player, -1)	
		#await main.move_character(main.CharacterArray[0], -1)	
class Discard_animation extends Profile.AnimationUnit:
	var count: int
	func _init(n: int):
		count = n
	func play(main:Main_menu):
		if main.card_manager != null:
			await main.card_manager.enter_discard_time(count)
		print("弃牌完成")
class Discard_one_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager != null:
			await main.card_manager.enter_discard_time(1)
		print("丢弃一张牌")
class Discard_two_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager != null:
			await main.card_manager.enter_discard_time(2)
		print("丢弃两张牌")
class Draw_one_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager!=null:
			await main.card_manager.draw_cards(1)
		print("抽一张牌")
class Draw_two_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager!=null:
			await main.card_manager.draw_cards(2)
		print("抽两张牌")
class Draw_three_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager!=null:
			await main.card_manager.draw_cards(3)
		print("抽三张牌")
class Load_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager!=null:
			await main.card_manager.enter_load_time()
		print("加载栈")
class Replace_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		if main.card_manager!=null:
			await main.card_manager.enter_replace_time()
		print("替换栈")
class Swipe_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		await main.execute_attack()
		print("打击")
class Turn_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		await main.change_player_mode()
		print("转换")
class Lock_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		print("锁")
class Consume_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		print("消耗")
class One_off_animation extends Profile.AnimationUnit:
	func play(main:Main_menu):
		print("一次性")
class Role:
	var Rname:String
	var health:int
	var max_health:int
	var attack_mode:Attack
	var origin_place:int
	var pic_path:String
class Player extends Role:
	var melee:Melee
	var shoot:Shoot
	var shelling:Shelling
	func _init() -> void:
		Rname="GP-3"
		pic_path="res://assets/character/enemy/player.png"
		max_health=80
		health=max_health
		melee=Melee.new()
		melee.damage=6
		melee.range=3
		melee.max_range=3
		melee.code="ME-00001"
		melee.price=10
		shoot=Shoot.new()
		shoot.damage=5
		shoot.probability=90
		shoot.max_probability=90
		shoot.code="ST-00001"
		shoot.price=10
		shelling=Shelling.new()
		shelling.damage=6
		shelling.time=1
		shelling.max_time=1
		shelling.firebomb=Firebomb.new()
		shelling.flashbang=FlashBang.new()
		shelling.flare=Flare.new()
		shelling.price=10
		shelling.code="SG-00001"
		origin_place=2
		attack_mode=melee

	
## 敌人行为枚举，用于 fight_menu 分发 AI 逻辑
## Role 只存标识，不存逻辑，判定由 fight_menu 统一处理
enum EnemyBehavior {
	BASIC_MELEE,    ## 基础近战：能打就打，打不到就向玩家移动
	BASIC_SHOOT,    ## 基础射击：永远不移动，直接攻击
	BASIC_SHELLING, ## 基础炮击：永远不移动，锁定后触发
	IMMOVABLE,      ## 不可移动型（如重装兵）：不移动，受伤减免
	MUTANT,         ## 变异体：可在近战/射击间切换
}

class Enemy_information:
	var enemy_id:int
	var enemy_position:int
	func _init(v1:int,v2:int) -> void:
		enemy_id=v1
		enemy_position=v2
	func deploy()->Enemy:
		if enemy_id==1:
			return MR_1.new(enemy_position)
		elif enemy_id==2:
			return SR_1.new(enemy_position)
		elif enemy_id==3:
			return SLR_1.new(enemy_position)
		return null
class Enemy extends Role:
	var id:int
	var isAimed:bool
	var reward:int
	var behavior: EnemyBehavior = EnemyBehavior.BASIC_MELEE
	func upgrade():#提升敌人强度
		var times=Profile.item.finished_times
		max_health*=(1+0.4*times)
		health=max_health
		attack_mode.damage*=(1+0.1*times)
class Test_Melee extends Enemy:
	func _init() -> void:
		Rname="TM-1"
		reward=30
		health=30
		max_health=health
		origin_place=8
		attack_mode=Melee.new()
		attack_mode.damage=5
		attack_mode.range=3
		attack_mode.max_range=3
		behavior=EnemyBehavior.BASIC_MELEE
class MR_1 extends Enemy:
	func _init(value:int) -> void:
		Rname="MR_1"
		id=1
		reward=25
		health=30
		max_health=health
		origin_place=value
		attack_mode=Melee.new()
		attack_mode.damage=5
		attack_mode.range=3
		attack_mode.max_range=3
		behavior=EnemyBehavior.BASIC_MELEE
		pic_path="res://assets/character/enemy/MR_1.png"
class SR_1 extends Enemy:
	func _init(value:int) -> void:
		Rname="SR_1"
		id=2
		reward=25
		health=20
		max_health=health
		origin_place=value
		attack_mode=Shoot.new()
		attack_mode.damage=7
		attack_mode.probability=85
		attack_mode.max_probability=85
		behavior=EnemyBehavior.BASIC_SHOOT
		pic_path="res://assets/character/enemy/SR_1.png"
class SLR_1 extends Enemy:
	func _init(value:int) -> void:
		Rname="SLR_1"
		id=3
		reward=25
		health=20
		max_health=health
		origin_place=value
		attack_mode=Shelling.new()
		attack_mode.damage=6
		attack_mode.time=1
		attack_mode.max_time=1
		attack_mode.firebomb=Firebomb.new()
		attack_mode.flashbang=FlashBang.new()
		attack_mode.flare=Flare.new()
		behavior=EnemyBehavior.BASIC_SHOOT
		pic_path="res://assets/character/enemy/SLR_1.png"
class Test_Shoot extends Enemy:
	func _init() -> void:
		Rname="TS-2"
		reward=30
		health=20
		max_health=health
		origin_place=9
		attack_mode=Shoot.new()
		attack_mode.damage=10
		attack_mode.probability=88
		attack_mode.max_probability=88
		behavior=EnemyBehavior.BASIC_SHOOT
## ========== 卡牌随机生成（从 card_reward 迁移） ==========

## 有用模组 ID 列表（排除 Lock=13、Blank=14）
const USEFUL_FUNCTIONS: Array[int] = [0,1,2,3,4,5,6,7,8,9,10,11,12]

## 各模组对应点数（绝对值用于计算稀有度权重）
const FUNCTION_POINTS: Dictionary = {
	0:  3,   # Forward
	1:  3,   # Backward
	2:  3,   # Discard_one
	3:  4,   # Discard_two
	4:  3,   # Draw_one
	5:  4,   # Draw_two
	6:  5,   # Draw_three
	7:  4,   # Load
	8:  4,   # Replace
	9:  3,   # Swipe
	10: 3,   # Turn
	11: -4,  # One_off
	12: -5,  # Consume
}

## 创建一张随机卡牌，挂载到场景前需调用 add_child
## exclude_signatures: 已有签名数组，用于去重
func random_card(exclude_signatures: Array[String] = []) -> Card:
	var card_scene = load("res://scenes/Card/card.tscn")
	var card: Card = card_scene.instantiate() as Card
	card.function_list.resize(4)

	var max_attempts: int = 20
	for _attempt in range(max_attempts):
		var max_function_num: int = _random_function_count()
		var picked_types: Array[int] = []
		var current_points: int = 0

		for slot in range(4):
			card.function_list[slot] = create_function(Function.Lock)

		for slot in range(max_function_num):
			var chosen: int = _pick_function(current_points, picked_types)
			if chosen == -1:
				break
			card.function_list[slot] = create_function(chosen as Function)
			current_points += abs(FUNCTION_POINTS[chosen])
			picked_types.append(chosen)

		var sig: String = _card_signature(picked_types)
		if not exclude_signatures.has(sig):
			return card

	return card

## 计算卡牌模组签名，用于去重
func _card_signature(picked: Array[int]) -> String:
	var sorted: Array[int] = picked.duplicate()
	sorted.sort()
	var parts: Array[String] = []
	for id in sorted:
		parts.append(str(id))
	return ",".join(parts)

## 从有用模组中随机选一个，保证加入后总点数不超 Card.max_point，且不重复
func _pick_function(current_points: int, exclude: Array[int] = []) -> int:
	var remaining: int = Card.max_point - current_points
	var candidates: Array = []
	for func_type in USEFUL_FUNCTIONS:
		if exclude.has(func_type):
			continue
		var abs_pt: int = abs(FUNCTION_POINTS[func_type])
		if abs_pt <= remaining:
			candidates.append(func_type)

	if candidates.is_empty():
		return -1

	var max_abs: int = 0
	for func_type in candidates:
		max_abs = max(max_abs, abs(FUNCTION_POINTS[func_type]))

	var weights: Array = []
	var total_weight: int = 0
	for func_type in candidates:
		var w: int = max_abs + 1 - abs(FUNCTION_POINTS[func_type])
		weights.append(w)
		total_weight += w

	var rand_val: int = randi() % total_weight
	var cumulative: int = 0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if rand_val < cumulative:
			return candidates[i]
	return candidates[0]

## 随机加权返回有用模组数量（1~4），权重 80:10:2:1
func _random_function_count() -> int:
	var weights: Array = [80, 10, 2, 1]
	var total_weight: int = 0
	for weight in weights:
		total_weight += weight
	var random_value: int = randi() % total_weight
	var cumulative_weight: int = 0
	for i in range(weights.size()):
		cumulative_weight += weights[i]
		if random_value < cumulative_weight:
			return i + 1
	return 1

## ========== 商店专用卡牌生成（加强稀有度） ==========

## 商店专用：随机返回有用模组数量（1~4），权重 20:30:30:20，偏向3-4个模组
func _random_function_count_shop() -> int:
	var weights: Array = [20, 30, 30, 20]
	var total_weight: int = 0
	for weight in weights:
		total_weight += weight
	var random_value: int = randi() % total_weight
	var cumulative_weight: int = 0
	for i in range(weights.size()):
		cumulative_weight += weights[i]
		if random_value < cumulative_weight:
			return i + 1
	return 1

## 商店专用：从有用模组中随机选一个，偏向高点数模组
func _pick_function_shop(current_points: int, exclude: Array[int] = []) -> int:
	var remaining: int = Card.max_point - current_points
	var candidates: Array = []
	for func_type in USEFUL_FUNCTIONS:
		if exclude.has(func_type):
			continue
		var abs_pt: int = abs(FUNCTION_POINTS[func_type])
		if abs_pt <= remaining:
			candidates.append(func_type)

	if candidates.is_empty():
		return -1

	# 权重 = abs_pt + 1，点数越高权重越大
	var weights: Array = []
	var total_weight: int = 0
	for func_type in candidates:
		var w: int = abs(FUNCTION_POINTS[func_type]) + 1
		weights.append(w)
		total_weight += w

	var rand_val: int = randi() % total_weight
	var cumulative: int = 0
	for i in range(candidates.size()):
		cumulative += weights[i]
		if rand_val < cumulative:
			return candidates[i]
	return candidates[0]

## 创建一张商店专用随机卡牌（加强稀有度），exclude_signatures 用于去重
func random_card_for_shop(exclude_signatures: Array[String] = []) -> Card:
	var card_scene = load("res://scenes/Card/card.tscn")
	var card: Card = card_scene.instantiate() as Card
	card.function_list.resize(4)

	var max_attempts: int = 50
	for _attempt in range(max_attempts):
		var max_function_num: int = _random_function_count_shop()
		var picked_types: Array[int] = []
		var current_points: int = 0

		for slot in range(4):
			card.function_list[slot] = create_function(Function.Lock)

		for slot in range(max_function_num):
			var chosen: int = _pick_function_shop(current_points, picked_types)
			if chosen == -1:
				break
			card.function_list[slot] = create_function(chosen as Function)
			current_points += FUNCTION_POINTS[chosen]
			picked_types.append(chosen)

		var sig: String = _card_signature(picked_types)
		if not exclude_signatures.has(sig):
			return card

	return card

## 生成 count 张不重复的商店卡牌，返回 Array[Card]
func random_cards_for_shop(count: int = 6) -> Array[Card]:
	var cards: Array[Card] = []
	var signatures: Array[String] = []
	for i in range(count):
		var card: Card = random_card_for_shop(signatures)
		var sig: String = _card_signature(_get_picked_types_from_card(card))
		signatures.append(sig)
		cards.append(card)
	return cards

## 从卡牌的 function_list 提取已选模组类型列表（排除 Lock/Blank/null）
func _get_picked_types_from_card(card: Card) -> Array[int]:
	var picked: Array[int] = []
	for fun in card.function_list:
		if fun == null:
			continue
		# 通过 mode 字段判断类型，需反向查找 Function 枚举值
		var ft: int = fun.mode
		if ft != Function.Lock and ft != Function.Blank:
			picked.append(ft)
	return picked

## ========== 武器随机生成（从 weapon_reward 迁移） ==========

## 随机生成一把武器，返回 Attack 实例
func random_weapon() -> Attack:
	var code: int = randi() % 6
	var weapon: Attack
	match code:
		0:
			weapon = Melee.new()
			weapon.damage = (randi() % 8 + 2)*(1+0.1*Profile.item.finished_times)
			weapon.range = randi() % 3 + 1
			weapon.max_range = weapon.range
		1:
			weapon = Shoot.new()
			weapon.damage = (randi() % 7 + 1)*(1+0.1*Profile.item.finished_times)
			weapon.probability = randi() % 50 + 50
			weapon.max_probability = weapon.probability
		2:
			weapon = Through_shoot.new()
			weapon.damage = (randi() % 5 + 2)*(1+0.1*Profile.item.finished_times)
			weapon.probability = randi() % 40 + 54
			weapon.max_probability = weapon.probability
			weapon.level = randi() % 3 + 1
		3:
			weapon = Shelling.new()
			weapon.damage = (randi() % 3 + 3)*(1+0.1*Profile.item.finished_times)
			weapon.time = randi() % 3 + 1
			weapon.max_time = weapon.time
			weapon.firebomb = Firebomb.new()
			weapon.flashbang = FlashBang.new()
			weapon.flare = Flare.new()
		4:
			weapon = Multi_target_missile.new()
			weapon.damage = (randi() % 3 + 2)*(1+0.1*Profile.item.finished_times)
			weapon.time = randi() % 4 + 1
			weapon.max_time = weapon.time
			weapon.firebomb = Firebomb.new()
			weapon.flashbang = FlashBang.new()
			weapon.flare = Flare.new()
		5:
			weapon = Sputtering_type_artillery.new()
			weapon.damage = (randi() % 3 + 3)*(1+0.1*Profile.item.finished_times)
			weapon.time = randi() % 2 + 1
			weapon.max_time = weapon.time
			weapon.sputter_range = randi() % 3 + 1
			weapon.firebomb = Firebomb.new()
			weapon.flashbang = FlashBang.new()
			weapon.flare = Flare.new()
		_:
			weapon = Melee.new()
			weapon.damage = (randi() % 8 + 2)*(1+0.1*Profile.item.finished_times)
			weapon.range = randi() % 3 + 1
			weapon.max_range = weapon.range
	if weapon is Shelling:
		var available: Array[bool] = _random_missile_availability()
		weapon.firebomb.isCanBeUsed = available[0]
		weapon.flare.isCanBeUsed = available[1]
		weapon.flashbang.isCanBeUsed = available[2]
	var num: int = randi() % 10000
	weapon.code = _weapon_prefix(weapon) + ("-%05d" % num)
	return weapon

## 武器类型前缀
func _weapon_prefix(weapon: Attack) -> String:
	if weapon is Melee:
		return "ME"
	elif weapon is Through_shoot:
		return "TS"
	elif weapon is Shelling:
		if weapon is Multi_target_missile:
			return "MTM"
		elif weapon is Sputtering_type_artillery:
			return "STA"
		return "SG"
	elif weapon is Shoot:
		return "ST"
	return "??"

## 随机 1~2 种属性弹可用
func _random_missile_availability() -> Array[bool]:
	var available_count: int = randi_range(1, 2)
	var result: Array[bool] = [false, false, false]
	var indices: Array[int] = [0, 1, 2]
	indices.shuffle()
	for i in range(available_count):
		result[indices[i]] = true
	return result

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng = RandomNumberGenerator.new()
	#initial_player()
	#enemy.resize(4)
	#enemy[0]=Test_Melee.new()
	#enemy[1]=Test_Shoot.new()
	#CharacterArray.append(player)
	#CharacterArray.append(enemy[0])
	#CharacterArray.append(enemy[1])
	#fill_test_weapons()
	#create_initial_deck()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func initial_player():
	time=TimeRecorder.new()
	player=Player.new()
	item=Item.new()
	item.set_money(99)
	item.energy=max_energy
	item.meleeBag.append(player.melee)
	item.shootBag.append(player.shoot)
	item.shellingBag.append(player.shelling)
	fill_test_weapons()
## [测试用] 往三个武器包各塞3把武器，后期删除即可
func fill_test_weapons() -> void:
	# --- 近战包 ---
	var weapon:Attack
	weapon=Melee.new()
	weapon.damage=8
	weapon.range=5
	weapon.max_range=5
	weapon.code="ME-00002"
	item.meleeBag.append(weapon)        # 高伤害高范围
	weapon=Melee.new()
	weapon.damage=10
	weapon.range=2
	weapon.max_range=2
	weapon.code="ME-00004"
	item.meleeBag.append(weapon)       # 高伤害低范围
	weapon=Melee.new()
	weapon.damage=3
	weapon.range=7
	weapon.max_range=7
	weapon.code="ME-00003"
	item.meleeBag.append(weapon)        # 低伤害高范围
	# --- 射击包 ---
	weapon=Shoot.new()
	weapon.damage=6
	weapon.probability=85
	weapon.max_probability=85
	weapon.code="ST-00002"
	item.shootBag.append(weapon)       # 均衡型
	weapon=Through_shoot.new()
	weapon.damage=4
	weapon.probability=70
	weapon.max_probability=70
	weapon.level=2
	weapon.code="TS-00002"
	item.shootBag.append(weapon)  # 贯穿射击 等级2
	weapon=Through_shoot.new()
	weapon.damage=3
	weapon.probability=60
	weapon.max_probability=60
	weapon.level=3
	weapon.code="TS-00003"
	item.shootBag.append(weapon)  # 贯穿射击 等级3
	# --- 炮击包 ---
	weapon=Shelling.new()
	weapon.damage=10
	weapon.time=2
	weapon.max_time=2
	weapon.firebomb=Firebomb.new()
	weapon.flashbang=FlashBang.new()
	weapon.flare=Flare.new()
	weapon.firebomb.isCanBeUsed=false
	weapon.code="SG-00002"
	item.shellingBag.append(weapon)      # 高伤害延时2
	weapon=Multi_target_missile.new()
	weapon.damage=6
	weapon.time=1
	weapon.max_time=1
	weapon.firebomb=Firebomb.new()
	weapon.flashbang=FlashBang.new()
	weapon.flare=Flare.new()
	weapon.flashbang.isCanBeUsed=false
	weapon.code="MTM-00001"
	item.shellingBag.append(weapon)  # 多目标导弹
	weapon=Sputtering_type_artillery.new()
	weapon.damage=4
	weapon.time=1
	weapon.max_time=1
	weapon.sputter_range=3
	weapon.firebomb=Firebomb.new()
	weapon.flashbang=FlashBang.new()
	weapon.flare=Flare.new()
	weapon.flare.isCanBeUsed=false
	weapon.flashbang.isCanBeUsed=false
	weapon.code="STA-00001"
	item.shellingBag.append(weapon)  # 散射炮 范围3

func get_random(low:int,high:int):
	print("随机数生成")
	return rng.randi_range(low,high)
## Function 枚举 → CardScript 内部类的映射表
## 新增 function 类型时只需在这里加一行，不用再到处改代码
var _function_class_map: Dictionary = {
	Function.Forward: CardScript.Forward,
	Function.Backward: CardScript.Backward,
	Function.Discard_one: CardScript.Discard_one,
	Function.Discard_two: CardScript.Discard_two,
	Function.Draw_one: CardScript.Draw_one,
	Function.Draw_two: CardScript.Draw_two,
	Function.Draw_three: CardScript.Draw_three,
	Function.Load: CardScript.Load,
	Function.Replace: CardScript.Replace,
	Function.Swipe: CardScript.Swipe,
	Function.Turn: CardScript.Turn,
	Function.Lock: CardScript.Lock,
	Function.One_off: CardScript.One_off,
	Function.Consume: CardScript.Consume,
	Function.Blank: CardScript.Blank,
}
var enemy_seed_list:Dictionary[int,Array]={
	0:[Enemy_information.new(1,7)],
	1:[Enemy_information.new(2,10)],
	2:[Enemy_information.new(1,7),Enemy_information.new(2,9)],
	3:[Enemy_information.new(1,7),Enemy_information.new(3,9)],
	4:[Enemy_information.new(1,7),Enemy_information.new(3,9),Enemy_information.new(2,10)]
}
## 根据枚举值创建对应的 function 实例
func create_function(mode: Function) -> function:
	if _function_class_map.has(mode):
		return (_function_class_map[mode] as GDScript).new()
	push_error("Profile: 未知的 Function 类型: %d" % mode)
	return CardScript.Lock.new()

## 创建一张卡，function_list 按 [主功能, 填充功能, 数量] 排列
func create_card(primary: Function, secondary: Function = Function.Lock, fill_count: int = 3) -> Card:
	var card_scene=load("res://scenes/Card/card.tscn")
	var card :Card= card_scene.instantiate() as Card 
	card.function_list.resize(4)
	card.function_list[0] = create_function(primary)
	for i in range(1, min(fill_count + 1, 4)):
		card.function_list[i] = create_function(secondary)
	return card
func load_deck(value:Array[Array]):#加载牌库
	Deck.clear()
	for array in value:
		var card_scene=load("res://scenes/Card/card.tscn")
		var card :Card= card_scene.instantiate() as Card 
		card.function_list.resize(4)
		for i in array.size():
			card.function_list[i]=id_to_function(array[i])
		Deck.append(card)
func id_to_function(value:int)->function:
	match value:
		0:
			return Card.Blank.new()
		1:
			return Card.Lock.new()
		2:
			return Card.Forward.new()
		3:
			return Card.Backward.new()
		4:
			return Card.Discard_one.new()
		5:
			return Card.Discard_two.new()
		6:
			return Card.Draw_one.new()
		7:
			return Card.Draw_two.new()
		8:
			return Card.Draw_three.new()
		9:
			return Card.Replace.new()
		10:
			return Card.Load.new()
		11:
			return Card.Swipe.new()
		12:
			return Card.Turn.new()
		13:
			return Card.One_off.new()
		14:
			return Card.Consume.new()
	return null
func load_data():#加载数据
	var path = "user://savadata/save.tres"
	time=TimeRecorder.new()
	if not FileAccess.file_exists(path):
		return null  # 没有存档
	var data=ResourceLoader.load(path) as SaveData
	if data!=null:
		player=Player.new()
		player.max_health=data.player_max_health
		player.health=data.player_health
		player.melee=data.current_melee
		player.shoot=data.current_shoot
		player.shelling=data.current_shelling
		player.attack_mode = player.melee
		item=data.item_data
		time.set_current_time(data.current_time)
		load_deck(data.deck_ids)
	else:
		print("存档保存了一个空值")
func create_initial_deck() -> void:
	Deck.clear()
	# 前进卡 ×3
	for _i in range(3):
		Deck.append(create_card(Function.Forward))
	# 后退卡 ×3
	for _i in range(3):
		Deck.append(create_card(Function.Backward))
	# 打击卡 ×3
	for _i in range(3):
		Deck.append(create_card(Function.Swipe))
	# 转向卡 ×1（特殊配方）
	var card_scene = load("res://scenes/Card/card.tscn")
	var turn_card: Card = card_scene.instantiate() as Card
	turn_card.function_list.resize(4)
	turn_card.function_list[0] = create_function(Function.Draw_two)
	turn_card.function_list[1] = create_function(Function.Turn)
	for _i in range(2):
		turn_card.function_list[_i + 2] = create_function(Function.Lock)
	Deck.append(turn_card)
	#var turn_card2:Card=card_scene.instantiate() as Card
	#turn_card2.function_list.resize(4)
	#turn_card2.function_list[0] = create_function(Function.Discard_two)
	#turn_card2.function_list[1] = create_function(Function.Replace)
	#for _i in range(2):
		#turn_card2.function_list[_i + 2] = create_function(Function.Lock)
	#Deck.append(turn_card2)
	print("创建完成")

## 为商店生成三种类型的优质武器（各一把），允许个别属性劣于玩家当前武器
func random_weapons_for_shop() -> Array[Attack]:
	var results: Array[Attack] = []
	results.append(_random_melee_for_shop())
	results.append(_random_shoot_for_shop())
	results.append(_random_shelling_for_shop())
	return results

## 为商店生成一把近战武器，总体优于玩家当前近战
func _random_melee_for_shop() -> Melee:
	var player_w: Melee = player.melee as Melee
	var candidate: Melee
	var best: Melee = null
	var best_score: int = -999

	# 采样10次，选总分最高的
	for _i in range(10):
		candidate = Melee.new()
		candidate.damage = get_random(4, 10)*(1+0.1*Profile.item.finished_times)
		candidate.range = get_random(1, 5)
		candidate.max_range = candidate.range
		var score: int = (candidate.damage - player_w.damage) + (candidate.max_range - player_w.max_range) * 3
		if score > best_score:
			best_score = score
			best = candidate

	if best == null:
		best = Melee.new()
		best.damage = get_random(4, 6)*(1+0.1*Profile.item.finished_times)
		best.range = get_random(3, 10)
		best.max_range = best.range
	best.code = "ME-" + str(get_random(10000, 99999))
	return best

## 为商店生成一把射击武器，总体优于玩家当前射击武器
func _random_shoot_for_shop() -> Shoot:
	var player_w: Shoot = player.shoot as Shoot
	var is_player_through: bool = player_w is Through_shoot
	var candidate: Shoot
	var best: Shoot = null
	var best_score: int = -999

	for _i in range(10):
		var is_through: bool = is_player_through or (randi() % 3 == 0)
		var rand_prob: int = get_random(50, 92)
		if is_through:
			candidate = Through_shoot.new()
			candidate.damage = get_random(4, 7)*(1+0.1*Profile.item.finished_times)
			candidate.probability = rand_prob
			candidate.max_probability = rand_prob
			candidate.level = get_random(1, 3)
		else:
			candidate = Shoot.new()
			candidate.damage = get_random(4, 8)*(1+0.1*Profile.item.finished_times)
			candidate.probability = rand_prob
			candidate.max_probability = rand_prob

		var score: int = (candidate.damage - player_w.damage) * 2
		if candidate is Through_shoot:
			if is_player_through:
				score += ((candidate as Through_shoot).level - (player_w as Through_shoot).level) * 15
			else:
				score += 20  # 从非贯穿升级到贯穿，大幅加分
		score += (candidate.max_probability - player_w.max_probability) * 2

		if score > best_score:
			best_score = score
			best = candidate

	if best == null:
		best = Shoot.new()
		best.damage = get_random(1, 8)
		best.probability = get_random(3, 10)
		best.max_probability = best.probability
	best.code = "ST-" 
	if best is Through_shoot:
		best.code="TS-"
	best.code+= str(get_random(10000, 99999))
	return best

## 为商店生成一把炮击武器，总体优于玩家当前炮击武器
func _random_shelling_for_shop() -> Shelling:
	var player_w: Shelling = player.shelling as Shelling
	var candidate: Shelling
	var best: Shelling = null
	var best_score: int = -999

	for _i in range(10):
		var is_multi: bool = player_w is Multi_target_missile or (randi() % 3 == 0)
		var is_sputter: bool = player_w is Sputtering_type_artillery or (not is_multi and randi() % 3 == 0)
		var rand_time: int = get_random(1, 5)

		if is_multi:
			candidate = Multi_target_missile.new()
			candidate.damage = get_random(4, 9)*(1+0.1*Profile.item.finished_times)
			candidate.time = rand_time
			candidate.max_time = rand_time
			candidate.firebomb = Firebomb.new()
			candidate.flashbang = FlashBang.new()
			candidate.flare = Flare.new()
		elif is_sputter:
			candidate = Sputtering_type_artillery.new()
			candidate.damage = get_random(4, 9)*(1+0.1*Profile.item.finished_times)
			candidate.time = rand_time
			candidate.max_time = rand_time
			candidate.sputter_range = get_random(1, 3)
			candidate.firebomb = Firebomb.new()
			candidate.flashbang = FlashBang.new()
			candidate.flare = Flare.new()
		else:
			candidate = Shelling.new()
			candidate.damage = get_random(4, 9)*(1+0.1*Profile.item.finished_times)
			candidate.time = rand_time
			candidate.max_time = rand_time
			candidate.firebomb = Firebomb.new()
			candidate.flashbang = FlashBang.new()
			candidate.flare = Flare.new()

		# 随机属性弹可用性
		candidate.firebomb.isCanBeUsed = randi() % 2 == 0
		candidate.flashbang.isCanBeUsed = randi() % 2 == 0
		candidate.flare.isCanBeUsed = randi() % 2 == 0

		var score: int = (candidate.damage - player_w.damage) * 2
		# 等待回合越少越好
		score += (player_w.max_time - candidate.max_time) * 15
		# 属性弹加分
		if candidate.firebomb.isCanBeUsed and not player_w.firebomb.isCanBeUsed:
			score += 20
		if candidate.flashbang.isCanBeUsed and not player_w.flashbang.isCanBeUsed:
			score += 20
		if candidate.flare.isCanBeUsed and not player_w.flare.isCanBeUsed:
			score += 20
		# 多目标/溅射加分
		if candidate is Multi_target_missile and not (player_w is Multi_target_missile):
			score += 25
		if candidate is Sputtering_type_artillery and not (player_w is Sputtering_type_artillery):
			score += 25

		if score > best_score:
			best_score = score
			best = candidate

	if best == null:
		best = Shelling.new()
		best.damage = get_random(4, 8)*(1+0.1*Profile.item.finished_times)
		best.time = get_random(3, 10)
		best.max_time = best.time
		best.firebomb = Firebomb.new()
		best.flashbang = FlashBang.new()
		best.flare = Flare.new()
	best.code="SG-"
	if best is Multi_target_missile:
		best.code="MTM-"
	elif best is Sputtering_type_artillery:
		best.code="STA-"
	best.code+=str(get_random(10000, 99999))
	return best
func start_new():
	initial_player()
	enemy.clear()
	enemy.resize(4)
	#enemy[0]=Test_Melee.new()
	#enemy[1]=Test_Shoot.new()
	CharacterArray.clear()
	CharacterArray.append(player)
	create_initial_deck()
func lock_enemy_array():
	CharacterArray.clear()
	CharacterArray.append(player)
	var step=item.finished_times
	if step>enemy_seed_list.size():
		step=enemy_seed_list.size()
	for i in enemy_seed_list[step]:
		print("加入敌人")
		var en=i.deploy()
		en.upgrade()
		CharacterArray.append(en)
	print("角色数量为"+str(CharacterArray.size()))
class TimeRecorder:
	var start_time: int
	var current_time:int=0
	func _init() -> void:
		start_time = Time.get_ticks_msec()
	func get_elapsed_time() -> int:
		return Time.get_ticks_msec() - start_time+current_time
	func reset():
		start_time = Time.get_ticks_msec()
	func set_current_time(value:int):
		current_time=value
	func get_time()->String:
		var total_seconds = get_elapsed_time()/1000
		var hours = total_seconds / 3600
		var minutes = (total_seconds % 3600) / 60
		var secs = total_seconds % 60
		return "%02dh:%02dm:%02ds" % [hours, minutes, secs]
func function_factory(value:function)->function:#模组工厂函数
	if value is Card.Forward:
		return Card.Forward.new()
	elif value is Card.Backward:
		return Card.Backward.new()
	elif value is Card.Discard_one:
		return Card.Discard_one.new()
	elif value is Card.Discard_two:
		return Card.Discard_two.new()
	elif value is Card.Draw_one:
		return Card.Draw_one.new()
	elif value is Card.Draw_two:
		return Card.Draw_two.new()
	elif value is Card.Draw_three:
		return Card.Draw_three.new()
	elif value is Card.Load:
		return Card.Load.new()
	elif value is Card.Replace:
		return Card.Replace.new()
	elif value is Card.Swipe:
		return Card.Swipe.new()
	elif value is Card.Turn:
		return Card.Turn.new()
	elif value is Card.Blank:
		return Card.Blank.new()
	elif value is Card.Lock:
		return Card.Lock.new()
	elif value != null:
		return create_function(value.mode)
	return null
