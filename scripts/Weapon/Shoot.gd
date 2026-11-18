extends Attack
class_name Shoot
@export var probability:int#攻击命中率
@export var max_probability:int
func attack():
	print("射击")
func evaluate_price():
	price=20
	price*=(1+0.1*damage+0.04*max_probability)
	return price
