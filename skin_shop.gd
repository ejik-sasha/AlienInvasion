extends CanvasLayer
@onready var message = $VBoxContainer/Label

@export var skin_buttons = {
	"SkinItem": {"skin": "Icon29_02", "price": 0},
	"SkinItem1": {"skin": "Icon29_09", "price": 1},
	"SkinItem2": {"skin": "Icon29_13", "price": 2},
	"SkinItem3": {"skin": "Icon29_16", "price": 3},
	"SkinItem4": {"skin": "Icon29_24", "price": 4},
	"SkinItem5": {"skin": "Icon29_27", "price": 5},
	"SkinItem6": {"skin": "Icon29_32", "price": 6},
	"SkinItem7": {"skin": "Icon29_38", "price": 7},
}
var player

func _ready():
	player = get_tree().get_root().get_node("Main/Player")
	highlight_owned_skins()
	connect_buttons()
	$Label2.hide()

func connect_buttons():
	for btn_name in skin_buttons.keys():
		var btn = $GridContainer.get_node(btn_name)
		btn.pressed.connect(func():
			on_skin_button_pressed(btn_name)
		)

func highlight_owned_skins():
	for btn_name in skin_buttons.keys():
		var btn = $GridContainer.get_node(btn_name)
		var skin = skin_buttons[btn_name]["skin"]
		if skin in player.owned_skins:
			btn.modulate = Color("lightgreen") 
		else:
			btn.modulate = Color("white") 

func on_skin_button_pressed(btn_name):
	var skin = skin_buttons[btn_name]["skin"]
	var price = skin_buttons[btn_name]["price"]

	if skin in player.owned_skins:
		player.current_skin = skin
		player.apply_skin()
		player.save_progress()
		player.skin_changed.emit()
	else:
		if player.coins >= price:
			player.coins -= price
			player.owned_skins.append(skin)
			player.current_skin = skin
			player.apply_skin()
			player.save_progress()
			player.coins_changed.emit(player.coins)
			player.skin_changed.emit()
			highlight_owned_skins()
		else:
			print("Недостаточно монет")
			$Label.hide()
			$Label2.show()
			await get_tree().create_timer(1).timeout
			$Label2.hide()
			$Label.show()
