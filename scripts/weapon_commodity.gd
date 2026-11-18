extends PanelContainer
class_name Weapon_commodity
var weapon:Attack
@export var context:RichTextLabel
@export var title:Label
@export var pic:TextureRect
@export var profit:float=1.6
signal weapon_is_selected(value:int)
var cost:int=0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func show_text(mode:Attack):
	context.text="攻击力："+str(mode.damage)+"\n"
	if mode is Melee:
		context.text+="攻击范围："+str(mode.range)+"\n"
	elif mode is Shoot:
		context.text+="命中率："+str(mode.probability)+"%\n"
		if mode is Through_shoot:
			context.text+="贯穿等级：Level"+str(mode.level)+"\n"
	elif mode is Shelling:
		if mode.firebomb.isCanBeUsed:
			context.text+="x燃烧弹可装备\n"
		if mode.flashbang.isCanBeUsed:
			context.text+="x闪光弹可装备\n"
		if mode.flare.isCanBeUsed:
			context.text+="x干扰弹可装备\n"
		if mode is Multi_target_missile:
			context.text+="可打击多个目标\n"
		elif mode is Sputtering_type_artillery:
			context.text+="溅射范围："+str(mode.sputter_range)+"\n"
		context.text+="需要等待的回合数："+str(mode.max_time)+"\n"
func change_texture(mode:Attack):
	if mode is Melee:
		pic.texture=load("res://assets/statebar/melee_mode.png")
	elif mode is Shoot:
		pic.texture=load("res://assets/statebar/shoot_mode.png")
	elif mode is Shelling:
		pic.texture=load("res://assets/statebar/shelling.png")
func show_cost():
	cost=weapon.evaluate_price()*profit
	context.text+="售价：[color=#FFD700]%d[/color]"%cost
func set_weapon(mode:Attack):
	weapon=mode
	title.text=weapon.code
	change_texture(weapon)
	show_text(weapon)
	show_cost()
func _on_texture_button_pressed() -> void:
	var flag=true
	if cost<=Profile.item.money:
		if weapon is Melee:
			Profile.item.meleeBag.append(weapon)
		elif weapon is Shoot:
			Profile.item.shootBag.append(weapon)
		elif weapon is Shelling:
			Profile.item.shellingBag.append(weapon)
	else:
		flag=false
	weapon_is_selected.emit(cost)
	if flag:
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self,"scale",Vector2(0,0),0.2)
		await tween.finished
		queue_free()
	pass # Replace with function body.
func discount(value):
	cost=cost*value
	if weapon!=null:
		show_text(weapon)
		context.text+="售价：[color=#00ff00]%d[/color]"%cost


func _on_texture_button_mouse_entered() -> void:
	scale=Vector2(1.2,1.2)
	pass # Replace with function body.


func _on_texture_button_mouse_exited() -> void:
	scale=Vector2(1,1)
	pass # Replace with function body.
