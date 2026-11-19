extends CanvasLayer
class_name Main_menu
var card_manager:Card_Manager
var Character_list:Array
var CharacterArray:Array
var playerNeedWaitTime:int
var enemyNeedWaitTime:int
var playerIsTarget:bool#玩家被敌人导弹锁定了
var enemyIsTarget:bool#敌人被玩家导弹锁定了
var battle_actors:Node2D
const UI_Z_INDEX:int = 100
@export var state_bar:State_bar
@export var ground:ColorRect
@export var playerItem:PanelContainer
@export var cmd_page:TextureRect
@export var final_report:Report
var money_reward:int=3
#保存三种类型武器原有伤害
var melee_damage:int
var shoot_damage:int
var shelling_damage:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerIsTarget=false
	enemyIsTarget=false
	await get_tree().process_frame
	# 所有背景层和容器设为鼠标穿透，不拦截鼠标事件
	var bg: TextureRect = get_node("TextureRect") as TextureRect
	if bg:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for child: Node in bg.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_manager = get_node("Card_manager") as Card_Manager
	battle_actors = _create_battle_actors()
	state_bar.z_index = UI_Z_INDEX
	playerItem.z_index = UI_Z_INDEX
	Profile.lock_enemy_array()
	Character_list=Profile.CharacterArray
	deployCharacter()
	CharacterArray[1].isAimed=true
	show_player_hit_range()
	show_enemy_hit_range(CharacterArray[1])
	CharacterArray[1].place.isAimed()
	card_manager.Fight_Menu=self
	card_manager.draw_deck_button.pressed.connect(check_draw_deck)
	card_manager.discard_deck_button.pressed.connect(check_discard_deck)
	card_manager.consume_deck_button.pressed.connect(check_consume_deck)
	enemy_is_locked(CharacterArray[1])
	playerItem.set_money(Profile.item.money)
	await show_turn_title("玩家回合")
	card_manager.draw_cards(7)
	card_manager.show_finished_button()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_refresh_actor_z_order()

## 角色放在战场背景内，使用小范围相对 z 值排序；所有 UI 保持在更高层。
func _create_battle_actors() -> Node2D:
	var actors: Node2D = Node2D.new()
	actors.name = "BattleActors"
	actors.z_index = 0
	ground.add_child(actors)
	return actors

func _refresh_actor_z_order() -> void:
	var player_faction: Array[Character] = []
	var enemy_faction: Array[Character] = []
	for character in CharacterArray:
		if character is not Character or character.setting == null:
			continue
		if _is_player_faction(character as Character):
			player_faction.append(character as Character)
		else:
			enemy_faction.append(character as Character)
	player_faction.sort_custom(_sort_characters_by_x)
	enemy_faction.sort_custom(_sort_characters_by_x)
	_apply_actor_z_order(player_faction, false)
	_apply_actor_z_order(enemy_faction, true)

func _sort_characters_by_x(left: Character, right: Character) -> bool:
	return left.global_position.x < right.global_position.x

## 玩家阵营使用 x 排序；敌方使用 -x 排序（越靠左越在上层）。
func _apply_actor_z_order(characters: Array[Character], left_is_above: bool) -> void:
	for index in range(characters.size()):
		var z_order: int = characters.size() - index if left_is_above else index + 1
		characters[index].z_index = z_order

func _is_player_faction(character: Character) -> bool:
	return character != null and character.setting != null and character.setting.faction == Profile.Faction.PLAYER

func _are_allies(first: Character, second: Character) -> bool:
	return first != null and second != null and first.setting != null and second.setting != null and first.setting.faction == second.setting.faction
func locate(value:int)->Position:#绑定位置块
	if value < 1 or value > 11:
		return null
	return ground.get_child(0).get_child(value - 1) as Position
