extends CharacterBody2D

const VELOCIDADE = 30
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var esquerda: RayCast2D = $Esquerda
@onready var direita: RayCast2D = $Direita
@onready var hitbox: Area2D = $hitbox

@export var health: int = 100

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

enum Estado { PATRULHANDO, PERSEGUINDO, ATACANDO, MORTO }
var estado_atual: Estado = Estado.PATRULHANDO

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, knockback_recuperacao * delta)

	match estado_atual:
		Estado.PATRULHANDO:
			estado_patrulhando(delta)
		Estado.PERSEGUINDO:
			estado_perseguindo(delta)
		Estado.ATACANDO:
			estado_atacando(delta)
		Estado.MORTO:
			estado_morto()

	velocity += knockback_vector
	move_and_slide()

func estado_morto() -> void:
	pass

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

func estado_atacando(_delta: float) -> void:
	velocity.x = 0
	if animacao.animation != "ataque":
		animacao.play("ataque")

func trocar_estado(novo_estado: Estado) -> void:
	if estado_atual != novo_estado:
		estado_atual = novo_estado

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		is_following_player = true
		trocar_estado(Estado.PERSEGUINDO)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
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
	if health <= 0:
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()
		print("Inimigo atingiu o jogador")
