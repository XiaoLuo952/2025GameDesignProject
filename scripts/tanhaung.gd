extends Area2D

@export var bounce_strength :=400.0    # 弹力强度
@export var use_animation := true       # 是否使用动画

#@onready var animation_player = $AnimationPlayer

func _ready():
	# 连接碰撞信号
	body_entered.connect(_on_body_entered) 

func _on_body_entered(body):
	if body.is_in_group("player"):
		apply_bounce(body)
		#if use_animation:
			#animation_player.play("compress")

func apply_bounce(body):
	# 获取弹簧的向上方向（本地Y轴）
	var spring_up = transform.y.normalized()
	# 计算垂直于弹簧方向的弹跳方向（本地X轴）
	var bounce_direction = Vector2(-spring_up.x,-spring_up.y)
	
	# 根据不同物理体类型处理
	if body.is_in_group("player"):
		body.velocity = bounce_direction * bounce_strength
	#elif body is RigidBody2D:
		#body.apply_central_impulse(bounce_direction * bounce_strength)
