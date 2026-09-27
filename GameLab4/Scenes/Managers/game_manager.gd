# ============================================================
#  FROZEN STAR - GameManager (Autoload)
#  สคริปต์นี้เป็น autoload เรียกใช้ได้จากทุกสคริปต์ในเกม
#
#  กติกาของเกม (ตามเอกสารโครงงาน)
#   - ตัวละครมีพลังชีวิต 3 หน่วย (หัวใจ)
#   - โดนศัตรู / กับดัก / ตกหลุม เสียพลังชีวิต 1 หน่วย
#   - พลังชีวิตหมด จะเริ่มด่านนั้นใหม่
#   - ต้องเก็บเศษดาวให้ครบตามจำนวนที่กำหนด ประตูทางออกจึงจะเปิด
#   - เก็บเหรียญเพื่อสะสมคะแนน
# ============================================================

extends Node2D

# ---------- ค่าคงที่ของเกม ----------
const MAX_HP : int = 3          # หัวใจสูงสุด 3 ดวง

# ---------- ตัวแปรตั้งค่าเสียง ----------
var sfx_on   = true
var music_on = true

# ---------- ตัวแปรอ้างอิง ----------
var player : Player = null
var current_level : String = "res://Scenes/Levels/level_01.tscn"
var save_path := "user://game.save"
var save_player_position = Vector2.ZERO
var player_stats = Stat.new()

# กันไม่ให้ damage ซ้ำซ้อนตอนกำลังตาย
var is_dying : bool = false

func _ready() -> void:
	restart()

# ============================================================
#  ส่วนอ่าน/เขียนค่าสถานะ
# ============================================================
func get_stat(key:String, default=0):
	return player_stats.data_get(key, default)

# ---------- คะแนน ----------
func add_score(v=1):
	player_stats.data_add("score", v)

# ---------- เหรียญ (ขั้นตอน 5 : ไอเท็มเหรียญ) ----------
func add_coin(v=1):
	player_stats.data_add("coins", v)
	add_score(v)

# ============================================================
#  ระบบเศษดาว - หัวใจของเกม FROZEN STAR
# ============================================================

# เรียกตอนเริ่มด่านใหม่ เพื่อกำหนดว่าด่านนี้ต้องเก็บเศษดาวกี่ชิ้น
func start_level(required : int, level_path : String = "") -> void:
	is_dying = false
	if level_path != "":
		current_level = level_path
	elif get_tree().current_scene != null:
		current_level = get_tree().current_scene.scene_file_path
	player_stats.data_set("star", 0)
	player_stats.data_set("star_required", required)
	player_stats.data_set("key", 0)

func add_star(v := 1) -> void:
	player_stats.data_add("star", v)

# เก็บเศษดาวครบตามจำนวนที่กำหนดหรือยัง -> ใช้ตัดสินว่าประตูทางออกเปิดไหม
func has_all_stars() -> bool:
	return get_stat("star") >= get_stat("star_required", 0)

func star_text() -> String:
	return "%d/%d" % [get_stat("star"), get_stat("star_required", 0)]

# ============================================================
#  ระบบกุญแจ (ด่าน 2 : หา Key เปิดประตูที่ล็อกอยู่)
# ============================================================
func add_key(v := 1) -> void:
	player_stats.data_add("key", v)

func has_key() -> bool:
	return get_stat("key") > 0

func use_key() -> bool:
	if has_key():
		player_stats.data_add("key", -1)
		return true
	return false

# ============================================================
#  ระบบพลังชีวิต (หัวใจ 3 ดวง)
# ============================================================

# เสียพลังชีวิต ปกติครั้งละ 1 หน่วย
func damage(val := 1):
	if is_dying:
		return
	var hp = player_stats.data_add("hp", -val)
	if hp <= 0:
		death()

func add_hp(val := 1):
	player_stats.data_add("hp", val)

func get_hp() -> int:
	return get_stat("hp", 0)

# พลังชีวิตหมด -> เริ่มด่านนี้ใหม่
func death():
	if is_dying:
		return
	is_dying = true
	if player != null:
		await player.death_tween()
	restart_level()

# เริ่มด่านปัจจุบันใหม่ (เศษดาวที่เก็บไว้ในด่านนี้จะหายไปด้วย)
func restart_level():
	player_stats.data_set("hp", MAX_HP)
	save_player_position = Vector2.ZERO
	var level_path = current_level
	if level_path == "" or level_path == null:
		level_path = "res://Scenes/Levels/level_01.tscn"
	get_tree().change_scene_to_file(level_path)

# ============================================================
#  เริ่มเกมใหม่ทั้งหมด
# ============================================================
func restart():
	player_stats.data_set("hp_max", MAX_HP)
	player_stats.data_set("hp", MAX_HP)
	player_stats.data_set("score", 0)
	player_stats.data_set("coins", 0)
	player_stats.data_set("star", 0)
	player_stats.data_set("star_required", 0)
	player_stats.data_set("key", 0)
	player_stats.data_set("killed_enemy", 0)
	current_level = "res://Scenes/Levels/level_01.tscn"
	save_player_position = Vector2.ZERO
	is_dying = false

# โหลดด่านถัดไป
func load_next_level(next_scene : PackedScene):
	get_tree().change_scene_to_packed(next_scene)

func enemy_died(entity : Enemy):
	player_stats.data_add("killed_enemy")
	player_stats.data_add("killed_" + entity.label)

# ============================================================
#  ตั้งค่าเสียง
# ============================================================
func update_option():
	var music_bus = AudioServer.get_bus_index("music")
	var sfx_bus = AudioServer.get_bus_index("sfx")
	AudioServer.set_bus_mute(sfx_bus, !sfx_on)
	AudioServer.set_bus_mute(music_bus, !music_on)

func save_option():
	var file = FileAccess.open("user://option.json", FileAccess.WRITE)
	if file:
		var payload: Dictionary = {
			"music" : music_on,
			"sound" : sfx_on,
		}
		var json_text = JSON.stringify(payload, "  ")
		file.store_pascal_string(json_text)
		file.close()

func load_option():
	if FileAccess.file_exists("user://option.json"):
		var file = FileAccess.open("user://option.json", FileAccess.READ)
		var text = file.get_pascal_string()
		var data = JSON.parse_string(text)
		file.close()
		if data != null:
			music_on = data.get("music", true)
			sfx_on = data.get("sound", true)
			update_option()

# ============================================================
#  ระบบ Save / Load
# ============================================================
func save_game():
	current_level = get_tree().current_scene.scene_file_path
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var pos = Vector2.ZERO
		if player != null:
			pos = player.global_position
		var payload: Dictionary = {
			"current_level" : current_level,
			"player" : [pos.x, pos.y],
			"player_stats" : player_stats.data
		}
		var json_text = JSON.stringify(payload, "  ")
		file.store_pascal_string(json_text)
		file.close()

func has_gamesaved():
	return FileAccess.file_exists(save_path)

func load_game():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var text = file.get_pascal_string()
		var data = JSON.parse_string(text)
		file.close()
		if data == null:
			restart()
			get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")
			return
		current_level = data.get("current_level", current_level)
		player_stats.data = data.get("player_stats", {})
		var pos = data.get("player", [0, 0])
		save_player_position = Vector2(pos[0], pos[1])
		is_dying = false
		get_tree().change_scene_to_file(current_level)
	else:
		restart()
		get_tree().change_scene_to_file("res://Scenes/Levels/level_01.tscn")
