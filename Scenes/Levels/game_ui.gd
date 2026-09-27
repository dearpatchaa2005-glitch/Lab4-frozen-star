extends CanvasLayer

# ============================================================
#  FROZEN STAR - UI ระหว่างเล่น
#  แสดง  พลังชีวิต (หัวใจ) / คะแนน / จำนวนเศษดาวที่เก็บได้ / กุญแจ
# ============================================================

@onready var score_label = %ScoreLabel
@onready var hp_bar = %ProgressBar
@onready var alert_label: Label = $GameUI/BottomBar/AlertLabel
@onready var status_label: Label = $GameUI/TopBar/HpLabel
@onready var life_rect = $GameUI/TopBar/LifeRect

func _ready() -> void:
	# ซ่อนแถบพลังชีวิตแบบเก่า เพราะเปลี่ยนมาใช้หัวใจ 3 ดวงแทน
	$GameUI/TopBar/HpRect.visible = false

func _process(_delta):
	score_label.text = "Score: %d" % GameManager.get_stat("score")

	# หัวใจ : กว้าง 48 px ต่อ 1 ดวง (TextureRect ปูภาพหัวใจซ้ำ)
	life_rect.size.x = 48 * max(GameManager.get_hp(), 0)

	# เศษดาว และ กุญแจ
	var text = "Star %s" % GameManager.star_text()
	if GameManager.has_key():
		text += "   Key %d" % GameManager.get_stat("key")
	status_label.text = text

	$GameUI/TopBar/btnSound/on.visible   = GameManager.sfx_on
	$GameUI/TopBar/btnSound/mute.visible = !GameManager.sfx_on
	$GameUI/TopBar/btnMusic/mute.visible = !GameManager.music_on

func alert(text):
	alert_label.text = text
	alert_label.visible = true
	alert_label.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(alert_label, "scale", Vector2(1,1), 0.3)
	await get_tree().create_timer(2).timeout
	alert_label.visible = false

func _on_btn_sound_pressed() -> void:
	GameManager.sfx_on = !GameManager.sfx_on
	GameManager.update_option()
	GameManager.save_option()

func _on_btn_music_pressed() -> void:
	GameManager.music_on = !GameManager.music_on
	GameManager.update_option()
	GameManager.save_option()

func _on_btn_left_pressed() -> void:
	Input.action_press("Left")

func _on_btn_left_released() -> void:
	Input.action_release("Left")

func _on_btn_up_pressed() -> void:
	Input.action_press("Jump")

func _on_btn_up_released() -> void:
	Input.action_release("Jump")

func _on_btn_right_pressed() -> void:
	Input.action_press("Right")

func _on_btn_right_released() -> void:
	Input.action_release("Right")

func _on_btn_shoot_button_down() -> void:
	Input.action_press("Shoot")

func _on_btn_shoot_button_up() -> void:
	Input.action_release("Shoot")

func _on_btn_save_pressed() -> void:
	GameManager.save_game()
	alert("บันทึกเกมแล้ว")
