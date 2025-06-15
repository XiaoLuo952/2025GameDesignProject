extends CharacterBody2D

# 移动和跳跃的参数
const SPEED = 120.0
const JUMP_VELOCITY = -280.0
const ACCEL_SMOOTHING = 0.2  # 加速平滑系数
const DECEL_SMOOTHING = 0.1  # 减速平滑系数

# 冲刺的参数
const DASH_SPEED = 280.0
const DASH_DURATION = 0.15
const DASH_EXIT_SPEED = 0.6  # 冲刺结束时保留的速度比例
const MAX_DASH_COUNT = 2     # 最大冲刺次数
var dash_count := 1          # 初始冲刺次数为1
var is_dashing := false
var dash_timer := 0.0
var dash_direction := Vector2.ZERO  # 记录冲刺方向

# 添加状态枚举和金羽毛相关变量
enum PlayerState {NORMAL, FEATHER}  # 玩家状态：普通、金羽毛
var current_state = PlayerState.NORMAL  # 当前状态
var feather_timer = 0.0  # 金羽毛效果持续时间
@export var FEATHER_DURATION = 5.0  # 金羽毛效果持续5秒
@export var FEATHER_SPEED = 150.0  # 金羽毛飞行速度
@export var feather_direction = Vector2.RIGHT  # 金羽毛初始方向

# 攀爬的参数
const CLIMB_SPEED = 80.0  # 攀爬速度
const WALL_JUMP_VELOCITY = Vector2(200.0, -350.0)  # 墙跳的初始速度
const WALL_JUMP_COOLDOWN = 0.15  # 墙跳后暂时禁用攀爬的时间
var is_climbing := false   # 是否正在攀爬
var can_climb := false     # 是否可以攀爬（靠近墙壁）
var wall_jump_timer := 0.0  # 墙跳冷却计时器
const GRAVITY = 980.0      # 重力常量
var gravity := GRAVITY  # 添加这行，用于动态控制重力

var current_platform = null  # 记录当前站立的平台
var current_moving_platform = null
var platform_velocity = Vector2.ZERO
var is_on_moving_platform := false

var is_in_dash_zone := false
var zone_dash_params := {"direction": Vector2.ZERO, "speed_multiplier": 1.0, "no_gravity": false}  # 存储区域参数

# 添加平台攀爬相关变量
var current_climbing_platform = null
var is_climbing_platform := false

# 添加一个变量来记录当前攀爬的墙壁的方向
var climbing_wall_direction := Vector2.ZERO

# 修改检测是否靠近墙壁的函数
func is_near_wall() -> bool:
	# 检测左侧墙壁
	var left_ray = $WallRayLeft
	# 检测右侧墙壁
	var right_ray = $WallRayRight
	
	# 如果已经在攀爬平台且正在攀爬，保持攀爬状态，防止掉落
	if is_climbing and is_climbing_platform and current_climbing_platform:
		return true
	
	# 重置墙壁方向
	climbing_wall_direction = Vector2.ZERO
	
	# 检查是否正在攀爬平台
	if left_ray and left_ray.is_colliding():
		var collider = left_ray.get_collider()
		if collider is StaticBody2D and collider.has_method("_on_body_entered"):
			current_climbing_platform = collider
			is_climbing_platform = true
			climbing_wall_direction = Vector2.LEFT
			return true
	
	if right_ray and right_ray.is_colliding():
		var collider = right_ray.get_collider()
		if collider is StaticBody2D and collider.has_method("_on_body_entered"):
			current_climbing_platform = collider
			is_climbing_platform = true
			climbing_wall_direction = Vector2.RIGHT
			return true
	
	# 只有当光线确实没有检测到墙壁时才清除攀爬状态
	if (left_ray and !left_ray.is_colliding()) and (right_ray and !right_ray.is_colliding()):
		# 如果我们不是在攀爬状态，则清除攀爬平台
		if !is_climbing:
			if current_climbing_platform and current_climbing_platform.has_method("clear_climbing_player"):
				current_climbing_platform.clear_climbing_player()
			current_climbing_platform = null
			is_climbing_platform = false
			climbing_wall_direction = Vector2.ZERO
	
	return (left_ray and left_ray.is_colliding()) or (right_ray and right_ray.is_colliding())

