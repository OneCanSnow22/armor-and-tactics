extends CanvasLayer
@export var expand_page:TextureRect
@export var rewrite_page:TextureRect
@export var expand_button:Button
@export var rewrite_button:Button
@export var money_label:Label
@export var Selected_card:Control
@export var card_list:HFlowContainer
@export var card_display:PanelContainer#用于展示被选中的卡牌
@export var ban:Control#使得被选中的卡牌不可被鼠标互动
@export var basket:HFlowContainer
@export var frame:PanelContainer
@export var approve_button:Button
@export var tear_frame:PanelContainer
@export var tear_basket:HFlowContainer
@export var current_money:Label
@export var cost:Label
@export var mode_number:Label
@export var function_frame:PanelContainer
@export var column:VBoxContainer
@export var gear:TextureRect
@export var progress:ProgressBar
@export var gear_background:ColorRect
@export var display_line:HFlowContainer
var Chosen_card:Card
var Chosen_function:Selected_function
var Chosen_function_value:function# 记录当前装入的原始 function 引用，用于撤回时还原
var times:int=0
var functions:Array[function]#用于存放拆解卡牌下来的模组
var cost_money:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	functions.clear()
	times=0
	gear_background.visible=false
	open_expand()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_rewrite_pressed() -> void:
	open_rewrite()
	pass # Replace with function body.


func _on_expand_pressed() -> void:
	open_expand()
	pass # Replace with function body.
func open_expand():
	clear_basket()
	clear_tear_basket()
	rewrite_page.visible=false
	rewrite_button.disabled=false
	expand_button.disabled=true
	expand_page.visible=true
	money_label.text="目前可用金额：%d"%Profile.item.money
	Selected_card.position=Vector2(570,86)
	var button=$page1/list/Button
	button.visible=false
	var cover=$page1/ScrollContainer
	cover.visible=false
	var texture=$page1/list/TextureButton
	texture.disabled=false
	card_display.visible=false
	ban.visible=false
var is_next_step:bool=false
func open_rewrite():
	clear_list()
	hide_all()
	expand_page.visible=false
	rewrite_button.disabled=true
	expand_button.disabled=false
	rewrite_page.visible=true
	is_next_step=false
	approve_button.text="开始修改"
	approve_button.disabled=false
	frame.position=Vector2(-600,112)
	tear_frame.position=Vector2(-600,112)
	function_frame.position=Vector2(2400,112)
	#functions.clear()
	can_be_tear_down=Profile.item.money>=_tear_cost()
func _on_button_pressed() -> void:
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(Selected_card,"position",Vector2(30,86),0.2)
	await tween.finished
	var cover=$page1/ScrollContainer
	cover.visible=true
	var texture=$page1/list/TextureButton
	texture.disabled=true
	show_card_list()
	pass # Replace with function body.
func clear_list():
	if card_list.get_child_count()>0:
		for _i in card_list.get_children():
			_i.just_for_check=false
			_i.just_for_reward=false
			if _i.reward_is_chosen.is_connected(display_chosen):
				_i.reward_is_chosen.disconnect(display_chosen)
			card_list.remove_child(_i)
func show_card_list():
	clear_list()
	for _i in Profile.Deck:
		# 只显示包含锁模组的卡牌
		var has_lock:bool=false
		for fun in _i.function_list:
			if fun is Card.Lock:
				has_lock=true
				break
		if not has_lock:
			continue
		card_list.add_child(_i)
		_i.apply_card()
		_i.hide_stack()
		_i.fresh_card()
		_i.display()
		_i.just_for_check=true
		_i.just_for_reward=true
		if !_i.reward_is_chosen.is_connected(display_chosen):
			_i.reward_is_chosen.connect(display_chosen)
func _refresh_card_functions(card:Card) -> void:
	# 清空旧的function子节点，重新绑定当前的function_list
	var line1:Control=card.get_node("func_background/VBoxContainer/HBoxContainer")
	var line2:Control=card.get_node("func_background/VBoxContainer/HBoxContainer2")
	for child in line1.get_children():
		line1.remove_child(child)
	for child in line2.get_children():
		line2.remove_child(child)
	for i in range(card.function_list.size()):
		var fun:function=card.function_list[i]
		if fun!=null:
			# 确保节点没有已有父节点
			if fun.get_parent()!=null:
				fun.get_parent().remove_child(fun)
			if i<2:
				line1.add_child(fun)
			else:
				line2.add_child(fun)

