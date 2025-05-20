extends CanvasItem  # 改为继承自CanvasItem以获得draw功能

# 雪花数组，存储每片雪花的数据
var snowflakes = []
# 屏幕尺寸
var screen_size: Vector2
# 雪花数量
@export var flake_count: int = 150
# 雪花速度范围
@export_range(10, 200) var min_speed: float = 30.0
@export_range(10, 200) var max_speed: float = 70.0
# 雪花大小范围
@export_range(0.1, 3.0) var min_size: float = 3
@export_range(0.1, 3.0) var max_size: float = 5
# 左右摆动幅度
@export_range(0, 50) var sway_amount: float = 8
# 摆动速度
@export_range(0, 5) var sway_speed: float = 1.0

func _ready():
	# 获取屏幕尺寸
	screen_size = get_viewport_rect().size
	# 初始化雪花
	for i in range(flake_count):
		snowflakes.append(create_snowflake())
	# 确保节点可绘制
	queue_redraw()

func create_snowflake() -> Dictionary:
	return {
		"position": Vector2(
			randf() * screen_size.x, 
			randf() * screen_size.y
		),
		"speed": randf_range(min_speed, max_speed),
		"size": randf_range(min_size, max_size),
		"sway_offset": randf() * 100.0,  # 用于摆动效果的随机偏移
		"sway_direction": 1 if randf() > 0.5 else -1  # 摆动方向
	}

func _process(delta: float):
	queue_redraw()  # 在Godot 4.x中使用queue_redraw()替代update()

func _draw():
	var delta = get_process_delta_time()  # 获取帧间隔时间
	for flake in snowflakes:
		# 更新位置 - 下落
		flake.position.y += flake.speed * delta
		
		# 更新位置 - 左右摆动
		var sway = sin(Time.get_ticks_msec() * 0.001 * sway_speed + flake.sway_offset) * sway_amount
		flake.position.x += sway * delta * flake.sway_direction
		
		# 如果雪花落到底部，重置到顶部
		if flake.position.y > screen_size.y + flake.size:
			flake.position = Vector2(
				randf() * screen_size.x,
				-flake.size
			)
			# 重置一些属性增加随机性
			flake.speed = randf_range(min_speed, max_speed)
			flake.sway_direction = 1 if randf() > 0.5 else -1
		
		# 绘制雪花 - 简单的像素风格
		draw_rect(
			Rect2(flake.position, Vector2(flake.size, flake.size)), 
			Color(1, 1, 1, 0.8)  # 白色带透明度
		)
