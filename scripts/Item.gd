extends Resource
class_name Item
@export var money:int
@export var energy:int
@export var buy_energy_times:int
@export var repair_times:int
@export var meleeBag:Array[Melee]
@export var shootBag:Array[Shoot]
@export var shellingBag:Array[Shelling]
@export var map_location:Vector2
@export var direction:Vector2
@export var towards:int
var max_money=99999#最大可获得金币数
@export var enemy_kill=0
@export var miss_time=0
@export var attack_times=0
@export var move_step=0
#var time:Profile.TimeRecorder#计时器
var isAlive:bool=true#用于给其他脚本判断角色是否死亡
@export var finished_times=0#胜利次数
func _init() -> void:
		meleeBag.clear()
		shootBag.clear()
		shellingBag.clear()
		buy_energy_times=0
		repair_times=0
		map_location=Vector2(3,10)
		direction=Vector2(1,1)
		towards=1
		enemy_kill=0#杀敌数
		miss_time=0#远程失误次数
		attack_times=0#攻击次数
		move_step=0#移动步数
		finished_times=0
func set_money(value:int):
	money=value
func refresh_location(value:Vector2,value2:Vector2):
		map_location=value
		direction=value2
func add_energy(value:int):
		energy+=value
		if energy>Profile.max_energy:
			energy=Profile.max_energy
func add_money(value:int):
		money+=value
		if money>max_money:
			money=max_money
func add_weapon(value:Attack):
	if value is Melee:
		meleeBag.append(value)
	elif value is Shoot:
		shootBag.append(value)
	elif value is Shelling:
		shellingBag.append(value)
func get_weapon_count()->int:
		return meleeBag.size()+shootBag.size()+shellingBag.size()
