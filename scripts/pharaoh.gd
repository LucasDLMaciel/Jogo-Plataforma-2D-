extends CharacterBody2D

@export var speed: float = 100.0
@export var float_strength: float = 40.0
@export var health = 25
@onready var pharaoh_remaster: Sprite2D = $"pharaoh-remaster"
@export var chance_ficar_parado: float = 1 
var dead = false
@onready var anim: AnimationPlayer = $"pharaoh-remaster/AnimationPlayer"
var current_anim = ""
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
		dead = true
		$idle.stop()
		velocity = Vector2.ZERO
		anim.play("idle")
		$Hitbox/CollisionShape2D.disabled = true
		$Float_timer.stop()
		modulate.a -= 0.005
		return
	
	atualizar_direcao_sprite()

func teleportar():
	is_invecible = true
	
	for t in get_tree().get_processed_tweens():
		if t.is_valid() && t.bind_node(self):
			t.kill()
			break

	var markers = get_parent().get_node("Marks_teleporters").get_children()
	if markers.is_empty():
		return

	var chosen = markers[rng.randi_range(0, markers.size() - 1)]
	global_position = chosen.global_position

	efeito_teleporte()

	var sorte = rng.randf()
	if sorte < chance_ficar_parado:
		print("Pharaoh pausou após teleporte!")
		pausar_apos_teleporte()
	else:
		is_invecible = false

func pausar_apos_teleporte():
	play_anim("idle")
	$idle.play()
	await get_tree().create_timer(3).timeout
	is_invecible = false

func efeito_teleporte():
	if !dead:
		modulate = Color(1, 1, 1, 0.2)
		await get_tree().create_timer(0.1).timeout
		modulate = Color(1, 1, 1, 1)

func _on_teleporter_timer_timeout() -> void:
	teleportar()

func _on_float_timer_timeout() -> void:
	if is_invecible:
		return
	play_anim("Tag")
	$idle.stop()
	var tween = create_tween().bind_node(self)

	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_speed_scale(0.8)
	tween.tween_property(self, "global_position", target.global_position, time)
	$dash.play()

func levar_dano(dano: int):
	$hit.pitch_scale = randf_range(1.5,3.0)
	$hit.play()
	health -= dano
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano(1)
		print("Inimigo atingiu o jogador")

func anim_tapa(directionExp : Vector2) -> void:
	explosion.get_children()[0].color = Color.html("e4d2aa")
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

func atualizar_direcao_sprite():
	if target == null:
		return
	if target.global_position.x < global_position.x:
		pharaoh_remaster.flip_h = true  # Player está à esquerda
	else:
		pharaoh_remaster.flip_h = false # Player está à direita

func play_anim(nome: String):
	if current_anim == nome:
		return
	current_anim = nome
	anim.play(nome)
		
func get_pharaoh_morto():
	if dead:
		return 1
	else: return 0
