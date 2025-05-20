extends StaticBody2D

var balls_required := 3  # 需要触碰3个球
var balls_activated := 0

func _ready():
	visible = true
	set_collision_layer_value(1, true)  # 启用碰撞

func ball_activated():
	balls_activated += 1
	if balls_activated >= balls_required:
		remove_barrier()

func remove_barrier():
	visible = false  # 隐藏挡板
	set_collision_layer_value(1, false)  # 关闭碰撞