func deployCharacter():
	for _i in Character_list:
		var CharacterScene=preload("res://scenes/character.tscn")
		var role=CharacterScene.instantiate() as Character
		battle_actors.add_child(role)
		role.setting=_i as Profile.Role
		role.sprite.texture=load(role.setting.pic_path)
		role.place=locate(role.getIndex())
		role.name=role.setting.Rname
		role.stayGround()
		CharacterArray.append(role)
		role.I_is_aimed.connect(enemy_is_locked)
		role.Show_info.connect(state_bar.show_information)
		role.Ishitted.connect(fresh_state_bar)
		role.Died.connect(_on_character_died)
		role.shoot_or_shell_need_fresh.connect(shoot_or_shell_need_fresh)
	#对于玩家攻击的初始化
	if CharacterArray[0].setting is Profile.Player:
		melee_damage=CharacterArray[0].setting.melee.damage
		shoot_damage=CharacterArray[0].setting.shoot.damage
		shelling_damage=CharacterArray[0].setting.shelling.damage
		CharacterArray[0].setting.attack_mode=CharacterArray[0].setting.melee
func show_player_hit_range():
	var player:Character=CharacterArray[0] as Character
	if player!=null:
		if CharacterArray.size()>1:
			var mode=player.setting.attack_mode
			if mode is Melee:
				var hit_range=mode.range
				if hit_range>0:
					var places=ground.get_child(0).get_children()
					var index=places.find(player.place)
					if hit_range+index>=places.size():
						hit_range=places.size()-index-1
					for i in range(hit_range):
						places[index+i+1].Player_turn_danger(0)
			elif mode is Shoot:
				if mode is Through_shoot:
					var through_level=mode.level
					if through_level>0:
						var num=min(through_level+1,CharacterArray.size()-1)
						for i in range(num):
							CharacterArray[i+1].place.Player_turn_danger(0)
					print()
				else:
					var enemy=CharacterArray[1] as Character
					if enemy!=null:
						enemy.place.Player_turn_danger(0)
			elif mode is Shelling:
				var shelling_mode := mode as Shelling
				if enemyIsTarget:#瞄准期间仅显示攻击范围，不显示倒计时
					if mode is Multi_target_missile:
						# 打击型：锁定所有敌人
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.setting is Profile.Player:
								continue
							_i.place.Player_turn_danger(0, false)
					elif mode is Sputtering_type_artillery:
						# 溅射型：锁定目标 + 向左右扩散溅射范围
						var aimedCharacter:Character
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.isAimed and _i.setting is not Profile.Player:
								_i.place.Player_turn_danger(0, false)
								aimedCharacter=_i
								break
						if aimedCharacter != null:
							var places=ground.get_child(0).get_children()
							var index=places.find(aimedCharacter.place)
							for i in range(index+1, min(index+shelling_mode.sputter_range+1, places.size())):
								places[i].Player_turn_danger(0, false)
							for i in range(max(0, index-shelling_mode.sputter_range), index):
								places[i].Player_turn_danger(0, false)
					else:
						# 普通型：锁定目标，可追踪
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.isAimed and _i.setting is not Profile.Player:
								_i.place.Player_turn_danger(0, false)
								_i.viscosity=true
								break
				else:
					clear_player_range()#清空范围不显示攻击范围
			else:
				print("攻击模式不正确")
func show_enemy_hit_range(character:Character):
	if character!=null:
		var mode=character.setting.attack_mode
		if mode is Melee:
			var hit_range=mode.range
			var places=ground.get_child(0).get_children()
			var index=places.find(character.place)
			if index-hit_range<0:
				hit_range=index
			for i in range(hit_range):
				places[index-i-1].Enemy_turn_danger(0)
		elif mode is Shoot:
			var player=CharacterArray[0] as Character
			if player!=null:
				player.place.Enemy_turn_danger(0)
		elif mode is Shelling:
			# 敌人炮击瞄准期间仅显示危险区域，不显示倒计时。
			var player=CharacterArray[0] as Character
			if player!=null:
				player.place.Enemy_turn_danger(0, false)
func enemy_is_locked(character:Character):#锁定目标并显示其攻击范围
	clear_aimed()
	clear_enemy_range()
	for c in CharacterArray:
		if c is not Character:
			continue
		if c.setting is Profile.Player:
			continue
		c.isAimed=false
	character.isAimed=true
	await character.place.isAimed()
	show_enemy_hit_range(character)
	show_damage_text(character)
	state_bar.show_information(character)
func clear_aimed():#清除所有的选中框
	var places=ground.get_child(0).get_children()
	for _i in places:
		_i.is_not_aimed()
	for c in CharacterArray:
		if c is Character and c.setting is not Profile.Player:
			c.isAimed=false
