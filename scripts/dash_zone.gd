extends Area2D

# 可调节参数（在编辑器中直接修改）
@export var speed_multiplier := 1.5    # 区域冲刺速度加成
@export var reset_dash_count := true   # 是否重置冲刺次数
@export var disable_gravity := true    # 是否禁用重力

# 当玩家进入区域时触发
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("start_zone_dash"):  # 检测是否是玩家
		var direction = body.velocity.normalized()
		if direction == Vector2.ZERO:      # 如果玩家静止，默认向右冲刺
			direction = Vector2.RIGHT * body.scale.x  # 考虑角色朝向
		
		# 传递参数给玩家
		body.start_zone_dash(
			direction, 
			speed_multiplier, 
			reset_dash_count, 
			disable_gravity
		)

# 初始化碰撞检测
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 2  # 建议将区域放在专用碰撞层
	collision_mask = 1   # 只检测玩家层（假设玩家在层1）
