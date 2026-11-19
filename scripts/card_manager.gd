extends CanvasLayer
class_name Card_Manager
const CARD_SCENE: PackedScene = preload("res://scenes/Card/card.tscn")
var deck: Array[Card] = []
var HintStacks:Array[ColorRect]
var stackBar:Array[ColorRect]=[null,null,null]
var stackArray:Array=[null,null,null]
var discard_deck:Array[Card]#消耗牌堆
var consume_deck:Array[Card]#弃牌堆
var hand:Array[Card]
var _current_page: int = 0
var _container: Control
var _btn_previous: TextureButton
var _btn_next: TextureButton
var drawStep:int=0
var need_discard:int=0
var handCount:int=0
var last_card:Card#用于显示的第一个卡牌
var total_pages:int
var need_draw:int=0
var Fight_Menu:Main_menu#战斗场景的绑定
const enhance_power=2#攻击力提升数值
@export var draw_label:Label
@export var discard_label:Label
@export var consume_label:Label
@export var alarm:ColorRect
@export var ban:Control
@export var finished_button:PanelContainer
@export var submit_button:PanelContainer
@export var ban_interact:ColorRect
@export var subutton:Button
@export var draw_deck_button:TextureButton
@export var discard_deck_button:TextureButton
@export var consume_deck_button:TextureButton
enum Click_mode{
	Fuction_mode,
	Discard_mode,
	Load_mode,
	Replace_mode
}
var click_mode=Click_mode.Fuction_mode
const PAGE_SIZE: int = 7
var _anim_queue: Array[Profile.AnimationUnit] = []#动画队列
var _is_playing: bool = false#动画队列是否正在进行
var _gather_tween: Tween = null#当前手牌聚拢动画引用
signal _discard_submitted#弃牌提交信号，供 AnimationUnit await
signal _replace_submitted#替换提交信号，供 AnimationUnit await
signal _load_submitted#加载完成信号，供 Load_animation await
var _replace_first: Card = null#替换模式选中的第一张牌
var _replace_second: Card = null#替换模式选中的第二张牌
## 等待手牌聚拢动画完成（如果有的话），用于抽牌等需要手牌稳定的操作
func await_hand_settled() -> void:
	if _gather_tween != null and _gather_tween.is_running():
		await _gather_tween.finished
func _ready() -> void:
	$ScaleRoot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$ScaleRoot/Column/TextureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container = $ScaleRoot/Column/TextureRect/Context
	_btn_previous = $ScaleRoot/Column/TextureRect/previous
	_btn_next = $ScaleRoot/Column/TextureRect/next
	stackBar[0]=$VBoxContainer/StackBar/stack1
	stackBar[1]=$VBoxContainer/StackBar/stack2
	stackBar[2]=$VBoxContainer/StackBar/stack3
	# 等一帧确保所有 AutoLoad 的 _ready() 已执行完毕
	await get_tree().process_frame
	deck = copy_all_deck()
	shuffle(deck)
	draw_label.text=str(deck.size())
	discard_label.text="0"
	consume_label.text="0"
	# 绑定按钮信号
	_btn_previous.pressed.connect(_on_previous_pressed)
	_btn_next.pressed.connect(_on_next_pressed)
	_btn_previous.disabled=true
	_btn_next.disabled=true
	alarm.self_modulate=Color(1,1,1,0)
	ban.visible=false
	finished_button.visible=false
	submit_button.visible=false
	ban_interact.visible=false
	subutton.disabled=true
	subutton.pressed.connect(_on_submit_button_pressed)
	for i in range(3):
		stackArray[i]=Stack.new()
		if stackArray[i]!=null:
			stackArray[i].stack_mode=Stack.Stack_mode.Empty
			match i:
				0:
					stackArray[i].stack_pos=Stack.Stack_pos.Left
				1:
					stackArray[i].stack_pos=Stack.Stack_pos.Medium
				2:
					stackArray[i].stack_pos=Stack.Stack_pos.Right
	show_information(null)
	#await draw_cards(7)
	#show_finished_button()
	HintStacks.resize(3)
	HintStacks[0]=$Baninteract/Stack1
	HintStacks[1]=$Baninteract/Stack2
	HintStacks[2]=$Baninteract/Stack3
	# 刷新显示
	#refresh_display()
