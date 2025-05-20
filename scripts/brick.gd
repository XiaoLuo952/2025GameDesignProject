extends StaticBody2D

#@onready var timer = $Timer
const DASH_SPEED = 100.0  # 冲刺移动的速度
const BACK_SPEED = 50.0  # 往回移动的速度
const HORIZONTAL_ACCEL = 0.2  # 水平加速度平滑系数
var wait_time := 0.2  # 等待时间
var velocity := Vector2.ZERO  # 平台速度
var initial_position := Vector2.ZERO  # 初始位置
var target_velocity := Vector2.ZERO 
var is_hit := false
var is_returning := false
var current_direction := 0  # 1=右, -1=左

@onready var leftray: RayCast2D = $leftray
@onready var rightray: RayCast2D = $rightray


func _ready():
	initial_position = position
	leftray.enabled = true
	rightray.enabled = true
	leftray.target_position = Vector2(10, 0)
	rightray.target_position = Vector2(10, 0)
	#timer.wait_time = 0.05
	#timer.one_shot = true

func _physics_process(delta):
	if is_hit:
		# 被撞击后的移动
		print("hit")
		# 平滑处理水平移动
		target_velocity.x = current_direction * DASH_SPEED
		velocity.x = lerp(velocity.x, target_velocity.x, HORIZONTAL_ACCEL)
		
		print(velocity.x)
		
		position += velocity * delta
		
		# 检测前方墙体
		leftray.force_raycast_update()
		if leftray.is_colliding() :
			hit_wall()
		rightray.force_raycast_update()
		if rightray.is_colliding():
			hit_wall()
	
	elif is_returning:
		# 返回原位的移动
		var direction = sign(initial_position.x - position.x)
		if abs(position.x - initial_position.x) < 5:  # 接近原位
			position.x =initial_position.x
			is_returning = false
		else:
			velocity.x = BACK_SPEED * direction
			position += velocity * delta


		
func hit_wall():
	is_hit = false
	velocity = Vector2.ZERO
	is_returning = true

#从左侧撞击砖块
func _on_left_body_entered(body):
	if body.is_in_group("player") and body.is_dashing and not is_hit :
		current_direction = -1
		is_hit = true

#从右侧撞击砖块
func _on_right_body_entered(body):
	if body.is_in_group("player") and body.is_dashing and not is_hit :
		current_direction = 1
		is_hit = true
