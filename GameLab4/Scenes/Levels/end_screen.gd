extends Node2D

# ============================================================
#  ฉากจบเกม (GameOver / WinGame)  - ขั้นตอน 8
#  แสดงคะแนนที่ทำได้ พร้อมเล่นเสียงประกอบ
#  แล้วรีเซ็ตค่าสถานะ เพื่อให้ปุ่ม Play Again เริ่มเกมใหม่ได้ถูกต้อง
# ============================================================

## true = ฉากชนะ, false = ฉากแพ้
@export var is_win : bool = false

func _ready() -> void:
	# อ่านคะแนนก่อนรีเซ็ต
	var score = GameManager.get_stat("score")
	var coins = GameManager.get_stat("coins")

	if has_node("Summary"):
		$Summary.text = "คะแนนรวม %d        เหรียญ %d" % [score, coins]

	# เสียงประกอบฉากจบ
	if is_win:
		AudioManager.level_complete_sfx.play()
	else:
		AudioManager.death_sfx.play()

	# รีเซ็ตค่าสถานะ พร้อมเริ่มเกมใหม่
	GameManager.restart()
