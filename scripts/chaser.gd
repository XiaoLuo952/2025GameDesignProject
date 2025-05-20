extends CharacterBody2D

# 追踪参数 - 修改为变量而非常量，以便外部脚本修改
var TRACK_DELAY = 1.0    # 默认延迟1.0秒，外部可覆盖
var POSITION_UPDATE_INTERVAL = 0.006  # 约166fps的更新频率
var APPEARANCE_ALPHA = 0.7  # 追踪者的透明度

# 追踪特性
var use_ghost_effect = true  # 是否使用半透明效果
var can_pass_through_walls = false  # 是否能够穿墙

# 追踪者ID，便于管理
var chaser_id = -1

var player = null  # 玩家引用
var can_track = false  # 是否可以开始追踪
var track_timer = 0.0  # 追踪计时器
var position_update_timer = 0.0  # 位置更新计时器
var is_reloading = false  # 防止重复重载场景
var initial_player_pos = null  # 记录玩家初始位置
var has_player_moved = false  # 检测玩家是否开始移动
var waiting_for_movement = true  # 是否正在等待玩家移动
var current_history_index = 0  # 当前正在重放的历史记录索引

# 运动状态记录
class MovementState:
	var position: Vector2
	var velocity: Vector2
	
	func _init(pos: Vector2, vel: Vector2):
		position = pos
		velocity = vel

var movement_history = []  # 存储运动状态历史

func _ready():
	# 将自己添加到"chaser"组，以便dash_zone能够识别
	add_to_group("chaser")
	
	player = get_tree().get_first_node_in_group("player")
	visible = false
	
	# 应用透明度设置
	if use_ghost_effect:
		modulate.a = APPEARANCE_ALPHA
		
	if player:
		initial_player_pos = player.global_position

func _physics_process(delta):
	if not player or is_reloading:
		return
		
	# 检测玩家是否开始移动
	if waiting_for_movement:
		var current_player_pos = player.global_position
		if current_player_pos.distance_to(initial_player_pos) > 5:
			has_player_moved = true
			waiting_for_movement = false
			track_timer = TRACK_DELAY
			# 开始记录玩家的初始状态
			movement_history.push_back(MovementState.new(initial_player_pos, Vector2.ZERO))
	
	# 只要玩家开始移动就记录状态，不管追踪者是否出现
	if has_player_moved:
		position_update_timer -= delta
		if position_update_timer <= 0:
			position_update_timer = POSITION_UPDATE_INTERVAL
			movement_history.push_back(MovementState.new(player.global_position, player.velocity))
		
		# 更新追踪计时器
		if track_timer > 0:
			track_timer -= delta
			if track_timer <= 0:
				if not visible:
					global_position = initial_player_pos
					visible = true
					can_track = true
	
	# 追踪逻辑
	if can_track and movement_history.size() > current_history_index:
		var past_state = movement_history[current_history_index]
		global_position = past_state.position
		velocity = past_state.velocity
		current_history_index += 1
		
		# 如果可以穿墙，使用teleport_character而不是move_and_slide
		if can_pass_through_walls:
			# 不进行碰撞检测，直接设置位置
			position += velocity * delta
			
			# 穿墙模式下手动检测与玩家的碰撞
			if not is_reloading and player and is_instance_valid(player):
				var distance_to_player = global_position.distance_to(player.global_position)
				if distance_to_player < 20: # 碰撞检测距离，调整为角色大小的合理值
					is_reloading = true
					await get_tree().create_timer(0.1).timeout
					if is_instance_valid(self):
						get_tree().reload_current_scene()
		else:
			move_and_slide()
			
			# 检查与玩家的碰撞
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() == player and not is_reloading:
					is_reloading = true
					await get_tree().create_timer(0.1).timeout
					if is_instance_valid(self):
						get_tree().reload_current_scene() 

# 以下是用于外部脚本设置属性的方法
func set_delay(delay: float) -> void:
	TRACK_DELAY = delay

func set_speed_factor(factor: float) -> void:
	POSITION_UPDATE_INTERVAL = 0.006 / factor  # 除以因子，数值越小更新越快

func set_ghost_effect(enabled: bool) -> void:
	use_ghost_effect = enabled
	if is_inside_tree():
		modulate.a = APPEARANCE_ALPHA if enabled else 1.0

func set_alpha(alpha: float) -> void:
	APPEARANCE_ALPHA = alpha
	if is_inside_tree() and use_ghost_effect:
		modulate.a = alpha

func set_pass_through_walls(enabled: bool) -> void:
	can_pass_through_walls = enabled

# 设置追踪者ID（由管理器调用）
func set_chaser_id(id: int) -> void:
	chaser_id = id

# 强制追踪者立即出现
func force_appear() -> void:
	has_player_moved = true
	waiting_for_movement = false
	track_timer = 0
	
	if player and movement_history.size() == 0:
		initial_player_pos = player.global_position
		movement_history.push_back(MovementState.new(initial_player_pos, Vector2.ZERO))
	
	global_position = initial_player_pos if initial_player_pos else global_position
	visible = true
	can_track = true 
