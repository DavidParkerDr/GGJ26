extends Node

@export var block_scene: PackedScene
@export var bit_scene: PackedScene

const STATE_RUNNING = 'Running'
const STATE_GAME_OVER = 'GameOver'

var state = STATE_RUNNING

var size = Vector2(10, 20)
var bits_map: Array[Array] = []

var bit_width = 50

var viewport_size: Vector2

var score = 0
var level = 1
var blocks_dropped = 0
var score_per_level = 100
var streak_length = 0

@onready var mask = $Mask
@onready var bits = $Bits

@onready var music := $MusicPlayer
@onready var sfx := $SfxPlayer
@onready var jingle := $JinglePlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport_size = get_viewport().size
	
	for i in range(0, size.x):
		var bits_column = []
		bits_column.resize(size.y + 1) # Extra row for mask
		bits_map.append(bits_column)
		
		var bit = bit_scene.instantiate()
		bit.position.x = i * bit_width
		
		bit.isOne = false
		bit.add_to_group("bitmap")
		bits_column[0] = bit
		
		mask.add_child(bit)
		
func handle_input(location):
	Input.action_release("move_left")
	Input.action_release("move_right")
			
	if location < viewport_size.x / 2:
		Input.action_press('move_left')
	elif location > (viewport_size.x / 2):
		Input.action_press("move_right")
			
func _unhandled_input(event):
	if state == STATE_RUNNING:
		if event is InputEventScreenTouch:
			if event.is_pressed():
				handle_input(event.position.x)

		if event is InputEventMouseButton:
			if event.is_pressed():
				handle_input(event.position.x)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update falling blocks
	for block in bits.get_children():
		if !block.isFalling:
			continue
			
		# Check if block crossing to next row
		var curr_grid_pos = canvas_position_to_grid(block.position)
		var next_canvas_pos = Vector2(block.position) + Vector2(0, delta * block.speed)
		var next_grid_pos = canvas_position_to_grid(next_canvas_pos)
		
		if curr_grid_pos.y == next_grid_pos.y || curr_grid_pos.y == 0:
			block.position = next_canvas_pos
			continue
		
		# Check any collisions against bitmap in next row
		var bits_collided = []
		for bit in block.get_children():
			var curr_bit_grid_pos = canvas_position_to_grid(block.position + bit.position)
			var collide_bit_pos = Vector2i(curr_bit_grid_pos.x, curr_bit_grid_pos.y - 1)
			var collide_bit = get_bit(collide_bit_pos.x, collide_bit_pos.y)
				
			bits_collided.append([bit, collide_bit, collide_bit_pos])
		
		# If nothing collided, keep going
		if bits_collided.all(
			func(r):
				return r[1] == null
		):
			block.position = next_canvas_pos
			continue
			
		var non_colliding = bits_collided.filter(
			func (r):
				return r[1] == null
		)
		
		var matching_bits = bits_collided.filter(
			func (r):
				return r[1] != null && r[0].isOne == r[1].isOne
		)
		
		# If all bits are either matching or non-colliding, remove matching,
		# let non-colliding continue
		if non_colliding.size() + matching_bits.size() == bits_collided.size():
			for bit in matching_bits:
				# Remove falling bit
				bit[0].queue_free()
				
				# Remove bit from map
				remove_bit_from_map(bit[2])
				
			update_score(10 * matching_bits.size())
				
			for bit in non_colliding:
				var new_block = block_scene.instantiate();
				
				new_block.position = next_canvas_pos + bit[0].position

				# TODO: Merge bits into blocks instead of creating block/bit
				
				bit[0].reparent(new_block)
				bit[0].position = Vector2(0, 0)
				bits.add_child(new_block)
		else:
			var block_bits = block.get_children()
			
			sfx.play_miss()
			streak_length = 0

			for bit_idx in range(0, block_bits.size()):
				var bit = block_bits[bit_idx]
				var next_bit_pos = curr_grid_pos + Vector2i(bit_idx, 0)
				
				set_bit(next_bit_pos.x, next_bit_pos.y, bit)
				
				bit.add_to_group("bitmap")
				bit.remove_from_group("falling")
				
				bit.reparent($Mask)
				
		block.queue_free()
		
	check_game_over()
		
	if state == STATE_RUNNING:
		# Handle input
		if Input.is_action_just_pressed("move_left"):
			move(-1)
		elif Input.is_action_just_pressed("move_right"):
			move(1)
	
	# Update UI
	$LevelValue.text = str(level)
	$ScoreValue.text = str(score)

func move(dx):
	var new_map: Array[Array] = []
	
	if dx == 1:
		new_map.append(bits_map[size.x - 1])
		
		for i in range(0, size.x - 1):
			new_map.append(bits_map[i])
	elif dx == -1:
		for i in range(1, size.x):
			new_map.append(bits_map[i])
			
		new_map.append(bits_map[0])
		
	for block in bits.get_children():
		var curr_grid_pos = canvas_position_to_grid(block.position)
		var bits = block.get_children()
		for bit_idx in range(0, bits.size()):
			var bit_grid_pos = Vector2i(curr_grid_pos.x + bit_idx, curr_grid_pos.y)
			if new_map[bit_grid_pos.x][bit_grid_pos.y] != null:
				return
	
	bits_map = new_map
	
	var bits = get_tree().get_nodes_in_group("bitmap")
	for bit in bits:
		bit.position.x += dx * bit_width
		
		if bit.position.x > (size.x - 1) * bit_width:
			bit.position.x = 0
			
		if bit.position.x < 0:
			bit.position.x = bit_width * (size.x - 1)
			

func _on_tick_timer_timeout() -> void:
	if state == STATE_RUNNING:
		var length = randi_range(1, level)
		var bits: Array[bool] = []
		
		for i in range(0, length):
			bits.append(randi_range(0, 1) == 0)
			
		add_block(bits)
	
func add_block(pattern: Array[bool]):
	blocks_dropped += 1
	
	var block = block_scene.instantiate()
	block.position.x = randi_range(0, size.x - pattern.size()) * bit_width
	
	for i in pattern.size():
		var bit = bit_scene.instantiate()
		bit.isOne = pattern[i]
		bit.position.x = i * bit_width
		
		block.add_child(bit)
		
	$Bits.add_child(block)
	
func remove_bit_from_map(pos: Vector2i):
	var bit = get_bit(pos.x, pos.y)
	
	if pos.y == 0 or bit == null:
		return
	
	set_bit(pos.x, pos.y, null)
	bit.queue_free()
	
	# TODO: Unsupported bits should drop down
	
func update_score(amount):
	if state == STATE_RUNNING:
		score += amount
		music.set_intensity(score/100)
		
		level = floor(score / score_per_level) + 1
		
		sfx.play_hit()
		streak_length = streak_length+1
		if (streak_length==3):
			jingle.play_bonus()
		if (streak_length==6):
			jingle.play_power_up()			
		if (streak_length==10):
			jingle.play_level_complete()	
		
func check_game_over():
	for i in range(0, size.x):
		if get_bit(i, size.y):
			handle_game_over()
			break
			
func handle_game_over():
	state = STATE_GAME_OVER
	
	jingle.play_game_over_sad()
	
func get_bit(x: int, y: int):
	return bits_map[x][y]
	
func set_bit(x: int, y: int, block: Node2D):
	bits_map[x][y] = block
	
func canvas_position_to_grid(pos: Vector2) -> Vector2i:
	var block_map_x = floor(pos.x / bit_width)
	var block_map_y = size.y - ceil(pos.y / bit_width)
	
	return Vector2i(block_map_x, block_map_y)
