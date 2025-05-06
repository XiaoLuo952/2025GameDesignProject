extends StaticBody2D

# 移动参数
const MOVE_SPEED = 40.0  # 向上移动的速度
const HORIZONTAL_SPEED = 10.0  # 水平移动的速度
const HORIZONTAL_ACCEL = 0.2  # 水平加速度平滑系数
var is_moving_up := false  # 是否正在向上移动
var is_moving := false  # 是否开始移动
var initial_position := Vector2.ZERO  # 初始位置
var velocity := Vector2.ZERO  # 平台速度
var target_velocity := Vector2.ZERO  # 目标速度

# 玩家引用
var player = null
var climbing_player = null  # 攀爬在平台上的玩家

func _ready():
	initial_position = position

func _physics_process(delta):
	if is_moving:
		# 向上移动
		if is_moving_up:
			velocity.y = -MOVE_SPEED
		
		# 如果有玩家，根据玩家输入进行水平移动
		var direction = 0
		
		# 优先处理攀爬的玩家输入
		if climbing_player:
			direction = Input.get_axis("ui_left", "ui_right")
		# 如果没有攀爬的玩家，处理站立的玩家输入
		elif player:
			direction = Input.get_axis("ui_left", "ui_right")
		
		# 平滑处理水平移动
		target_velocity.x = direction * HORIZONTAL_SPEED
		velocity.x = lerp(velocity.x, target_velocity.x, HORIZONTAL_ACCEL)
		
		# 应用移动
		position += velocity * delta
	else:
		velocity = Vector2.ZERO
		target_velocity = Vector2.ZERO

# 允许外部脚本设置攀爬玩家
func set_climbing_player(p):
	climbing_player = p
	
# 清除攀爬玩家引用
func clear_climbing_player():
	climbing_player = null

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		is_moving = true
		is_moving_up = true

func _on_body_exited(body):
	if body.is_in_group("player") and body == player:
		player = null 
