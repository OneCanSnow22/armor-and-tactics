extends CanvasLayer
@export var melee_label:Label
@export var shoot_label:Label
@export var shelling_label:Label
@export var current_weapon_detail:Label#显示当前装备的武器的详细信息
@export var select_weapon_detail:RichTextLabel#显示当前选择的武器的详细信息
@export var detail:HBoxContainer
@export var list:VBoxContainer
enum Weapon_list{
	Melee_list,
	Shoot_list,
	Shelling_list
}
var mode_list:Weapon_list
var weapon_scene=load("res://scenes/weapon_select.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	detail.visible=false
	show_current_equipment()
	pass # Replace with function body.
func show_text(mode:Attack):
	current_weapon_detail.text=mode.code+"\n"
	current_weapon_detail.text+="攻击力："+str(mode.damage)+"\n"
	if mode is Melee:
		current_weapon_detail.text+="攻击范围："+str(mode.range)+"\n"
	elif mode is Shoot:
		current_weapon_detail.text+="命中率："+str(mode.probability)+"%\n"
		if mode is Through_shoot:
			current_weapon_detail.text+="贯穿等级：Level"+str(mode.level)+"\n"
	elif mode is Shelling:
		if mode.firebomb.isCanBeUsed:
			current_weapon_detail.text+="x燃烧弹可装备\n"
		if mode.flashbang.isCanBeUsed:
			current_weapon_detail.text+="x闪光弹可装备\n"
		if mode.flare.isCanBeUsed:
			current_weapon_detail.text+="x干扰弹可装备\n"
		if mode is Multi_target_missile:
			current_weapon_detail.text+="可打击多个目标\n"
		elif mode is Sputtering_type_artillery:
			current_weapon_detail.text+="溅射范围："+str(mode.sputter_range)+"\n"
		current_weapon_detail.text+="需要等待的回合数："+str(mode.max_time)+"\n"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func show_current_equipment():
	melee_label.text=Profile.player.melee.code
	shoot_label.text=Profile.player.shoot.code
	shelling_label.text=Profile.player.shelling.code


func _on_shelling_pressed() -> void:
	mode_list=Weapon_list.Shelling_list
	open_detail()
	pass # Replace with function body.


func _on_melee_pressed() -> void:
	mode_list=Weapon_list.Melee_list
	open_detail()
	pass # Replace with function body.


func _on_shoot_pressed() -> void:
	mode_list=Weapon_list.Shoot_list
	open_detail()
	pass # Replace with function body.
func open_detail():
	detail.visible=true
	if mode_list==Weapon_list.Melee_list:
		show_text(Profile.player.melee)
	elif mode_list==Weapon_list.Shoot_list:
		show_text(Profile.player.shoot)
	elif mode_list==Weapon_list.Shelling_list:
		show_text(Profile.player.shelling)
	list_display(mode_list)
func list_display(value:Weapon_list):
	if list.get_child_count()>0:
		for _i in list.get_children():
			list.remove_child(_i)
			_i.queue_free()
	var bags:Array
	var weapon
	if value==Weapon_list.Melee_list:
		bags=Profile.item.meleeBag
		weapon=Profile.player.melee
	elif value==Weapon_list.Shoot_list:
		bags=Profile.item.shootBag
		weapon=Profile.player.shoot
	elif value==Weapon_list.Shelling_list:
		bags=Profile.item.shellingBag
		weapon=Profile.player.shelling
	for _i in bags:
		if _i !=weapon:
			var weapon_unit=weapon_scene.instantiate()
			list.add_child(weapon_unit)
			weapon_unit.set_weapon(_i)
			weapon_unit.weapon_clicked.connect(equip)
			weapon_unit.weapon_selected.connect(show_select)
func equip(value:Attack):
	detail.visible=false
	if mode_list==Weapon_list.Melee_list:
		Profile.player.melee=value
	elif mode_list==Weapon_list.Shoot_list:
		Profile.player.shoot=value
	elif mode_list==Weapon_list.Shelling_list:
		Profile.player.shelling=value
	show_current_equipment()


func _on_button_pressed() -> void:
	detail.visible=false
	pass # Replace with function body.
func show_select(value:Attack):
	if value!=null:
		select_weapon_detail.text=value.code+"\n"
		select_weapon_detail.text+="攻击力：%d "%value.damage
		if value is Melee:
			var gap=value.damage-Profile.player.melee.damage
			if gap>0:
				select_weapon_detail.text+="[color=#00ff00]+%d[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#ff0000]%d[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
			select_weapon_detail.text+="攻击范围：%d "%value.max_range
			gap=value.max_range-Profile.player.melee.max_range
			if gap>0:
				select_weapon_detail.text+="[color=#00ff00]+%d[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#ff0000]%d[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
		elif value is Shoot:
			var gap=value.damage-Profile.player.shoot.damage
			if gap>0:
				select_weapon_detail.text+="[color=#00ff00]+%d[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#ff0000]%d[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
			select_weapon_detail.text+="命中率：%d%% "%value.max_probability
			gap=value.max_probability-Profile.player.shoot.max_probability
			if gap>0:
				select_weapon_detail.text+="[color=#00ff00]+%d%%[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#ff0000]%d%%[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
			if value is Through_shoot:
				if Profile.player.shoot is not Through_shoot:
					select_weapon_detail.text+="[color=#00ff00]+贯穿等级：level%d[/color]\n"%value.level
				else:
					select_weapon_detail.text+="贯穿等级：level%d "%value.level
					gap=value.level-Profile.player.shoot.level
					if gap>0:
						select_weapon_detail.text+="[color=#00ff00]+%d[/color]\n" % gap
					elif gap<0:
						select_weapon_detail.text+="[color=#ff0000]%d[/color]\n" % gap
					else:
						select_weapon_detail.text+="\n"
			else:
				if Profile.player.shoot is Through_shoot:
					select_weapon_detail.text+="[color=#ff0000]-贯穿等级：level%d[/color]\n"%Profile.player.shoot.level
		elif value is Shelling:
			var gap=value.damage-Profile.player.shelling.damage
			if gap>0:
				select_weapon_detail.text+="[color=#00ff00]+%d[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#ff0000]%d[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
			if value.firebomb.isCanBeUsed and !Profile.player.shelling.firebomb.isCanBeUsed:
				select_weapon_detail.text+="[color=#00ff00]可装备燃烧弹[/color]\n"
			elif !value.firebomb.isCanBeUsed and Profile.player.shelling.firebomb.isCanBeUsed:
				select_weapon_detail.text+="[color=#ff0000]无法装备燃烧弹[/color]\n"
			elif value.firebomb.isCanBeUsed:
				select_weapon_detail.text+="可装备燃烧弹\n"
			if value.flashbang.isCanBeUsed and !Profile.player.shelling.flashbang.isCanBeUsed:
				select_weapon_detail.text+="[color=#00ff00]可装备闪光弹[/color]\n"
			elif !value.flashbang.isCanBeUsed and Profile.player.shelling.flashbang.isCanBeUsed:
				select_weapon_detail.text+="[color=#ff0000]无法装备闪光弹[/color]\n"
			elif value.flashbang.isCanBeUsed:
				select_weapon_detail.text+="可装备闪光弹\n"
			if value.flare.isCanBeUsed and !Profile.player.shelling.flare.isCanBeUsed:
				select_weapon_detail.text+="[color=#00ff00]可装备干扰弹[/color]\n"
			elif !value.flare.isCanBeUsed and Profile.player.shelling.flare.isCanBeUsed:
				select_weapon_detail.text+="[color=#ff0000]无法装备干扰弹[/color]\n"
			elif value.flare.isCanBeUsed:
				select_weapon_detail.text+="可装备干扰弹\n"
			select_weapon_detail.text+="需要等待的回合数：%d "%value.max_time
			gap=value.max_time-Profile.player.shelling.max_time
			if gap>0:
				select_weapon_detail.text+="[color=#ff0000]+%d[/color]\n" % gap
			elif gap<0:
				select_weapon_detail.text+="[color=#00ff00]%d[/color]\n" % gap
			else:
				select_weapon_detail.text+="\n"
			
	else:
		select_weapon_detail.text=""


func _on_delete_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.
