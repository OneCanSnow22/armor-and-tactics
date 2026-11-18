extends HBoxContainer

## 能量条控制器
## 挂载在 information.tscn 的 bar(HBoxContainer) 节点上

const MAX_ENERGY: int = 15
const CELL_WIDTH: int = 100
const CELL_COLOR: Color = Color(0.126, 0.915, 1.0, 1.0) # 淡蓝色
const CELL_SEPARATION: int = 10 # 与 HBoxContainer 的 separation 一致

var _current_energy: int = 0
var _is_animating: bool = false

func _ready() -> void:
	pass

## 初始化能量条，传入初始能量值
func init_energy(value: int) -> void:
	_current_energy = clampi(value, 0, MAX_ENERGY)
	# 清空现有格子
	for child in get_children():
		child.queue_free()
	# 创建对应数量格子
	for i in range(_current_energy):
		_add_cell_instant()

## 消耗一格能量（随移动动画结束调用），带淡出动画
func consume_one(on_finished: Callable = Callable()) -> void:
	if _current_energy <= 0:
		if on_finished.is_valid():
			on_finished.call()
		return
	_current_energy -= 1
	var cells: Array = get_children()
	if cells.is_empty():
		if on_finished.is_valid():
			on_finished.call()
		return
	# 取最右端格子做淡出
	var last_cell: ColorRect = cells[cells.size() - 1] as ColorRect
	var tw: Tween = create_tween()
	tw.tween_property(last_cell, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(last_cell.queue_free)
	if on_finished.is_valid():
		tw.tween_callback(on_finished)

## 获得能量，逐一在最右端加入，溢出部分不播放动画
## on_finished：全部格子加入完成后调用（可为空 Callable）
func gain_energy(amount: int, on_finished: Callable = Callable()) -> void:
	if _current_energy >= MAX_ENERGY or amount <= 0:
		if on_finished.is_valid():
			on_finished.call()
		return
	# 计算实际可加数量
	var actual: int = mini(amount, MAX_ENERGY - _current_energy)
	_current_energy += actual
	_is_animating = true
	_add_cells_one_by_one(actual, 0, on_finished)

## 递归逐一加入格子
func _add_cells_one_by_one(total: int, index: int, on_finished: Callable = Callable()) -> void:
	if index >= total:
		_is_animating = false
		if on_finished.is_valid():
			on_finished.call()
		return
	var cell: ColorRect = _create_cell()
	cell.modulate.a = 0.0
	add_child(cell)
	var tw: Tween = create_tween()
	tw.tween_property(cell, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	# 每格加入完成后再加下一格
	tw.tween_callback(func(): _add_cells_one_by_one(total, index + 1, on_finished))

## 创建一个能量格 ColorRect（不加入树）
func _create_cell() -> ColorRect:
	var cell: ColorRect = ColorRect.new()
	cell.custom_minimum_size = Vector2(CELL_WIDTH, 0)
	cell.color = CELL_COLOR
	cell.size_flags_vertical = Control.SIZE_FILL
	return cell

## 直接添加一格（无动画，用于初始化）
func _add_cell_instant() -> void:
	var cell: ColorRect = _create_cell()
	add_child(cell)

## 获取当前能量值
func get_energy() -> int:
	return _current_energy
