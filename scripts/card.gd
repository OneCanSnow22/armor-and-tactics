class_name Card
extends Control
var ban:TextureRect
var stack: Stack
var select:TextureRect
var function_list:Array[function]=[null, null, null, null]
var used_times:int=0
var just_for_check:bool=false
var just_for_reward:bool=false
var just_for_expand:bool=false
const max_point:int=10#所有功能点数加起来超过10就是非法卡牌
@export var leave_statue:Leave_statue
@export var discard_logo:TextureRect
@export var line_box:HFlowContainer
signal mouse_is_hover(card:Card)
signal reward_is_chosen(card:Card)
enum Leave_statue{#离开状态
	Discard,#丢弃
	Consume,#消耗
	One_off#一次性
}
class Forward extends function:
	func _init() -> void:
		id=2
		point=3
		title="前进"
		context="向前移动一格"
		animation_unit=Profile.Forward_animation.new()
		mode=Profile.Function.Forward
	func apply(menu:Main_menu):#调用功能
		print("向右移")
		menu.card_manager._anim_queue.append(animation_unit)
class Backward extends function:
	func _init() -> void:
		id=3
		point=3
		title="后退"
		context="向后移动一格"
		animation_unit=Profile.Backward_animation.new()
		mode=Profile.Function.Backward
	func apply(menu:Main_menu):#调用功能
		print("向左移")
		menu.card_manager._anim_queue.append(animation_unit)
class Discard_one extends function:
	func _init() -> void:
		id=4
		point=3
		title="丢弃1"
		context="丢弃一张牌"
		animation_unit=Profile.Discard_one_animation.new()
		mode=Profile.Function.Discard_one
	func apply(menu:Main_menu):#调用功能
		print("丢一张牌")
		menu.card_manager._anim_queue.append(animation_unit)
class Discard_two extends function:
	func _init() -> void:
		id=5
		point=4
		title="丢弃2"
		context="丢弃两张牌"
		animation_unit=Profile.Discard_two_animation.new()
		mode=Profile.Function.Discard_two
	func apply(menu:Main_menu):#调用功能
		print("丢两张牌")
		menu.card_manager._anim_queue.append(animation_unit)
class Draw_one extends function:#抽一张牌
	func _init() -> void:
		id=6
		point=3
		title="抽牌1"
		context="抽一张牌"
		animation_unit=Profile.Draw_one_animation.new()
		mode=Profile.Function.Draw_one
	func apply(main:Main_menu):
		print("抽一张牌")
		main.card_manager._anim_queue.append(animation_unit)
class Draw_two extends function:#抽两张牌
	func _init() -> void:
		id=7
		point=4
		title="抽牌2"
		context="抽两张牌"
		animation_unit=Profile.Draw_two_animation.new()
		mode=Profile.Function.Draw_two
	func apply(main:Main_menu):
		print("抽两张牌")
		main.card_manager._anim_queue.append(animation_unit)
class Draw_three extends function:#抽三张牌
	func _init() -> void:
		id=8
		point=5
		title="抽牌3"
		context="抽三张牌"
		animation_unit=Profile.Draw_three_animation.new()
		mode=Profile.Function.Draw_three
	func apply(main:Main_menu):
		print("抽三张牌")
		main.card_manager._anim_queue.append(animation_unit)
class Load extends function:
	func _init() -> void:
		id=10
		point=4
		title="加载"
		context="使手牌中一张牌\n栈类别与该牌栈类别一致"
		animation_unit=Profile.Load_animation.new()
		mode=Profile.Function.Load
	func apply(main:Main_menu):
		print("加载模块")
		main.card_manager._anim_queue.append(animation_unit)
class Replace extends function:
	func _init() -> void:
		id=9
		point=4
		title="替换"
		context="交换两张卡牌的栈"
		animation_unit=Profile.Replace_animation.new()
		mode=Profile.Function.Replace
	func apply(main:Main_menu):
		print("替换模块")
		main.card_manager._anim_queue.append(animation_unit)
