extends SceneTree
const Session=preload("res://persistence/campaign_session.gd")
class InterruptedStore:
	extends "res://persistence/save_store.gd"
	var fail_at := -1
	var calls := 0
	func write(kind: String, data: Variant, validate: Callable) -> Dictionary:
		var index := calls
		calls+=1
		if index == fail_at: return {"ok":false,"error":"Authored transaction interruption"}
		return super.write(kind,data,validate)
func _initialize() -> void:
	var content=load("res://content/campaign.gd").new()
	for interruption in 4:
		var path := "user://master_journal_"+str(Time.get_ticks_usec())
		var backend := InterruptedStore.new(path)
		var session := Session.new(path,content,backend)
		assert(session.new_run("ENG",42,"journal_new_mode",false,true).ok)
		var before: Dictionary=session.controller.snapshot()
		backend.calls=0; backend.fail_at=interruption
		assert(not session.act("acquire",[before.offer.cards[0],""],before.revision).ok and session.blocked)
		var reload := Session.new(path,content)
		assert(not reload.blocked)
		var state: Dictionary=reload.controller.snapshot()
		assert(state.plan.cards.size() == (16 if interruption == 0 else 17))
		assert(state.acquisitions.size() == (0 if interruption == 0 else 1))
		assert(state.cash == 0 and reload.profile.schema == 2 and reload.profile.legacy.marks == 0)
		assert(Session.new(path,content).controller.snapshot() == state,"Recovery is idempotent")
	print("MASTER JOURNAL: all four write interruption boundaries recover schema4 runs/schema2 profiles without duplicate signing or reward")
	quit()
