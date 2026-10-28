extends Resource
const Traits = preload("res://match/traits.gd")
## Immutable authored identity and base ratings. Match effects live on the footballer.
const STATS := ["PAC","SHO","PAS","DRI","DEF","PHY"]
const KEEPING := ["REF","HAN","POS","DIV","KIC"]
const WEIGHTS := {"ST":[15,40,5,20,0,20],"LW":[25,20,20,25,0,10],"RW":[25,20,20,25,0,10],"AM":[10,25,30,25,0,10],"CM":[10,10,35,20,15,10],"DM":[10,5,25,10,30,20],"CB":[15,0,10,5,40,30],"LB":[25,5,20,10,25,15],"RB":[25,5,20,10,25,15],"GK":[30,20,25,15,10]}
@export var person_id := ""
@export var card_id := ""
@export var display_name := ""
@export var primary_role := "CM"
@export var natural_roles: Array[String] = []
@export var familiar_roles: Array[String] = []
@export var attributes := {"PAC":70,"SHO":70,"PAS":70,"DRI":70,"DEF":70,"PHY":70}
@export var keeper_attributes := {"REF":35,"HAN":35,"POS":35,"DIV":35,"KIC":35}
@export var trait_id := ""
@export var portrait_id := ""

func errors() -> Array[String]:
	var found: Array[String] = []
	if person_id.is_empty() or card_id.is_empty() or display_name.is_empty(): found.append("Missing identity")
	if not WEIGHTS.has(primary_role) or primary_role not in natural_roles: found.append("Invalid primary role")
	if not trait_id.is_empty() and not Traits.catalogue.has(trait_id): found.append("Unknown signature trait")
	for role in natural_roles+familiar_roles:
		if not WEIGHTS.has(role): found.append("Unknown role: "+role)
	for key in STATS+KEEPING:
		var data: Dictionary = attributes if key in STATS else keeper_attributes
		var value = data.get(key)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floorf(float(value)) or value < 1 or value > 120:
			found.append("Invalid attribute: "+key)
	return found

func familiarity(role: String) -> float:
	if role in natural_roles: return 1.0
	return 0.95 if role in familiar_roles else 0.85

func rating(role: String = "", adjusted: bool = false) -> int:
	var assigned := primary_role if role.is_empty() else role
	if not WEIGHTS.has(assigned): return 0
	var keys: Array = KEEPING if assigned == "GK" else STATS
	var values: Dictionary = keeper_attributes if assigned == "GK" else attributes
	var total := 0.0
	for i in keys.size():
		var value: float = values[keys[i]]
		if assigned == "GK" and "GK" not in natural_roles: value = 35
		total += value*WEIGHTS[assigned][i]
	return floori(total/100.0*(familiarity(assigned) if adjusted and assigned != "GK" else 1.0)+0.5)

func tier() -> String:
	var ovr := rating()
	return "bronze" if ovr < 70 else ("silver" if ovr < 85 else ("gold" if ovr < 100 else "legend"))

func to_data() -> Dictionary:
	return {"person_id":person_id,"card_id":card_id,"display_name":display_name,"primary_role":primary_role,"natural_roles":natural_roles.duplicate(),"familiar_roles":familiar_roles.duplicate(),"attributes":attributes.duplicate(),"keeper_attributes":keeper_attributes.duplicate(),"trait_id":trait_id,"portrait_id":portrait_id}

static func from_data(data: Dictionary) -> Resource:
	var card = load("res://content/player_card.gd").new()
	for key in ["person_id","card_id","display_name","primary_role","trait_id","portrait_id"]:
		if data.get(key) is not String: return null
		card.set(key,data[key])
	for key in ["natural_roles","familiar_roles"]:
		if data.get(key) is not Array: return null
		for role in data[key]:
			if role is not String: return null
		card.get(key).assign(data[key])
	for key in ["attributes","keeper_attributes"]:
		if data.get(key) is not Dictionary: return null
		card.set(key,data[key].duplicate())
	return card if card.errors().is_empty() else null
