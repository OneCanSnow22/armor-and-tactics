extends CanvasLayer
@export var list:VBoxContainer
@export var context:Label
@export var money:RichTextLabel
@export var free_button:Button
@export var normal_button:Button
@export var vip_button:Button
var normal_cost:int=50
var vip_cost:int=100
@export var speed:float=10
@export var normal_repair:int=30
@export var vip_upgrage:int=20
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	list.visible=false
	refresh_money()
	await engineer_speak("本店提供最好的维修服务。")
	list.visible=true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func engineer_speak(value:String):
	context.visible_characters=0
	context.text=value
	var time:float=value.length()/speed
	var tween=create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(context,"visible_characters",value.length(),time)
	await tween.finished
func refresh_money():
	money.text="当前剩余金额:[color=#FFD700]%d[/color]"%Profile.item.money

func _on_free_pressed() -> void:
	heal(15)
	free_button.disabled=true
	pass # Replace with function body.


func _on_normal_pressed() -> void:
	var cost=normal_cost*(1+0.2*Profile.item.repair_times)
	if cost<=Profile.item.money:
		Profile.item.money-=cost
		heal(normal_repair)
		Profile.item.repair_times+=1
		cost=normal_cost*(1+0.2*Profile.item.repair_times)
		normal_button.text="初级维修：%d费用/回复%d点生命值"%[cost,normal_repair]
		cost=vip_cost*(1+0.6*Profile.item.repair_times)
		vip_button.text="高级维修：%d费用/提升%d点最大生命"%[cost,vip_upgrage]
		refresh_money()
	else:
		say_no()
	pass # Replace with function body.
func heal(value:int):
	Profile.player.health+=value
	if Profile.player.health>Profile.player.max_health:
		Profile.player.health=Profile.player.max_health
func upgrade(value:int):
	Profile.player.max_health+=value
	Profile.player.health+=value


func _on_vip_pressed() -> void:
	var cost=vip_cost*(1+0.6*Profile.item.repair_times)
	if cost<=Profile.item.money:
		Profile.item.money-=cost
		heal(normal_repair)
		Profile.item.repair_times+=1
		cost=vip_cost*(1+0.6*Profile.item.repair_times)
		vip_button.text="高级维修：%d费用/提升%d点最大生命"%[cost,vip_upgrage]
		cost=normal_cost*(1+0.2*Profile.item.repair_times)
		normal_button.text="初级维修：%d费用/回复%d点生命值"%[cost,normal_repair]
		refresh_money()
	else:
		say_no()
	pass # Replace with function body.
func say_no():
	engineer_speak("抱歉，本服务目前无法提供。")


func _on_delete_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map.tscn")
	pass # Replace with function body.
