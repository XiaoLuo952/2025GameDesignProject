extends Area2D

@export var bounce_strength := 400.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# 计算从弹簧中心指向碰撞点的方向向量
		var direction = (body.global_position - global_position).normalized()
		
		
		# 应用弹射力
		apply_bounce(body, direction)

func apply_bounce(body, direction):
	# 保留部分原有速度（可选）
	var incoming_velocity = body.velocity if "velocity" in body else Vector2.ZERO
	
	if body.has_method("apply_impulse"):
		# 对于RigidBody2D，可以添加冲量
		body.apply_impulse(direction * bounce_strength)
	else:
		# 对于CharacterBody2D，设置新速度
		# 可以混合原有速度和弹射方向
		body.velocity = direction * bounce_strength + incoming_velocity * 0.2
