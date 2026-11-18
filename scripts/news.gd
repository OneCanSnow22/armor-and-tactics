extends CanvasLayer
class_name Report
@export var title:Label
@export var reward_button:Button
@export var back_button:Button
@export var typing_speed: float = 15.0  # 字符/秒
@export var cardReward:CanvasLayer
@export var weaponReward:CanvasLayer
@export var repairReward:CanvasLayer
@export var chargerReward:CanvasLayer
enum Reward_type{
	Card_reward,#卡牌奖励
	Battery_reward,#电池奖励
	Repair_reward,#修理奖励
	Weapon_reward,#武器奖励
	Dead_reward#死亡报告
}
enum Quit_forward{
	Map,
	Start
}
var reward_type:Reward_type
var quit_forward:Quit_forward
var isVictory:bool=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reward_button.position.x=-500
	back_button.position.x=-500
	cardReward.visible=false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func type_title(value:String):
	title.text=value
	title.visible_characters=0
	var duration=value.length()/typing_speed
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(title,"visible_characters",value.length(),duration)
	await tween.finished
func deceide_type():#根据情况给予奖励
	if Profile.item.energy<3:
		reward_type=Reward_type.Battery_reward
	elif Profile.player.health<Profile.player.max_health*0.1:
		reward_type=Reward_type.Repair_reward
	elif Profile.rng.randi_range(0,15)<6:
		print("奖励武器")
		reward_type=Reward_type.Weapon_reward
	else:
		print("奖励卡牌")
		reward_type=Reward_type.Card_reward	
func open_page(value:bool):
	show()
	isVictory=value
	if isVictory:#玩家胜利
		Profile.item.finished_times+=1
		title.add_theme_color_override("font_color",Color("00c385"))
		await type_title("[已清除威胁]")
		reward_button.text="结算报酬"
		back_button.text="返回地图"
		quit_forward=Quit_forward.Map
		deceide_type()
		button_roll_to_center()
	else:#玩家失败
		title.add_theme_color_override("font_color",Color("ff0000"))
		await type_title("[任务失败]")
		reward_button.text="结算报告"
		back_button.text="返回主页"
		quit_forward=Quit_forward.Start
		reward_type=Reward_type.Dead_reward
		button_roll_to_center()
func button_roll_to_center():
	reward_button.disabled=true
	back_button.disabled=true
	reward_button.position.x=-400
	back_button.position.x=-400
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.1)
	tween.tween_property(reward_button,"position",Vector2(68,30),0.2)
	tween.tween_interval(0.1)
	tween.tween_property(back_button,"position",Vector2(68,140),0.2)
	await tween.finished
	reward_button.disabled=false
	back_button.disabled=false


func _on_reward_report_pressed() -> void:
	if reward_type==Reward_type.Card_reward:
		cardReward.visible=true
		cardReward.create_reward()
	elif reward_type==Reward_type.Weapon_reward:
		weaponReward.visible=true
		weaponReward.show_chip()
	elif reward_type==Reward_type.Repair_reward:
		repairReward.open_page()
	elif reward_type==Reward_type.Battery_reward:
		chargerReward.open_page()
	elif reward_type==Reward_type.Dead_reward:
		get_tree().change_scene_to_file("res://scenes/Final_report.tscn")
	pass # Replace with function body.


func _on_back_pressed() -> void:
	if quit_forward==Quit_forward.Map:
		get_tree().change_scene_to_file("res://scenes/map.tscn")
	elif quit_forward==Quit_forward.Start:
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
	pass # Replace with function body.
