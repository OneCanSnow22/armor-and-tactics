extends CanvasLayer
class_name Main_menu
var card_manager:Card_Manager
var Character_list:Array
var CharacterArray:Array
var playerNeedWaitTime:int
var enemyNeedWaitTime:int
var playerIsTarget:bool#玩家被敌人导弹锁定了
var enemyIsTarget:bool#敌人被玩家导弹锁定了
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
func _process(delta: float) -> void:
	pass
func locate(value:int)->Position:#绑定位置块
	if value < 1 or value > 11:
		return null
	return ground.get_child(0).get_child(value - 1) as Position
func deployCharacter():
	for _i in Character_list:
		var CharacterScene=preload("res://scenes/character.tscn")
		var role=CharacterScene.instantiate() as Character
		ground.add_child(role)
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
				# 哑火检查：每层Dud让炮击显示的等待回合数
				var dud:Buff=CharacterArray[0].get_buff("Dud")
				var extra_wait:int=0
				if dud!=null:
					extra_wait=dud.level
				var display_time:int=shelling_mode.current_time+extra_wait
				if enemyIsTarget:#只有攻击模组触发后开始显示攻击范围，并会随回合数更新
					if mode is Multi_target_missile:
						# 打击型：锁定所有敌人
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.setting is Profile.Player:
								continue
							_i.place.Player_turn_danger(display_time)
					elif mode is Sputtering_type_artillery:
						# 溅射型：锁定目标 + 向左右扩散溅射范围
						var aimedCharacter:Character
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.isAimed and _i.setting is not Profile.Player:
								_i.place.Player_turn_danger(display_time)
								aimedCharacter=_i
								break
						if aimedCharacter != null:
							var places=ground.get_child(0).get_children()
							var index=places.find(aimedCharacter.place)
							for i in range(index+1, min(index+shelling_mode.sputter_range+1, places.size())):
								places[i].Player_turn_danger(display_time)
							for i in range(max(0, index-shelling_mode.sputter_range), index):
								places[i].Player_turn_danger(display_time)
					else:
						# 普通型：锁定目标，可追踪
						for _i in CharacterArray:
							if _i is not Character:
								continue
							if _i.isAimed and _i.setting is not Profile.Player:
								_i.place.Player_turn_danger(display_time)
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
			# 敌人炮击：显示玩家位置为危险区域，附带等待回合数
			var shelling_mode := mode as Shelling
			# 哑火检查：每层Dud让炮击显示的等待回合数+1
			var dud:Buff=character.get_buff("Dud")
			var extra_wait:int=0
			if dud!=null:
				extra_wait=dud.level
			var display_time:int=shelling_mode.current_time+extra_wait
			var player=CharacterArray[0] as Character
			if player!=null:
				player.place.Enemy_turn_danger(display_time)
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
	if can_move_to(target_index, character, places):
		await _do_move(character, places[target_index])
		show_player_hit_range()
		# 玩家移动后刷新敌人攻击范围显示，让远程/近战判定跟随新位置
		if character.setting is Profile.Player:
			show_enemy_hit_range_for_all()
		return true
	# 原方向走不了，反弹到反方向
	var reverse_index: int = current_index - direction
	if can_move_to(reverse_index, character, places):
		await _do_move(character, places[reverse_index])
		show_player_hit_range()
		if character.setting is Profile.Player:
			show_enemy_hit_range_for_all()
		return true
	# 两边都被挡，无法移动
	print(str(character.name) + " 无法移动")
	show_player_hit_range()
	return false
## 判断目标位置块是否可以移动过去
func can_move_to(index: int, mover: Character, places: Array) -> bool:
	if index < 0 or index >= places.size():
		return false # 超出边界
	var target_pos: Position = places[index]
	for c in CharacterArray:
		if c != mover and c.place == target_pos:
			return false # 被其他角色占据
	return true
