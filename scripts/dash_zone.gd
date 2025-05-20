extends Area2D

# 可调节参数（在编辑器中直接修改）
@export var speed_multiplier := 1.5    # 区域冲刺速度加成
@export var reset_dash_count := false   # 是否重置冲刺次数，默认不重置
@export var disable_gravity := true    # 是否禁用重力

# 实体碰撞体引用
@onready var solid_collision: CollisionShape2D = $"../SolidBody/CollisionShape2D" if has_node("../SolidBody/CollisionShape2D") else null
@onready var detector_area: Area2D = $"../PreDetector" if has_node("../PreDetector") else null

# 玩家引用
var player = null
var player_is_dashing = false
var check_for_collisions = false  # 是否检测碰撞

func _physics_process(delta):
	# 持续监测附近玩家是否在冲刺
	if detector_area:
		var bodies = detector_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("start_zone_dash"):
				player = body
				
				# 如果是追踪者，直接让它通过
				if body.is_in_group("chaser") or body.get_name() == "Chaser":
					disable_solid_collision()
					player_is_dashing = true
					return
				
				# 如果玩家正在冲刺，立即禁用碰撞
				if player.is_dashing and not player_is_dashing:
					player_is_dashing = true
					disable_solid_collision()
					check_for_collisions = true  # 开始检测碰撞
				# 如果玩家不再冲刺，且碰撞被禁用，恢复碰撞
				elif not player.is_dashing and player_is_dashing:
					player_is_dashing = false
					check_for_collisions = false  # 停止检测碰撞
					await get_tree().create_timer(0.2).timeout
					
					# 检查是否有追踪者在附近，如果有则不恢复碰撞
					var has_chaser_nearby = false
					for nearby_body in detector_area.get_overlapping_bodies():
						if nearby_body.is_in_group("chaser") or nearby_body.get_name() == "Chaser":
							has_chaser_nearby = true
							break
					
					if not player.is_dashing and not has_chaser_nearby:  # 再次检查
						enable_solid_collision()
	
	# 在玩家冲刺过程中检测碰撞
	if check_for_collisions and player and player.is_dashing:
		check_player_collision()

# 当玩家进入区域时触发
func _on_body_entered(body: Node2D) -> void:
	# 只有当玩家正在冲刺时才响应
	if body.has_method("start_zone_dash") and body.is_dashing:
		# 禁用实体碰撞已经在物理处理中完成
		
		# 使用玩家当前的冲刺方向，而不是重新计算
		var direction = body.dash_direction
		
		# 传递参数给玩家
		body.start_zone_dash(
			direction, 
			speed_multiplier, 
			reset_dash_count, 
			disable_gravity
		)
		
		# 开始检测碰撞
		if body.has_method("die"):
			player = body
			check_for_collisions = true

# 当玩家离开区域时触发
func _on_body_exited(body: Node2D) -> void:
	# 检测是否是追踪者
	if body.is_in_group("chaser") or body.get_name() == "Chaser":
		# 检查是否还有其他需要保持通过的物体
		await get_tree().create_timer(0.1).timeout
		
		# 检查是否有玩家或其他追踪者在附近
		var can_enable_collision = true
		for nearby_body in detector_area.get_overlapping_bodies():
			if nearby_body.has_method("start_zone_dash") and nearby_body.is_dashing:
				can_enable_collision = false
				break
			if nearby_body.is_in_group("chaser") or nearby_body.get_name() == "Chaser":
				can_enable_collision = false
				break
		
		if can_enable_collision:
			enable_solid_collision()
		return
		
	# 检测是否是玩家
	if body.has_method("end_zone_dash"):
		body.end_zone_dash()
		check_for_collisions = false  # 停止检测碰撞
		
		# 玩家离开后恢复实体碰撞
		# 延迟一下恢复，确保玩家完全离开
		await get_tree().create_timer(0.1).timeout
		
		# 检查是否有追踪者在附近，如果有则不恢复碰撞
		var has_chaser_nearby = false
		for nearby_body in detector_area.get_overlapping_bodies():
			if nearby_body.is_in_group("chaser") or nearby_body.get_name() == "Chaser":
				has_chaser_nearby = true
				break
				
		if not player_is_dashing and not has_chaser_nearby:  # 确保玩家不再冲刺且没有追踪者
			enable_solid_collision()

# 初始化碰撞检测
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)  # 连接离开事件
	collision_layer = 2  # 建议将区域放在专用碰撞层
	collision_mask = 1   # 只检测玩家层（假设玩家在层1）
	
	# 检查实体碰撞体是否存在
	if not solid_collision:
		print("警告：DashZone需要一个SolidBody子节点，包含CollisionShape2D")
	
	# 检查预检测区域是否存在
	if not detector_area:
		print("警告：DashZone需要一个PreDetector Area2D子节点，用于提前检测玩家冲刺")

# 禁用实体碰撞
func disable_solid_collision() -> void:
	if solid_collision:
		solid_collision.disabled = true

# 启用实体碰撞
func enable_solid_collision() -> void:
	if solid_collision:
		solid_collision.disabled = false

# 检查玩家周围是否有碰撞物体
func check_player_collision():
	if not player or not is_instance_valid(player):
		return
		
	var space_state = player.get_world_2d().direct_space_state
	var collision_check_distance = 15.0  # 检测距离
	var collision_mask = 15  # 二进制为1111，表示检测层0、1、2、3
	
	# 四个方向的检测向量
	var directions = [
		Vector2.RIGHT,  # 右
		Vector2.LEFT,   # 左
		Vector2.UP,     # 上
		Vector2.DOWN    # 下
	]
	
	# 检测四个方向
	for direction in directions:
		# 创建碰撞查询
		var query = PhysicsRayQueryParameters2D.create(
			player.global_position, 
			player.global_position + direction * collision_check_distance
		)
		query.collision_mask = collision_mask
		query.exclude = [player]  # 排除自身
		
		# 执行射线检测
		var result = space_state.intersect_ray(query)
		
		# 如果检测到物体，触发死亡
		if result and not result.collider.is_in_group("dash_zone") and not result.collider.get_parent() == self:
			print("Dash冲刺碰撞物体: ", result.collider.name, " 在方向: ", direction)
			if player.has_method("die"):
				player.die()
				check_for_collisions = false  # 停止检测
				break  # 找到一个就足够了，退出循环
