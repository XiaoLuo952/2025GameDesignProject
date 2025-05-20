extends CanvasLayer

func _ready():
	# 确保鼠标可见
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# 正确连接按钮信号
	$StartButton.pressed.connect(_on_StartButton_pressed)

func _on_StartButton_pressed():
	# 切换到游戏场景
	get_tree().change_scene_to_file("res://scenes/game.tscn")  # 注意这里也更新了方法
