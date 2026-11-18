extends Shelling
class_name Sputtering_type_artillery

@export var sputter_range:int
func attack():
	print("溅射型炮击")
func evaluate_price():
	price=40
	var rate=1.0
	if firebomb.isCanBeUsed:
		rate+=0.08
	if flashbang.isCanBeUsed:
		rate+=0.08
	if flare.isCanBeUsed:
		rate+=0.08
	rate+=(damage*0.08)
	rate-=(max_time*0.1)
	rate+=(sputter_range*0.12)
	if rate<0.3:
		rate=0.3
	price*=rate
	return price
