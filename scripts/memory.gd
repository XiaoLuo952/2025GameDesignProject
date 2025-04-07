extends Area2D
#收集并存储数目，可能需要针对每个实例化对象编号

func _on_body_entered(body: Node2D) -> void:
	queue_free()
	pass # Replace with function body.
