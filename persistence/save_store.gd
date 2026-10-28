extends RefCounted
## Native Variant bytes preserve int64 RNG/Vector2 exactly; executable objects are disabled.
const LIMIT := 32*1024*1024
var directory: String

func _init(root: String = "user://campaign") -> void:
	directory = ProjectSettings.globalize_path(root)
	DirAccess.make_dir_recursive_absolute(directory)

func path(kind: String) -> String:
	return directory+"/"+kind+".sav" if kind in ["run","profile","journal","settings"] else ""

static func digest(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

func read_file(file: String, kind: String, validate: Callable) -> Dictionary:
	if not FileAccess.file_exists(file): return {"ok":false,"status":"missing"}
	var input := FileAccess.open(file,FileAccess.READ)
	if input == null or input.get_length() < 4 or input.get_length() > LIMIT: return {"ok":false,"status":"unreadable"}
	var envelope = bytes_to_var(input.get_buffer(input.get_length()))
	if envelope is not Dictionary or envelope.get("magic") != "ELEVEN_AGAIN" or envelope.get("schema") != 1 or envelope.get("kind") != kind or envelope.get("payload") is not PackedByteArray or envelope.get("hash") is not String: return {"ok":false,"status":"incompatible_or_corrupt"}
	if envelope.payload.size() < 4 or digest(envelope.payload) != envelope.hash: return {"ok":false,"status":"checksum_failed"}
	var data = bytes_to_var(envelope.payload)
	if not validate.call(data): return {"ok":false,"status":"invalid_state"}
	return {"ok":true,"data":data}

func read(kind: String, validate: Callable) -> Dictionary:
	var target := path(kind)
	if target.is_empty(): return {"ok":false,"status":"invalid_kind"}
	var primary := read_file(target,kind,validate)
	if primary.ok:
		primary.source = "primary"
		return primary
	var backup := read_file(target+".bak",kind,validate)
	if backup.ok:
		backup.source = "backup"
		backup.primary_status = primary.status
		return backup
	return {"ok":false,"status":"missing" if primary.status == "missing" and backup.status == "missing" else "recovery_required","primary_status":primary.status,"backup_status":backup.status}

func write(kind: String, data: Variant, validate: Callable) -> Dictionary:
	var target := path(kind)
	if target.is_empty() or not validate.call(data): return {"ok":false,"error":"Invalid save data."}
	var payload := var_to_bytes(data)
	var bytes := var_to_bytes({"magic":"ELEVEN_AGAIN","schema":1,"kind":kind,"payload":payload,"hash":digest(payload)})
	if bytes.size() > LIMIT: return {"ok":false,"error":"Save exceeds size limit."}
	var output := FileAccess.open(target+".tmp",FileAccess.WRITE)
	if output == null: return {"ok":false,"error":"Cannot write temporary save."}
	output.store_buffer(bytes)
	output.flush()
	var write_error := output.get_error()
	output.close()
	if write_error != OK or not read_file(target+".tmp",kind,validate).ok: return {"ok":false,"error":"Temporary save verification failed."}
	if FileAccess.file_exists(target):
		if read_file(target,kind,validate).ok:
			if DirAccess.copy_absolute(target,target+".bak.tmp") != OK or DirAccess.rename_absolute(target+".bak.tmp",target+".bak") != OK: return {"ok":false,"error":"Cannot retain previous valid save."}
		else:
			# Preserve corrupt/incompatible bytes before repairing from a valid recovered state.
			var preserved := target+".preserved."+str(Time.get_unix_time_from_system())+"."+str(Time.get_ticks_usec())
			if DirAccess.copy_absolute(target,preserved) != OK: return {"ok":false,"error":"Cannot preserve damaged save."}
	if DirAccess.rename_absolute(target+".tmp",target) != OK: return {"ok":false,"error":"Cannot atomically replace save."}
	return {"ok":true}