class Swipe extends function:
	func _init() -> void:
		id=11
		point=3
		title="攻击"
		context="造成伤害"
		animation_unit=Profile.Swipe_animation.new()
		mode=Profile.Function.Swipe
	func get_context() -> String:
		var mode = Profile.player.attack_mode
		if mode is Shelling:
			var s := mode as Shelling
			var total := s.damage + s.bonus_damage
			if s.bonus_damage > 0:
				return "造成%d点伤害(含叠加+%d)" % [total, s.bonus_damage]
			else:
				return "造成%d点伤害" % s.damage
		return "造成%d点伤害" % mode.damage
	func apply(main:Main_menu):
		print("攻击模块")
		main.card_manager._anim_queue.append(animation_unit)
class Turn extends function:
	func _init() -> void:
		id=12
		point=3
		title="调节"
		context="转变当前的攻击模式"
		animation_unit=Profile.Turn_animation.new()
		mode=Profile.Function.Turn
	func apply(main:Main_menu):
		print("更改攻击模式")
		main.card_manager._anim_queue.append(animation_unit)
class Lock extends function:#用于对模块上锁
	func _init() -> void:
		id=1
		point=0
		title="封锁"
		context="当前模块无法使用"
		animation_unit=Profile.Lock_animation.new()
		mode=Profile.Function.Lock
class One_off extends function:
	func _init()->void:
		id=13
		point=-4
		title="1次性"
		context="该卡牌只能使用一次"
		animation_unit=Profile.One_off_animation.new()
		mode=Profile.Function.One_off
class Consume extends function:
	func _init()->void:
		id=14
		point=-5
		title="消耗"
		context="卡牌在被使用或结束回合时\n存在于手牌中都将被消耗"
		animation_unit=Profile.Consume_animation.new()
		mode=Profile.Function.Consume
class Loop_twice extends function:
	func _init()->void:
		id=15
		point=4
		title="循环2"
		context="循环执行下一个模组两次"
		animation_unit=Profile.AnimationUnit.new()
		mode=Profile.Function.Loop_twice
class Loop_third extends function:
	func _init()->void:
		id=16
		point=6
		title="循环3"
		context="循环执行下一个模组三次"
		animation_unit=Profile.AnimationUnit.new()
		mode=Profile.Function.Loop_third
class Blank extends function:#不存在于奖励卡牌中属于特殊空位用于存入其他模组
	func _init()->void:
		id=0
		point=0
		title="N/A"
		context="无效内容"
		animation_unit=null
		mode=Profile.Function.Blank
# Called when the node enters the scene tree for the first time.
signal card_clicked(card: Card)
signal card_is_deleted(card:Card)
signal card_selected(card:Card)
func _ready() -> void:
	ban=$ban
	stack=$stack
	select=$select
	#var line=$func_background/HFlowContainer
	#for i in range(4):
		#if function_list[i] != null and line!=null:
			#line.add_child(function_list[i])
	if ban!=null:
		if ban.visible==false:
			ban.visible=true
	isNotDiscard_target()
	apply_card()
	
	
func apply_function(main:Main_menu):
	var index:int=0
	while index<function_list.size():
		index=await _apply_function_at(main,index)

func _apply_function_at(main:Main_menu,index:int)->int:
	if index<0 or index>=function_list.size():
		return function_list.size()
	var current:function=function_list[index]
	if current==null:
		return index+1
	if current is Lock:
		return function_list.size()
	if current is Loop_twice or current is Loop_third:
		var repeat_count:int=2 if current is Loop_twice else 3
		var next_index:int=index+1
		var next_after:int=next_index
		for _repeat in range(repeat_count):
			next_after=await _apply_function_at(main,next_index)
			if next_after>=function_list.size():
				return function_list.size()
		return next_after
	await current.apply(main)
	return index+1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		if !just_for_check:
			if ban != null and ban.visible:
				return
			if select!= null and select.visible:
				card_clicked.emit(self)
		else:
			if just_for_reward and select.visible:
				reward_is_chosen.emit(self)
