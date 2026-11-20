extends Attack
class_name Shelling
@export var time:int#延时回合
@export var firebomb:Firebomb
@export var flashbang:FlashBang
@export var flare:Flare
@export var current_missile:Missile
@export var max_time:int
@export var bonus_damage:int = 0#等待期内由攻击模组叠加的额外伤害
func attack():
	print("炮击")
func evaluate_price():
	price=30
	var rate=1.0
	if firebomb.isCanBeUsed:
		rate+=0.08
	if flashbang.isCanBeUsed:
		rate+=0.08
	if flare.isCanBeUsed:
		rate+=0.08
	rate+=(damage*0.08)
	rate-=(max_time*0.08)
	if rate<0.3:
		rate=0.3
	price*=rate
	return price
