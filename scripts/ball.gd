extends CharacterBody2D

var player_ref: WeakRef
var speed = 100  # 小球移动速度

func _ready():
	if player_ref:
		# 5秒后恢复玩家
		await get_tree().create_timer(5.0).timeout
		restore_player()

func _physics_process(delta):
	# WASD控制小球移动
	var input = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	velocity = input * speed
	move_and_slide()

func restore_player():
	var player = player_ref.get_ref() if player_ref else null
	if player:
		# 先转移摄像机再重生玩家
		var camera = $Camera2D
		remove_child(camera)
		player.respawn_player(global_position, camera)  # 传递摄像机
	queue_free()  # 销毁小球
