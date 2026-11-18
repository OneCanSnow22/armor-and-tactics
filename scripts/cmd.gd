extends TextureRect
var title: Label
var context: RichTextLabel
var input_field: LineEdit
var button1: TextureButton
var button2: TextureButton
var button3: TextureButton
var is_not_on_map:bool=false
## 打字机相关变量
var _typewriter_timer: Timer
var _typewriter_queue: Array[String] = []  # 待显示的文本队列
var _current_text: String = ""              # 当前正在打的文本
var _char_index: int = 0                    # 当前字符索引
var _typing_speed: float = 0.05             # 每个字符的间隔（秒）

## 光标闪烁相关变量
var _cursor_blink_timer: Timer
var _cursor_visible: bool = true
const CURSOR_CHAR: String = "█"  # 光标字符（可用 ▋ █ _ 等）
## CRT 滤镜控制：打开 cmd 时暂停，关闭时恢复
var _crt_node: CanvasItem = null
var _crt_was_visible: bool = true
@export var card_main:Control
@export var crt:CanvasLayer
signal shut_screen()
signal close_screen()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title = $HBoxContainer/title
	context = $context as RichTextLabel
	input_field = $input as LineEdit
	
	
	
	card_main.visible=false
	# 创建打字机定时器
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = _typing_speed
	_typewriter_timer.autostart = false
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)

	# 创建光标闪烁定时器
	_cursor_blink_timer = Timer.new()
	_cursor_blink_timer.wait_time = 0.5  # 每 0.5 秒闪烁一次
	_cursor_blink_timer.autostart = false
	_cursor_blink_timer.timeout.connect(_on_cursor_blink)
	add_child(_cursor_blink_timer)
	_cursor_blink_timer.start()

	# 初始状态不显示任何文本
	context.text = ""

	# 输入框配置
	input_field.placeholder_text = "输入命令..."

	# 向上查找同场景中的 CRT 滤镜节点（通用名称匹配）
	_try_find_crt()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 当对话框可见时，按 Enter 键处理输入
	if visible and Input.is_action_just_pressed("ui_accept"):
		if input_field.has_focus():
			# 输入框有焦点时，提交输入
			_handle_input_submit()
		else:
			# 否则关闭对话框
			_on_delete_pressed()

	# 更新输入框光标显示（基于闪烁状态）
	if visible and input_field:
		if _cursor_visible:
			input_field.caret_blink = false  # 禁用原生光标，我们手动模拟
		else:
			input_field.caret_blink = true
## 打开页面（保持原有逻辑，但清空打字机队列）
var deck:Array#需要查看的牌库
func open_page(page_title: String) -> void:
	var tween: Tween
	visible = true
	scale = Vector2(0, 0)
	pivot_offset = Vector2(960, 540)
	# 清空打字机队列和当前文本
	_stop_typewriter()
	context.text = ""
	# 暂停 CRT 滤镜（如果存在）
	_pause_crt()
	# 提升层级，确保覆盖所有界面
	z_index = 100
	if page_title == "shop":
		title.text = "🛒shop"
	elif page_title == "state":
		title.text = "🙂state"
		button1 = $"../select/button1"
		if button1!=null:
			pivot_offset = button1.global_position
	elif page_title == "deck":#牌库界面
		title.text = "🃏deck"
		button2 = $"../select/button2"
		if button2!=null:
			pivot_offset = button2.global_position
		show_card_list(Profile.Deck)
	elif page_title == "setting":
		title.text = "⚙️setting"
		button3 = $"../select/button3"
		if button3!=null:
			pivot_offset = button3.global_position
	elif page_title=="draw_deck":
		title.text="♣️draw_deck"
		show_card_list(deck)
	elif page_title=="discard_deck":
		title.text="♥️discard_deck"
		show_card_list(deck)
	elif page_title=="consume_deck":
		title.text="♦️consume_deck"
		show_card_list(deck)
	elif page_title=="repair":
		title.text="🔧repair"
	elif page_title=="charger":
		title.text="🔋charger"
	else:
		print("不存在任何页面")
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

func _on_delete_pressed() -> void:#关闭界面
	pivot_offset.x=960
	var tween=create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"scale",Vector2(0,1),0.2)
	await tween.finished
	if visible:
		visible = false
		_stop_typewriter()
		context.text = ""
		# 恢复 CRT 滤镜（如果存在）
		_resume_crt()
		# 还原层级
		z_index = 0
		if card_main.visible:
			var page=$Card_Main/CardList/HFlowContainer
			for _i in page.get_children():
				page.remove_child(_i)
			card_main.visible=false
		if is_not_on_map:
			shut_screen.emit()
	close_screen.emit()
	print("发送关闭信号")
	pass # Replace with function body.

## ===== 打字机系统 =====

