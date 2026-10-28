extends Resource
@export var cards: Array[Resource] = []

func errors() -> Array[String]:
	var found: Array[String] = []
	var people := {}
	var versions := {}
	for card in cards:
		found.append_array(card.errors())
		if people.has(card.person_id) or versions.has(card.card_id): found.append("Duplicate roster identity")
		people[card.person_id] = true
		versions[card.card_id] = true
	return found