func _process(_delta: float) -> void:
	if click_mode==Click_mode.Discard_mode and Input.is_action_just_pressed("quit"):#撤销所有被选中的弃牌目标
		discardNum=FirstDiscardNum
		subutton.disabled=true
		for card_node: Node in _container.get_children():
			var card: Card = card_node as Card
			if card != null:
				card.isNotDiscard_target()
	elif click_mode==Click_mode.Replace_mode and Input.is_action_just_pressed("quit"):#撤销替换选择
		_replace_first=null
		_replace_second=null
		subutton.disabled=true
		for card_node: Node in _container.get_children():
			var card: Card = card_node as Card
			if card != null:
				card.isNotDiscard_target()
func show_finished_button():#显示结束回合按钮
	finished_button.visible=true
	finished_button.scale=Vector2(0,0)
	if finished_button!=null:
		var tween=create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(finished_button,"scale",Vector2(1,1),0.3)
## 获取总页数
func _get_total_pages() -> int:
	return ceilf(float(_container.get_child_count()) / float(PAGE_SIZE)) as int

## 清除当前页所有卡牌节点（用快照避免迭代器失效）
func _clear_display_cards() -> void:
	if(_container.get_child_count()):
		var children: Array[Node] = _container.get_children()
		for child: Node in children:
			if child is Card:
				_container.remove_child(child)
## 刷新当前页的卡牌显示
func shuffle(array:Array):#打乱顺序
	for i in range(array.size() - 1, 0, -1):
		var j: int = Profile.rng.randi_range(0, i)
		var temp= array[i]
		array[i] = array[j]
		array[j] = temp
## 上一页
func _on_previous_pressed() -> void:
	if _current_page>0:
		_current_page-=1
		move_right()
		if _current_page==0:
			_btn_previous.disabled=true
	# 基于当前页码和总页数判断，而非无脑启用
	if _current_page < total_pages - 1:
		_btn_next.disabled=false
	else:
		_btn_next.disabled=true
	#refresh_display()

## 下一页
func _on_next_pressed() -> void:
	if _btn_previous.disabled:
		_btn_previous.disabled=false
	if _current_page < total_pages - 1:
		_current_page += 1
		move_left()
	if _current_page==total_pages-1:
		_btn_next.disabled=true
		#refresh_display()
func add_card_to_hand(stack: Stack) -> void:
	await await_hand_settled()
	if deck.size() > 0:
		print("还有牌抽")
	elif discard_deck.size()>0:
		print("没有牌抽")
		for i in range(discard_deck.size()):
			deck.append(discard_deck.pop_front())
		shuffle(deck)
		draw_label.text=str(deck.size())
		discard_label.text=str(discard_deck.size())
	else:
		return
	var card: Card = deck.pop_front()
	# 在 add_child 之前判断当前页是否已满（用当前子节点数算）
	var cards_on_current_page: int = clampi(_container.get_child_count() - _current_page * PAGE_SIZE, 0, PAGE_SIZE)
	var page_full: bool = cards_on_current_page >= PAGE_SIZE
	if stack == null:
		_container.add_child(card)
		card.random_stack()
		card.display()
	else:
		_container.add_child(card)
		card.copy_stack(stack)
		card.display()
	card.isNotDiscard_target()
	card.set_card_go()
	if card.just_for_check:
		card.just_for_check=false
	card.scale=Vector2(0.5,0.5)
	card.modulate=Color(1,1,1,0)
	if _container.get_child_count()==1:
		card.position=Vector2(13,0)
	else:
		if last_card!=null:
			card.position=Vector2(last_card.position.x+133,0)
		else:#删除了第一个再添加时
			card.position=Vector2(13,0)
	var tween:Tween=create_tween()
	if not page_full:#当前窗口不满7张（加入这张之前），添加动画
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(card,"modulate",Color(1,1,1,1),0.2)
		tween.tween_property(card,"scale",Vector2(1,1),0.2)
	else:#当前窗口满7张，直接排在末尾
		card.modulate=Color(1,1,1,1)
		card.scale=Vector2(1,1)
		alarm.self_modulate=Color(1,1,1,0)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(alarm,"self_modulate",Color(1,0,0,1),0.2)
		tween.tween_property(alarm,"self_modulate",Color(1,1,1,0),0.2)
		_btn_next.disabled=false
	if card.stack != null:
		if !is_coverd(card.stack):
			card.ban_card()
		else:
			card.apply_card()
	last_card=card
	total_pages = _get_total_pages()
	if not card.card_clicked.is_connected(cope_with_card_clicked):
		card.card_clicked.connect(cope_with_card_clicked)
	if not card.card_is_deleted.is_connected(cope_with_the_final):
		card.card_is_deleted.connect(cope_with_the_final)
	if not card.card_selected.is_connected(show_information):
		card.card_selected.connect(show_information)
	drawStep+=1
	draw_label.text=str(deck.size())