## 执行移动动画并更新 place 引用
func _do_move(character: Character, target_place: Position) -> void:
	character.place = target_place
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "global_position",
		target_place.global_position + Vector2(70, -70), 0.2)
	await tween.finished
	# 炮击方移动会重置锁定回合数
	if character.setting.attack_mode is Shelling:
		var shelling := character.setting.attack_mode as Shelling
		if character.setting is Profile.Player:
			# 玩家炮击：重置倒计时 + 清掉已积累的叠加伤害
			if enemyIsTarget:
				shelling.current_time = shelling.time
				shelling.bonus_damage = 0
		else:
			# 敌人炮击：被迫移动时重置锁定状态，无叠加伤害机制
			if shelling.is_targeting:
				shelling.current_time = shelling.time
				shelling.is_targeting = false
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
		# 炮击不立即造成伤害，只更新锁定区域显示
		if !enemyIsTarget:
			enemyIsTarget=true
			mode.current_time=mode.time
			show_player_hit_range()
		#else:
			## 等待期内再次触发攻击模组：累计额外伤害
			#mode.bonus_damage+=mode.damage
			#print("炮击等待期叠加伤害：+" + str(mode.damage) + "，当前bonus=" + str(mode.bonus_damage))
		# 锁定完成时发射（当前回合 current_time 已被 Turn_for_player 递减过）
		if mode.current_time<=0 and enemyIsTarget:
			await _player_shelling_fire(mode)
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
	var total_damage = mode.damage + mode.bonus_damage
	enemyIsTarget=false
	mode.bonus_damage=0
	for _c in CharacterArray:
		if _c.place.EnemyisDangerous:
			_c.ishitted(total_damage)
			# 对每个被炮击命中的敌人施加属性弹buff
			_apply_missile_buff(mode, _c)
	fresh_player_range()
	await get_tree().create_timer(0.3).timeout
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
		# 炮击：每个敌人用自己实例的 is_targeting，不再共用全局变量
		if !mode.is_targeting:
			mode.is_targeting=true
			mode.current_time=mode.time
			if attacker.isAimed:
				show_enemy_hit_range(attacker)
		if mode.is_targeting:
			mode.current_time-=1
			if attacker.isAimed:
				show_enemy_hit_range(attacker)
		if _can_shelling_hit_player(attacker) and mode.current_time<=0:
			mode.is_targeting=false
			player.ishitted(mode.damage)
			# 施加属性弹buff（被命中方是玩家）
			_apply_missile_buff(mode, player)
			hit=true
	if hit:
		await get_tree().create_timer(0.5).timeout
	else:
		print(attacker.setting.Rname + "的攻击范围内没有目标")
		await get_tree().create_timer(0.2).timeout
func change_player_mode():#改变玩家攻击模式
	if CharacterArray[0].setting is Profile.Player:
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
			await state_bar.change_mode(trans_mode)
			
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
	var title := preload("res://scenes/Effects/turn_title.tscn").instantiate()
	title.set_turn_text(text_value)
	add_child(title)
	await title.finished

## 单个敌人行动分发
func enemy_turn(enemy: Character) -> void:
	var e := enemy.setting as Profile.Enemy
	if e == null:
		return
	print(e.Rname + " 开始行动")
	clear_enemy_range()  # 每个敌人行动前清理上一个敌人残留的范围标记
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

## 计算队友（射击/炮击）的最大潜在伤害
## 射击：用命中率随机判定是否命中，命中则取 damage
## 炮击：只考虑即将触发的（current_time <= 1），取 damage + bonus_damage
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
			# 仅考虑下回合即将触发的炮击
			if mode.time == 1:
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
	update_enemy_shelling_time()
	# 敌人buff回合开始递减
	for _c in CharacterArray:
		if _c is not Character:
			continue
		if _c.setting is Profile.Player:
			continue
		var changed:bool=_c.tick_buffs()
		if changed and _c==state_bar.current_role:
			state_bar.refresh_buff_basket(_c)
	#await _enemy_shelling_attack()
	await show_turn_title("敌人回合")
	var m=confirm_aimed_target()
	for enemy in CharacterArray:
		if enemy.setting is not Profile.Player:
			enemy_is_locked(enemy)
			await enemy_turn(enemy)
			await get_tree().create_timer(0.2).timeout
	if m != -1 and m < CharacterArray.size():#当玩家死亡时，代码运行出现了问题
		enemy_is_locked(CharacterArray[m])
	else:
		print("不存在任何可锁定目标")
	Turn_for_player()
## 触发所有锁定完成的炮击（玩家回合开始时调用）
## 检查玩家当前炮击模式，锁定回合 time <= 0 则触发攻击
func trigger_shelling_attacks(character:Character) -> void:
	var mode=character.setting.attack_mode
	if character.setting is Profile.Player:
		if mode is Shelling and mode.current_time<=0 and enemyIsTarget:
			await _player_shelling_fire(mode as Shelling)
	else:
		if mode is Shelling and mode.current_time<=0:
			await causeDamage(character)
## 玩家炮击攻击逻辑：根据炮击类型对锁定目标造成伤害
func _enemy_shelling_attack() -> void:
	for _c in CharacterArray:
		if _c is not Character:
			continue
		if _c.setting is Profile.Player:
			continue
		if _c.setting.attack_mode is Shelling:
			await trigger_shelling_attacks(_c)
func update_enemy_shelling_time():
	for _c in CharacterArray:
		if _c.setting is not Profile.Player:
			var mode=_c.setting.attack_mode
			if mode is Shelling:
				if mode.is_targeting:
					mode.current_time-=1
func Turn_for_player():
	# 玩家buff回合开始递减
	var player:Character=CharacterArray[0] as Character
	if player!=null:
		var changed:bool=player.tick_buffs()
		if changed and player==state_bar.current_role:
			state_bar.refresh_buff_basket(player)
	Profile.last_round_missed = Profile.miss_times > 0
	Profile.miss_times = 0
	if enemyIsTarget:
		if CharacterArray[0].setting.attack_mode is Shelling:
			CharacterArray[0].setting.attack_mode.current_time-=1
			if CharacterArray[0].setting.attack_mode.current_time>=0:
				fresh_player_range()
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
