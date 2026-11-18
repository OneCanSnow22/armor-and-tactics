extends Shelling
class_name Multi_target_missile

# Called when the node enters the scene tree for the first time.
func attack():
	print("多目标炮击")
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
	rate-=(max_time*0.08)
	if rate<0.3:
		rate=0.3
	price*=rate
	return price