func display_chosen(card:Card):#用于显示被选中的卡牌
	card_display.visible=true
	Chosen_card=card
	for i in display_line.get_children():
		display_line.remove_child(i)
		i.queue_free()
	for _i in Chosen_card.function_list:
		if _i!=null:
			var clone:function = Profile.function_factory(_i)
			if clone!=null:
				display_line.add_child(clone)
				clone.display()
	ban.visible=true
	var button=$page1/list/Button
	var cost:int=_calc_cost()
	# 计算选中卡牌上Lock数量，更新按钮状态
	var lock_count:int=_count_locks(card)
	if lock_count==0:
		button.disabled=true
		button.text="不可扩容"
	elif Profile.item.money<cost:
		button.disabled=true
		button.text="-%d（不足）"%cost
	else:
		button.disabled=false
		cost=_calc_cost()
		button.text="-%d"%cost
	button.visible=true

## 计算当前扩容花费：100 * 2^times
func _calc_cost() -> int:
	return 100 * (1 << times)

## 计算卡牌上的Lock数量
func _count_locks(card:Card) -> int:
	var count:int=0
	for fun in card.function_list:
		if fun is Card.Lock:
			count+=1
	return count

func expand_card():#将Chosen_card的所有锁模组变为空白模组Blank
	if Chosen_card==null:
		return
	var lock_count:int=_count_locks(Chosen_card)
	if lock_count==0:
		return
	var cost:int=_calc_cost()
	if Profile.item.money<cost:
		return
	# 扣钱
	Profile.item.money-=cost
	money_label.text="目前可用金额：%d"%Profile.item.money
	# 只替换第一个出现的Lock为Blank
	for i in range(Chosen_card.function_list.size()):
		if Chosen_card.function_list[i] is Card.Lock:
			Chosen_card.change_function(Card.Blank.new(),i)
			break
	# 花费翻倍
	times+=1
	# 刷新card_display
	display_chosen(Chosen_card)
	# 刷新卡牌列表（Lock变Blank后可能不再显示）
	show_card_list()
	
	


func _on_delete_pressed() -> void:
	clear_list()
	clear_basket()
	clear_tear_basket()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
func clear_basket():
	if basket.get_child_count()>0:
		for _i in basket.get_children():
			_i=_i as Card
			_i.just_for_check=false
			_i.just_for_reward=false
			if _i.reward_is_chosen.is_connected(confirm_page):
				_i.reward_is_chosen.disconnect(confirm_page)
			basket.remove_child(_i)
func clear_tear_basket():
	if tear_basket.get_child_count()>0:
		for _i in tear_basket.get_children():
			_i=_i as Card
			_i.just_for_check=false
			_i.just_for_reward=false
			if _i.reward_is_chosen.is_connected(tear_down):
				_i.reward_is_chosen.disconnect(tear_down)
			tear_basket.remove_child(_i)
func put_blank_to_basket():
	print("把空白的模组卡放入篮子")
	clear_basket()
	for _i in Profile.Deck:
		var flag=false
		for _j in _i.function_list:
			if _j is Card.Blank:
				flag=true
				break
		if flag:
			_i.just_for_check=true
			_i.just_for_reward=true
			_i.display()
			basket.add_child(_i)
			#_refresh_card_functions(_i)
			if !_i.reward_is_chosen.is_connected(confirm_page):
				_i.reward_is_chosen.connect(confirm_page)
func show_tear_resource():
	clear_tear_basket()
	for _i in Profile.Deck:
		if _i !=Chosen_card:
			_i.just_for_check=true
			_i.just_for_reward=true
			_i.display()
			tear_basket.add_child(_i)
			if !_i.reward_is_chosen.is_connected(tear_down):
				_i.reward_is_chosen.connect(tear_down)
## 计算当前拆解花费：70 * (1 + 0.5 * times)
func _tear_cost() -> int:
	return int(70 * (1 + 0.5 * times))
func hide_all():
	var box=$page2/VBoxContainer/HBoxContainer/PanelContainer/HFlowContainer
	for _i in box.get_children():
		_i.visible=false
func show_all():
	var box=$page2/VBoxContainer/HBoxContainer/PanelContainer/HFlowContainer
	for _i in box.get_children():
		_i.visible=true
var can_be_tear_down:bool=true
func tear_down(card:Card):
	if not can_be_tear_down:
		return
	# 算花费、扣钱、times递增
	var current_cost:int=_tear_cost()
	Profile.item.money-=current_cost
	times+=1
	# 拆解模组：跳过 null、Lock、Blank，其余全部保留
	for fun in card.function_list:
		if fun==null:
			continue
		if fun is Card.Lock or fun is Card.Blank:
			continue
		functions.append(fun)
	# 从牌库中移除该卡牌
	Profile.Deck.erase(card)
	# 如果卡牌还在 tear_basket 中，移除
	if card.get_parent()!=null:
		card.get_parent().remove_child(card)
	# 更新UI
	fresh_column()
	mode_number.text="可用模组数量：%d"%functions.size()
	cost.text="拆解所需金额：%d"%_tear_cost()
	current_money.text="目前还剩资金：%d"%Profile.item.money
	# 判断下次是否还拆得起
	can_be_tear_down=Profile.item.money>=_tear_cost()
