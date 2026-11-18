extends Label

## 回合标题浮动文字，实例化后显示标题文本，播放动画后自动销毁。
## 用法：
##   var title := preload("res://scenes/Effects/turn_title.tscn").instantiate()
##   title.set_turn_text("玩家回合")
##   add_child(title)
##   await title.finished  # 等待动画播完

signal finished

func set_turn_text(text_value: String) -> void:
	text = text_value
	# 初始状态：居中、透明、略小
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modulate.a = 0.0
	scale = Vector2(0.6, 0.6)
	pivot_offset=Vector2(size.x/2,size.y/2)

func _ready() -> void:
	var tween := create_tween()

	# 第一阶段：淡入 + 放大（0.3秒）— 冲击感
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.set_parallel(false)

	# 第二阶段：回弹到正常大小（0.15秒）
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

	# 第三阶段：停留（0.5秒）— 让玩家看清文字
	tween.tween_interval(1)

	# 第四阶段：向上淡出（0.4秒）
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position:y", position.y - 60, 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.set_parallel(false)

	# 动画结束
	tween.chain().tween_callback(_on_finished)


func _on_finished() -> void:
	finished.emit()
	queue_free()
