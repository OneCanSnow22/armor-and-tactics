extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var animation
var direction
var camera:Camera2D
var up
var right
var down
var left
var text
func _ready() -> void:
	animation=$AnimatedSprite2D
	direction=$direction
	up=$direction/up
	right=$direction/right
	down=$direction/down
	left=$direction/left
	camera=$Camera2D
	text=$direction/Label
	direction.visible=false
	
func walk()->void:
	print("角色移动了")
	animation.play("walk")
func stop()->void:
	animation.play("idle")
func need_turn_to()->bool:
	if animation.scale.x>0:
		return false#面朝右边
	else:
		return true#面朝左边
func turn_to():
	animation.scale.x=-animation.scale.x
func select_direction(direct:int,id:int):
	direction.visible=true
	text.text="选择移动方向"
	down.visible=false
	left.visible=false
	right.visible=false
	up.visible=false
	if id==18:
		down.visible=true
		left.visible=true
		right.visible=true
		if direct==0:
			down.visible=false
		if direct==1:
			left.visible=false
		if direct==3:
			right.visible=false
	elif id==19:
		down.visible=true
		up.visible=true
		right.visible=true
		if direct==0:
			down.visible=false
		if direct==3:
			right.visible=false
		if direct==2:
			up.visible=false
func hide_direct():
	if direction.visible:
		direction.visible=false
func enlarge_screen()->Tween:
	var tween=create_tween()
	tween.tween_property(camera,"zoom",Vector2(6,6),0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween
func normal_screen():	
	var tween=create_tween()
	tween.tween_property(camera,"zoom",Vector2(4,4),0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