func confirm_page(card:Card):
	Chosen_card=card
	show_alarm()
func who_is_the_target():#显示模组
	show_all()
	var page=$page2/ColorRect
	page.visible=false
	var funs=$page2/VBoxContainer/HBoxContainer/PanelContainer/HFlowContainer.get_children()
	for i in range(4):
		var fun:function=Chosen_card.function_list[i]
		if fun==null:
			funs[i]._set_function(null)
			continue
		# Blank特殊处理：display()会直接return，需要手动加载纹理
		if fun is Card.Blank:
			fun.texture=load("res://assets/cards/blank.png")
		else:
			fun.display()
		funs[i]._set_function(fun)
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(frame,"position",Vector2(-600,112),0.1)
	await tween.finished
	clear_basket()
	show_tear_resource()
	mode_number.text="可用模组数量：%d"%functions.size()
	cost.text="拆解所需金额：%d"%(70*(1+0.5*times))
	current_money.text="目前还剩资金：%d"%Profile.item.money
	tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(tear_frame,"position",Vector2(33,112),0.2)

func _on_refuse_pressed() -> void:
	Chosen_card=null
	var page=$page2/ColorRect
	page.visible=false
	pass # Replace with function body.
func show_alarm():
	var page=$page2/ColorRect
	page.visible=true
	var gframe=$page2/ColorRect/PanelContainer
	gframe.position=Vector2(760,900)
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(gframe,"position",Vector2(760,440),0.2)


func _on_confirm_pressed() -> void:
	if !is_next_step:
		approve_button.disabled=true
		put_blank_to_basket()
		approve_button.text="应用"
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(frame,"position",Vector2(33,112),0.2)
		is_next_step=true
	else:
		gear_progress()
		print("应用")
	pass # Replace with function body.
func clear_column():
	if column.get_child_count()>0:
		var kids=column.get_children()
		for _i in kids:
			column.remove_child(_i)
			_i.queue_free()
func fresh_column():
	var unit=load("res://scenes/Card/Information_unit.tscn")
	clear_column()
	for _i in functions:
		var unit_detail:Function_detail=unit.instantiate() as Function_detail
		column.add_child(unit_detail)
		unit_detail.show_unit(_i)
		unit_detail.sent_mode.connect(cope_with_mode)
		unit_detail.selected.visible=true
func open_func_list(value:Selected_function):
	if functions.size()>0:
		if Chosen_function!=null:
			Chosen_function.locked.visible=false
			Chosen_function.button.disabled=false
		Chosen_function=value#选中了哪一个空白模组
		Chosen_function.button.disabled=true
		Chosen_function.locked.visible=true
		function_frame.position=Vector2(2400,112)
		fresh_column()
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(function_frame,"position",Vector2(1529,112),0.2)
func cope_with_mode(value:function):#将Chosen_function修改为选择的function
	Chosen_function_value=value# 保存原始引用
	Chosen_function._set_function(value)
	functions.erase(value)
	fresh_column()
	Chosen_function.locked.visible = false
	Chosen_function.button.disabled=false
	if approve_button.disabled:
		if is_legal():
			approve_button.disabled=false
	mode_number.text="可用模组数量：%d"%functions.size()
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(function_frame,"position",Vector2(2400,112),0.2)
func back_to_column(value:function):#撤回选择
	if Chosen_function!=null:
		Chosen_function.locked.visible=false
		Chosen_function.button.disabled=false
		Chosen_function._set_function(Card.Blank.new())
		Chosen_function.measure.display()
		Chosen_function.button.disabled=true
		Chosen_function.locked.visible=true
		function_frame.position=Vector2(2400,112)
		functions.append(Chosen_function_value)
		Chosen_function_value=null
		fresh_column()
		mode_number.text="可用模组数量：%d"%functions.size()
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(function_frame,"position",Vector2(1529,112),0.2)
func gear_progress():#启用修改
	gear_background.visible=true
	progress.value=0
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(gear,"rotation",gear.rotation+PI*2,3)
	tween.tween_property(progress,"value",100,3)
	await tween.finished
	gear_background.visible=false
	apply_modification()
	clear_list()
	clear_basket()
	clear_tear_basket()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
func apply_modification():#将添加的模组加入选中的卡牌中
	var funs = $page2/VBoxContainer/HBoxContainer/PanelContainer/HFlowContainer.get_children()
	for i in range(4):
		var select_func:Selected_function = funs[i]
		Chosen_card.change_function(select_func.measure,i)
func is_legal()->bool:#判断卡牌是否合法
	var sum=0
	if Chosen_card!=null:
		for i in Chosen_card.function_list:
			sum+=i.point
		if sum<=Chosen_card.max_point:
			return true
	return false