func clear_enemy_range():
	var places=ground.get_child(0).get_children()
	for _i in places:
		_i.PlayerbecomeSafe()
func clear_player_range():
	var places=ground.get_child(0).get_children()
	for _i in places:
		_i.EnemybecomeSafe()
func fresh_player_range():
	clear_player_range()
	show_player_hit_range()
## 刷新所有敌人的攻击范围显示（玩家移动后调用，确保远程判定跟随新位置）
func show_enemy_hit_range_for_all():
	clear_enemy_range()
	for c in CharacterArray:
		if c is not Character:
			continue
		if c.setting is Profile.Player:
			continue
		if c.setting.health <= 0:
			continue
		if c.isAimed:
			show_enemy_hit_range(c)
			break
## 在指定敌人头顶显示伤害预览文本
func show_damage_text(enemy: Character) -> void:
	_hide_all_damage_preview()
	var mode = enemy.setting.attack_mode
	var damage := 0
	damage=mode.damage
	enemy.show_damage_preview(damage)
## 隐藏所有角色的伤害预览文本
func _hide_all_damage_preview() -> void:
	for c in CharacterArray:
		if c is Character:
			c.hide_damage_preview()
func get_enemy_at(pos: Position) -> Character:
	for c in CharacterArray:
		if c.place == pos and c.setting is not Profile.Player:
			return c
	return null
## 移动角色，direction: 1=右移，-1=左移
## 先尝试原方向，不行反弹到反方向，两边都被挡则无法移动
func move_character(character: Character, direction: int) -> bool:
	var places: Array = ground.get_child(0).get_children()
	var current_index: int = places.find(character.place)
	if current_index == -1:
		return false
	var target_index: int = current_index + direction
	# 先尝试原方向
	clear_player_range()
	var moved: bool = await _try_move_to_index(target_index, character, places)
	if moved:
		show_player_hit_range()
		# 玩家移动后刷新敌人攻击范围显示，让远程/近战判定跟随新位置
		if character.setting is Profile.Player:
			show_enemy_hit_range_for_all()
		return true
	# 原方向走不了，反弹到反方向
	var reverse_index: int = current_index - direction
	moved = await _try_move_to_index(reverse_index, character, places)
	if moved:
		show_player_hit_range()
		if character.setting is Profile.Player:
			show_enemy_hit_range_for_all()
		return true
	# 两边都被挡，无法移动
	print(str(character.name) + " 无法移动")
	show_player_hit_range()
	return false
## 尝试移动至目标位置；同阵营角色占位时同步换位，敌对阵营仍不可穿越。
func _try_move_to_index(index: int, mover: Character, places: Array) -> bool:
	if index < 0 or index >= places.size():
		return false
	var target_pos: Position = places[index]
	var occupant: Character = _get_character_at(target_pos, mover)
	if occupant == null:
		await _do_move(mover, target_pos)
		return true
	if _are_allies(mover, occupant):
		await _swap_character_positions(mover, occupant)
		return true
	return false

func _get_character_at(target_pos: Position, excluded: Character) -> Character:
	for character in CharacterArray:
		if character is Character and character != excluded and character.place == target_pos:
			return character as Character
	return null
## 执行移动动画并更新 place 引用
func _do_move(character: Character, target_place: Position) -> void:
	character.place = target_place
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "global_position",
		target_place.global_position + Vector2(70, -70), 0.2)
	await tween.finished
	_handle_character_position_changed(character)

func _swap_character_positions(first: Character, second: Character) -> void:
	var first_place: Position = first.place
	var second_place: Position = second.place
	if first_place == null or second_place == null:
		return
	first.place = second_place
	second.place = first_place
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(first, "global_position", second_place.global_position + Vector2(70, -70), 0.2)
	tween.tween_property(second, "global_position", first_place.global_position + Vector2(70, -70), 0.2)
	await tween.finished
	_handle_character_position_changed(first)
	_handle_character_position_changed(second)

func _handle_character_position_changed(character: Character) -> void:
	# 追踪炮击移动后保留瞄准；非追踪炮击移动后取消瞄准。
	if character.setting.attack_mode is Shelling:
		var shelling := character.setting.attack_mode as Shelling
		if shelling is Multi_target_missile or shelling is Sputtering_type_artillery:
			_cancel_shelling_aim(character)
