extends Node

const MOVE_DURATION: float = 1.0
const ENERGY_EVENT_GAIN: int = 3

var robot: CharacterBody2D
var map: TileMapLayer
var tween: Tween
var is_moving: bool = false
var is_awaiting_direction: bool = false
var _ui_open: bool = false
var energy_bar: HBoxContainer
var cmd_page: Node

@export var robot_direction: direct
@export var originPositon: Vector2
@export var energy: int
@export var danger: CanvasLayer
@export var setting_page: CanvasLayer
@export var crt_button: Button
@export var crt_screen: CanvasLayer

enum direct {
	UP,
	RIGHT,
	DOWN,
	LEFT
}


func _ready() -> void:
	robot = $"../robot" as CharacterBody2D
	map = $"../chess_table" as TileMapLayer
	var background: ColorRect = $"../background/ColorRect" as ColorRect
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_color_rect: ColorRect = $"../CRT/ColorRect" as ColorRect
	crt_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar = $"../information/EnergyBar/bar" as HBoxContainer
	cmd_page = $"../information/cmd"
	cmd_page.crt = $"../CRT"
	cmd_page.close_screen.connect(func() -> void: _ui_open = false)
	danger.visible = false
	setting_page.visible = false
	energy = Profile.item.energy
	energy_bar.init_energy(energy)
	connect_press_signal()
	locate_robot(Profile.item.map_location)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		request_move()


func locate_robot(pos: Vector2) -> void:
	robot.scale = Profile.item.direction
	var where_pos: Vector2 = map.map_to_local(pos)
	originPositon = pos
	robot_direction = Profile.item.towards
	where_pos.y -= 12
	robot.position = where_pos


func save_robot() -> void:
	var map_loc: Vector2 = map.local_to_map(robot.position)
	Profile.item.refresh_location(map_loc, robot.scale)
	Profile.item.towards = robot_direction


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("edit"):
		Profile.item.add_money(666)
		save_robot()
		get_tree().change_scene_to_file("res://scenes/workshop.tscn")


func request_move() -> void:
	if is_moving or is_awaiting_direction or _ui_open:
		return
	if Profile.item.energy <= 0:
		is_moving = true
		danger.energy_is_exhausted()
		return
	move()


func move() -> void:
	is_moving = true
	robot.hide_direct()
	var destination_cell: Vector2 = originPositon
	match robot_direction:
		direct.UP:
			destination_cell.y -= 1
		direct.RIGHT:
			destination_cell.x += 1
		direct.DOWN:
			destination_cell.y += 1
		direct.LEFT:
			destination_cell.x -= 1
	originPositon = destination_cell
	var destination_position: Vector2 = map.map_to_local(destination_cell)
	destination_position.y -= 12
	tween = create_tween()
	tween.tween_property(robot, "position", destination_position, MOVE_DURATION)
	robot.walk()
	tween.finished.connect(animation_finished)


func animation_finished() -> void:
	robot.stop()
	var tile_data: TileData = map.get_cell_tile_data(originPositon)
	if tile_data == null:
		unlock_movement()
		return
	var tile_id: int = int(tile_data.get_custom_data("id"))
	check_direction(tile_id)
	consume_step_and_energy(tile_id, func() -> void:
		await finish_landing(tile_id)
	)


func finish_landing(tile_id: int) -> void:
	while _ui_open:
		await get_tree().process_frame
	if tile_id == 20:
		Profile.item.isAlive = true
		get_tree().change_scene_to_file("res://scenes/Final_report.tscn")
		return
	if tile_id != 2 and Profile.item.energy <= 0:
		danger.energy_is_exhausted()
		return
	if tile_id == 18 or tile_id == 19:
		var zoom_tween: Tween = robot.enlarge_screen()
		await zoom_tween.finished
		if not is_instance_valid(self):
			return
		is_moving = false
		is_awaiting_direction = true
		robot.select_direction(robot_direction, tile_id)
		return
	enter_event(tile_id)


func unlock_movement() -> void:
	is_moving = false
	is_awaiting_direction = false


