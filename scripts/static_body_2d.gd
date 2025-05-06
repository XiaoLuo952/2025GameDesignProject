extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
var is_active := true

func _ready():
	# 正确连接物理碰撞信号
	body_entered.connect(_on_body_entered)

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
