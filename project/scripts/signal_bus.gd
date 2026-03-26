extends Node

@warning_ignore_start("unused_signal")

signal game_started
signal sonar_highlight(position: Vector3)
signal fish_caught(fish: Node3D)
signal dialogue_started
signal dialogue_ended

# Boat level signals
signal sonar_highlight_finished(position: Vector3)

@warning_ignore_restore("unused_signal")
