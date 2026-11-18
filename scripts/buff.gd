extends Control
class_name Buff
@export var pic:TextureRect#用于显示图标
@export var level_label:Label#用于显示层数
var level:int#层数
var is_permanent:bool = false#是否为常驻型，常驻型不随回合递减
var _buff_type:String = "Buff"#唯一标识类型名，用于叠层判断

## 类型标识常量
const TYPE_FRAGILE := "Fragile"
const TYPE_OVERHEATED := "Overheated"
const TYPE_BLINDED := "Blinded"
const TYPE_DUD := "Dud"

## 根据类型名设置图标和标识
func setup_by_type(type_name: String) -> void:
	_buff_type = type_name
	if pic:
		match type_name:
			TYPE_FRAGILE:
				pic.texture = load("res://assets/buff/dangerous.png")
			TYPE_OVERHEATED:
				pic.texture = load("res://assets/buff/overheated.png")
			TYPE_BLINDED:
				pic.texture = load("res://assets/buff/blinded.png")
			TYPE_DUD:
				pic.texture = load("res://assets/buff/dud.png")
			_:
				pass

## 设置层数并更新显示
func set_level(new_level: int) -> void:
	level = new_level
	if level_label:
		level_label.text = str(level)

## 回合开始时调用，临时型层数-1，返回false表示已移除
func on_turn_start() -> bool:
	if is_permanent:
		return true
	level -= 1
	if level_label:
		level_label.text = str(level)
	return level > 0

## 获取该BUFF的唯一标识类型名
func get_buff_type() -> String:
	return _buff_type

## 刷新层数显示
func refresh_display() -> void:
	if level_label:
		level_label.text = str(level)

## 子类可重写此方法定义常驻型移除条件，返回true表示应该移除
func check_removal() -> bool:
	return false
