extends RefCounted
## Presentation only. Never delay actions, consume gameplay RNG or move layout slots.

static func bind_control(control: Control, reduced: Callable) -> void:
	if not (control is BaseButton or control is Slider or control is LineEdit) or control.has_meta("motion_feedback"): return
	var viewport := control.get_viewport()
	if not viewport.has_meta("motion_input"):
		viewport.set_meta("motion_input",true)
		viewport.add_child(InputMode.new())
	if control is Button: preload("res://ui/glass_panel.gd").button(control)
	var feedback := Feedback.new()
	feedback.name = "MotionFeedback"
	feedback.control = control
	feedback.reduced = reduced
	control.set_meta("motion_feedback",feedback)
	control.add_child(feedback)

static func settle_tree(node: Node) -> void:
	if node.has_meta("motion_feedback"): node.get_meta("motion_feedback").refresh(true)
	for child in node.get_children(): settle_tree(child)

static func freeze(node: Node) -> void:
	# Outgoing nodes cannot act or advance a hidden match. Names cannot shadow new controls.
	node.name = "Leaving_"+str(node.name)
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): freeze(child)
	node.process_mode = Node.PROCESS_MODE_DISABLED

class InputMode:
	extends Node
	func _input(event: InputEvent) -> void:
		var viewport := get_viewport()
		var keyboard: bool = viewport.get_meta("keyboard_navigation",false)
		var next := keyboard
		if event is InputEventKey and event.pressed: next = true
		elif event is InputEventMouseButton or event is InputEventMouseMotion: next = false
		if next == keyboard: return
		viewport.set_meta("keyboard_navigation",next)
		get_tree().call_group("motion_feedback","input_mode_changed")

class Feedback:
	extends Node
	var control: Control
	var reduced: Callable
	var tween: Tween
	var amount := 0.0
	var down := false
	var base_scale := Vector2.ONE
	var base_tint := Color.WHITE
	var press_layout_down := false
	func _ready() -> void:
		add_to_group("motion_feedback")
		base_scale = control.scale
		base_tint = control.self_modulate
		control.mouse_entered.connect(refresh)
		control.mouse_exited.connect(refresh)
		control.focus_entered.connect(refresh)
		control.focus_exited.connect(refresh)
		if control is BaseButton:
			control.button_down.connect(func(): down=true; refresh())
			control.button_up.connect(func(): down=false; refresh())
			control.toggled.connect(func(_pressed): refresh())
		control.resized.connect(func(): control.pivot_offset=control.size/2)
		control.pivot_offset = control.size/2
		input_mode_changed()
	func input_mode_changed() -> void:
		if not is_inside_tree() or get_viewport() == null: return
		var keyboard: bool = get_viewport().get_meta("keyboard_navigation",false)
		if control.get_meta("game_control",false): control.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		elif keyboard: control.remove_theme_stylebox_override("focus")
		else: control.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		refresh(true)
	func refresh(immediate: bool = false) -> void:
		if not is_inside_tree() or get_viewport() == null: return
		press_layout()
		if tween != null: tween.kill()
		var disabled: bool = control is BaseButton and control.disabled
		var keyboard: bool = get_viewport().get_meta("keyboard_navigation",false)
		var active := not disabled and (control.has_focus() if keyboard else control.get_global_rect().has_point(control.get_global_mouse_position()))
		var target := 0.0 if disabled else 0.55 if down else 1.0 if active else 0.0
		if immediate or reduced.call():
			apply(target)
			return
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_method(apply,amount,target,0.07 if down else 0.14)
	func apply(value: float) -> void:
		amount = value
		if control.get_meta("dealing",false): return
		var reduced_now: bool = reduced.call()
		var zoom := 1.0 # Stable pixel clusters; surface/palette animation supplies feedback.
		control.scale = base_scale*zoom
		control.self_modulate = base_tint*Color(1.0+0.07*value,1.0+0.07*value,1.0+0.07*value,1)
		if control.has_meta("motion_surface"):
			var surface: Control = control.get_meta("motion_surface")
			surface.activity = value
			surface.pressed_surface = down
			surface.keyboard_focus = control.has_focus() and get_viewport().get_meta("keyboard_navigation",false)
			surface.queue_redraw()
		control.queue_redraw()
	func press_layout() -> void:
		if not control.has_meta("motion_surface") or not control is Button or down == press_layout_down: return
		press_layout_down=down
		var style: StyleBox = control.get_theme_stylebox("pressed").duplicate()
		style.content_margin_top=10 if down else 8
		style.content_margin_bottom=6 if down else 8
		control.add_theme_stylebox_override("pressed",style)
		for child in control.get_children():
			if not child is Control or child == control.get_meta("motion_surface"): continue
			if down:
				child.set_meta("press_origin",child.position)
				child.position.y+=2
			elif child.has_meta("press_origin"):
				child.position=child.get_meta("press_origin")
				child.remove_meta("press_origin")

class Swap:
	extends RefCounted
	var outgoing: Control
	var current: Control
	var tween: Tween
	func finish() -> void:
		if tween != null: tween.kill()
		if is_instance_valid(outgoing): outgoing.queue_free()
		if is_instance_valid(current):
			current.modulate.a = 1
			current.position = current.get_meta("motion_destination",current.position)
	func replace(old: Control, incoming: Control, reduced: bool, offset: Vector2 = Vector2(0,6)) -> void:
		if tween != null: tween.kill()
		if is_instance_valid(outgoing) and outgoing != old: outgoing.queue_free()
		outgoing = old
		current = incoming
		if is_instance_valid(old):
			# Never composite two sets of live text, pitches or controls. The arena/chrome stays put.
			old.hide()
			load("res://ui/motion.gd").freeze(old)
			old.queue_free()
		if reduced:
			if is_instance_valid(old): old.queue_free()
			if is_instance_valid(incoming): incoming.modulate.a=1
			return
		if not is_instance_valid(incoming): return
		tween = incoming.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if is_instance_valid(incoming):
			var destination := incoming.position
			incoming.set_meta("motion_destination",destination)
			incoming.modulate.a = 1
			incoming.position += offset
			tween.tween_property(incoming,"position",destination,0.16)
