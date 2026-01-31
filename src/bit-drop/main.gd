extends Node

@export var bit_scene: PackedScene

@onready var music := $MusicPlayer
@onready var sfx := $SfxPlayer

var size = Vector2(10, 20)

var bit_width = 50

@onready var mask = $Mask
@onready var bits = $Bits

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music.set_mood(music.Mood.RELAXED)
	sfx.play_game_over()
	
	for i in range(0, size.x):
		var bit = bit_scene.instantiate()
		bit.position.x = i * bit_width
		
		bit.isOne = false
		bit.isFalling = false
		bit.add_to_group("bitmap")
		
		mask.add_child(bit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move(-1)
	elif Input.is_action_just_pressed("move_right"):
		move(1)
		
	move_bits(delta)
	
	pass

func move(dx):
	var bits = get_tree().get_nodes_in_group("bitmap")
	for bit in bits:
		bit.position.x += dx * bit_width
		
		if bit.position.x > (size.x - 1) * bit_width:
			bit.position.x = 0
			
		if bit.position.x < 0:
			bit.position.x = bit_width * (size.x - 1)

func _on_tick_timer_timeout() -> void:
	add_bit()
	
func move_bits(delta: float):
	for bit in bits.get_children():
		pass
	
func add_bit():
	var bit = bit_scene.instantiate()
	bit.isOne = randf() > 0.5
	bit.position.y = -bit_width
	bit.position.x = randi_range(0, size.x - 1) * bit_width
	
	bit.bit_collide.connect(_on_bit_collide)
	
	bits.add_child(bit)
	
func _on_bit_collide(falling, stationary):
	
	sfx.play_hit()
	if (falling.isOne == stationary.isOne):
		falling.queue_free()
	
	falling.add_to_group("bitmap")
	falling.remove_from_group("falling")
	
	falling.isFalling = false
	
	falling.position.x = snapped(falling.position.x, bit_width)
	falling.position.y = snapped(falling.position.y, bit_width)
