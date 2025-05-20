extends Area2D

@export var activated_color := Color.GREEN  # 触碰后变绿色
var is_activated := false

func _ready():
	# 连接碰撞信号
	body_entered.connect(_on_body_entered) 
	$Sprite2D.modulate = Color.WHITE  # 初始白色

func _on_body_entered(body):
	if body.is_in_group("player") and not is_activated:
		activate_ball()

func activate_ball():
	is_activated = true
	$Sprite2D.modulate = activated_color  # 变色
	get_node("/root/Game").ball_activated()  # 通知关卡
