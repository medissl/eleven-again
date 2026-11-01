extends SceneTree
const Packs=preload("res://run/draft_packs.gd")
func _initialize() -> void:
	var content=load("res://content/campaign.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed=42
	for kind in ["standard","elite"]:
		for act in 3:
			var weights: Array=Packs.BALANCE[kind+"_weights"][act]
			assert(weights.reduce(func(a,b): return a+b,0) == 10000)
			var counts := [0,0,0,0]
			for roll in 100000: counts[Packs.rarity(weights,rng)]+=1
			for tier in 4:
				var p: float=float(weights[tier])/10000
				assert(absf(counts[tier]-100000*p) <= maxf(5,6*sqrt(100000*p*(1-p))))
	for group in Packs.GROUPS:
		for seed_value in range(1,41):
			rng.seed=seed_value
			var before := rng.state
			var pack: Dictionary=Packs.generate(content.recruits,2,"position",group,[],rng)
			assert(pack.ok and pack.cards.size() == 4)
			var people := []
			var targets := 0
			for id in pack.cards:
				assert(content.cards[id].person_id not in people)
				people.append(content.cards[id].person_id)
				if content.cards[id].primary_role in Packs.GROUPS[group]: targets+=1
			assert(targets >= 2)
			rng.state=before
			assert(Packs.generate(content.recruits,2,"position",group,[],rng) == pack)
	assert(not Packs.generate([],1,"standard","",[],rng).ok)
	assert(not Packs.generate(content.recruits,1,"position","INVALID",[],rng).ok)
	var low: Array=content.recruits.filter(func(card): return card.tier() in ["bronze","silver"]).slice(0,4)
	assert(Packs.focus_card(low).is_empty(),"Bronze/Silver never receive a tunnel")
	var high: Array=content.recruits.filter(func(card): return card.tier() in ["gold","legend"])
	high.sort_custom(func(a,b): return a.rating() > b.rating() if a.rating() != b.rating() else a.card_id < b.card_id)
	assert(Packs.focus_card([low[0],high[2],high[1],high[0]]) == high[0].card_id,"Only the highest Gold/Legend receives the pack tunnel")
	print("DRAFT PACKS: 600000 tier rolls,160 deterministic targeted packs, unique people and shortage cancellation passed")
	quit()
