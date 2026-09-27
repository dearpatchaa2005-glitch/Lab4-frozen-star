class_name Player
extends CharacterBody2D

# ============================================================
#  FROZEN STAR - Player (นักผจญภัย)
#  - เดินซ้าย-ขวา และกระโดดข้ามสิ่งกีดขวาง
#  - มีพลังชีวิต 3 หน่วย
#  - โดนศัตรู / กับดัก / ตกหลุม เสียพลังชีวิต 1 หน่วย
#  - กระโดดเหยียบหัวศัตรูเพื่อกำจัดศัตรูได้
# ============================================================

signal hit_enemy
signal hit_trap


# --------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 300
@export var jump_force : float = 650
@export var gravity : float = 30
@export var max_jump_count : int = 2
@export var bullet_scene : PackedScene
@export var shoot_cooldown_time : float = 0.2
@export var bullet_lifetime = 2.0

@export_category("Fall / Pit")
## ถ้าตกลงมาเร็วเกินค่านี้ ถือว่าตกหลุม เสียพลังชีวิต 1 หน่วย แล้วกลับไปจุดเริ่มต้น
@export var pit_fall_speed : float = 2000.0

var jump_count : int = 2
var flip_x = false

@export_category("Toggle Functions")
@export var double_jump : = false

var is_grounded : bool = false
var movement_enabled : bool = true
var spawn_point = Vector2(0,0)
var is_attacking = false
var shoot_cooldown_timer = 0.0
var can_damage = true

@onready var player_sprite : AnimationPlayer = $student/AnimationPlayer
@onready var player_node = $student
@onready var bullet_marker = $BulletMarker
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles


# --------- BUILT-IN FUNCTIONS ---------- #
func _ready() -> void:
	spawn_point = global_position
	if GameManager.save_player_position.x != 0:
		global_position =  GameManager.save_player_position
		GameManager.save_player_position = Vector2.ZERO
	player_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	is_grounded = is_on_floor()
	movement()
	_handle_enemy_contact()

func _process(_delta):
	player_animations()
	flip_player()
	handle_shooting()
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= _delta

# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement():
	# Gravity
	if !is_on_floor():
		velocity.y += gravity
	elif is_on_floor():
		jump_count = max_jump_count
		if abs(velocity.x)>0.5:
			velocity.x *= 0.6
		else:
			velocity.x =0

	handle_jumping()

	# Move Player
	if movement_enabled:
		if Input.is_action_pressed("Left"):
			velocity.x = -move_speed
			flip_x = true
		if Input.is_action_pressed("Right"):
			velocity.x = move_speed
			flip_x = false

	# ตกหลุม : เสียพลังชีวิต 1 หน่วย แล้วกลับไปเริ่มที่จุดเกิด
	if velocity.y > pit_fall_speed and can_damage and movement_enabled:
		fall_into_pit()

	move_and_slide()

# ตกหลุม
func fall_into_pit():
	damage_tween()
	GameManager.damage(1)
	# ถ้ายังมีพลังชีวิตเหลือ ให้ย้ายกลับจุดเกิด (ถ้าหมดแล้ว GameManager จะเริ่มด่านใหม่เอง)
	if GameManager.get_hp() > 0:
		velocity = Vector2.ZERO
		global_position = spawn_point

# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping():
	if Input.is_action_just_pressed("Jump") and movement_enabled:
		if is_on_floor() and !double_jump:
			jump()
		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1

# Player jump
func jump():
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force

# Handle Player Animations
func player_animations():
	particle_trails.emitting = false
	if is_attacking:
		return

	if is_on_floor():
		if abs(velocity.x) > 0:
			particle_trails.emitting = true
			player_sprite.current_animation = "Walk"
		else:
			player_sprite.current_animation = "Idle"
	else:
		player_sprite.current_animation = "Jump"


# Flip player sprite based on X velocity
func flip_player():
	if flip_x:
		player_node.scale.x = -1
	else:
		player_node.scale.x = 1

# Tween Animations
func death_tween():
	AudioManager.death_sfx.play()
	death_particles.emitting = true
	movement_enabled = false
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(self, "position", Vector2(position.x,position.y-100), 0.15)
	await tween.finished
	global_position = spawn_point
	await get_tree().create_timer(0.3).timeout
	movement_enabled = true
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(self, "position", spawn_point, 0.15)

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0,1.0), 0.1)

# กระพริบสีแดง และอยู่ในสภาพอมตะชั่วคราว กันโดนซ้ำรัว ๆ
func damage_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	can_damage = false
	for i in range(1,10):
		tween.tween_property(player_node , "modulate", Color.RED, 0.1)
		tween.tween_property(player_node , "modulate", Color.WHITE, 0.1)
	await tween.finished
	can_damage = true

func _handle_enemy_contact() -> void:
	if !can_damage:
		return
	var bodies = $Collision.get_overlapping_bodies()
	for body in bodies:
		if body != null:
			_on_collision_body_entered(body)

# ตรวจว่าผู้เล่นกำลังตกลงมาเหยียบหัวศัตรูหรือไม่
func _is_stomping(body) -> bool:
	if velocity.y <= 0:
		return false
	return (body.global_position.y - global_position.y) > 20.0

# เหยียบหัวศัตรู -> กำจัดศัตรู และเด้งขึ้น
func _stomp_enemy(body) -> void:
	velocity.y = -jump_force * 0.7
	AudioManager.death_sfx.play()
	if body.has_method("take_damage"):
		body.take_damage(9999, global_position.x)
	elif body.has_method("die"):
		body.die()

func _apply_enemy_damage(body) -> void:
	var dx = body.position.x - position.x
	velocity.y = -400
	if dx > 0:
		velocity.x = -300
	else:
		velocity.x = 300
	damage_tween()
	hit_enemy.emit()

# --------- SIGNALS ---------- #

func _on_collision_body_entered(body):
	if body.is_in_group("Traps") and can_damage:
		damage_tween()
		hit_trap.emit()
	if body.is_in_group("Enemy") and can_damage:
		# กระโดดเหยียบด้านบน = กำจัดศัตรู, ชนด้านข้าง = เสียพลังชีวิต
		if _is_stomping(body):
			_stomp_enemy(body)
		else:
			_apply_enemy_damage(body)

func handle_shooting():
	if Input.is_action_just_pressed("Shoot") and movement_enabled and shoot_cooldown_timer <= 0:
		shoot()

func shoot():
	if bullet_scene == null:
		return
	is_attacking = true
	player_sprite.play("Attack")
	var bullet = bullet_scene.instantiate()
	bullet.global_position = bullet_marker.global_position
	var angle = deg_to_rad(randf_range(0, 20))
	var sign_x = 1.0 if player_node.scale.x > 0 else -1.0
	var dir = Vector2(cos(angle) * sign_x, -sin(angle))
	get_parent().add_child(bullet)
	bullet.shoot(dir, 600, bullet_lifetime)
	shoot_cooldown_timer = shoot_cooldown_time

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Attack":
		is_attacking = false
