extends Node

#
# Goal: create extendable st of conditions by which, for
# a particular level, it's determined if the player has 
# caught enough to progress
#

# todo: support multiple fish types

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connect to the fish_caught signal
	util.aok(signalbus.fish_caught.connect(_on_fish_caught))


func _on_fish_caught(fish: Node3D) -> void:
	print("fish caught: ", fish)
	
	# check the level state and 
	pass