func move_left():
	var tween:Tween=create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	for card in _container.get_children():
		tween.tween_property(card,"position",card.position-Vector2(7* 133, 0),0.2)
func move_right():
	var tween:Tween=create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	for card in _container.get_children():
		tween.tween_property(card,"position",card.position+Vector2(7* 133, 0),0.2)
	
func _on_button_pressed() -> void:#测试用按钮
	add_card_to_hand(null)
	pass # Replace with function body.
func enhance_for_stack():
	for i in range(stackArray.size()-1):
		if stackArray[0].stack_mode!=stackArray[i+1].stack_mode:
			return
	match stackArray[0].stack_mode:
		Stack.Stack_mode.Melee:
			Profile.player.melee.enhance(enhance_power)
		Stack.Stack_mode.Shoot:
			Profile.player.shoot.enhance(enhance_power)
		Stack.Stack_mode.Shelling:
			Profile.player.shelling.enhance(enhance_power)
	clear_stackBar()
func clear_stackBar():#清除栈条所有栈
	var tween:Tween=create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	for i in range(3):
		if stackArray[i]!=null:
			stackArray[i].stack_mode=Stack.Stack_mode.Empty
			tween.tween_property(stackBar[i],"color",Color(1,1,1,0),0.2)
	
	await  tween.finished
	fresh_cards()
var is_function:bool#启用效果
func cope_with_card_clicked(card:Card):#处理点击信号
	is_function=false
	match click_mode:
		Click_mode.Fuction_mode:
			ban.visible=true
			ChosenStack=card.stack
			card.used_times+=1
			if card.stack!=null:
				#print_stackBar()
				check_stack(card.stack)
				#print_stackBar()
				card.decide_card_where_to_go()
				fresh_cards()
				is_function=true
		Click_mode.Discard_mode:#点击为需要丢弃的卡牌
			if discardNum>0:
				if card.discard_logo.visible:
					# 已经标记为弃牌目标，再次点击取消
					discardNum+=1
					card.isNotDiscard_target()
					subutton.disabled=true
				else:
					# 标记为弃牌目标
					discardNum-=1
					card.isDiscard_target()
					if discardNum==0:
						subutton.disabled=false
		Click_mode.Load_mode:
			if ChosenStack!=null:
				card.stack.stack_mode=ChosenStack.stack_mode
				card.stack.fresh()
				ban_interact.visible=false
				finished_button.visible=true
				click_mode=Click_mode.Fuction_mode
				fresh_cards()
				_load_submitted.emit()
		Click_mode.Replace_mode:
			if card.stack != null and card.stack.stack_mode != Stack.Stack_mode.Empty:
				if _replace_first == null:
					# 选第一张
					_replace_first = card
					card.isDiscard_target()
				elif _replace_second == null and card != _replace_first:
					# 选第二张
					_replace_second = card
					card.isDiscard_target()
					subutton.disabled=false
				elif card == _replace_first or card == _replace_second:
					# 点击已选的牌取消选择
					card.isNotDiscard_target()
					if card == _replace_first:
						_replace_first = null
					else:
						_replace_second = null
					subutton.disabled=true
	
