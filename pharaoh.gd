extends CharacterBody2D

@export var speed: float = 100.0
@export var float_strength: float = 40.0
@export var health = 25
const projectile_scene = preload("res://entitys/projetil_pharaoh.tscn")
var target
var is_invecible = false
var time = 1
var float_direction := Vector2.ZERO
var rng := RandomNumberGenerator.new()
@onready var explosion: Node2D = $Explosion

const KNOCKBACK_DIRECTIONS = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}
var knockback_strength = 180
var knockback_vector: Vector2 = Vector2.ZERO

func _ready():
	target = get_tree().get_first_node_in_group("Player")
	rng.randomize()

	$Teleporter_timer.start()
	$Attack_timer.start()
	$Float_timer.start()


func _physics_process(delta: float):
	if health <= 0:
		queue_free()
		return
	flutuar(delta)
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
	move_and_slide()

func flutuar(delta):
	velocity = float_direction * speed

func teleportar():
	if has_method("get_tree"):
		for t in get_tree().get_processed_tweens():
			t.kill()
	
	is_invecible = true
	var markers = get_parent().get_node("Marks_teleporters").get_children()
	if markers.size() == 0:
		return

	var chosen = markers[rng.randi_range(0, markers.size() - 1)]
	global_position = chosen.global_position

	efeito_teleporte()
	is_invecible = false


func efeito_teleporte():
	modulate = Color(1, 1, 1, 0.2)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1, 1)

#func atacar():
	#if projectile_scene == null:
		#print("Nenhum projétil configurado!")
		#return
#
	#var projectile = projectile_scene.instantiate()
	#get_parent().add_child(projectile)
#
	#projectile.global_position = global_position

	

func _on_teleporter_timer_timeout() -> void:
	teleportar()

#func _on_attack_timer_timeout() -> void:
	#atacar()

func _on_float_timer_timeout() -> void:
	await get_tree().create_timer(1).timeout
	var origem = global_position
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_speed_scale(0.5)

	tween.tween_property(self, "global_position", target.global_position, time)

func levar_dano(dano: int):
	if is_invecible:
		return
	health -= dano
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()
		print("Inimigo atingiu o jogador")

func anim_tapa(directionExp : Vector2) -> void:
	explosion.get_children()[0].color = Color.html("FFFFFF")
	if health == 0:
		directionExp = Vector2(0,0)
	if directionExp.x == -1:
		explosion.global_position = Vector2(global_position.x, global_position.y + 10)
	elif directionExp.x == +1:
		explosion.global_position = Vector2(global_position.x, global_position.y + 10)
	elif directionExp.y == +1:
		explosion.global_position = Vector2(global_position.x, global_position.y+15)
	elif directionExp.y == -1:
		explosion.global_position = Vector2(global_position.x, global_position.y-15)	
	explosion.anim_tapa(directionExp)

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)
