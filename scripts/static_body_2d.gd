extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var detector: Area2D = $Area2D  # 添加一个Area2D子节点用于检测
var is_active := true

func _ready():
	# 使用Area2D来检测碰撞
	if detector:
		detector.body_entered.connect(_on_body_entered)
	else:
		print("错误：缺少Area2D子节点！请添加Area2D子节点并命名为'Area2D'")

# 必须明确声明参数类型为 PhysicsBody2D
func _on_body_entered(body: PhysicsBody2D):
	if body.name == "Player" && is_active:
		is_active = false
		await get_tree().create_timer(1.0).timeout
		_disappear()

func _disappear():
	collision.set_deferred("disabled", true)
	sprite.modulate.a = 0.3
	await get_tree().create_timer(4.0).timeout
	_reappear()

func _reappear():
	collision.disabled = false
	sprite.modulate.a = 1.0
	is_active = true