func apply_card():#启用卡牌
	if ban!=null:
		if ban.visible:
			ban.visible=false;
func ban_card():
	if ban!=null:
		if !ban.visible:
			ban.visible=true;
func discard_card():
	var tween:Tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale",Vector2(0,0),0.1)
	await tween.finished#等待动画结束后
	print("卡牌的丢弃动画播放完毕")
	card_is_deleted.emit(self)
func consume_card():
	var tween:Tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale",Vector2(0,1),0.1)
	await tween.finished#等待动画结束后
	print("卡牌的消耗动画播放完毕")
	card_is_deleted.emit(self)
func decide_card_where_to_go():#决定卡牌的处理动画
	match leave_statue:
		Leave_statue.Discard:
			discard_card()
		Leave_statue.Consume:
			consume_card()
		Leave_statue.One_off:
			print("不进入弃牌堆")
func _on_select_mouse_entered() -> void:#鼠标选中
	select.visible=true;
	select.self_modulate = Color(1, 1, 1, 0)
	var tween:Tween=create_tween()
	tween.tween_property(select,"self_modulate",Color(1,1,1,1),0.1)
	tween.set_ease(Tween.EASE_IN_OUT)
	card_selected.emit(self)
	mouse_is_hover.emit(self)
	pass # Replace with function body.
func _on_interact_mouse_exited() -> void:
	var tween:Tween=create_tween()
	tween.tween_property(select,"self_modulate",Color(1,1,1,0),0.1)
	tween.tween_callback(hide_select.bind(select))
	tween.set_ease(Tween.EASE_IN_OUT)
	card_selected.emit(null)
	mouse_is_hover.emit(null)
	pass # Replace with function body.
func hide_select(control:Control):#隐藏选择框
	control.visible=false
func display():#让数据层的同步到UI层
	var functions=$func_background/HFlowContainer.get_children()
	for i in range(functions.size()):
		function_list[i]=functions[i]#将节点信息同步
		function_list[i].display()
func random_stack():
	if !stack.visible:
		stack.visible=true
	stack.random()
	stack.position.x=40*stack.stack_pos
func copy_stack(value:Stack):
	if !stack.visible:
		stack.visible=true
	stack.stack_mode=value.stack_mode
	stack.stack_pos=value.stack_pos
	stack.fresh()
func random_stack_type(pos:Stack.Stack_pos):
	if !stack.visible:
		stack.visible=true
	stack.random_type()
	stack.stack_pos=pos
	stack.position.x=40*pos
func hide_stack():
	stack.visible=false
func set_card_go():#检查点击后卡牌的流向
	for funtion in function_list:
		if funtion!=null:
			if funtion is One_off:#如果是一次性类
				leave_statue=Leave_statue.One_off
			elif funtion is Consume:
				leave_statue=Leave_statue.Consume
func isDiscard_target():
	discard_logo.visible=true
func isNotDiscard_target():
	if discard_logo.visible:
		discard_logo.visible=false
func change_function(value:function,index:int):#更改模组
	if value==function_list[index]:
		return
	if index>=0 and index<4:
		var old=function_list[index]
		function_list[index]=value
		var HF=$func_background/HFlowContainer
		for _i in HF.get_children():
			HF.remove_child(_i)
		old.queue_free()
		for _i in function_list:
			if _i!=null:
				if _i.get_parent()!=null:
					_i.get_parent().remove_child(_i)
				HF.add_child(_i)
				_i.display()
func fresh_card():
	var HF=$func_background/HFlowContainer
	var funs=HF.get_children()
	if funs.size()==4:
		for i in range(4):
			var old=funs[i]
			HF.remove_child(old)
			if old!=function_list[i]:
				old.queue_free()
	if HF.get_child_count()==0:
		for i in function_list:
			if i!=null:
				HF.add_child(i)
		
			
