extends Attack
class_name Melee
@export var range:int#攻击范围
@export var max_range:int
func attack():
	print("斩击")
func evaluate_price():
	price=20
	price*=(1+0.08*damage+0.12*max_range)
	return price