func execute_attack(attacker:Character = CharacterArray[0] as Character):#统一入口：造成伤害 + 更新血条
	await causeDamage(attacker)
func causeDamage(attacker:Character = CharacterArray[0] as Character):#通用伤害函数，默认为玩家
	var mode=attacker.setting.attack_mode
	var is_player = attacker.setting is Profile.Player
	if is_player:
		await _player_causeDamage(mode)
	else:
		await _enemy_causeDamage(attacker)
func _player_causeDamage(mode:Attack):#玩家攻击逻辑
	Profile.item.attack_times+=1
	if mode is Shoot:
		# 检查玩家是否被致盲
		var blinded:Buff=CharacterArray[0].get_buff("Blinded")
		var actual_probability:int=mode.probability
		if blinded!=null:
			actual_probability=max(0, mode.probability - 15*blinded.level)
		if mode is Through_shoot:
			var times=min(CharacterArray.size()-1,mode.level+1)
			for i in range(times):
				var hit:bool=CharacterArray[i+1].isShot(mode.damage,actual_probability)
				if not hit:
					# 未命中，攻击者自加易伤
					_add_buff_to_character(CharacterArray[0],"Fragile",1)
				await get_tree().create_timer(0.5).timeout
		else:
			var enemy=CharacterArray[1] as Character
			if enemy!=null:
				var hit:bool=enemy.isShot(mode.damage,actual_probability)
				if not hit:
					_add_buff_to_character(CharacterArray[0],"Fragile",1)
				await get_tree().create_timer(0.5).timeout
			else:
				await get_tree().create_timer(0.2).timeout
	elif mode is Shelling:
		# 首次 Swipe 进入瞄准；瞄准期间的后续 Swipe 直接失效。
		if enemyIsTarget:
			return
		enemyIsTarget=true
		_add_buff_to_character(CharacterArray[0] as Character, Buff.TYPE_LOCK, mode.time)
		show_player_hit_range()
	elif mode is Melee:
		var uflag=false
		# 检查过热：近战范围减少，攻击力增加
		var overheated:Buff=CharacterArray[0].get_buff("Overheated")
		var actual_range:int=mode.range
		var actual_damage:int=mode.damage
		if overheated!=null:
			actual_range=max(1, mode.range - overheated.level)
			if actual_range>0:
				actual_damage=mode.damage + mode.damage/actual_range
		var targets:=CharacterArray.duplicate()
		for _i in targets:
			if _i is not Character:
				continue
			if _i.setting is Profile.Player:
				continue
			if _i.setting.health<=0:
				continue
			if _i.place.EnemyisDangerous:
				if not uflag:
					uflag=true
				_i.ishitted(actual_damage)
		if uflag:
			await get_tree().create_timer(0.5).timeout
	else:
		print("没有任何敌人受到伤害")
		await get_tree().create_timer(0.2).timeout
## 玩家炮击发射：独立函数，供 _player_causeDamage 和 trigger_shelling_attacks 共用
func _player_shelling_fire(mode: Shelling) -> void:
	enemyIsTarget=false
	for _c in CharacterArray:
		if _c.place.EnemyisDangerous:
			_c.ishitted(mode.damage)
			# 对每个被炮击命中的敌人施加属性弹buff
			_apply_missile_buff(mode, _c)
	fresh_player_range()
	state_bar.refresh_shelling_mode_label(CharacterArray[0] as Character)
	await get_tree().create_timer(0.3).timeout
func _enemy_shelling_fire(attacker: Character, mode: Shelling) -> void:
	var player: Character = CharacterArray[0] as Character
	var can_hit: bool = _can_shelling_hit_player(attacker)
	_cancel_shelling_aim(attacker)
	if can_hit and player != null:
		player.ishitted(mode.damage)
		_apply_missile_buff(mode, player)
		await get_tree().create_timer(0.5).timeout
	else:
		print(attacker.setting.Rname + "的炮击范围内没有目标")
		await get_tree().create_timer(0.2).timeout
