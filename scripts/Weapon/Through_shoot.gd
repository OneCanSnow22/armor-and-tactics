extends Shoot
class_name Through_shoot
@export var level:int#贯穿等级
func attack():
	print("射击")
func evaluate_price():
	price=30
	price*=(1+0.1*damage+0.04*self.max_probability+0.15*level)
	return price

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
