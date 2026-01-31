extends Node

@export var bit_scene: PackedScene

var size = Vector2(10, 20)

var bit_width = 50

@onready var mask = $Mask
@onready var bits = $Bits

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(0, size.x):
		var bit = bit_scene.instantiate()
		bit.position.x = i * bit_width
		bit.isOne = i % 2 == 0
		
		mask.add_child(bit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_left"):
		pass
	elif Input.is_action_just_pressed("move_right"):
		pass
		
	pass


func _on_tick_timer_timeout() -> void:
	move_bits()
	
	add_bit()
	
func move_bits():
	for bit in bits.get_children():
		bit.position.y += bit_width


	
func add_bit():
	var bit = bit_scene.instantiate()
	bit.isOne = randf() > 0.5
	
	bit.position.x = randi_range(0, size.x - 1) * bit_width
	
	bits.add_child(bit)