func _cancel_shelling_aim(character: Character) -> void:
	character.remove_buff_by_type(Buff.TYPE_LOCK)
	if character.setting is Profile.Player:
		enemyIsTarget=false
		clear_player_range()
	else:
		var mode: Attack = character.setting.attack_mode
		if mode is Shelling:
			(mode as Shelling).is_targeting=false
		clear_enemy_range()
	if character == state_bar.current_role:
		state_bar.refresh_buff_basket(character)
	state_bar.refresh_shelling_mode_label(character)
func _finish_shelling_turn(character: Character) -> void:
	var mode: Attack = character.setting.attack_mode
	var is_aiming: bool = enemyIsTarget if character.setting is Profile.Player else mode is Shelling and (mode as Shelling).is_targeting
	if not is_aiming:
		return
	if character.tick_lock_buff_on_turn_end() and character == state_bar.current_role:
		state_bar.refresh_buff_basket(character)
	state_bar.refresh_shelling_mode_label(character)
func _enemy_causeDamage(attacker:Character):#敌人攻击逻辑，用 index 计算判定
	var player=CharacterArray[0] as Character
	if player==null:
		return
	var mode=attacker.setting.attack_mode
	var hit=false
	if mode is Shoot:
		# 检查敌人是否被致盲
		var blinded:Buff=attacker.get_buff("Blinded")
		var actual_probability:int=mode.probability
		if blinded!=null:
			actual_probability=max(0, mode.probability - 15*blinded.level)
		if _can_shoot_hit_player(attacker):
			var shot_hit:bool=player.isShot(mode.damage,actual_probability)
			if not shot_hit:
				# 未命中，攻击者自加易伤
				_add_buff_to_character(attacker,"Fragile",1)
			hit=true
	elif mode is Melee:
		# 检查敌人过热
		var overheated:Buff=attacker.get_buff("Overheated")
		var actual_damage:int=mode.damage
		var actual_range:int=mode.range
		if overheated!=null:
			actual_range=max(1, mode.range - overheated.level)
			if actual_range>0:
				actual_damage=mode.damage + mode.damage/actual_range
		if _can_melee_hit_player(attacker):
			player.ishitted(actual_damage)
			hit=true
	elif mode is Shelling:
		# 首次炮击行动进入瞄准；瞄准期间不重复添加或重置 Buff。
		if !mode.is_targeting:
			mode.is_targeting=true
			_add_buff_to_character(attacker, Buff.TYPE_LOCK, mode.time)
			show_enemy_hit_range(attacker)
	if hit:
		await get_tree().create_timer(0.5).timeout
	else:
		print(attacker.setting.Rname + "的攻击范围内没有目标")
		await get_tree().create_timer(0.2).timeout
func change_player_mode():#改变玩家攻击模式
	if CharacterArray[0].setting is Profile.Player:
		var player: Character = CharacterArray[0] as Character
		if enemyIsTarget:
			_cancel_shelling_aim(player)
		var trans_mode:Attack
		if CharacterArray[0].setting.attack_mode is Melee:
			trans_mode=CharacterArray[0].setting.shoot
		elif CharacterArray[0].setting.attack_mode is Shoot:
			trans_mode=CharacterArray[0].setting.shelling
		elif CharacterArray[0].setting.attack_mode is Shelling:
			trans_mode=CharacterArray[0].setting.melee
		if trans_mode!=null:
			CharacterArray[0].setting.attack_mode=trans_mode
			fresh_player_range()
			if state_bar.current_role==player:
				state_bar.change_mode(trans_mode)
				await state_bar.fresh_mode(trans_mode, player)
			
		else:
			print("转化的攻击模式是空的")
	else:
		print("玩家无需转变攻击模式")
func fresh_state_bar(character:Character, damage:int):
	if character==state_bar.current_role:
		state_bar.decrease_health(damage)

