tool
extends EditorPlugin

var button = null
var importer = null

func get_name():
	return "Overlap2D Importer"

func _enter_tree():
	button = Button.new()
	button.set_text("Importer")
	button.connect("pressed",self,"_show_menu")
	add_custom_control(CONTAINER_CANVAS_EDITOR_MENU,button)
	
	importer = preload("importer/main.gd").new()
	add_child(importer)

func _show_menu():
	importer.popup()



func _exit_tree():
	button.free()
	button = null
	


