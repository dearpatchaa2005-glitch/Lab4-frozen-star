extends Enemy

# ============================================================
#  Bat - ศัตรูบิน (ขั้นตอน 2 : สร้างศัตรูใหม่)
#  เคลื่อนที่ขึ้น-ลงอยู่กับที่ ใช้เพิ่มความท้าทายในบางจุดของด่าน
#  ผู้เล่นชนด้านข้าง = เสียพลังชีวิต, กระโดดเหยียบด้านบน = กำจัดได้
# ============================================================

@export_category("Bat Flight")
## ระยะที่บินขึ้น-ลงจากจุดเริ่มต้น (px)
@export var fly_amplitude : float = 110.0
## ความเร็วในการบินขึ้น-ลง
@export var fly_speed : float = 1.6
## ระยะบินไป-กลับแนวนอน (0 = ลอยอยู่กับที่)
@export var drift_amplitude : float = 0.0
## ความเร็วบินแนวนอน
@export var drift_speed : float = 0.8

var fly_origin : Vector2 = Vector2.ZERO
var fly_time : float = 0.0
var drift_time : float = 0.0

func _ready() -> void:
	super._ready()
	# ค้างคาวบินได้ จึงไม่ต้องโดนแรงโน้มถ่วง
	gravity_scale = 0.0
	fly_origin = global_position
	# สุ่มจังหวะเริ่ม ค้างคาวแต่ละตัวจะได้ไม่บินพร้อมกัน
	fly_time = randf_range(0.0, TAU)
	drift_time = randf_range(0.0, TAU)
	if has_node("Sprite/AnimateSprite"):
		$Sprite/AnimateSprite.play("fly")

# เขียนทับการเคลื่อนที่ของ Enemy ทั้งหมด เพราะค้างคาวบิน ไม่ได้เดินบนพื้น
func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	fly_time += delta * fly_speed
	drift_time += delta * drift_speed

	# ตำแหน่งแนวตั้งเป็นคลื่น sin -> ความเร็วคือ cos
	velocity.y = cos(fly_time) * fly_amplitude * fly_speed
	velocity.x = cos(drift_time) * drift_amplitude * drift_speed

	# กันไม่ให้ลอยหลุดออกจากจุดเริ่มต้น
	var dy = global_position.y - fly_origin.y
	if dy > fly_amplitude and velocity.y > 0.0:
		velocity.y = 0.0
	elif dy < -fly_amplitude and velocity.y < 0.0:
		velocity.y = 0.0

	# หันหน้าตามทิศที่บิน (Enemy จะเอาค่า direction ไปพลิกภาพให้เอง)
	if absf(velocity.x) > 1.0:
		direction = 1 if velocity.x > 0.0 else -1

	move_and_slide()
