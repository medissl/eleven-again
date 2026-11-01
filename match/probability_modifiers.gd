extends RefCounted
const POSITIVE_CAP := 0.12
## One absolute probability budget shared by skills and manager cards. Order is stable and explicit.
static func resolve(base: float, contributions: Array, minimum: float = 0.05, maximum: float = 0.95) -> Dictionary:
	assert(is_finite(base) and minimum <= maximum)
	var positive := 0.0
	var negative := 0.0
	var sources := []
	for entry in contributions:
		var requested: float=entry.amount
		assert(is_finite(requested))
		var applied := minf(requested,maxf(0,POSITIVE_CAP-positive)) if requested > 0 else requested
		if applied > 0: positive+=applied
		else: negative+=applied
		sources.append({"id":str(entry.id),"requested":requested,"applied":applied})
	return {"base":base,"value":clampf(base+positive+negative,minimum,maximum),"sources":sources}
