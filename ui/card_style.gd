extends RefCounted
## Shared arcade frames; catalogue definitions, portraits and stat geometry remain authoritative.
const PALETTES := {"bronze":["D99C3A","EDC4A0","5B3829"],"silver":["A8C8BF","E1E8CF","31596A"],"gold":["F5CE65","FFF4D2","A46430"],"legend":["9B58AC","EAD1ED","633D67"],"unknown":["62816A","A8C8BF","233A50"]}
static func paint(card: Control) -> void:
	if not is_instance_valid(card.content): return
	var tier: String=card.display_tier()
	var accent:=Color(PALETTES[tier][0])
	card.draw_set_transform(card.content.position,0,card.content.scale)
	card.draw_rect(Rect2(0,0,300,420),Color("101827"))
	card.draw_rect(Rect2(6,6,288,408),Color(PALETTES[tier][2]))
	card.draw_rect(Rect2(10,10,280,400),Color("17253B"))
	card.draw_style_box(preload("res://ui/matchday_theme.gd").frame(Color(accent,0.9)),Rect2(0,0,300,420))
	card.draw_rect(Rect2(20,230,260,24),accent)
	var marks: int={"bronze":1,"silver":2,"gold":3,"legend":4,"unknown":0}[tier]
	for index in marks: card.draw_rect(Rect2(244+index*7,237,4,10),Color("101827"))
	card.draw_line(Vector2(24,306),Vector2(276,306),Color(accent,0.45),1,true)
	card.draw_line(Vector2(150,316),Vector2(150,405),Color(accent,0.15),1,true)
	var keyboard: bool=card.get_viewport() != null and card.get_viewport().get_meta("keyboard_navigation",false)
	if card.button_pressed or (keyboard and card.has_focus()) or (card.is_hovered() and not card.disabled):
		card.draw_style_box(preload("res://ui/matchday_theme.gd").frame(Color("FFF4D2")),Rect2(-2,-2,304,424))
	if card.reveal_flash > 0:
		card.draw_style_box(preload("res://ui/matchday_theme.gd").frame(Color(accent,card.reveal_flash)),Rect2(-4,-4,308,428))
	card.draw_set_transform(Vector2.ZERO)
