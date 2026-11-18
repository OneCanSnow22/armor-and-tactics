extends Control

## 状态栏脚本。自动检测镜像并修复 Label 文字方向和位置。

func _ready() -> void:
	if scale.x == -1.0:
		_fix_label($HBoxContainer/Progress/Label, 9.0, 40.0)
		_fix_label($mode_debuff/Label, 0.0, 40.0)

## 修复被镜像的 Label：反转文字方向 + 还原视觉位置
func _fix_label(label: Label, original_left: float, original_right: float) -> void:
	if label == null:
		return
	# 抵消父级镜像，文字恢复正常
	label.scale.x = -1.0
	# 翻转锚点到右侧对齐
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.grow_horizontal = 0
	# 反转 offset 还原视觉位置
	label.offset_left = -original_right
	label.offset_right = -original_left
