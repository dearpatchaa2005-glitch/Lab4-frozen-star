extends AnimatableBody2D

# ============================================================
#  แท่นที่ตกลงมา (Falling Platform)  - ขั้นตอน 4 : กับดัก
#  เมื่อผู้เล่นเหยียบ แท่นจะสั่นเตือนสักครู่ แล้วร่วงลงไป
#  จากนั้นจะกลับมาที่เดิมอีกครั้ง
# ============================================================

enum State { IDLE, SHAKING, FALLING, GONE }

## เวลาสั่นเตือนก่อนร่วง (วินาที)
@export var shake_time : float = 0.7
## ความเร็วในการร่วง
@export var fall_speed : float = 900.0
## ตกไปไกลเท่าไรถึงจะหายไป
@export var fall_distance : float = 900.0
## กี่วินาทีจึงจะกลับมาที่เดิม
@export var respawn_time : float = 3.0

var state : int = State.IDLE
var start_position : Vector2 = Vector2.ZERO
var fallen : float = 0.0

func _ready() -> void:
	start_position = position

func _physics_process(delta: float) -> void:
	if state != State.FALLING:
		return
	var step = fall_speed * delta
	position.y += step
	fallen += step
	if fallen >= fall_distance:
		state = State.GONE
		visible = false
		await get_tree().create_timer(respawn_time).timeout
		reset_platform()

# ผู้เล่นเหยียบแท่น
func _on_top_sensor_body_entered(body: Node2D) -> void:
	if state != State.IDLE or not body.is_in_group("Player"):
		return
	state = State.SHAKING
	await shake()
	# เริ่มร่วง
	if state == State.SHAKING:
		state = State.FALLING

# สั่นเตือนก่อนร่วง
func shake() -> void:
	var tween = create_tween()
	var n = int(shake_time / 0.1)
	for i in range(n):
		tween.tween_property(self, "position:x", start_position.x + 4, 0.05)
		tween.tween_property(self, "position:x", start_position.x - 4, 0.05)
	tween.tween_property(self, "position:x", start_position.x, 0.05)
	await tween.finished

# กลับไปที่เดิม พร้อมให้เหยียบใหม่
func reset_platform() -> void:
	position = start_position
	fallen = 0.0
	modulate.a = 0.0
	visible = true
	state = State.IDLE
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
