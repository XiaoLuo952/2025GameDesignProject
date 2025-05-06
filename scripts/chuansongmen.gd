extends Area2D

# Godot 4.x 导出语法
@export var target_portal_path: NodePath
@export var teleport_cooldown: float = 0.5  # 防止连续传送的冷却时间
var can_teleport: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if body.is_in_group("player") and target_portal_path and can_teleport:
		var target_portal = get_node(target_portal_path)
		
		# 检查玩家是否有传送方法
		if body.has_method("start_teleport"):
			# 触发玩家的传送动画
			body.start_teleport(target_portal.global_position)
			
			# 设置冷却时间
			can_teleport = false
			get_tree().create_timer(teleport_cooldown).timeout.connect(
				func(): can_teleport = true
			)
		else:
			# 如果没有传送动画方法，直接传送
			body.global_position = target_portal.global_position
