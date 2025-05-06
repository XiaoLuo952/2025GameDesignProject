extends CharacterBody2D

# 移动和跳跃的参数
const SPEED = 80.0
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

# 攀爬的参数
const CLIMB_SPEED = 80.0  # 攀爬速度
const WALL_JUMP_VELOCITY = Vector2(200.0, -350.0)  # 墙跳的初始速度
const WALL_JUMP_COOLDOWN = 0.15  # 墙跳后暂时禁用攀爬的时间
var is_climbing := false   # 是否正在攀爬
var can_climb := false     # 是否可以攀爬（靠近墙壁）
var wall_jump_timer := 0.0  # 墙跳冷却计时器
const GRAVITY = 980.0      # 重力常量

var current_platform = null  # 记录当前站立的平台

# 检测是否靠近墙壁
func is_near_wall() -> bool:
	# 检测左侧墙壁
	var left_ray = $WallRayLeft
	# 检测右侧墙壁
	var right_ray = $WallRayRight
	return (left_ray and left_ray.is_colliding()) or (right_ray and right_ray.is_colliding())

func _physics_process(delta: float) -> void:
	# 更新墙跳冷却计时器
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		can_climb = false  # 墙跳冷却期间禁用攀爬
	
	# 更新是否可以攀爬的状态
	can_climb = is_near_wall()
	
	# 处理攀爬状态
	if can_climb and Input.is_action_pressed("climb"):
		is_climbing = true
	else:
		is_climbing = false
	
	if not is_dashing:
		# 处理重力 - 如果在攀爬状态则不受重力
		if not is_on_floor() and not is_climbing:
			velocity.y += GRAVITY * delta
		elif is_on_floor():
			# 触地恢复冲刺次数(如果冲刺次数小于1则恢复为1)
			if dash_count < 1:
				dash_count = 1
	
	# 平台互动检测
	if is_on_floor():
		# 获取所有碰撞的平台
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is CharacterBody2D: # 假设平台都是CharacterBody2D
				# 确认是从上方碰撞（玩家在平台上方）
				if collision.get_normal().dot(Vector2.UP) > 0.7:
					current_platform = collision.get_collider()
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
	
	# 跳跃逻辑 - 地面跳跃或墙壁跳跃
	if Input.is_action_just_pressed("ui_accept"):
		if (is_on_floor() or is_climbing) and not is_dashing:
			velocity.y = JUMP_VELOCITY
			is_climbing = false
		elif can_climb and wall_jump_timer <= 0:
			perform_wall_jump()
	
	# 处理水平移动
	var direction := Input.get_axis("ui_left", "ui_right")
	var target_velocity = direction * SPEED
	
	if direction:
		velocity.x = lerp(velocity.x, target_velocity, ACCEL_SMOOTHING)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECEL_SMOOTHING)
	
	# 处理攀爬移动
	if is_climbing:
		var vertical_direction = Input.get_axis("ui_up", "ui_down")
		velocity.y = vertical_direction * CLIMB_SPEED
		# 如果没有垂直输入，停止垂直移动
		if vertical_direction == 0:
			velocity.y = 0
	
	# 冲刺逻辑
	if Input.is_action_just_pressed("dash") and dash_count > 0:
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
			
	if is_dashing:
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
	
	
