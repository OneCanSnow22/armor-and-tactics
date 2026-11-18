class_name function
extends TextureRect
@export var mode:Profile.Function
@export var id:int
var animation_unit:Profile.AnimationUnit
var point:int#点数
var context:String
var title:String
## 动态获取描述文本，子类可覆盖以实现运行时更新（如 Swipe 随攻击模式变化）
func get_context() -> String:
	return context
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size.x=32
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func apply(menu:Main_menu):#调用功能
	print("没有任何功能")
func display():
	texture=load(Profile.Func_picture[mode])
func hint():
	print("我是"+str(mode))
