extends AnimatableBody2D
@onready var target: Sprite2D = $target
@export var time = 1
func _ready() -> void:
	var tween = create_tween()
	target.visible = false
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_speed_scale(0.5)
	tween.tween_property(self, "global_position", target.global_position, time)
	tween.tween_property(self, "global_position", global_position, time)
	tween.set_loops()
