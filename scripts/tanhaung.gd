extends Area2D

@export var bounce_strength := 500.0    # 弹力强度
@export var bounce_direction := Vector2.UP  # 默认向上
@export var use_animation := true       # 是否使用动画

@onready var animation_player = $AnimationPlayer

func _ready():
	# 连接碰撞信号
	body_entered.connect(_on_body_entered) 

func _on_body_entered(body):
	if body.is_in_group("Player"):
		apply_bounce(body)
		if use_animation:
			animation_player.play("compress")

func apply_bounce(body):
	var final_direction = bounce_direction.normalized()
	# 根据不同物理体类型处理
	if body is CharacterBody2D:
		body.velocity = final_direction * bounce_strength
	elif body is RigidBody2D:
		body.apply_central_impulse(final_direction * bounce_strength)
