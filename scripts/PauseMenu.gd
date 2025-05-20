extends Control

# 使用 @onready 确保节点存在后再连接
@onready var continue_btn: Button = $VBoxContainer/ContinueButton
@onready var quit_btn: Button = $VBoxContainer/QuitButton

# Godot 4.x 必须用这种信号声明方式
signal continue_game
signal quit_game

func _ready():
	# 强制显示按钮状态（调试用）
	continue_btn.modulate = Color.GREEN
	quit_btn.modulate = Color.RED
	
	# 现代信号连接语法（Godot 4.x 必须这样写！）
	continue_btn.pressed.connect(_on_continue_pressed.bind())
	quit_btn.pressed.connect(_on_quit_pressed.bind())
	
	# 打印连接状态
	print("继续按钮信号连接状态：", continue_btn.pressed.is_connected(_on_continue_pressed))
	print("退出按钮信号连接状态：", quit_btn.pressed.is_connected(_on_quit_pressed))

func _on_continue_pressed():
	print("继续按钮物理触发！")  # 先确认按钮本身是否有效
	continue_game.emit()  # Godot 4.x 必须用 emit()

func _on_quit_pressed():
	print("退出按钮物理触发！")
	quit_game.emit()
