extends ColorRect
class_name Stack
enum Stack_mode{
	Melee,
	Shoot,
	Shelling,
	Empty
}
enum Stack_pos{
	Left,
	Medium,
	Right
}
@export var stack_mode:Stack_mode
@export var stack_pos:Stack_pos
const Stack_color:Dictionary={
	Stack_mode.Melee:Color("ff3250"),
	Stack_mode.Shoot:Color("00e6b4"),
	Stack_mode.Shelling:Color("ffb900"),
	Stack_mode.Empty:Color("ffffff00")
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#stack_mode=Stack_mode.Empty
	fresh()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func random():
	stack_mode=Profile.rng.randi_range(0,2)
	color=Stack_color[stack_mode]
	stack_pos=Profile.rng.randi_range(0,2)
func random_type():
	stack_mode=Profile.rng.randi_range(0,2)
	color=Stack_color[stack_mode]
func fresh():#更新栈位置和栈类型
	color=Stack_color[stack_mode]
	position.x=40*stack_pos
