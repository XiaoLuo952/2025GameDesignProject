extends Area2D

@export var bounce_strength := 500.0    # 弹力强度
@export var bounce_direction := Vector2.UP  # 默认向上
@export var use_animation := true       # 是否使用动画

# 注意这里的修改，确保在使用前检查节点是否存在
var animation_player

func _ready():
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	print("弹簧初始化完成")
	
	# 获取动画播放器引用并检查是否存在
	animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
	
	# 检查是否有compress动画
	if animation_player and use_animation:
		if not animation_player.has_animation("compress"):
			print("警告：弹簧没有'compress'动画，将创建一个简单动画")
			_create_default_animation()

func _on_body_entered(body):
	print("物体触碰到弹簧:", body.name)
	if body.is_in_group("player"):
		print("玩家触发弹簧效果")
		apply_bounce(body)
		if use_animation and animation_player:
			animation_player.play("compress")

func apply_bounce(body):
	var final_direction = bounce_direction.normalized()
	# 根据不同物理体类型处理
	if body is CharacterBody2D:
		body.velocity = final_direction * bounce_strength
	elif body is RigidBody2D:
		body.apply_central_impulse(final_direction * bounce_strength)

# 创建默认压缩动画
func _create_default_animation():
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	
	# 设置轨道属性
	animation.track_set_path(track_index, "Sprite2D:scale")
	animation.length = 0.3
	
	# 添加关键帧
	animation.track_insert_key(track_index, 0.0, Vector2(1, 1))  # 正常大小
	animation.track_insert_key(track_index, 0.15, Vector2(1.2, 0.8))  # 压缩
	animation.track_insert_key(track_index, 0.3, Vector2(1, 1))  # 恢复
	
	# 循环设置
	animation.loop_mode = Animation.LOOP_NONE
	
	# 添加到动画播放器
	animation_player.add_animation("compress", animation)