func _physics_process(delta: float) -> void:
	# 处理金羽毛状态
	match current_state:
		PlayerState.NORMAL:
			# 正常状态下的物理处理
			normal_physics_process(delta)
		PlayerState.FEATHER:
			# 金羽毛状态下的物理处理
			feather_physics_process(delta)
			# 更新金羽毛计时器
			feather_timer -= delta
			if feather_timer <= 0:
				current_state = PlayerState.NORMAL
				# 恢复普通玩家图像，隐藏冲击波图像
				$AnimatedSprite2D.visible = true
				$FeatherSprite.visible = false

# 添加激活金羽毛效果的公共方法
func activate_feather(duration: float = FEATHER_DURATION) -> void:
	current_state = PlayerState.FEATHER
	feather_timer = duration
	velocity = Vector2.ZERO  # 重置速度，防止惯性

	# 设置随机初始方向
	var random_angle = randf_range(0, 2 * PI)
	feather_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()

	# 显示冲击波图像，隐藏普通玩家图像
	$AnimatedSprite2D.visible = false
	$FeatherSprite.visible = true
	
	# 设置冲击波图像的初始旋转
	$FeatherSprite.rotation = feather_direction.angle()

# 添加金羽毛状态下的物理处理函数
func feather_physics_process(delta: float) -> void:
	# 八方向移动，无重力
	var input_direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	# 如果有输入，更新方向
	if input_direction != Vector2.ZERO:
		feather_direction = input_direction
	
		# 更新冲击波图像的旋转，使其头部朝向移动方向（平滑过渡）
		var target_angle = feather_direction.angle()
		# 使用lerp_angle函数平滑过渡到目标角度
		$FeatherSprite.rotation = lerp_angle($FeatherSprite.rotation, target_angle, 0.1)
	else:
		# 即使没有新输入，也继续平滑旋转到当前方向
		var target_angle = feather_direction.angle()
		$FeatherSprite.rotation = lerp_angle($FeatherSprite.rotation, target_angle, 0.1)
		
	# 使用平滑插值实现延迟转向效果
	var target_velocity = feather_direction * FEATHER_SPEED
	
	# 始终保持移动，只是方向会根据输入变化
	velocity = velocity.lerp(target_velocity, 0.07)
	
	move_and_slide()
	