## 敌人死亡后，若当前锁定目标是该敌人，自动转移到邻近的存活敌人
func _on_character_died(dead: Character):
	# 玩家死亡 → 清除所有攻击判定，弹出失败界面
	if dead.setting is Profile.Player:
		dead.hide_damage_preview()
		clear_aimed()         # 清锁定红框
		clear_enemy_range()   # 清玩家攻击判定
		clear_player_range()  # 清敌人攻击判定
		CharacterArray.erase(dead)
		Profile.item.isAlive=false#角色死亡
		final_report.open_page(false)
		return
	# 敌人死亡：结算金钱奖励
	Profile.item.money += dead.setting.reward * (1 + 0.1 * money_reward)
	playerItem.set_money(Profile.item.money)
	Profile.item.enemy_kill+=1
	dead.hide_damage_preview()
	CharacterArray.erase(dead)
	# 检查是否还有存活敌人
	var has_enemy: bool = false
	for c in CharacterArray:
		if c is Character and c.setting is not Profile.Player:
			has_enemy = true
			break
	if not has_enemy:
		# 所有敌人都死了 → 胜利
		print("所有敌人已被清楚")
		clear_aimed()
		clear_enemy_range()
		back_damage()
		final_report.open_page(true)
		return
	if not dead.isAimed:
		return  # 死的不是锁定目标，无需转移
	var places: Array = ground.get_child(0).get_children()
	var dead_idx: int = places.find(dead.place)
	if dead_idx == -1:
		return
	# 优先找位置最近的存活敌人（先右后左）
	var closest: Character = null
	var closest_dist: int = 999
	for c in CharacterArray:
		if c is not Character:
			continue
		if c == dead or c.setting is Profile.Player:
			continue
		if c.setting.health <= 0:
			continue
		var c_idx: int = places.find(c.place)
		if c_idx == -1:
			continue
		var dist: int = abs(c_idx - dead_idx)
		if dist < closest_dist:
			closest_dist = dist
			closest = c
	if closest != null:
		enemy_is_locked(closest)
	else:
		clear_aimed()
		clear_enemy_range()
func back_damage():#还原三种模式的伤害
	var player=Profile.player
	player.melee.damage=melee_damage
	player.shoot.damage=shoot_damage
	player.shelling.damage=shelling_damage
	print("伤害都被还原了")
# ============================================================
# 敌人 AI 系统
# 判定全部基于位置块 index 差值计算，不依赖 PlayerisDangerous
# PlayerisDangerous 仅用于 UI 警告显示
# ============================================================

## 获取位置块数组
func _get_places() -> Array:
	return ground.get_child(0).get_children()

## 获取角色所在的位置块 index
func _get_place_index(character: Character) -> int:
	return _get_places().find(character.place)

## 判断某敌人能否用当前近战攻击命中玩家
func _can_melee_hit_player(enemy: Character) -> bool:
	var player: Character = CharacterArray[0]
	var places: Array = _get_places()
	var enemy_idx: int = places.find(enemy.place)
	var player_idx: int = places.find(player.place)
	if enemy_idx == -1 or player_idx == -1:
		return false
	var melee_range: int = (enemy.setting.attack_mode as Melee).range
	var dist: int = enemy_idx - player_idx
	return dist > 0 and dist <= melee_range

## 判断某敌人能否用射击命中玩家（射击无视距离，只检查友军遮挡）
## TODO: 后续加入友军遮挡判定
func _can_shoot_hit_player(enemy: Character) -> bool:
	return true  # 射击型暂时默认能命中（无遮挡机制时）

## 判断某敌人能否用炮击命中玩家（炮击锁定中视为能命中）
func _can_shelling_hit_player(enemy: Character) -> bool:
	return enemy.viscosity or enemy.place.PlayerisDangerous

## 判断某个敌人能否打到玩家
func _can_hit_player(enemy: Character) -> bool:
	var mode = enemy.setting.attack_mode
	if mode is Melee:
		return _can_melee_hit_player(enemy)
	elif mode is Shoot:
		return _can_shoot_hit_player(enemy)
	elif mode is Shelling:
		return _can_shelling_hit_player(enemy)
	return false

## 敌人回合入口，逐个执行所有敌人的行动
func all_enemies_turn() -> void:
	# 从 CharacterArray[1] 开始，跳过玩家（index 0）
	for i in range(1, CharacterArray.size()):
		var enemy: Character = CharacterArray[i] as Character
		if enemy == null or enemy.setting is Profile.Player:
			continue
		if enemy.setting.health <= 0:
			continue
		await enemy_turn(enemy)
		await get_tree().create_timer(0.3).timeout

## 显示回合标题，动画播完才返回
func show_turn_title(text_value: String) -> void:
	var title: Label = preload("res://scenes/Effects/turn_title.tscn").instantiate() as Label
	if title == null:
		return
	title.z_index = UI_Z_INDEX
	title.set_turn_text(text_value)
	add_child(title)
	await title.finished

