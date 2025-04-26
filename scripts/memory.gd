extends Area2D
#收集并存储数目，可能需要针对每个实例化对象编号

# 刷新设置
@export var respawn_time := 5.0  # 重生时间，单位秒
var initial_position := Vector2.ZERO  # 初始位置
var is_collected := false  # 是否已被收集
var respawn_timer := 0.0  # 重生计时器

# 保存原始显示状态的引用
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# 连接信号
	body_entered.connect(_on_body_entered)
	# 记录初始位置
	initial_position = global_position
	print("Memory初始化完成，位置:", initial_position)

func _process(delta):
	# 如果已被收集，更新计时器
	if is_collected:
		respawn_timer -= delta
		if respawn_timer <= 0:
			respawn()

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return  # 如果已被收集，忽略碰撞
		
	print("物体触碰到Memory:", body.name)
	if body.is_in_group("player"):
		print("玩家收集到Memory")
		# 设置玩家冲刺次数为2
		body.set_dash_count(2)
		collect()

# 收集Memory
func collect():
	is_collected = true
	respawn_timer = respawn_time
	
	# 隐藏而不是销毁
	sprite.visible = false
	collision.disabled = true
	
	print("Memory已被收集，将在", respawn_time, "秒后重生")

# 重生Memory
func respawn():
	is_collected = false
	
	# 恢复可见性和碰撞
	sprite.visible = true
	collision.disabled = false
	
	print("Memory已重生")