# 将原来的_physics_process内容移到这个函数中
func normal_physics_process(delta: float) -> void:
	print(velocity)
	# 在现有代码开头添加平台跟随逻辑
	if is_on_moving_platform and current_moving_platform:
		# 获取平台的速度并应用到玩家身上
		velocity.x = current_moving_platform.velocity.x
	
	# 区域冲刺状态检测
	if is_in_dash_zone:
		# DashZone区域本身负责管理玩家进入/退出状态
		pass
	# 更新墙跳冷却计时器
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		can_climb = false  # 墙跳冷却期间禁用攀爬
	
	# 更新是否可以攀爬的状态
	can_climb = is_near_wall()
	
	# 处理攀爬状态 - 改进攀爬逻辑
	if can_climb and Input.is_action_pressed("climb"):
		is_climbing = true
		# 如果正在攀爬平台，设置攀爬玩家引用
		if is_climbing_platform and current_climbing_platform and current_climbing_platform.has_method("set_climbing_player"):
			current_climbing_platform.set_climbing_player(self)
	elif is_climbing_platform and current_climbing_platform and Input.is_action_pressed("climb"):
		# 如果已经正在攀爬平台，即使射线没有检测到墙壁，也保持攀爬状态
		is_climbing = true
		current_climbing_platform.set_climbing_player(self)
	else:
		is_climbing = false
		# 如果不再攀爬，清除攀爬玩家引用
		if current_climbing_platform and current_climbing_platform.has_method("clear_climbing_player"):
			current_climbing_platform.clear_climbing_player()
	
	if not is_dashing:
		# 处理重力 - 如果在攀爬状态则不受重力
		if not is_on_floor() and not is_climbing:
			velocity.y += GRAVITY * delta
		elif is_on_floor():
			# 触地恢复冲刺次数(如果冲刺次数小于1则恢复为1)
			if dash_count < 1:
				dash_count = 1
	
	# 修改平台互动检测部分
	if is_on_floor():
		# 获取所有碰撞的平台
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			# 检查是否是可移动平台
			if collider is StaticBody2D and collider.has_method("_on_body_entered"):
				current_moving_platform = collider
				is_on_moving_platform = true
			# 检查是否是可移动平台（通过检查必要的方法是否存在）
			elif collider is CharacterBody2D and collider.has_method("set_rising") and collider.has_method("set_downing"):
				# 确认是从上方碰撞（玩家在平台上方）
				if collision.get_normal().dot(Vector2.UP) > 0.7:
					current_platform = collider
					if current_platform.has_method("start_moving"):
						current_platform.start_moving()
					if Input.is_action_pressed("ui_up"):
						current_platform.set_rising(true)
					else:
						current_platform.set_rising(false)
					if Input.is_action_pressed("ui_down"):
						current_platform.set_downing(true)
					else:
						current_platform.set_downing(false)
	
	# 如果没有站在任何平台上，清除平台引用
	if not is_on_floor():
		current_moving_platform = null
		current_platform = null
		is_on_moving_platform = false
	
	# 跳跃逻辑 - 地面跳跃或墙壁跳跃
	if Input.is_action_just_pressed("ui_accept"):
		if (is_on_floor() or is_climbing) and not is_dashing:
			velocity.y = JUMP_VELOCITY
			is_climbing = false
		elif can_climb and wall_jump_timer <= 0:
			perform_wall_jump()
	
	# 处理水平移动 - 只在不在移动平台上时处理
	if not is_on_moving_platform:
		var direction := Input.get_axis("ui_left", "ui_right")
		var target_velocity = direction * SPEED
		
		if direction:
			velocity.x = lerp(velocity.x, target_velocity, ACCEL_SMOOTHING)
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL_SMOOTHING)
	
	# 添加攀爬平台的跟随逻辑
	if is_climbing and is_climbing_platform and current_climbing_platform:
		# 跟随平台的上升速度
		if current_climbing_platform.velocity.y < 0: # 如果平台正在上升
			velocity.y = current_climbing_platform.velocity.y
		else:
			# 如果平台不在上升，保持攀爬的正常逻辑
			var vertical_direction = Input.get_axis("ui_up", "ui_down")
			velocity.y = vertical_direction * CLIMB_SPEED
			if vertical_direction == 0:
				velocity.y = 0
	
	# 处理攀爬移动 - 修改处理攀爬时的移动逻辑
	if is_climbing:
		# 处理平台攀爬时的左右输入
		if is_climbing_platform and current_climbing_platform:
			# 获取左右输入
			var horizontal_direction = Input.get_axis("ui_left", "ui_right")
			
			# 完全禁用玩家自身的水平移动，防止卡顿
			velocity.x = 0
			
			# 跟随平台的水平位置
			if climbing_wall_direction != Vector2.ZERO:
				# 根据射线位置更新玩家位置，保持贴在墙上
				update_climbing_position()
				
			# 处理上下攀爬
			if current_climbing_platform.velocity.y < 0: # 如果平台正在上升
				# 玩家可以通过上下键在平台上下攀爬
				var vertical_direction = Input.get_axis("ui_up", "ui_down")
				if vertical_direction != 0:
					velocity.y = vertical_direction * CLIMB_SPEED
				# 如果没有垂直输入，保持与平台相同的速度
				else:
					velocity.y = current_climbing_platform.velocity.y
			else:
				# 普通墙壁攀爬的行为
				var vertical_direction = Input.get_axis("ui_up", "ui_down")
				velocity.y = vertical_direction * CLIMB_SPEED
				# 如果没有垂直输入，停止垂直移动
				if vertical_direction == 0:
					velocity.y = 0
		else:
			# 普通墙壁攀爬的行为
			var vertical_direction = Input.get_axis("ui_up", "ui_down")
			velocity.y = vertical_direction * CLIMB_SPEED
			# 如果没有垂直输入，停止垂直移动
			if vertical_direction == 0:
				velocity.y = 0
	
	# 冲刺逻辑
	if Input.is_action_just_pressed("dash") and dash_count > 0 and not is_in_dash_zone:
		var new_dash_direction = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")  # 即使限制移动，仍允许八方向冲刺
		)
		if new_dash_direction == Vector2.ZERO:
			new_dash_direction = Vector2.RIGHT
		dash_direction = new_dash_direction.normalized()
		dash_count -= 1
		is_climbing = false  # 冲刺时停止攀爬
		start_dash()
	print(is_dashing)
	# 处理冲刺状态		
	if is_dashing:
		# 区域冲刺和普通冲刺有不同的处理逻辑
		if is_in_dash_zone:
			# 区域冲刺 - 保持方向和速度直到离开区域
			velocity = zone_dash_params.direction * DASH_SPEED * zone_dash_params.speed_multiplier
			move_and_slide()
			return
		else:
			# 普通冲刺 - 有时间限制
			dash_timer -= delta
			if dash_timer <= 0:
				# 平滑退出冲刺
				is_dashing = false
				velocity *= DASH_EXIT_SPEED
				if dash_direction.y < 0:
					velocity.y = min(velocity.y, JUMP_VELOCITY * 0.7)
			else:
				velocity = dash_direction * DASH_SPEED
				move_and_slide()
				return
	
	move_and_slide()

