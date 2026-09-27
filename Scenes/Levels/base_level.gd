extends Node2D

# ============================================================
#  FROZEN STAR - Base Level
#  สคริปต์กลางของทุกด่าน ทำหน้าที่
#   - ตั้งค่าจำนวนเศษดาวที่ต้องเก็บในด่านนี้
#   - แสดงชื่อด่านตอนเริ่ม
#   - รับสัญญาณเมื่อผู้เล่นโดนศัตรูหรือกับดัก แล้วหักพลังชีวิต 1 หน่วย
# ============================================================

## ชื่อด่านที่แสดงตอนเริ่มเล่น
@export var level_name : String = "Level"
## คำอธิบายเป้าหมายของด่าน
@export var level_goal : String = ""
## ต้องเก็บเศษดาวกี่ชิ้นประตูทางออกจึงจะเปิด
@export var star_required : int = 5

func _ready() -> void:
	GameManager.player = %Player
	# กำหนดจำนวนเศษดาวที่ต้องเก็บของด่านนี้ และจำว่าตอนนี้อยู่ด่านไหน
	GameManager.start_level(star_required, scene_file_path)

	if has_node("MusicPlayer"):
		$MusicPlayer.play(0)

	# แสดงชื่อด่าน แล้วค่อย ๆ หายไป
	var label = $UserInterface/Label
	label.text = level_name
	label.scale = Vector2.ZERO
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(label, "scale", Vector2.ONE, 1)

	# แจ้งเป้าหมายของด่าน
	if level_goal != "":
		$UserInterface.alert(level_goal)

	await get_tree().create_timer(3).timeout
	if is_instance_valid(label):
		label.queue_free()

# โดนศัตรู -> เสียพลังชีวิต 1 หน่วย
func _on_player_hit_enemy() -> void:
	GameManager.damage(1)

# โดนกับดัก -> เสียพลังชีวิต 1 หน่วย (ไม่ตายทันทีแบบเดิม)
func _on_player_hit_trap() -> void:
	GameManager.damage(1)

func _on_music_player_finished() -> void:
	$MusicPlayer.play(0)
