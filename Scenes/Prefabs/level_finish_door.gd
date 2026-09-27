extends Area2D

# ============================================================
#  ประตูทางออกของด่าน
#  จะเปิดได้ก็ต่อเมื่อเก็บเศษดาวครบตามจำนวนที่กำหนดของด่านนั้น
# ============================================================

## ด่านถัดไปที่จะโหลดเมื่อผ่านด่านนี้ (เว้นว่าง = จบเกม)
@export var next_scene : PackedScene
## ถ้า true คือประตูทางออกสุดท้าย เข้าแล้วจบเกม (ไปหน้า WinGame)
@export var is_final_door : bool = false

var _was_open : bool = false

func _ready() -> void:
	_update_look()

func _process(_delta: float) -> void:
	# เปลี่ยนหน้าตาประตูตามสถานะ ล็อก/เปิด
	if GameManager.has_all_stars() != _was_open:
		_update_look()

# ประตูล็อกจะเป็นสีมืด, ประตูเปิดจะสว่างและเรืองแสง
func _update_look() -> void:
	_was_open = GameManager.has_all_stars()
	if _was_open:
		modulate = Color(1, 1, 1, 1)
	else:
		modulate = Color(0.45, 0.45, 0.55, 1)

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return

	# ยังเก็บเศษดาวไม่ครบ -> เข้าไม่ได้
	if not GameManager.has_all_stars():
		_alert("เก็บเศษดาวให้ครบก่อน! (%s)" % GameManager.star_text())
		return

	AudioManager.level_complete_sfx.play()

	if is_final_door or next_scene == null:
		# ผ่านด่านสุดท้าย -> จบเกม
		await get_tree().create_timer(0.4).timeout
		get_tree().change_scene_to_file("res://Scenes/Levels/game_win.tscn")
	else:
		SceneTransition.load_scene(next_scene)

func _alert(text : String) -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UserInterface")
	if ui != null and ui.has_method("alert"):
		ui.alert(text)