## 单个敌人行动分发
func enemy_turn(enemy: Character) -> void:
	var e := enemy.setting as Profile.Enemy
	if e == null:
		return
	print(e.Rname + " 开始行动")
	await trigger_shelling_attacks(enemy)
	clear_enemy_range()  # 自动炮击结算后清理旧范围，再展示本次行动的范围
	match e.behavior:
		Profile.EnemyBehavior.BASIC_MELEE:
			await _ai_basic_melee(enemy)
		Profile.EnemyBehavior.BASIC_SHOOT:
			await _ai_basic_shoot(enemy)
		Profile.EnemyBehavior.BASIC_SHELLING:
			await _ai_basic_shelling(enemy)
		Profile.EnemyBehavior.IMMOVABLE:
			await _ai_immovable(enemy)
		Profile.EnemyBehavior.MUTANT:
			await _ai_mutant(enemy)
		_:
			await _ai_basic_melee(enemy)
	clear_enemy_range()  # 该敌人行动完毕，清理范围标记

## 计算队友（射击/炮击）的最大潜在伤害。
## 炮击仅在瞄准态且 Lock Buff 已耗尽时，会在该角色回合开始自动发射。
func _calc_teammate_total_damage(enemy: Character) -> int:
	var total_damage: int = 0
	for i in range(1, CharacterArray.size()):
		if i == CharacterArray.find(enemy):
			continue  # 跳过自己
		var teammate: Character = CharacterArray[i] as Character
		if teammate == null:
			continue
		var mode = teammate.setting.attack_mode
		if mode is Shoot:
			# 用命中率随机判定：随机数落在 [0, probability) 内则命中
			if Profile.rng.randi_range(0, 99) < mode.probability:
				total_damage+= mode.damage
		elif mode is Shelling:
			if mode.is_targeting and teammate.get_buff(Buff.TYPE_LOCK) == null:
				total_damage+=mode.damage
	return total_damage

## 基础近战 AI：
## 能打到玩家时：判断队友伤害是否更高，是则移动压位，否则攻击
## 打不到时：向玩家移动一格
func _ai_basic_melee(enemy: Character) -> void:
	if _can_hit_player(enemy):
		var my_mode: Melee = enemy.setting.attack_mode as Melee
		var my_damage: int = my_mode.damage if my_mode != null else 0
		var teammate_max_damage: int = _calc_teammate_total_damage(enemy)

		if teammate_max_damage > my_damage and CharacterArray[0].setting.attack_mode==Melee:
			# 当玩家是近战攻击时，队友潜在伤害更高，移动压位（自己仍在攻击范围内）
			show_enemy_hit_range(enemy)
			await move_character(enemy, -1)
		else:
			# 自己打更有价值
			show_enemy_hit_range(enemy)
			await execute_attack(enemy)
	else:
		await move_character(enemy, -1)

## 基础射击 AI：永远不移动，直接攻击
func _ai_basic_shoot(enemy: Character) -> void:
	show_enemy_hit_range(enemy)
	await execute_attack(enemy)

## 基础炮击 AI：永远不移动，锁定后触发
func _ai_basic_shelling(enemy: Character) -> void:
	show_enemy_hit_range(enemy)
	await execute_attack(enemy)

## 不可移动型 AI：不移动，直接攻击
func _ai_immovable(enemy: Character) -> void:
	show_enemy_hit_range(enemy)
	await execute_attack(enemy)

## 变异体 AI：近战/射击双模式，打不到当前模式就切换
func _ai_mutant(enemy: Character) -> void:
	if _can_hit_player(enemy):
		show_enemy_hit_range(enemy)
		await execute_attack(enemy)
		return
	# 尝试切换到备用攻击模式
	var e := enemy.setting as Profile.Enemy
	# TODO: 变异体需要持有备用攻击模式引用，切换逻辑待实现
	# 切换后刷新攻击范围，再判定一次
func confirm_aimed_target()->int:#获取玩家所指的位置
	for c in CharacterArray:
		if c is not Character:
			continue
		if c.setting is Profile.Player:
			continue
		if c.isAimed:
			var n=CharacterArray.find(c)
			return n
	return -1
