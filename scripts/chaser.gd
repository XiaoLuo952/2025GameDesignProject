extends CharacterBody2D

# 追踪参数
const TRACK_DELAY = 2.0    # 2秒后出现
const POSITION_UPDATE_INTERVAL = 0.006  # 约166fps的更新频率

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
	player = get_tree().get_first_node_in_group("player")
	visible = false
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
		move_and_slide()
		
		# 检查与玩家的碰撞
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() == player and not is_reloading:
				is_reloading = true
				await get_tree().create_timer(0.1).timeout
				if is_instance_valid(self):
					get_tree().reload_current_scene() 
