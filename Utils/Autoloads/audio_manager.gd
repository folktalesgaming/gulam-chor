extends Node2D

@onready var button_sfx = %ButtonSFX
@onready var card_pair_throw_sfx = %CardPairThrowSFX
@onready var card_take_sfx = %CardTakeSFX
@onready var shuffle_sfx = %ShuffleSFX

func _play_button_sfx():
	button_sfx.play()

func _play_shuffle_sfx():
	shuffle_sfx.play()

func _stop_shuffle_sfx():
	shuffle_sfx.stop()

func _play_card_pair_throw_sfx():
	card_pair_throw_sfx.play()

func _play_card_take_sfx():
	card_take_sfx.play()
