extends StaticBody2D

# ============================================================
#  ประตูที่ล็อกอยู่ (ด่าน 2 : ถ้ำมืด)
#  ผู้เล่นต้องหา Key ที่ซ่อนอยู่ในด่านมาเปิดจึงจะผ่านไปได้
# ============================================================

@onready var sprite : Sprite2D = $Sprite2D
@onready var shape : CollisionShape2D = $CollisionShape2D

var opened : bool = false

func _on_trigger_body_entered(body: Node2D) -> void:
	if opened or not body.is_in_group("Player"):
		return

	if GameManager.use_key():
		open_door()
	else:
		_alert("ประตูล็อกอยู่ ต้องหากุญแจก่อน")

# เปิดประตู : เลื่อนขึ้นแล้วจางหาย จากนั้นปิดการชน
func open_door() -> void:
	opened = true
	AudioManager.level_complete_sfx.play()
	_alert("ใช้กุญแจเปิดประตูแล้ว")
	# ปิดการชนทันที ผู้เล่นจะได้เดินผ่านได้เลย
	shape.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, position.y - 90), 0.6)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.6)
	await tween.finished
	visible = false

func _alert(text : String) -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UserInterface")
	if ui != null and ui.has_method("alert"):
		ui.alert(text)
