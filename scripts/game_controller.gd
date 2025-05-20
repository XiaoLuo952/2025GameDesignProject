extends Node

# 追踪者管理器引用
@onready var chaser_manager = $ChaserManager if has_node("ChaserManager") else null

# 追踪者难度控制
enum GamePhase {PHASE_1, PHASE_2, PHASE_3, BOSS}
var current_phase = GamePhase.PHASE_1

# 游戏进度跟踪
var memories_collected = 0
var total_memories = 0
var player_deaths = 0

func _ready():
	# 不自动修改追踪者难度，保留场景中已设置的难度
	pass

# 根据游戏进度获取难度级别
func get_difficulty_level():
	# 这里可以读取保存的游戏设置、进度等
	# 示例：根据收集的记忆数量设置难度
	var difficulty = 0
	
	# 可以使用总记忆收集百分比
	if total_memories > 0:
		var progress = float(memories_collected) / total_memories
		if progress < 0.3:
			difficulty = 0  # 简单
		elif progress < 0.7:
			difficulty = 1  # 中等
		else:
			difficulty = 2  # 困难
	
	# 或者考虑玩家死亡次数
	if player_deaths > 10:
		difficulty = max(0, difficulty - 1)  # 死亡多次，降低难度
	
	return difficulty

# 设置追踪者数量和特性
func set_chasers_by_difficulty(difficulty_level: int):
	if not chaser_manager:
		return
		
	match difficulty_level:
		0:  # 简单难度
			chaser_manager.set_difficulty(chaser_manager.Difficulty.EASY)
		1:  # 中等难度
			chaser_manager.set_difficulty(chaser_manager.Difficulty.NORMAL)
		2:  # 困难难度
			chaser_manager.set_difficulty(chaser_manager.Difficulty.HARD)
		_:  # 默认或其他情况
			chaser_manager.set_difficulty(chaser_manager.Difficulty.NORMAL)

# 示例：进入新游戏阶段时调整追踪者
func advance_game_phase():
	current_phase = (current_phase + 1) % 4  # 循环切换阶段
	
	if not chaser_manager:
		return
	
	match current_phase:
		GamePhase.PHASE_1:
			# 第一阶段：1个普通追踪者
			chaser_manager.set_custom_chaser_count(1)
		
		GamePhase.PHASE_2:
			# 第二阶段：2个追踪者，第二个更快
			chaser_manager.chaser_configs = [
				{"delay": 2.0, "speed_factor": 1.0},
				{"delay": 3.5, "speed_factor": 1.3}
			]
			chaser_manager.set_custom_chaser_count(2)
		
		GamePhase.PHASE_3:
			# 第三阶段：3个不同特性的追踪者
			chaser_manager.chaser_configs = [
				{"delay": 2.0, "speed_factor": 1.0},
				{"delay": 3.0, "speed_factor": 1.2, "ghost_effect": true},
				{"delay": 4.0, "speed_factor": 1.5, "pass_through_walls": true}
			]
			chaser_manager.set_custom_chaser_count(3)
		
		GamePhase.BOSS:
			# Boss阶段：特殊追踪者配置
			chaser_manager.chaser_configs = [
				{"delay": 1.5, "speed_factor": 1.3},
				{"delay": 1.5, "speed_factor": 1.3},
				{"delay": 3.0, "speed_factor": 1.8, "pass_through_walls": true, "ghost_effect": true}
			]
			chaser_manager.set_custom_chaser_count(3)

# 示例：通过触发区域调整追踪者
func _on_difficulty_area_entered(area_name: String):
	if not chaser_manager:
		return
		
	# 根据进入的区域调整追踪者
	match area_name:
		"easy_area":
			chaser_manager.set_difficulty(chaser_manager.Difficulty.EASY)
		
		"normal_area":
			chaser_manager.set_difficulty(chaser_manager.Difficulty.NORMAL)
		
		"hard_area":
			chaser_manager.set_difficulty(chaser_manager.Difficulty.HARD)
		
		"boss_area":
			# 特殊难度：一个非常快的追踪者
			chaser_manager.chaser_configs = [
				{"delay": 1.0, "speed_factor": 2.0, "pass_through_walls": true}
			]
			chaser_manager.set_custom_chaser_count(1)
		
		"chase_free_area":
			# 安全区：暂时没有追踪者
			chaser_manager.set_custom_chaser_count(0)

# 收集记忆时调用此方法
func on_memory_collected():
	memories_collected += 1
	
	# 每收集3个记忆，增加一个追踪者（示例）
	if memories_collected % 3 == 0 and chaser_manager:
		var new_count = min(chaser_manager.active_chasers.size() + 1, 4)  # 最多4个
		
		# 添加一个新的自定义追踪者
		chaser_manager.add_custom_chaser(
			2.0 + chaser_manager.active_chasers.size() * 0.5,  # 延迟递增
			1.0 + chaser_manager.active_chasers.size() * 0.1   # 速度递增
		)

# 玩家死亡时调用
func on_player_death():
	player_deaths += 1
	
	# 示例：多次死亡后减少追踪者难度
	if player_deaths % 3 == 0 and chaser_manager:
		var difficulty = get_difficulty_level()
		set_chasers_by_difficulty(max(0, difficulty - 1))  # 降低一级难度 