var discardNum:int#需要弃牌的数量
var FirstDiscardNum:int#起初需要弃牌的数量
var ChosenStack:Stack
func enter_discard_time(value:int):#进入弃牌模式，await 直到玩家提交
	discardNum=value#需要丢弃的数量
	FirstDiscardNum=discardNum
	click_mode=Click_mode.Discard_mode
	discard_fresh()
	ban.visible=false#关闭功能模式的 ban，让牌可以被点击
	ban_interact.visible=true
	ban_interact.color=Color("1d1d1d99")
	hide_hint()
	finished_button.visible=false
	submit_button.visible=true
	subutton.disabled=true
	# 如果手牌不够弃，直接跳过
	if _container.get_child_count() < discardNum:
		exit_discard_mode()
		return
	await _discard_submitted
func enter_load_time():#栈加载选择界面，await 直到玩家选择目标卡牌
	click_mode=Click_mode.Load_mode
	load_fresh()
	ban_interact.visible=true
	ban.visible=false
	ban_interact.color=Color(Stack.Stack_color[ChosenStack.stack_mode], 0.6)
	hide_hint()
	finished_button.visible=false
	await _load_submitted
func enter_replace_time():#进入替换模式，await 直到玩家提交
	click_mode=Click_mode.Replace_mode
	_replace_first=null
	_replace_second=null
	replace_fresh()
	ban.visible=false#关闭功能模式的 ban
	ban_interact.visible=true
	ban_interact.color=Color("1d1d1d99")
	hide_hint()
	finished_button.visible=false
	submit_button.visible=true
	subutton.disabled=true
	# 如果手牌不够两张有栈的牌，直接跳过
	var valid_count:int=0
	for card_node: Node in _container.get_children():
		var card: Card = card_node as Card
		if card != null and card.stack != null and card.stack.stack_mode != Stack.Stack_mode.Empty:
			valid_count+=1
	if valid_count < 2:
		ban_interact.visible=false
		submit_button.visible=false
		click_mode=Click_mode.Fuction_mode
		return
	await _replace_submitted
func submit_replace():#替换提交回调，交换两张牌的栈
	if click_mode != Click_mode.Replace_mode:
		return
	if _replace_first==null or _replace_second==null:
		return
	# 交换两张牌的栈模式和位置
	var temp_mode: Stack.Stack_mode = _replace_first.stack.stack_mode
	var temp_pos: Stack.Stack_pos = _replace_first.stack.stack_pos
	_replace_first.stack.stack_mode = _replace_second.stack.stack_mode
	_replace_first.stack.stack_pos = _replace_second.stack.stack_pos
	_replace_second.stack.stack_mode = temp_mode
	_replace_second.stack.stack_pos = temp_pos
	_replace_first.stack.fresh()
	_replace_first.isNotDiscard_target()
	_replace_second.stack.fresh()
	_replace_second.isNotDiscard_target()
	exit_replace_mode()
func exit_replace_mode():
	_replace_first=null
	_replace_second=null
	ban_interact.visible=false
	submit_button.visible=false
	finished_button.visible=true
	click_mode=Click_mode.Fuction_mode
	subutton.disabled=true
	fresh_cards()
	_replace_submitted.emit()
func _on_submit_button_pressed():
	match click_mode:
		Click_mode.Discard_mode:
			submit_discard()
		Click_mode.Replace_mode:
			submit_replace()
func submit_discard():#弃牌提交回调，收集标记牌并逐张弃掉
	if click_mode != Click_mode.Discard_mode:
		return
	# 收集所有标记了 discard_logo 的牌
	var to_discard: Array[Card] = []
	for card_node: Node in _container.get_children():
		var card: Card = card_node as Card
		if card != null and card.discard_logo.visible:
			to_discard.append(card)
	# 逐张执行弃牌
	for card: Card in to_discard:
		card.leave_statue = Card.Leave_statue.Discard
		await card.decide_card_where_to_go()
		await get_tree().create_timer(0.1).timeout
	exit_discard_mode()
