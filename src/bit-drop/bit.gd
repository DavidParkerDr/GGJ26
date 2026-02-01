extends Node2D

var isOne = false
var operator = 'Equal'

@onready var label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isOne:
		label.text = "1"
	else:
		label.text = "0"
		
	if operator == 'Equal':
		$ColorRect.color = Color('045604d2')
	elif operator == 'NotEqual':
		$ColorRect.color = Color("be252bdd")
	elif operator == 'None':
		$ColorRect.color = Color("4d7173dd")
	elif operator == 'Mask':
		$ColorRect.color = Color("081111eb")