## 开始逐行对话
## lines: 字符串数组，每行会依次显示
## speed: 可选，每个字符的间隔（秒）
func start_dialogue(lines: Array, speed: float = 0.05) -> void:
	if lines.is_empty():
		return

	# 确保所有元素都是字符串
	_typewriter_queue.clear()
	for line in lines:
		if line is String:
			_typewriter_queue.append(line as String)
	
	_typewriter_timer.wait_time = speed
	_char_index = 0
	_current_text = ""
	context.text = ""

	# 开始打第一行
	_start_next_line()

## 停止打字机（用于关闭对话框或中断对话）
func _stop_typewriter() -> void:
	if _typewriter_timer:
		_typewriter_timer.stop()
	_typewriter_queue.clear()
	_char_index = 0

## 开始下一行
func _start_next_line() -> void:
	if _typewriter_queue.is_empty():
		return

	_current_text = _typewriter_queue.pop_front()
	_char_index = 0
	# 不清空已有内容，如果是第一行才清空
	if context.text.is_empty():
		context.text = ""
	else:
		# 之前的内容后面加换行符
		context.text += "\n"
	_typewriter_timer.start()

## 打字机定时器回调（每帧打一个字符）
func _on_typewriter_tick() -> void:
	if _char_index >= _current_text.length():
		# 当前行打完了，停一下再打下一行
		_typewriter_timer.stop()
		# 0.5 秒后开始下一行
		await get_tree().create_timer(0.5).timeout
		_start_next_line()
		return

	# 添加一个字符
	var char: String = _current_text.substr(_char_index, 1)
	context.text += char
	_char_index += 1

## ===== 光标系统 =====

## 光标闪烁定时器回调
func _on_cursor_blink() -> void:
	_cursor_visible = !_cursor_visible

## ===== 输入系统 =====

## 处理输入提交（按 Enter）
func _handle_input_submit() -> void:
	var input_text: String = input_field.text.strip_edges()
	if input_text.is_empty():
		return

	# 将输入内容追加到对话历史
	context.text += "\n>>" + input_text
	input_field.clear()

	# 这里可以添加命令解析逻辑
	print("玩家输入: " + input_text)

## ===== 可选：着色器光标效果 =====
## 如果需要着色器光标，可以在 RichTextLabel 的 text 中添加自定义 BBCode 标签
## 例如：[cursor]█[/cursor]，然后在着色器里根据标签判断光标位置并应用辉光效果

## 光标辉光着色器伪代码（供参考，需要配合 RichTextLabel 的 meta 系统）
## """
## shader_type canvas_item;
## uniform vec4 cursor_color: source_color = vec4(0.0, 1.0, 1.0, 1.0);
## uniform float cursor_blink: hint_range(0.0, 1.0) = 1.0;
##
## void fragment() {
##     vec4 tex_color = texture(TEXTURE, UV);
##     COLOR = tex_color;
##
##     // 这里可以通过 UV 坐标判断是否在光标位置（需要从脚本传递位置信息）
##     if (is_cursor_position) {
##         COLOR.rgb = mix(COLOR.rgb, cursor_color.rgb, 0.5);
##         COLOR.a = mix(COLOR.a, cursor_color.a * cursor_blink, 0.8);
##     }
## }
## """
func show_card_list(deck:Array):
	if !card_main.visible:
		card_main.visible=true
		input_field.visible=false
	var basket=$Card_Main/CardList/HFlowContainer
	if basket.get_child_count()>0:#删除原先挂载的节点
		for _i in basket.get_children():
			basket.remove_child(_i)
	for _i in deck:
		_i=_i as Card
		basket.add_child(_i)
		_i.apply_card()
		_i.hide_stack()
		_i.fresh_card()
		_i.display()
		_i.just_for_check=true
		if !_i.mouse_is_hover.is_connected(show_information):
			_i.mouse_is_hover.connect(show_information)
		_refresh_card_functions(_i)
	print()
func _refresh_card_functions(card:Card) -> void:
	for child in card.line_box.get_children():
		card.line_box.remove_child(child)
	for i in range(card.function_list.size()):
		var fun:function=card.function_list[i]
		if fun!=null:
			if fun.get_parent()!=null:
				fun.get_parent().remove_child(fun)
			card.line_box.add_child(fun)
func show_information(card:Card):
	print("显示卡牌信息")
	var ulist=$Card_Main/PanelContainer.get_child(0).get_children()
	var step=0
	if card!=null:
		for unit in ulist:
			unit.show_unit(card.function_list[step])
			step+=1
	else:
		for unit in ulist:
			unit.show_unit(null)

## ===== CRT 滤镜控制 =====

## 向上遍历场景树，查找名称含 "crt" 的 CanvasItem 节点
func _try_find_crt() -> void:
	var parent = get_parent()
	while parent != null:
		for child in parent.get_children():
			if child == self:
				continue
			if child is CanvasItem and "CRT" in child.name.to_upper():
				_crt_node = child as CanvasItem
				return
		parent = parent.get_parent()

## 暂停 CRT 滤镜
func _pause_crt() -> void:
	if crt!=null:
		crt.visible=false

## 恢复 CRT 滤镜
func _resume_crt() -> void:
	if crt!=null:
		crt.visible=true
