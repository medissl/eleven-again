extends Node
var audio: Node
var reduced := false
func deal(cards: Array) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree(): return
	if not reduced and is_instance_valid(audio): audio.play("shuffle",-12)
	for index in cards.size():
		if not is_instance_valid(cards[index]): continue
		var card: Control = cards[index]
		if reduced: continue
		var destination := card.position
		var stack: Vector2 = card.get_parent().get_global_transform().affine_inverse()*(get_parent().card_area.global_position+Vector2(8,12))
		card.set_meta("dealing",true)
		card.position = stack+Vector2(index*2,index*2)
		card.rotation = -0.04+index*0.012
		card.scale = Vector2.ONE*0.72
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := card.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card,"position",destination,0.38).set_delay(index*0.1)
		tween.tween_property(card,"rotation",0.0,0.38).set_delay(index*0.1)
		tween.tween_property(card,"scale",Vector2.ONE,0.38).set_delay(index*0.1)
		tween.finished.connect(func(): land(card))
func land(card: Control) -> void:
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_instance_valid(audio): audio.play("place",-15)
	if card.definition.tier() == "legend" and not reduced:
		card.reveal_flash = 1
		card.legend_reveal = true
		card.set_process(true)
		legend_notice(card)
		var pulse := card.create_tween().set_trans(Tween.TRANS_SINE)
		pulse.tween_property(card,"scale",Vector2.ONE*1.055,0.11)
		pulse.tween_property(card,"scale",Vector2.ONE,0.2)
		pulse.finished.connect(func(): card.set_meta("dealing",false); if card.has_meta("motion_feedback"): card.get_meta("motion_feedback").refresh())
	else:
		card.set_meta("dealing",false)
		if card.has_meta("motion_feedback"): card.get_meta("motion_feedback").refresh()
func legend_notice(card: Control) -> void:
	var notice := Label.new()
	notice.text = "LEGEND AVAILABLE"
	notice.theme_type_variation = "BodyStrong"
	notice.add_theme_font_size_override("font_size",17)
	notice.add_theme_color_override("font_color",Color("D9B4FF"))
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent: Control = get_parent()
	parent.add_child(notice)
	notice.position = parent.get_global_transform().affine_inverse()*card.global_position-Vector2(0,30)
	notice.size = Vector2(card.size.x,28)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fade := notice.create_tween()
	fade.tween_interval(1.0)
	fade.tween_property(notice,"modulate:a",0.0,0.3)
	fade.tween_callback(notice.queue_free)
