extends CharacterBody2D

var caido = false
var dead = false
const VELOCIDADE = 50
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var esquerda: RayCast2D = $Esquerda
@onready var direita: RayCast2D = $Direita
@onready var hitbox: Area2D = $hitbox
@onready var respawn_timer: Timer = $respawn_timer
@onready var explosion: Node2D = $Explosion

@export var health: int = 4
var health_respawn

const KNOCKBACK_DIRECTIONS = {
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var player: CharacterBody2D = null
var direcao: Vector2 = Vector2.LEFT
var tempo_troca: float = 0.0
var is_following_player = false

var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 180
var knockback_recuperacao = 600.0

enum Estado { PATRULHANDO, PERSEGUINDO, RESPAWN, MORTO, CAIDO }
var estado_atual: Estado = Estado.PATRULHANDO

func _ready() -> void:
	health_respawn = health

func _process(delta: float) -> void:
	if health == 0:
		trocar_estado(Estado.CAIDO)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, knockback_recuperacao * delta)

	match estado_atual:
		Estado.PATRULHANDO:
			estado_patrulhando(delta)
		Estado.PERSEGUINDO:
			estado_perseguindo(delta)
		Estado.RESPAWN:
			estado_respawn(delta)
		Estado.MORTO:
			estado_morto()
		Estado.CAIDO:
			estado_caido()
	
	if !caido:
		velocity += knockback_vector
	move_and_slide()

func estado_caido() -> void:
	if not caido:
		caido = true
		velocity = Vector2.ZERO
		animacao.play("dead")
		respawn_timer.start()
		min_hitbox()


func estado_morto() -> void:
	velocity = Vector2.ZERO
	dead = true
	if animacao.animation != "dead2":
		animacao.play("dead2")
	await(get_tree().create_timer(0.2).timeout)
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	modulate.a -= 0.025
	if modulate.a <= 0:
		queue_free()

func estado_patrulhando(delta: float) -> void:
	if is_on_floor():
		_verificar_direcao()

	tempo_troca -= delta
	if tempo_troca <= 0.0:
		_mover_aleatorio()

	velocity.x = direcao.x * VELOCIDADE
	animacao.flip_h = direcao.x < 0

	if animacao.animation != "andando":
		animacao.play("andando")


func estado_perseguindo(delta: float) -> void:
	if not player:
		trocar_estado(Estado.PATRULHANDO)
		return
	if is_following_player:
		var dir = (player.position - position).normalized()
		velocity.x = dir.x * VELOCIDADE * 2
		animacao.flip_h = dir.x < 0

	if animacao.animation != "andando":
		animacao.play("andando", 2.0, false)

func estado_respawn(_delta: float) -> void:
	velocity = Vector2.ZERO
	animacao.play("dead", -1.0, true)

func trocar_estado(novo_estado: Estado) -> void:
	if estado_atual != novo_estado:
		estado_atual = novo_estado

func min_hitbox() -> void:
	hitbox.scale.y = 0.3
	hitbox.global_position.y = global_position.y + 17
	
func max_hitbox() -> void:
	hitbox.scale.y = 1
	hitbox.global_position.y = global_position.y

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") && (!caido && !dead):
		player = body
		is_following_player = true
		trocar_estado(Estado.PERSEGUINDO)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player && (!caido && !dead):
		player = null
		trocar_estado(Estado.PATRULHANDO)

func _mover_aleatorio() -> void:
	var opcoes = [Vector2.RIGHT, Vector2.LEFT]
	direcao = opcoes[randi() % opcoes.size()]
	tempo_troca = randf_range(2.0, 4.0)

func _verificar_direcao() -> void:
	if not is_on_floor():
		return
	if direcao == Vector2.RIGHT and not direita.is_colliding():
		direcao = Vector2.LEFT
	elif direcao == Vector2.LEFT and not esquerda.is_colliding():
		direcao = Vector2.RIGHT

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		var dir = KNOCKBACK_DIRECTIONS[comando]
		knockback_vector = dir * knockback_strength
		print("Knockback:", comando)

func levar_dano(dano: int):
	health -= dano
	if caido && !animacao.is_playing():
		trocar_estado(Estado.MORTO)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()
		print("Inimigo atingiu o jogador")

func _on_respawn_timer_timeout() -> void:
	if estado_atual == Estado.CAIDO:
		animacao.play_backwards("dead")  
		await animacao.animation_finished
		health = health_respawn
		caido = false
		dead = false
		max_hitbox()
		trocar_estado(Estado.PATRULHANDO)
		
func anim_tapa(directionExp : Vector2) -> void:
	explosion.get_children()[0].color = Color.html("#c2bc90")
	if health == 0:
		directionExp = Vector2(0,0)
	if directionExp.x == -1:
		explosion.global_position = Vector2(global_position.x - 10, global_position.y + 10)
	elif directionExp.x == +1:
		explosion.global_position = Vector2(global_position.x + 10, global_position.y + 10)
	elif directionExp.y == +1:
		explosion.global_position = Vector2(global_position.x, global_position.y+15)
	elif directionExp.y == -1:
		explosion.global_position = Vector2(global_position.x, global_position.y-15)	
	explosion.anim_tapa(directionExp)
