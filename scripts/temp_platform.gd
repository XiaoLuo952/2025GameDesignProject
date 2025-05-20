extends StaticBody2D

@onready var timer = $Timer
@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D

var player_on_platform = false
var disappearing = false

func _ready():
	timer.wait_time = 0.7
	timer.one_shot = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_on_platform = true
		print("disapper")
		timer.start()

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_on_platform = false
		timer.stop()

func _on_timer_timeout():
	print("time out")
	if player_on_platform:
		disappearing = true
		sprite.hide()
		collision.set_deferred("disabled", true)
		# 设置一个重新出现的计时器
		get_tree().create_timer(2.4).timeout.connect(_reappear)
		
func _reappear():
	disappearing = false
	sprite.show()
	collision.set_deferred("disabled", false)
