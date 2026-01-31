extends Node2D

var speed = 200
var isFalling = true

signal block_collide(block, block_bit, mask_bit) 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isFalling:
		var collided = false
		position.y += speed * delta
		
		for bit in get_children():
			for collision in bit.get_node('Area2D').get_overlapping_areas():
				var static_bit = collision.get_parent()
				
				block_collide.emit(self, bit, static_bit)
				collided = true
				
			if (collided):
				position.y -= speed * delta
