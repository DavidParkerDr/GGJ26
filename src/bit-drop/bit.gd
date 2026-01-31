extends Node2D

var isFalling = true

var isOne = false

var speed = 200

@onready var label = $Label

signal bit_collide(falling, mask) 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isOne:
		label.text = "1"
	else:
		label.text = "0"
		
	if isFalling:
		var collided = false
		position.y += speed * delta
		
		for collision in $Area2D.get_overlapping_areas():
			var static_bit = collision.get_parent()
			
			bit_collide.emit(self, static_bit)
			collided = true
			
		if (collided):
			position.y -= speed * delta
		

	
