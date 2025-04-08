#extends Area2D
#
#@onready var timer: Timer = $Timer
#
#func _ready():
	#print("陷阱脚本已加载")  # 调试    
	#connect("body_entered", _on_body_entered)
#
#func _on_body_entered(body):
	#print("有物体进入:", body.name)  # 调试
	#if body.is_in_group("player") :
		#print("玩家触碰陷阱!")  # 调试用
		#Engine.time_scale = 0.5
		#body.get_node("CollisionShape2D").queue_free()
		#timer.start()
		#
#
#func _on_timer_timeout() -> void:
	#print("重新加载场景")
	#Engine.time_scale = 1.0
	#get_tree().reload_current_scene()
	#
	## 方法 2：切换到指定场景（如重新开始关卡）
	## get_tree().change_scene_to_file("res://levels/level_1.tscn")
	
extends Area2D

# 设置延迟时间（秒）
@export var reload_delay: float = 1.0

func _ready():
	connect("body_entered", _on_body_entered)
	print("陷阱脚本已加载")

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("玩家触碰陷阱！将在", reload_delay, "秒后重载场景")
		
		# 使用场景树的计时器而不是节点计时器
		await get_tree().create_timer(reload_delay).timeout
		
		# 直接重载场景
		get_tree().reload_current_scene()
