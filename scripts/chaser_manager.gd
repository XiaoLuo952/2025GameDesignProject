extends Node

# 追踪者场景预加载
@export var chaser_scene: PackedScene

# 追踪者配置数组
# 每个配置包含延迟时间和追踪特性
@export var chaser_configs: Array[Dictionary] = [
	{
		"delay": 1.0,       # 延迟1秒
		"speed_factor": 1.0 # 默认速度倍率
	}
]

# 难度设置 - 根据场景条件改变追踪者数量
enum Difficulty {EASY, NORMAL, HARD, CUSTOM}
@export var difficulty: Difficulty = Difficulty.NORMAL

# 不同难度下的追踪者数量
@export var easy_count := 1
@export var normal_count := 2
@export var hard_count := 3
@export var custom_count := 0  # 自定义数量，通过代码设置

# 实例引用
var player = null
var active_chasers = []  # 当前活跃的追踪者

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# 根据难度设置追踪者数量
	var count = 0
	match difficulty:
		Difficulty.EASY:
			count = easy_count
		Difficulty.NORMAL:
			count = normal_count
		Difficulty.HARD:
			count = hard_count
		Difficulty.CUSTOM:
			count = custom_count
	
	# 根据设置的数量生成追踪者
	spawn_chasers(count)

# 将难度枚举转换为字符串，方便输出
func difficulty_to_string(diff: Difficulty) -> String:
	match diff:
		Difficulty.EASY:
			return "简单"
		Difficulty.NORMAL:
			return "普通"
		Difficulty.HARD:
			return "困难"
		Difficulty.CUSTOM:
			return "自定义"
		_:
			return "未知"

# 根据数量生成追踪者
func spawn_chasers(count: int) -> void:
	# 清除现有追踪者
	for chaser in active_chasers:
		if is_instance_valid(chaser):
			chaser.queue_free()
	active_chasers.clear()
	
	# 检查配置数组是否有足够的配置
	while chaser_configs.size() < count:
		# 如果配置不足，复制最后一个配置并修改延迟
		var last_config = chaser_configs[chaser_configs.size() - 1].duplicate()
		last_config.delay += 0.2  # 每个新追踪者比前一个晚0.2秒出现
		chaser_configs.append(last_config)
	
	# 生成追踪者
	for i in range(count):
		spawn_single_chaser(i)

# 生成单个追踪者
func spawn_single_chaser(index: int) -> void:
	if not chaser_scene:
		printerr("错误：未设置追踪者场景！请在编辑器中设置chaser_scene属性")
		return
	
	var chaser_instance = chaser_scene.instantiate()
	add_child(chaser_instance)
	active_chasers.append(chaser_instance)
	
	# 设置追踪者ID
	if chaser_instance.has_method("set_chaser_id"):
		chaser_instance.set_chaser_id(index)
	
	# 设置追踪者的参数
	if index < chaser_configs.size():
		var config = chaser_configs[index]
		
		# 覆盖默认延迟时间
		chaser_instance.TRACK_DELAY = config.delay
		
		# 如果配置中有速度因子，修改更新频率
		if "speed_factor" in config:
			chaser_instance.POSITION_UPDATE_INTERVAL = chaser_instance.POSITION_UPDATE_INTERVAL / config.speed_factor
		
		# 传递其他自定义参数
		for key in config:
			if key != "delay" and key != "speed_factor":
				if chaser_instance.has_method("set_" + key):
					chaser_instance.call("set_" + key, config[key])

# 公共方法，允许其他脚本通过代码设置难度
func set_difficulty(new_difficulty: Difficulty) -> void:
	difficulty = new_difficulty
	# 如果已经准备好，重新生成追踪者
	if is_inside_tree():
		var count = 0
		match difficulty:
			Difficulty.EASY:
				count = easy_count
			Difficulty.NORMAL:
				count = normal_count
			Difficulty.HARD:
				count = hard_count
			Difficulty.CUSTOM:
				count = custom_count
		spawn_chasers(count)

# 公共方法，允许设置自定义数量的追踪者
func set_custom_chaser_count(count: int) -> void:
	custom_count = count
	difficulty = Difficulty.CUSTOM
	if is_inside_tree():
		spawn_chasers(count)

# 添加自定义配置的追踪者
func add_custom_chaser(delay: float, speed_factor: float = 1.0, custom_params: Dictionary = {}) -> void:
	var config = {
		"delay": delay,
		"speed_factor": speed_factor
	}
	
	# 添加自定义参数
	for key in custom_params:
		config[key] = custom_params[key]
	
	chaser_configs.append(config)
	custom_count = chaser_configs.size()
	difficulty = Difficulty.CUSTOM
	
	# 如果已经准备好，立即生成一个新的追踪者
	if is_inside_tree():
		spawn_single_chaser(chaser_configs.size() - 1)

# 强制显示所有追踪者
func force_show_all_chasers() -> void:
	for i in range(active_chasers.size()):
		var chaser = active_chasers[i]
		if is_instance_valid(chaser):
			chaser.visible = true
			chaser.can_track = true
			chaser.has_player_moved = true
			chaser.waiting_for_movement = false
			chaser.track_timer = 0
			
			# 确保有足够的历史记录供追踪
			if chaser.movement_history.size() == 0 and is_instance_valid(chaser.player):
				var player_pos = chaser.player.global_position
				chaser.initial_player_pos = player_pos
				chaser.movement_history.push_back(chaser.MovementState.new(player_pos, Vector2.ZERO)) 