func check_direction(id: int) -> void:
	if id == 14:
		if robot_direction == direct.RIGHT:
			robot_direction = direct.DOWN
		elif robot_direction == direct.UP:
			robot_direction = direct.LEFT
	elif id == 15:
		if robot_direction == direct.RIGHT:
			robot_direction = direct.UP
		elif robot_direction == direct.DOWN:
			robot_direction = direct.LEFT
	elif id == 16:
		if robot_direction == direct.LEFT:
			robot_direction = direct.DOWN
		elif robot_direction == direct.UP:
			robot_direction = direct.RIGHT
	elif id == 17:
		if robot_direction == direct.LEFT:
			robot_direction = direct.UP
		elif robot_direction == direct.DOWN:
			robot_direction = direct.RIGHT
	need_turn()


func need_turn() -> void:
	if not robot.need_turn_to() and robot_direction == direct.LEFT:
		robot.turn_to()
	elif robot.need_turn_to() and robot_direction == direct.RIGHT:
		robot.turn_to()


func choose_direction(new_direction: direct) -> void:
	if not is_awaiting_direction or is_moving:
		return
	robot_direction = new_direction
	is_awaiting_direction = false
	robot.normal_screen()
	need_turn()
	move()


func _on_up_pressed() -> void:
	choose_direction(direct.UP)


func _on_right_pressed() -> void:
	choose_direction(direct.RIGHT)


func _on_down_pressed() -> void:
	choose_direction(direct.DOWN)


func _on_left_pressed() -> void:
	choose_direction(direct.LEFT)


func consume_step_and_energy(id: int, on_finished: Callable = Callable()) -> void:
	if id < 14:
		Profile.item.energy -= 1
		Profile.item.move_step += 1
		energy = Profile.item.energy
		energy_bar.consume_one(on_finished)
	elif on_finished.is_valid():
		on_finished.call()


func enter_event(id: int) -> void:
	match id:
		1:
			unlock_movement()
		2:
			Profile.item.add_energy(ENERGY_EVENT_GAIN)
			energy = Profile.item.energy
			energy_bar.gain_energy(ENERGY_EVENT_GAIN, unlock_movement)
		3:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/trap.tscn")
		4:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/shop.tscn")
		5:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/equipment_adjustment.tscn")
		6:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/workshop.tscn")
		7:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/Pawn.tscn")
		8:
			unlock_movement()
		10:
			save_robot()
			danger.becomeDanger()
		11:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/repair.tscn")
		12:
			save_robot()
			get_tree().change_scene_to_file("res://scenes/treasure.tscn")
		_:
			unlock_movement()


func connect_press_signal() -> void:
	var btn1: BaseButton = $"../information/select/button1" as BaseButton
	var btn2: BaseButton = $"../information/select/button2" as BaseButton
	var btn3: BaseButton = $"../information/select/button3" as BaseButton
	if btn1 != null:
		btn1.pressed.connect(open_character_menu)
	if btn2 != null:
		btn2.pressed.connect(open_deck)
	if btn3 != null:
		btn3.pressed.connect(open_setting)


func open_character_menu() -> void:
	_ui_open = true
	robot.stop()
	cmd_page.open_page("state")
	cmd_page.start_dialogue([
		">>当前血量：%d/%d" % [Profile.player.health, Profile.player.max_health],
		">>当前剩余金额：%d$" % Profile.item.money,
		">>目前拥有卡牌数量：%d" % Profile.Deck.size(),
		">>目前拥有武器数量：%d" % Profile.item.get_weapon_count(),
		">>按'enter'退出"
	])


func open_deck() -> void:
	_ui_open = true
	robot.stop()
	cmd_page.open_page("deck")


func open_setting() -> void:
	_ui_open = true
	robot.stop()
	setting_page.visible = true


func _on_close_pressed() -> void:
	if crt_screen.visible:
		crt_screen.visible = false
		crt_button.text = "打开滤镜"
	else:
		crt_screen.visible = true
		crt_button.text = "关闭滤镜"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Start.tscn")


func _on_quit_pressed() -> void:
	var savedata: SaveData = SaveData.new()
	save_robot()
	savedata.save_data()
	get_tree().quit()


func _on_setting_pressed() -> void:
	setting_page.visible = false
	_ui_open = false
