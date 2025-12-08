extends Node2D

@export var cooldown: float = 2.5
@export var projectile_scene: PackedScene = preload("res://entitys/projetil_pharaoh.tscn")
var rng := RandomNumberGenerator.new()
var pharaohmorto

func _ready():
	rng.randomize()
	spawn_loop()
	
func _process(delta: float) -> void:
	var boss = get_tree().get_nodes_in_group("inimigos")[0]
	if boss.get_pharaoh_morto():
		pharaohmorto = true
	else: pharaohmorto = false

func spawn_loop():
	while !pharaohmorto:
		await get_tree().create_timer(cooldown).timeout
		spawn_projectil()

func spawn_projectil():
	var markers = get_node("../Marks_teleporters").get_children()
	if markers.is_empty():
		return

	var chosen = markers[rng.randi_range(0, markers.size() - 1)]

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = chosen.global_position
	await get_tree().create_timer(1).timeout
	
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		await get_tree().create_timer(1).timeout
		var dir = player.global_position - chosen.global_position
		projectile.tocar_sfx()
		if projectile != null:
			projectile.set_direction(dir)
