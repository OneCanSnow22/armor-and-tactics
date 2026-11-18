extends Button
var weapon:Attack
var cost:int
var Pawn_flag=false#收购
signal weapon_clicked(value:Attack)
signal weapon_selected(value:Attack)
signal cost_is_input(value:int)
signal cost_is_apply(value:int)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	weapon_clicked.emit(weapon)
	if Pawn_flag:
		cost_is_apply.emit(cost)
		queue_free()
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	weapon_selected.emit(weapon)
	if Pawn_flag:
		cost_is_input.emit(cost)
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	weapon_selected.emit(null)
	pass # Replace with function body.
func set_weapon(value:Attack):
	weapon=value
	if weapon!=null:
		text=weapon.code
	cost=weapon.evaluate_price()
