extends PanelContainer
class_name Card_commodity
var card:Card
@export var worth:RichTextLabel
@export var goods:HBoxContainer
@export var cost:int=0

signal card_is_hoverd(value:Card)
signal card_is_clicked(value:Card)
signal cost_is_too_high()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_mouse_entered() -> void:
	scale=Vector2(1.2,1.2)
	card_is_hoverd.emit(card)
	pass # Replace with function body.
func set_card(value:Card):
	card=value
	if card!=null:
		goods.add_child(card)
		card.apply_card()
		card.hide_stack()
		card.fresh_card()
		card.display()
	evaluate()
func _on_texture_button_mouse_exited() -> void:
	scale=Vector2(1,1)
	card_is_hoverd.emit(null)
	pass # Replace with function body.

func random_angle_simple() -> float:
	# 随机选择正区间(0)或负区间(1)
	var choose_positive = randi() % 2 == 0
	if choose_positive:
		# 正区间: 10-15度，转为弧度
		return deg_to_rad(randf_range(10.0, 15.0))
	else:
		# 负区间: -10到-15度，转为弧度
		return deg_to_rad(randf_range(-15.0, -10.0))
func _on_texture_button_pressed() -> void:
	if Profile.item.money<cost:#买不起
		cost_is_too_high.emit()
		return
	Profile.item.money-=cost
	Profile.Deck.append(card)
	card_is_clicked.emit(card)
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"rotation",random_angle_simple(),0.1)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale",Vector2(0,0),0.2)
	await tween.finished
	if card!=null:
		goods.remove_child(card)
	queue_free()
	pass # Replace with function body.
func evaluate():
	cost=0
	var times=0
	if card!=null:
		for _i in card.function_list:
			if _i!=Card.Blank and _i!=Card.Lock:
				cost+=abs(_i.point)*15*(1+0.5*times)
				times+=1
	worth.text=str(cost)
func discount(value:float):
	cost=cost*value
	worth.text="[color=#00ff00]%d[/color]"%cost
func inertia():
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"position",Vector2(position.x,position.y-10),0.2)
