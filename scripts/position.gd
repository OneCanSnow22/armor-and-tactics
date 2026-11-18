extends ColorRect
class_name Position
@export var Enemy_danger:TextureRect#用于显示敌人该位置受到攻击
@export var Player_danger:TextureRect
@export var aimed:TextureRect
@export var enemy_danger_wait_label:Label#用于显示玩家攻击触发还剩所需等待时间
@export var player_danger_wait_label:Label#用于显示敌人攻击触发还剩所需等待时间
var isFriendly:bool#是否是友方
var isPlayer:bool#是否是玩家
var EnemyisDangerous:bool=false
var PlayerisDangerous:bool=false
func isAimed():
	if aimed!=null:
		aimed.visible=true
	var tween=create_tween()
	aimed.modulate=Color(1,1,1,0)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(aimed,"modulate",Color(1,1,1,1),0.2)
func is_not_aimed():
	if aimed!=null:
		aimed.visible=false
func EnemybecomeSafe():
	EnemyisDangerous=false
	Enemy_danger.visible=false
func PlayerbecomeSafe():
	PlayerisDangerous=false
	Player_danger.visible=false
func Player_turn_danger(value:int):#玩家攻击范围
	Enemy_danger.visible=true
	EnemyisDangerous=true
	enemy_danger_wait_label.text=str(value)
func Enemy_turn_danger(value:int):#敌人攻击范围
	Player_danger.visible=true
	PlayerisDangerous=true
	player_danger_wait_label.text=str(value)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerbecomeSafe()
	EnemybecomeSafe()
	is_not_aimed()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
