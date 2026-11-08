class_name NPCDialogueGateway
extends RefCounted
## Provider-neutral dialogue DTO boundary. Provider calls are deliberately outside the client.

const SCHEMA_VERSION: int = 1
const MAX_PLAYER_INPUT: int = 500
const MAX_SCENE_SUMMARY: int = 300
const MAX_DIALOGUE_LENGTH: int = 600
const MAX_CONTEXT_MEMORIES: int = 5
const ALLOWED_INTENTS: Array[String] = ["none","ask_for_help","offer_trade","refuse","share_information","propose_meeting"]
const RESPONSE_FIELDS: Array[String] = ["schema_version","request_id","npc_id","dialogue_text","intent","target_id","referenced_memory_ids"]

func build_request(request_id: String, npc: Dictionary, player_input: String, scene_summary: String, memories: Array) -> Dictionary:
	var npc_id: String = str(npc.get("id",""))
	if request_id.is_empty() or request_id.length() > 64 or npc_id.is_empty() or npc_id.length() > 64:
		return {"ok":false,"error":"Dialogue request and NPC IDs must be bounded non-empty strings"}
	if player_input.strip_edges().is_empty() or player_input.length() > MAX_PLAYER_INPUT:
		return {"ok":false,"error":"Player input must contain 1 to %d characters" % MAX_PLAYER_INPUT}
	if scene_summary.length() > MAX_SCENE_SUMMARY or memories.size() > MAX_CONTEXT_MEMORIES:
		return {"ok":false,"error":"Dialogue context exceeds its configured bounds"}
	var memory_context: Array[Dictionary] = []
	for memory: Variant in memories:
		if not memory is Dictionary or not memory.has("id") or not memory.has("summary"):
			return {"ok":false,"error":"Dialogue context contains an invalid memory"}
		memory_context.append({
			"id":str(memory.id),
			"summary":str(memory.summary).substr(0,240),
			"timestamp_minute":int(memory.get("timestamp_minute",0)),
			"source":str(memory.get("source","hearsay")),
			"confidence":clampi(int(memory.get("confidence",0)),0,100),
			"participants":memory.get("participants",[]).duplicate(true),
			"tags":memory.get("tags",[]).duplicate(true)
		})
	var persona: String = "%s, %s" % [str(npc.get("name","Unknown")),str(npc.get("role","resident"))]
	return {"ok":true,"request":{
		"schema_version":SCHEMA_VERSION,
		"request_id":request_id,
		"npc_id":npc_id,
		"npc_name":str(npc.get("name","Unknown")),
		"npc_persona_summary":persona.substr(0,160),
		"current_goal":str(npc.get("goal","work")).substr(0,80),
		"current_activity":str(npc.get("activity","")).substr(0,80),
		"player_input":player_input.strip_edges(),
		"current_scene_summary":scene_summary,
		"relevant_memory_records":memory_context,
		"allowed_intents":ALLOWED_INTENTS.duplicate(),
		"allowed_target_ids":[],
		"response_constraints":{"max_dialogue_length":MAX_DIALOGUE_LENGTH,"max_referenced_memories":MAX_CONTEXT_MEMORIES}
	}}

func offline_response(request: Dictionary) -> Dictionary:
	var persona: String = str(request.get("npc_persona_summary","resident"))
	var memories: Array = request.get("relevant_memory_records", [])
	var line: String = "%s: I can speak only from what I have seen or learned." % persona
	var referenced_ids: Array[String] = []
	if not memories.is_empty() and memories[0] is Dictionary:
		var memory: Dictionary = memories[0]
		line = "%s: I remember %s." % [persona, str(memory.get("summary", "what happened"))]
		referenced_ids.append(str(memory.get("id", "")))
	return {"schema_version":SCHEMA_VERSION,"request_id":str(request.get("request_id","")),"npc_id":str(request.get("npc_id","")),"dialogue_text":line,"intent":"none","target_id":null,"referenced_memory_ids":referenced_ids}

func validate_response(request: Dictionary, response: Variant) -> Dictionary:
	if not response is Dictionary:
		return {"ok":false,"error":"AI response must be a JSON object"}
	for field: Variant in response:
		if not field is String or not RESPONSE_FIELDS.has(field):
			return {"ok":false,"error":"AI response contains an unapproved field"}
	for field: String in RESPONSE_FIELDS:
		if not response.has(field):
			return {"ok":false,"error":"AI response is missing field: " + field}
	if typeof(response.schema_version) != TYPE_INT or int(response.schema_version) != SCHEMA_VERSION:
		return {"ok":false,"error":"Unsupported AI response schema version"}
	if str(response.request_id) != str(request.get("request_id","")) or str(response.npc_id) != str(request.get("npc_id","")):
		return {"ok":false,"error":"AI response does not match the active request"}
	if not response.dialogue_text is String or str(response.dialogue_text).strip_edges().is_empty() or str(response.dialogue_text).length() > MAX_DIALOGUE_LENGTH:
		return {"ok":false,"error":"AI dialogue text is empty or exceeds its length limit"}
	if not response.intent is String or not ALLOWED_INTENTS.has(response.intent):
		return {"ok":false,"error":"AI response contains an unsupported intent"}
	if response.target_id != null:
		if not response.target_id is String or not request.get("allowed_target_ids",[]).has(response.target_id):
			return {"ok":false,"error":"AI response target is not in the allowed target list"}
	if not response.referenced_memory_ids is Array or response.referenced_memory_ids.size() > MAX_CONTEXT_MEMORIES:
		return {"ok":false,"error":"AI response contains an invalid memory reference list"}
	var supplied_ids: Array[String] = []
	for memory: Dictionary in request.get("relevant_memory_records",[]):
		supplied_ids.append(str(memory.get("id","")))
	for memory_id: Variant in response.referenced_memory_ids:
		if not memory_id is String or not supplied_ids.has(memory_id):
			return {"ok":false,"error":"AI response references memory outside its supplied context"}
	return {"ok":true,"proposal":{
		"schema_version":SCHEMA_VERSION,
		"request_id":str(response.request_id),
		"npc_id":str(response.npc_id),
		"dialogue_text":str(response.dialogue_text).strip_edges(),
		"intent":str(response.intent),
		"target_id":response.target_id,
		"referenced_memory_ids":response.referenced_memory_ids.duplicate(true)
	}}
