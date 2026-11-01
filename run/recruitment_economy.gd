extends RefCounted
## Coins and mutable owned copies belong to a run. Authored card Resources stay immutable.
const Balance=preload("res://content/master_balance.gd")
const Packs=preload("res://run/draft_packs.gd")
const Card=preload("res://content/player_card.gd")
const Lineup=preload("res://squad/lineup.gd")

static func empty(plan: Resource, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed=seed_value ^ 11027
	return {"cash":int(Balance.DATA.starting_coins),"wallet":[],"plan":plan.to_data(),"released":[],"acquisitions":[],"training":[],"offer":{},"offers_rng":str(rng.state),"packs":[],"pack_return":"prepare"}

static func excluded(data: Dictionary) -> Array:
	var result: Array=data.released.duplicate()
	for card in data.plan.cards: result.append(card.person_id)
	return result

static func receipt(data: Dictionary, id: String, amount: int, kind: String) -> String:
	if id.is_empty() or data.wallet.any(func(row): return row.id == id): return "This coin receipt has already been applied."
	if data.cash+amount < 0: return "Not enough coins."
	data.wallet.append({"id":id,"amount":amount,"kind":kind})
	data.cash+=amount
	return ""

static func release_value(data: Dictionary, content: RefCounted, id: String) -> int:
	var acquisition: Array=data.acquisitions.filter(func(row): return row.card_id == id)
	if acquisition.is_empty(): return 0
	var cap: int=int(Balance.DATA.release_caps[content.cards[id].tier()])
	var value: int=floori(cap*0.85)
	if "finance3" in data.get("legacy",[]): value=mini(cap,ceili(value*1.05))
	return value if int(acquisition[0].cost) == 0 else mini(value,int(acquisition[0].cost)/4)

static func open_pack(data: Dictionary, content: RefCounted, act: int, kind: String, target: String, id: String, free: bool = false, refresh: bool = false, discount: int = 0) -> String:
	if refresh and (data.offer.is_empty() or data.offer.kind == "starter"): return "This pack cannot be rerolled."
	if not refresh and not data.offer.is_empty(): return "Finish the current pack first."
	var cost: int=Balance.cost("refresh" if refresh else kind) if not free else 0
	cost=maxi(0,cost-discount)
	if data.cash < cost: return "Not enough coins."
	var rng := RandomNumberGenerator.new()
	rng.state=int(data.offers_rng)
	var offer := Packs.generate(content.recruits,act,kind,target,excluded(data),rng)
	if not offer.ok: return offer.error
	var error := receipt(data,id,-cost,"reroll" if refresh else "pack")
	if not error.is_empty(): return error
	offer.erase("ok")
	offer.id=id
	offer.cost=cost
	offer.presentation_seen=false
	data.offers_rng=str(rng.state)
	data.offer=offer
	data.packs.append(offer.duplicate(true))
	return ""

static func sign(data: Dictionary, content: RefCounted, id: String, outgoing_id: String, receipt_id: String, direct: bool = false) -> String:
	if not content.cards.has(id) or content.cards[id] not in content.recruits: return "Unknown recruit."
	if not direct and id not in data.offer.get("cards",[]): return "Choose a player from this saved pack."
	var card: Resource=content.cards[id]
	if card.person_id in excluded(data): return "This player is owned or has left this run."
	var cost: int=Balance.direct_price(card) if direct else 0
	if data.cash < cost: return "Not enough coins."
	var plan: Resource=Lineup.from_data(data.plan)
	var outgoing := -1
	for index in plan.cards.size():
		if plan.cards[index].card_id == outgoing_id: outgoing=index
	if plan.cards.size() == 18 and outgoing < 0: return "Choose a player to replace; the squad holds 18."
	if plan.cards.size() < 18 and not outgoing_id.is_empty(): return "A replacement is only needed at 18 players."
	if outgoing >= 0 and "GK" in plan.cards[outgoing].natural_roles and "GK" not in card.natural_roles and plan.cards.filter(func(c): return "GK" in c.natural_roles).size() == 1: return "Keep a trained goalkeeper."
	if outgoing >= 0:
		var release_error := receipt(data,receipt_id+"/replacement",release_value(data,content,outgoing_id),"replacement_release")
		if not release_error.is_empty(): return release_error
		data.released.append(plan.cards[outgoing].person_id)
		plan.cards[outgoing]=Card.from_data(card.to_data())
	else: plan.cards.append(Card.from_data(card.to_data()))
	# Assign an owned trained keeper before validating the new XI.
	if "GK" not in plan.cards[plan.starters[0]].natural_roles:
		for index in plan.cards.size():
			if "GK" not in plan.cards[index].natural_roles: continue
			var old_slot: int=plan.starters.find(index)
			if old_slot >= 0: plan.starters[old_slot]=plan.starters[0]
			plan.starters[0]=index
			break
	plan.refresh_bench_order()
	if not plan.errors().is_empty(): return "The replacement would leave an invalid squad."
	var error := receipt(data,receipt_id,-cost,"sign")
	if not error.is_empty(): return error
	data.plan=plan.to_data()
	data.acquisitions.append({"id":receipt_id,"card_id":id,"person_id":card.person_id,"cost":cost,"outgoing_id":outgoing_id})
	if not direct: data.offer={}
	return ""

static func voucher(data: Dictionary, id: String) -> String:
	if data.offer.is_empty() or data.offer.kind == "starter": return "Choose your opening player first."
	var error := receipt(data,id,25,"voucher")
	if error.is_empty(): data.offer={}
	return error

static func train(data: Dictionary, id: String, stat: String, receipt_id: String, discount: int = 0) -> String:
	var plan: Resource=Lineup.from_data(data.plan)
	var index: int=plan.cards.find_custom(func(card): return card.card_id == id)
	if index < 0: return "Choose an owned player."
	var card: Resource=plan.cards[index]
	var keys: Array=Card.KEEPING if card.primary_role == "GK" else Card.STATS
	if stat not in keys: return "Choose an eligible attribute."
	if data.training.filter(func(row): return row.card_id == id).size() >= int(Balance.DATA.training_per_player_limit): return "This player has used both run training sessions."
	var values: Dictionary=card.keeper_attributes if stat in Card.KEEPING else card.attributes
	var before: int=values[stat]
	var after: int=mini(int(Balance.DATA.attribute_cap),before+int(Balance.DATA.training_stat_increase))
	if before == after: return "This attribute is already capped; no coins charged."
	var cost: int=maxi(0,Balance.cost("training")-discount)
	var error := receipt(data,receipt_id,-cost,"training")
	if not error.is_empty(): return error
	values[stat]=after
	data.plan=plan.to_data()
	data.training.append({"id":receipt_id,"card_id":id,"stat":stat,"before":before,"after":after,"cost":cost})
	return ""

static func release(data: Dictionary, content: RefCounted, id: String, receipt_id: String) -> String:
	var plan: Resource=Lineup.from_data(data.plan)
	var index: int=plan.cards.find_custom(func(card): return card.card_id == id)
	if index < 0 or plan.cards.size() <= 11: return "Keep at least eleven owned players."
	if index in plan.starters: return "Move this player to the bench before releasing."
	var card: Resource=plan.cards[index]
	if "GK" in card.natural_roles and plan.cards.filter(func(c): return "GK" in c.natural_roles).size() == 1: return "Keep a trained goalkeeper."
	# Original starters pay zero; finite acquired people are excluded after release.
	var value: int=release_value(data,content,id)
	var error := receipt(data,receipt_id,value,"release")
	if not error.is_empty(): return error
	data.released.append(card.person_id)
	plan.cards.remove_at(index)
	for slot in plan.starters.size():
		if plan.starters[slot] > index: plan.starters[slot]-=1
	plan.bench_order.clear()
	plan.pinned_replacements.clear()
	plan.refresh_bench_order()
	data.plan=plan.to_data()
	return ""
