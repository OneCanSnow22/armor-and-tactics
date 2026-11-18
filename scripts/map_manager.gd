extends Node
var robot#角色
var map:TileMapLayer#tile地图
var tween:Tween
var random_step:RandomNumberGenerator
var step
var is_moving:bool
var _ui_open: bool = false  # 门控：任一信息界面打开时为 true，阻断移动链的下一步操作
var result_dice:TextureRect
var roll_dice:AnimationPlayer
var dice_layer
var energy_bar#能量条控制器
var cmd_page
@export var robot_direction:direct
@export var originPositon:Vector2
@export var energy:int
@export var danger:CanvasLayer
@export var setting_page:CanvasLayer
@export var crt_button:Button
@export var crt_screen:CanvasLayer
enum direct{
	UP,
	RIGHT,
	DOWN,
	LEFT
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	robot=$"../robot"
	map=$"../chess_table"
	result_dice=$"../dice/result"
	result_dice.visible=false
	roll_dice=$"../dice/AnimationPlayer"
	dice_layer=$"../dice"
	var crt_color_rect: ColorRect = $"../CRT/ColorRect"
	crt_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_moving=true
	# 获取能量条引用并初始化
	energy_bar=$"../information/EnergyBar/bar"
	cmd_page=$"../information/cmd"
	cmd_page.crt=$"../CRT"
	cmd_page.close_screen.connect(func(): _ui_open = false)
	print("连接成功")
	danger.visible=false
	setting_page.visible=false
	energy=Profile.item.energy
	energy_bar.init_energy(energy)
	connect_press_signal()
	locate_robot(Profile.item.map_location)
	random_step=RandomNumberGenerator.new()
	if Profile.intercepted:
		dice_layer.visible=false
		step=Profile.remained_step
		Profile.intercepted=false
		move()
	else:
		roll_dice_get_step()
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func locate_robot(pos:Vector2):
	robot.scale=Profile.item.direction
	var where_pos=map.map_to_local(pos)
	originPositon=pos
	robot_direction=Profile.item.towards
	where_pos.y-=12
	robot.position=where_pos
func save_robot():#记录角色位置和方向
	var map_loc=map.local_to_map(robot.position)
	Profile.item.refresh_location(map_loc,robot.scale)
	Profile.item.towards=robot_direction
func _process(delta: float) -> void:
	#用于DIY测试
	if Input.is_action_just_pressed("edit"):
		Profile.item.add_money(666)
		save_robot()
		get_tree().change_scene_to_file("res://scenes/workshop.tscn")
		print("修改模组")
	pass
func move()->void:
	is_moving=true
	robot.hide_direct()
	var finalplace:Vector2=originPositon
	#tween=create_tween()
	if robot_direction==0:
		finalplace.y-=1
		print("向上移动")
	elif robot_direction==1:
		finalplace.x+=1
		print("向右移动")
	elif robot_direction==2:
		print("向下移动")
		finalplace.y+=1
	elif robot_direction==3:
		finalplace.x-=1
		print("向左移动")
	originPositon=finalplace
	finalplace=map.map_to_local(finalplace)
	finalplace.y-=12
	tween=create_tween()
	tween.tween_property(robot,"position",finalplace,1)
	robot.walk()
	tween.finished.connect(animation_finished)
func animation_finished() -> void:
	robot.stop()
	var tile_data: TileData = map.get_cell_tile_data(originPositon)
	if tile_data:
		var tile_id = tile_data.get_custom_data("id")
		check_direction(tile_id)
		# 消耗动画播完后，再执行事件逻辑
		consume_step_and_energy(tile_id, func():
			# 等待信息界面关闭，避免界面打开时自顾自转场
			while _ui_open:
				await get_tree().process_frame
			if tile_id==20:
				is_moving = false
				Profile.item.isAlive=true
				get_tree().change_scene_to_file("res://scenes/Final_report.tscn")
				return
			elif tile_id==10 and step>0:#经过敌人块也会触发战斗
				is_moving = false
				Profile.remained_step=step
				Profile.intercepted=true
				save_robot()
				danger.becomeDanger()
				return
			if tile_id!=2 and Profile.item.energy==0:#能量耗尽
				is_moving = false
				danger.energy_is_exhausted()
				return
			if step <= 0:
				is_moving = false
				enter_event(tile_id)
				return
			if tile_id >= 18 and tile_id <= 19:
				# 岔路口：停下交给玩家选择方向
				is_moving = false
				robot.enlarge_screen()
				robot.select_direction(robot_direction, tile_id,step)
			else:
				# 普通地块且步数未耗尽：自动继续走下一步
				move()
		)
		print("当前图块 ID：" + str(tile_id))
		
func check_direction(id:int):
	if id==14:
		if robot_direction==direct.RIGHT:
			robot_direction=direct.DOWN
		elif robot_direction==direct.UP:
			robot_direction=direct.LEFT
	elif id==15:
		if robot_direction==direct.RIGHT:
			robot_direction=direct.UP
		elif robot_direction==direct.DOWN:
			robot_direction=direct.LEFT
	elif id==16:
		if robot_direction==direct.LEFT:
			robot_direction=direct.DOWN
		elif robot_direction==direct.UP:
			robot_direction=direct.RIGHT
	elif id==17:
		if robot_direction==direct.LEFT:
			robot_direction=direct.UP
		elif robot_direction==direct.DOWN:
			robot_direction=direct.RIGHT
	need_turn()
func need_turn():
	if !robot.need_turn_to() and robot_direction==direct.LEFT:
		robot.turn_to()
	elif robot.need_turn_to() and robot_direction==direct.RIGHT:
		robot.turn_to()


func _on_up_pressed() -> void:
	robot_direction=direct.UP
	robot.normal_screen()
	need_turn()
	move()
	pass # Replace with function body.


func _on_right_pressed() -> void:
	robot_direction=direct.RIGHT
	robot.normal_screen()
	need_turn()
	move()
	pass # Replace with function body.


func _on_down_pressed() -> void:
	robot_direction=direct.DOWN
	robot.normal_screen()
	need_turn()
	move()
	pass # Replace with function body.


func _on_left_pressed() -> void:
	robot_direction=direct.LEFT
	robot.normal_screen()
	need_turn()
	move()
	pass # Replace with function body.
func roll_dice_get_step():
	dice_layer.visible=true
	step=random_step.randi_range(1,min(Profile.item.energy,9))
	Profile.remained_step=step
	print("随机到的步数为"+str(step))
	if step<1 or step>9:
		step=1
	var picture:Texture=load("res://assets/chessboard/dice/dice_"+str(step)+".png")
	if picture:
		result_dice.texture=picture
	roll_dice.play("roll")
func consume_step_and_energy(id:int, on_finished: Callable = Callable()):
	if id<14:
		step-=1
		Profile.remained_step=step
		Profile.item.energy-=1
		Profile.item.move_step+=1
		# 消耗能量条最右端一格，带淡出动画，完成后执行回调
		energy_bar.consume_one(on_finished)
	else:
		# 非普通地块不消耗，直接执行回调
		if on_finished.is_valid():
			on_finished.call()
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	dice_layer.visible=false
	# 骰子动画结束后自动开始移动
	move()
	pass # Replace with function body.
func enter_event(id:int):
	if step<=0:
		if id==1:
			print("重掷骰子")
			roll_dice_get_step()
		elif id==2:
			print("获得电池")
			var gain_amount: int = 3 # 每次获得3点能量，可按需调整
			energy = clampi(energy + gain_amount, 0, 10)
			# 获得能量动画播完后再掷骰子
			energy_bar.gain_energy(gain_amount, func():
				roll_dice_get_step()
			)
		elif id==3:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/trap.tscn")
			print("掉进陷阱")
			#roll_dice_get_step()
		elif id==4:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/shop.tscn")
			print("商店")
			#roll_dice_get_step()
		elif id==5:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/equipment_adjustment.tscn")
			print("进入整备间")
			#roll_dice_get_step()
		elif id==6:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/workshop.tscn")
			print("修改模组")
			#roll_dice_get_step()
		elif id==7:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/Pawn.tscn")
			print("典当行")
			#roll_dice_get_step()
		elif id==8:
			print("以物易物")
			#roll_dice_get_step()
		elif id==10:
			save_robot()
			danger.becomeDanger()
			print("触发战斗")
			#roll_dice_get_step()
		elif id==11:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/repair.tscn")
			print("进入修理间")
			#roll_dice_get_step()
		elif id==12:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/treasure.tscn")
			print("发现宝贝")
			#roll_dice_get_step()
		elif id==20:
			get_tree().change_scene_to_file("res://scenes/Final_report.tscn")
			print("发现是终点")
		else:
			print("是其他节点")
			#roll_dice_get_step()
func connect_press_signal():
	var btn1=$"../information/select/button1"
	var btn2=$"../information/select/button2"
	var btn3=$"../information/select/button3"
	if btn1 and btn1.has_signal("pressed"):
		btn1.pressed.connect(open_character_menu)
	if btn2 and btn2.has_signal("pressed"):
		btn2.pressed.connect(open_deck)
	if btn3 and btn3.has_signal("pressed"):
		btn3.pressed.connect(open_setting)

func open_character_menu() -> void:
	_ui_open = true
	robot.stop()
	cmd_page.open_page("state")
	cmd_page.start_dialogue([
		">>当前血量：%d/%d"%[Profile.player.health,Profile.player.max_health],
		">>当前剩余金额：%d$"%Profile.item.money,
		">>目前拥有卡牌数量：%d"%Profile.Deck.size(),
		">>目前拥有武器数量：%d"%Profile.item.get_weapon_count(),
		">>按'enter'退出"
	])
	print("打开人物界面")

func open_deck() -> void:
	_ui_open = true
	robot.stop()
	cmd_page.open_page("deck")
	print("查看牌库")

func open_setting() -> void:
	_ui_open = true
	robot.stop()
	setting_page.visible=true
	print("查看设置")


func _on_close_pressed() -> void:
	if crt_screen.visible:
		crt_screen.visible=false
		crt_button.text="打开滤镜"
	else:
		crt_screen.visible=true
		crt_button.text="关闭滤镜"
	pass # Replace with function body.


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Start.tscn")
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	var savedata=SaveData.new()
	save_robot()
	savedata.save_data()
	get_tree().quit()
	pass # Replace with function body.


func _on_setting_pressed() -> void:
	setting_page.visible=false
	_ui_open = false
