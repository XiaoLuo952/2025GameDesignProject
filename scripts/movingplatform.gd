# 平台脚本
extends CharacterBody2D

@export var move_speed := 50.0
@export var vertical_speed := 50.0     # 竖直速度

var is_moving := false
var is_rising := false                # 是否正在上升
var is_downing := false               # 是否正在下降


func start_moving():
	#print('move')
	is_moving = true

func _physics_process(delta):
	#水平移动
	if is_moving:
		#print('moving')
		velocity.x = move_speed
	else:
		velocity.x = 0
		
	# 垂直移动（修正后的逻辑）
	velocity.y = 0  # 先重置
	if is_rising:
		velocity.y = -vertical_speed
	elif is_downing:  # 使用elif确保不会同时设置
		velocity.y = vertical_speed

	move_and_slide()


# 外部调用来控制上升状态
func set_rising(state: bool):
	is_rising = state
# 外部调用来控制下降状态
func set_downing(state: bool):
	is_downing = state
