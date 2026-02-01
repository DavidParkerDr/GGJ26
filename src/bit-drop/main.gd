extends Node

@export var block_scene: PackedScene
@export var bit_scene: PackedScene

var state = 'Running'

var size = Vector2(10, 20)
var blocks: Array[Node2D] = []

var bit_width = 50

var viewport_size: Vector2

var score = 0
var level = 1
var blocks_dropped = 0
var score_per_level = 100

@onready var mask = $Mask
@onready var bits = $Bits

@onready var music := $MusicPayer
@onready var sfx := $SfxPlayer
@onready var jingle := $JinglePlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport_size = get_viewport().size
	blocks.resize(size.x * size.y)
	
	for i in range(0, size.x):
		var bit = bit_scene.instantiate()
		bit.position.x = i * bit_width
		
		bit.isOne = false
		bit.add_to_group("bitmap")
		
		mask.add_child(bit)
		
func handle_input(location):
	Input.action_release("move_left")
	Input.action_release("move_right")
			
	if location < viewport_size.x / 2:
		Input.action_press('move_left')
	elif location > (viewport_size.x / 2):
		Input.action_press("move_right")
			
func _unhandled_input(event):
	if state == "Running":
		if event is InputEventScreenTouch:
			if event.is_pressed():
				handle_input(event.position.x)

		if event is InputEventMouseButton:
			if event.is_pressed():
				handle_input(event.position.x)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		move(-1)
	elif Input.is_action_just_pressed("move_right"):
		move(1)
	
	$LevelValue.text = str(level)
	$ScoreValue.text = str(score)

func move(dx):
	var bits = get_tree().get_nodes_in_group("bitmap")
	for bit in bits:
		bit.position.x += dx * bit_width
		
		if bit.position.x > (size.x - 1) * bit_width:
			bit.position.x = 0
			
		if bit.position.x < 0:
			bit.position.x = bit_width * (size.x - 1)

func _on_tick_timer_timeout() -> void:
	var length = randi_range(1, level)
	var bits: Array[bool] = []
	
	for i in range(0, length):
		bits.append(randi_range(0, 1) == 0)
		
	add_block(bits)
	
func add_block(pattern: Array[bool]):
	blocks_dropped += 1
	
	var block = block_scene.instantiate()
	block.position.x = randi_range(0, size.x - pattern.size()) * bit_width
	block.block_collide.connect(_on_block_collide)
	
	for i in pattern.size():
		var bit = bit_scene.instantiate()
		bit.isOne = pattern[i]
		bit.position.x = i * bit_width
		
		block.add_child(bit)
		
	$Bits.add_child(block)
	
func update_score(amount):
	if (state == "Running"):
		score += amount
		
		level = floor(score / score_per_level) + 1
	
func _on_block_collide(block, block_bit, mask_bit):
	sfx.play_hit()
		
	if (block_bit.isOne == mask_bit.isOne):
		block_bit.queue_free()
		update_score(10)
	
	else:
		block.isFalling = false
		block.position.x = snapped(block.position.x, bit_width)
		block.position.y = snapped(block.position.y, bit_width)
			
		for bit in block.get_children():
			bit.add_to_group("bitmap")
			bit.remove_from_group("falling")
			
			bit.reparent($Mask)
			
		block.queue_free()
		check_game_over()
		
func check_game_over():
	for bit in get_tree().get_nodes_in_group('bitmap'):
		if (bit.position.y > size.y * bit_width):
			handle_game_over()
			
func handle_game_over():
	state = "GameOver"
	
func get_block(x: int, y: int):
	return blocks[x + y * size.y]
	
func block(x: int, y: int, block: Node2D):
	blocks[x + y * size.y] = block
