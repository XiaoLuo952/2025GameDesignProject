extends Area2D

func _ready():
	pass
	
func _on_body_entered(body):
	print(body.name)
	if body.name == "Player":
		print(body.name)
		body.activate_feather(body.FEATHER_DURATION) #进入金羽毛状态 FEATHER_DURATION(5) 秒钟
