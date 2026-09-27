extends Area2D

# ============================================================
#  FROZEN STAR - ไอเท็มที่เก็บได้ (ขั้นตอน 5 : สร้างไอเท็ม)
#
#  ใช้สคริปต์เดียวกันทุกไอเท็ม แล้วเลือกชนิดจากช่อง Kind ใน Inspector
#    STAR = เศษดาว  เก็บครบตามจำนวนเพื่อเปิดประตูทางออก
#    KEY     = กุญแจ    ใช้เปิดประตูที่ล็อกอยู่
#    HEART   = หัวใจ    เพิ่มพลังชีวิต 1 หน่วย
#    COIN    = เหรียญ   เพิ่มคะแนน
# ============================================================

enum Kind { STAR, KEY, HEART, COIN }

## ชนิดของไอเท็ม
@export var kind : Kind = Kind.STAR
## เพิ่มทีละกี่หน่วย
@export var amount : int = 1

@export_category("Hover Animation")
## ระยะลอยขึ้นลง
@export var amplitude : float = 5.0
## ความเร็วในการลอย
@export var frequency : float = 3.0
## ให้หมุนด้วยไหม
@export var spin : bool = false

var time_passed : float = 0.0
var initial_position : Vector2 = Vector2.ZERO
var collected : bool = false

func _ready() -> void:
	initial_position = position
	# สุ่มจังหวะเริ่ม เพื่อให้ไอเท็มแต่ละชิ้นลอยไม่พร้อมกัน
	time_passed = randf_range(0.0, 6.28)

func _process(delta: float) -> void:
	if collected:
		return
	hover(delta)

# ทำให้ไอเท็มลอยขึ้น-ลงเบา ๆ
func hover(delta: float) -> void:
	time_passed += delta
	position.y = initial_position.y + amplitude * sin(frequency * time_passed)
	if spin:
		rotation += 1.5 * delta

# เก็บไอเท็ม
func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("Player"):
		return
	collected = true

	match kind:
		Kind.STAR:
			GameManager.add_star(amount)
			GameManager.add_score(10 * amount)
			_alert("เศษดาว %s" % GameManager.star_text())
		Kind.KEY:
			GameManager.add_key(amount)
			_alert("ได้กุญแจแล้ว!")
		Kind.HEART:
			GameManager.add_hp(amount)
		Kind.COIN:
			GameManager.add_coin(amount)

	AudioManager.coin_pickup_sfx.play()
	await _collect_effect()
	queue_free()

# เอฟเฟกต์ตอนเก็บ : ลอยขึ้นแล้วขยายจนหายไป
func _collect_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, position.y - 60), 0.4)
	tween.set_parallel()
	tween.tween_property(self, "scale", scale * 1.8, 0.4)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished

func _alert(text : String) -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UserInterface")
	if ui != null and ui.has_method("alert"):
		ui.alert(text)