func exit_discard_mode():#退出弃牌模式，恢复功能模式
	click_mode=Click_mode.Fuction_mode
	ban_interact.visible=false
	submit_button.visible=false
	subutton.disabled=true
	finished_button.visible=true
	ban.visible=true
	fresh_cards()
	_discard_submitted.emit()
func print_stackBar():
	print("栈堆目前有：")
	for stack in stackArray:
		if stack!=null:
			print("栈的类型"+str(stack.stack_mode))
		else:
			print("没有栈")
func check_stack(stack:Stack):#判断是否可以覆盖
	if stack!=null:
		if is_coverd(stack):
			apply_stack(stack)
func apply_stack(stack:Stack):
	if stackArray[stack.stack_pos]==null:
		print("复制失败：该位置为空指针")
		return
	stackArray[stack.stack_pos].stack_mode = stack.stack_mode
	var tween:Tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(stackBar[stack.stack_pos],"color",stack.color,0.2)
	await tween.finished#等待添加动画
	enhance_for_stack()
func is_coverd(stack:Stack)->bool:#判断是否可以覆盖
	# 同类型不能替换，只能被克制链替换：Melee→Shoot→Shelling→Melee
	var cover_list:Dictionary={
		Stack.Stack_mode.Melee:Stack.Stack_mode.Shoot,
		Stack.Stack_mode.Shoot:Stack.Stack_mode.Shelling,
		Stack.Stack_mode.Shelling:Stack.Stack_mode.Melee
	}
	var current: Stack = stackArray[stack.stack_pos]
	# 空位置直接放
	if current == null:
		return true
	# 传入的栈是空类型，不能覆盖
	if stack.stack_mode == Stack.Stack_mode.Empty:
		return false
	# 当前槽位是空类型，可以直接放
	if current.stack_mode == Stack.Stack_mode.Empty:
		return true
	# 当前槽位与传入栈同类型，不能覆盖
	if current.stack_mode == stack.stack_mode:
		return false
	# 查克制链
	if cover_list.has(current.stack_mode) and cover_list[current.stack_mode] == stack.stack_mode:
		return true
	return false
func fresh_cards():
	for card in _container.get_children():
		var chip:Card=card as Card
		if is_coverd(chip.stack):
			if chip.ban.visible==true:
				chip.apply_card()
		else:
			chip.ban_card()
func get_previous_sibling(node: Node)->Node:
	if not node or not node.get_parent():
		return null
	var parent = node.get_parent()
	var siblings = parent.get_children()
	var current_index = siblings.find(node)
	if current_index > 0:  # 确保有前一个兄弟
		return siblings[current_index - 1]
	return null  # 没有前一个兄弟，是第一个子节点
func get_next_sibling(node: Node)->Node:
	if not node or not node.get_parent():
		return null
	var parent = node.get_parent()
	var siblings = parent.get_children()
	var current_index = siblings.find(node)
	if current_index <siblings.size()-1:  # 确保有后一个兄弟
		return siblings[current_index + 1]
	return null  # 没有后一个兄弟，是最后一个子节点

		
func final_animation(card:Card):
	var the_next_card=get_next_sibling(card)
	if the_next_card!=null:
		var all=_container.get_children()
		var current_index=all.find(the_next_card)
		# 启动聚拢动画但不等待，让功能队列可以立即开始
		_gather_tween=create_tween()
		_gather_tween.set_parallel(true)
		_gather_tween.set_trans(Tween.TRANS_BACK)
		_gather_tween.set_ease(Tween.EASE_OUT)
		for i in range(current_index,all.size()):
			_gather_tween.tween_property(all[i],"position",all[i].position-Vector2(133,0),0.2)
		last_card=all[all.size()-1]
	else:
		last_card=get_previous_sibling(card)
	if card.leave_statue==card.Leave_statue.Discard:
		discard_deck.append(card)
		discard_label.text=str(discard_deck.size())
	_container.remove_child(card)
	total_pages = _get_total_pages()
	if _container.get_children().size() <= 7:
		_btn_next.disabled=true
	# 左移动画结束后，根据 need_draw 逐张抽牌
	#if need_draw > 0:
		#await draw_cards(need_draw)
		#need_draw = 0
	if is_function:
		_anim_queue.clear()
		await card.apply_function(Fight_Menu)
		await consume_queue()
	if click_mode != Click_mode.Discard_mode:
		ban.visible=false
	is_function=false
