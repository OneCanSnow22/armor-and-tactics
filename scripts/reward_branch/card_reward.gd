extends CanvasLayer
@export var basket: HFlowContainer
@export var Hint:Label
@export var ban:Control
@export var typing_speed: float = 15.0
@export var refuseButton:Button

func _ready() -> void:
	refuseButton.visible=false
	Hint.visible_characters=0

func _process(_delta: float) -> void:
	pass

## 清除 basket 中所有卡牌节点
## selected_card: 玩家已选择的卡（只 remove_child 保留节点），其余全 queue_free
## 传 null 表示没有被选择的卡，全部 queue_free
func clear_all_card(selected_card: Card = null) -> void:
	if basket.get_child_count() > 0:
		for child in basket.get_children():
			if child == selected_card:
				basket.remove_child(child)
			else:
				child.queue_free()

var ChosenCard:Card=null
func ensure_card(card:Card):
	ChosenCard=card
	card.just_for_reward=false
	card.just_for_check=false
	Profile.Deck.append(card)
	card.reward_is_chosen.disconnect(ensure_card)
	ban.visible=true
	clear_all_card(ChosenCard)
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func create_reward() -> void:
	type_hint()
	clear_all_card(ChosenCard)
	var signatures: Array[String] = []
	for _i in range(4):
		var card: Card = Profile.random_card(signatures)
		if card != null:
			basket.add_child(card)
			card.reward_is_chosen.connect(ensure_card)
			card.fresh_card()
			card.display()
			card.hide_stack()
			card.just_for_check = true
			card.just_for_reward = true
			# 记录签名，下一张卡生成时排除
			var picked: Array[int] = []
			for fu in card.function_list:
				if fu != null and fu.mode != Profile.Function.Lock:
					picked.append(fu.mode as int)
			signatures.append(Profile._card_signature(picked))

func type_hint():
	var hint="选择其中一张加入库存"
	var duration=hint.length()/typing_speed
	Hint.text=hint
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(Hint,"visible_characters",hint.length(),duration)
	await tween.finished
	ban.visible=false
	refuseButton.visible=true

func _on_button_pressed() -> void:
	clear_all_card(null)
	get_tree().change_scene_to_file("res://scenes/map.tscn")
