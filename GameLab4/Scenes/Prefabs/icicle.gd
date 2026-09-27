extends StaticBody2D

# ============================================================
#  หินย้อยน้ำแข็ง (Icicle)  - ขั้นตอน 4 : กับดัก
#  ห้อยอยู่บนเพดานถ้ำ พอถึงจังหวะจะสั่นเตือนแล้วร่วงลงมา
#  จากนั้นจะกลับไปห้อยที่เดิมเพื่อร่วงรอบถัดไป
#  อยู่ในกลุ่ม "Traps" ผู้เล่นโดนแล้วเสียพลังชีวิต 1 หน่วย
# ============================================================

## เว้นระยะกี่วินาทีจึงร่วงลงมาอีกครั้ง
@export var interval : float = 3.0
## สั่นเตือนกี่วินาทีก่อนร่วง
@export var warn_time : float = 0.5
## แรงโน้มถ่วงที่ดึงหินย้อยลงมา
@export var gravity : float = 1800.0
## ร่วงลงไปไกลเท่าไรจึงหายไป
@export var fall_distance : float = 720.0
## หน่วงเวลาเริ่มต้น (ติดลบ = สุ่ม ทำให้แต่ละอันไม่ร่วงพร้อมกัน)
@export var start_delay : float = -1.0

var start_position : Vector2 = Vector2.ZERO
var velocity_y : float = 0.0
var falling : bool = false
var warning : bool = false
var timer : float = 0.0
var fallen : float = 0.0

func _ready() -> void:
	start_position = position
	if start_delay < 0.0:
		timer = randf_range(0.0, interval)
	else:
		timer = interval - start_delay

func _physics_process(delta: float) -> void:
	if falling:
		velocity_y += gravity * delta
		var step = velocity_y * delta
		position.y += step
		fallen += step
		if fallen >= fall_distance:
			_reset()
		return

	if warning:
		return

	timer += delta
	if timer >= interval:
		_warn()

# สั่นเตือนก่อนร่วง ให้ผู้เล่นทันหลบ
func _warn() -> void:
	warning = true
	var tween = create_tween()
	var n = int(warn_time / 0.1)
	for i in range(n):
		tween.tween_property(self, "position:x", start_position.x + 3, 0.05)
		tween.tween_property(self, "position:x", start_position.x - 3, 0.05)
	tween.tween_property(self, "position:x", start_position.x, 0.05)
	await tween.finished
	warning = false
	falling = true

func _reset() -> void:
	falling = false
	warning = false
	timer = 0.0
	fallen = 0.0
	velocity_y = 0.0
	position = start_position
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
