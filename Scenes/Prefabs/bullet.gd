extends RigidBody2D

# ลูกศรน้ำแข็ง : ยิงออกไปตามทิศที่ผู้เล่นหัน แล้วหายไปเมื่อหมดอายุ

func shoot(direction: Vector2, speed: float, lifetime: float):
	# หันหัวลูกศรไปตามทิศที่ยิง (ล็อกการหมุนไว้ในฉาก ลูกศรจึงไม่หมุนคว้าง)
	rotation = direction.angle()
	apply_impulse(direction * speed)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
