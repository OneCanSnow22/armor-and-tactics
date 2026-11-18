extends PanelContainer
@export var gear:Sprite2D
@export var total:Label
const Max_money:int=99999#最大金额
var money:int=0#当前金额

## 设置金额并播放数字滚动动画
func set_money(value:int, duration:float=1)->void:
	value=clampi(value,0,Max_money)
	if total==null:
		money=value
		return
	var from:=money
	var to:=value
	money=to
	var tween:=create_tween()
	# 按帧插值更新 Label 文本
	tween.tween_method(func(v:int)->void:
		total.text=str(v), from, to, duration)
	# 滚动结束时确保最终值精确
	tween.tween_callback(func()->void:
		total.text=str(to))
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass


func _on_texture_button_mouse_entered() -> void:
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(gear,"scale",Vector2(1.4,1.4),0.1)
	tween.tween_property(gear,"rotation",gear.rotation-PI*2,0.3)


func _on_texture_button_mouse_exited() -> void:
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(gear,"rotation",0,0.2)
	tween.tween_property(gear,"scale",Vector2(1.2,1.2),0.1)
	pass # Replace with function body.
