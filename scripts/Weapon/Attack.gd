extends Resource
class_name Attack
@export var code:String
@export var damage:int
@export var price:int
func attack():
	print("攻击")
func enhance(value:int):
	damage+=value
func evaluate_price():
	print("评估价格")
# Called when the node enters the scene tree for the first time.