func Turn_for_enemys():#进入敌人的回合
	if money_reward>0:
		money_reward-=1
	# 敌人buff回合开始递减
	for _c in CharacterArray:
		if _c is not Character:
			continue
		if _c.setting is Profile.Player:
			continue
		var changed:bool=_c.tick_buffs()
		if changed and _c==state_bar.current_role:
			state_bar.refresh_buff_basket(_c)
		if changed:
			state_bar.refresh_shelling_mode_label(_c)
	await show_turn_title("敌人回合")
	var m=confirm_aimed_target()
	for enemy in CharacterArray:
		if enemy.setting is not Profile.Player:
			enemy_is_locked(enemy)
			await enemy_turn(enemy)
			_finish_shelling_turn(enemy)
			await get_tree().create_timer(0.2).timeout
	if m != -1 and m < CharacterArray.size():#当玩家死亡时，代码运行出现了问题
		enemy_is_locked(CharacterArray[m])
	else:
		print("不存在任何可锁定目标")
	Turn_for_player()
## 角色回合开始时，瞄准态但 Lock Buff 已消失则自动发射。
func trigger_shelling_attacks(character:Character) -> void:
	var mode: Attack = character.setting.attack_mode
	if mode is not Shelling:
		return
	if character.get_buff(Buff.TYPE_LOCK) != null:
		return
	if character.setting is Profile.Player:
		if enemyIsTarget:
			await _player_shelling_fire(mode as Shelling)
	else:
		if (mode as Shelling).is_targeting:
			await _enemy_shelling_fire(character, mode as Shelling)
func Turn_for_player():
	# 玩家buff回合开始递减
	var player:Character=CharacterArray[0] as Character
	if player!=null:
		var changed:bool=player.tick_buffs()
		if changed and player==state_bar.current_role:
			state_bar.refresh_buff_basket(player)
		if changed:
			state_bar.refresh_shelling_mode_label(player)
	Profile.last_round_missed = Profile.miss_times > 0
	Profile.miss_times = 0
	await show_turn_title("玩家回合")
	await trigger_shelling_attacks(CharacterArray[0])
	await card_manager.draw_cards(7)
	card_manager.show_finished_button()
func shoot_or_shell_need_fresh(character:Character):#射击情况下一个玩家死亡后需要重新更新玩家的攻击判定
	if CharacterArray[0].setting.attack_mode is Shoot or character.viscosity:
		fresh_player_range()
func check_draw_deck():
	if card_manager.deck.size()>0:
		cmd_page.deck=card_manager.deck
		cmd_page.open_page("draw_deck")
func check_discard_deck():
	if card_manager.discard_deck.size()>0:
		cmd_page.deck=card_manager.discard_deck
		cmd_page.open_page("discard_deck")
func check_consume_deck():
	if card_manager.consume_deck.size()>0:
		cmd_page.deck=card_manager.consume_deck
		cmd_page.open_page("consume_deck")
## ============ BUFF 辅助函数 ============
## 创建并给角色添加指定类型的buff，叠层处理由add_buff负责
func _add_buff_to_character(character:Character, buff_type:String, level:int) -> void:
	var buff_scene:=preload("res://scenes/buff.tscn")
	var buff:Buff=buff_scene.instantiate() as Buff
	buff.setup_by_type(buff_type)
	buff.level=level
	character.add_buff(buff)
	# 如果该角色是当前state_bar选中的目标，刷新UI
	if character==state_bar.current_role:
		state_bar.refresh_buff_basket(character)
	state_bar.refresh_shelling_mode_label(character)
## 根据炮击的current_missile给被命中一方施加对应属性弹buff
func _apply_missile_buff(mode:Shelling, target:Character) -> void:
	if mode.current_missile==null:
		return
	if target==null:
		return
	if mode.current_missile is Firebomb and mode.firebomb.isCanBeUsed:
		_add_buff_to_character(target,"Overheated",1)
	elif mode.current_missile is FlashBang and mode.flashbang.isCanBeUsed:
		_add_buff_to_character(target,"Blinded",1)
	elif mode.current_missile is Flare and mode.flare.isCanBeUsed:
		_add_buff_to_character(target,"Dud",1)
