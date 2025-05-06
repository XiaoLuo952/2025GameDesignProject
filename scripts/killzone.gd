extends Area2D

# 设置延迟时间（秒）
@export var reload_delay: float = 0.01

var _is_reloading_initiated: bool = false 

func _ready():
	connect("body_entered", _on_body_entered)
	print("死亡区域脚本已加载")

func _on_body_entered(body):
	if body.is_in_group("player"):
		_is_reloading_initiated = true 
		print("玩家触碰陷阱！将在", reload_delay, "秒后重载场景")
		
		var tree = get_tree()
		if tree:
			await tree.create_timer(reload_delay).timeout
			
			# 在 await 之后再次检查 tree 是否有效是个好习惯
			var current_tree = get_tree()
			if current_tree:
				# 在真正重载前，可以再次检查全局状态（如果使用 Autoload）
				# if not GlobalState.can_really_reload_now(): # 也许有其他条件
				#    GlobalState.is_reloading = false # 重置状态
				#    _is_reloading_initiated = false
				#    return 
				
				print("时间到，正在重载场景...")
				current_tree.reload_current_scene()
				# 重载后，所有实例变量会重置为默认值 false
			else:
				printerr("Error: Tree became null after await!")
				# 如果树没了，也需要重置状态（虽然可能意义不大）
				# GlobalState.is_reloading = false # (如果使用 Autoload)
				_is_reloading_initiated = false 
		else:
			printerr("Error: Tree was null before await!")
			_is_reloading_initiated = false # 重置状态
