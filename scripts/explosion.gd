extends Node2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	cpu_particles_2d.emitting = false
	pass

func anim_tapa(direction : Vector2) -> void:
	cpu_particles_2d.direction = direction
	if direction != Vector2(0,0):
		cpu_particles_2d.spread = 45
	else:
		cpu_particles_2d.spread = 180
	cpu_particles_2d.emitting = true
