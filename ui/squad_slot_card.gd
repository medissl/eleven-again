extends "res://ui/player_card.gd"
var editor: Control
var card_index := -1
var slot := -1
func _get_drag_data(_at: Vector2) -> Variant:
	if editor.opponent_mode or definition.person_id in editor.unavailable: return null
	var preview := preload("res://ui/player_card.gd").new()
	preview.custom_minimum_size=Vector2(104,145.6)
	preview.size=preview.custom_minimum_size
	preview.bind(definition,info)
	preview.mouse_filter=MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	editor.begin_player_drag()
	return {"type":"owned_squad_card","editor":editor.get_instance_id(),"index":card_index,"card_id":definition.card_id}
func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return slot >= 0 and data is Dictionary and data.get("type") == "owned_squad_card" and data.get("editor") == editor.get_instance_id() and data.get("index") is int and editor.can_assign(data.index,slot) and editor.plans[editor.team].cards[data.index].card_id == data.get("card_id")
func _drop_data(at: Vector2, data: Variant) -> void:
	if _can_drop_data(at,data): editor.assign_index(data.index,slot)