## 抽取指定数量的牌，每张牌之间等待动画播完。
## [param count] 要抽的张数。
func draw_cards(count: int) -> void:
	var stacks:Array
	var need_put_stack:bool=false
	if count>=3:#必定有三张栈位置不同
		need_put_stack=true
		for i in range(3):
			var st=Stack.new()
			st.stack_pos=i as Stack.Stack_pos
			st.random_type()
			stacks.append(st)
		for i in range(count-3):
			var st=Stack.new()
			st.random()
			stacks.append(st)
		stacks.shuffle()
	for _i in range(count):
		if deck.size() > 0 or discard_deck.size() > 0:
			if !need_put_stack:
				add_card_to_hand(null)
			else:
				add_card_to_hand(stacks[_i])
			await get_tree().create_timer(0.1).timeout
func cope_with_the_final(card:Card):
	if card!=null:
		final_animation(card)
func show_information(card:Card):
	var showArray:Array
	showArray.resize(4)
	showArray[0]=$PanelContainer/VBoxContainer/PanelContainer1
	showArray[1]=$PanelContainer/VBoxContainer/PanelContainer2
	showArray[2]=$PanelContainer/VBoxContainer/PanelContainer3
	showArray[3]=$PanelContainer/VBoxContainer/PanelContainer4
	if card!=null:
		for i in range(4):
			showArray[i].show_unit(card.function_list[i])
	else:
		for i in range(4):
			showArray[i].show_unit(null)

func hide_finished_button():#隐藏回合结束按钮
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(finished_button,"scale",Vector2(0,0),0.4)
	await tween.finished
	finished_button.visible=false
func _on_finished_button_pressed() -> void:#结束回合
	clear_stackBar()
	hide_finished_button()
	ban.visible = true
	# 用快照避免迭代过程中子节点变化
	var cards: Array[Node] = _container.get_children()
	for card_node: Node in cards:
		var card: Card = card_node as Card
		if card != null:
			await card.decide_card_where_to_go()
			await get_tree().create_timer(0.15).timeout
	Fight_Menu._finish_shelling_turn(Fight_Menu.CharacterArray[0] as Character)
	Fight_Menu.Turn_for_enemys()
func consume_queue():
	if _is_playing or _anim_queue.is_empty():
		return
	_is_playing = true
	var unit = _anim_queue.pop_front()
	await unit.play(Fight_Menu)   # play 内部做动画，结束后 return
	_is_playing = false
	await consume_queue()
func load_fresh():#加载选择界面时禁用所有同类型的栈卡
	for card in _container.get_children():
		card.apply_card()
		if card.stack!=null:
			if card.stack.stack_mode==ChosenStack.stack_mode:
				card.ban_card()
func replace_fresh():#替换模式下，没有栈或栈为空的牌不可选
	for card in _container.get_children():
		card.apply_card()
		if card.stack==null or card.stack.stack_mode==Stack.Stack_mode.Empty:
			card.ban_card()
func discard_fresh():
	for card in _container.get_children():
		card.apply_card()
func hide_hint():#用于隐藏所有提示栈
	for coi in HintStacks:
		coi.visible=false
func copy_card(value:Card)->Card:#复制卡牌
	if value!=null:
		var card_scene=load("res://scenes/Card/card.tscn")
		var card :Card= card_scene.instantiate() as Card 
		card.function_list.resize(4)
		var step=0
		card.used_times=value.used_times
		for _i in value.function_list:
			card.function_list[step]=Profile.function_factory(_i)
			step+=1
		card.fresh_card()
		return card
	return null
func copy_all_deck()->Array[Card]:#复制所有的牌库到战斗场景
	var deck:Array[Card]
	for _i in Profile.Deck:
		if _i is Card:
			var card=copy_card(_i)
			if card!=null:
				deck.append(card)
	return deck
