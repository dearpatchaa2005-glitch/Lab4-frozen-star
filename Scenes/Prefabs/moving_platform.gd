extends AnimatableBody2D

# ============================================================
#  แผ่นเลื่อน (Moving Platform)  - ขั้นตอน 4 : วัตถุสำหรับสร้างด่าน
#  เลื่อนไป-กลับระหว่างจุดเริ่มต้นกับจุดปลาย ผู้เล่นยืนบนแผ่นแล้วไปด้วยกันได้
#  (เปิด Sync To Physics ไว้ ผู้เล่นจึงถูกพาไปพร้อมแผ่น)
# ============================================================

## ระยะที่เลื่อนไปจากจุดเริ่มต้น เช่น (300, 0) = เลื่อนไปทางขวา 300 px
@export var move_offset : Vector2 = Vector2(300, 0)
## ความเร็วในการเลื่อน (px ต่อวินาที)
@export var speed : float = 90.0
## หยุดพักกี่วินาทีเมื่อถึงปลายทางแต่ละฝั่ง
@export var wait_time : float = 0.6

var start_position : Vector2 = Vector2.ZERO
var end_position : Vector2 = Vector2.ZERO
var progress : float = 0.0      # 0.0 = จุดเริ่ม, 1.0 = จุดปลาย
var direction : float = 1.0
var wait_timer : float = 0.0

func _ready() -> void:
	start_position = position
	end_position = start_position + move_offset

func _physics_process(delta: float) -> void:
	# กำลังพักอยู่ที่ปลายทาง
	if wait_timer > 0.0:
		wait_timer -= delta
		return

	var total = move_offset.length()
	if total <= 0.0:
		return

	progress += direction * (speed / total) * delta

	if progress >= 1.0:
		progress = 1.0
		direction = -1.0
		wait_timer = wait_time
	elif progress <= 0.0:
		progress = 0.0
		direction = 1.0
		wait_timer = wait_time

	position = start_position.lerp(end_position, progress)