func start_dash():
	is_dashing = true
	dash_timer = DASH_DURATION

# 执行墙跳
func perform_wall_jump():
	is_climbing = false
	wall_jump_timer = WALL_JUMP_COOLDOWN
	
	# 检测朝向哪边墙壁
	var wall_direction = Vector2.ZERO
	if $WallRayLeft.is_colliding():
		wall_direction = Vector2.RIGHT  # 从左墙跳向右边
	elif $WallRayRight.is_colliding():
		wall_direction = Vector2.LEFT   # 从右墙跳向左边
	
	# 设置墙跳速度
	velocity.x = wall_direction.x * WALL_JUMP_VELOCITY.x
	velocity.y = WALL_JUMP_VELOCITY.y

# 公共方法，让其他脚本可以增加冲刺次数
func set_dash_count(count: int) -> void:
	dash_count = min(count, MAX_DASH_COUNT)
	
## 区域冲刺逻辑
func start_zone_dash(
	direction: Vector2, 
	speed_multiplier: float, 
	reset_count: bool, 
	no_gravity: bool
) -> void:
	# 如果已经在区域冲刺中，不重复触发
	if is_in_dash_zone: return
	
	# 存储参数 - 保存进入时的方向
	zone_dash_params = {
		"direction": direction,
		"speed_multiplier": speed_multiplier,
		"no_gravity": no_gravity
	}
	
	# 区域进入时不改变冲刺次数
	# 冲刺次数将在离开区域时刷新
	
	# 触发区域冲刺
	is_in_dash_zone = true
	is_dashing = true  # 设置为冲刺状态，防止受到重力等影响
	# 移除dash_timer，让其保持冲刺状态直到离开区域
	
	# 使用传入的方向和速度
	velocity = direction * DASH_SPEED * speed_multiplier
	
	# 禁用重力如果需要
	if no_gravity:
		gravity = 0.0

## 结束区域冲刺
func end_zone_dash() -> void:
	# 只有在区域冲刺中才处理
	if not is_in_dash_zone: return
	
	is_in_dash_zone = false
	is_dashing = false  # 结束冲刺状态
	gravity = GRAVITY   # 恢复重力
	
	# 保留一部分速度作为出口速度
	velocity *= DASH_EXIT_SPEED
	
	# 无论之前有几次冲刺，都刷新为1次冲刺
	dash_count = 1
	
	# 检测四周是否有碰撞物体
	var space_state = get_world_2d().direct_space_state
	var collision_check_distance = 15.0  # 检测距离，可以根据需要调整
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
			global_position, 
			global_position + direction * collision_check_distance
		)
		query.collision_mask = collision_mask
		query.exclude = [self]  # 排除自身
		
		# 执行射线检测
		var result = space_state.intersect_ray(query)
		
		# 如果检测到物体，触发死亡
		if result:
			print("检测到碰撞物体: ", result.collider.name, " 在方向: ", direction)
			die()
			break  # 找到一个就足够了，退出循环

# 更新攀爬位置，确保玩家紧贴墙壁
func update_climbing_position():
	if current_climbing_platform and is_climbing_platform:
		# 确保玩家跟随平台的水平位置
		var platform_position = current_climbing_platform.position
		var player_offset = 25  # 玩家与平台中心的水平偏移
		
		if climbing_wall_direction == Vector2.LEFT:
			# 平台在右侧，玩家在左侧
			position.x = platform_position.x - player_offset
		elif climbing_wall_direction == Vector2.RIGHT:
			# 平台在左侧，玩家在右侧
			position.x = platform_position.x + player_offset

## 玩家死亡逻辑
func die() -> void:
	# 禁用输入，防止死亡后继续响应控制
	set_physics_process(false)
	
	# 可以添加死亡动画效果
	# $AnimationPlayer.play("death")
	
	# 可以添加死亡音效
	# $DeathSound.play()
	
	# 短暂延迟后重新加载场景
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
