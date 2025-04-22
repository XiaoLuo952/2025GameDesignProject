extends CharacterBody2D

#移动和跳跃的参数
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ACCEL_SMOOTHING = 0.2  # 加速平滑系数
const DECEL_SMOOTHING = 0.1  # 减速平滑系数

#冲刺的参数
const DASH_SPEED = 600.0
const DASH_DURATION = 0.15
var can_dash := true
var is_dashing := false
var dash_timer := 0.0

var bounce_force := 1000.0  # 弹射力大小，可在编辑器中调整

func _on_spring_body_entered(spring):
	# 计算圆心连线方向
	var direction = (spring.global_position - global_position).normalized()
	
	# 应用弹射力
	velocity = direction * bounce_force

#盲猜每帧进行
func _physics_process(delta: float) -> void:
	if not is_dashing:
		# 重力
		if not is_on_floor():
			velocity += get_gravity() * delta
		if is_on_floor() :
			can_dash = true #触地情况下可以立刻刷新冲刺

	# 跳跃逻辑a
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_dashing:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	var target_velocity = direction * SPEED
	if direction:
		velocity.x = lerp(velocity.x, target_velocity, ACCEL_SMOOTHING)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECEL_SMOOTHING)

	#冲刺逻辑
	if Input.is_action_just_pressed("dash") and can_dash:
		var dash_direction = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")  # 即使限制移动，仍允许八方向冲刺
		)#记录八个方向 
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2.RIGHT
			
		dash_direction = dash_direction.normalized()
		can_dash = false
		start_dash(dash_direction)
			
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
			
	move_and_slide()

func start_dash(direction: Vector2):
	is_dashing = true
	dash_timer = DASH_DURATION
	velocity = direction * DASH_SPEED
	
func end_dash():
	is_dashing = false
	velocity.x = lerp(velocity.x, 0.0, 0.5)
