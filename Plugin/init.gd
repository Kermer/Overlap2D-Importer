tool
extends EditorPlugin

var button = null

var config = ConfigFile.new()
var CFG_PATH

func get_name():
	return "Overlap2D Importer"

func _init():
	CFG_PATH = get_script().get_path()
	CFG_PATH = CFG_PATH.get_base_dir() + "/config.cfg"
	
func _ready():
	button = Button.new()
	button.set_text("Overlap2D")
	button.connect("pressed",self,"_show_menu")
	add_custom_control(CONTAINER_CANVAS_EDITOR_MENU,button)
	
	var script = preload("importer/main.gd")
	var importer = preload("importer/menu.xml").instance()
	importer.set_script(script)
	importer.hide()
	add_child(importer)
	
	load_config()

func _show_menu():
	if !get_node("Menu").is_visible():
		get_node("Menu").show()


func _exit_tree():
	button.free()
	button = null
	
func load_config():
	config.load(CFG_PATH)
#	if !config.has_section("Menu"):
#		return
	if config.has_section_key("Menu","last_path"):
		var last_path = config.get_value("Menu","last_path")
		get_node("Menu")._file_selected(last_path)
	else:
		get_node("Menu/Path").set_text(Globals.globalize_path("res://"))
	if config.has_section_key("Menu","scene"):
		var sc_select = get_node("Menu/Scene")
		var sc_name = config.get_value("Menu","scene")
		sc_select.clear()
		sc_select.add_item(sc_name)
		sc_select.set_item_text(0,sc_name)
	if config.has_section_key("Menu","invert_x"):
		get_node("Menu/InvertX").set_pressed(config.get_value("Menu","invert_x"))
	if config.has_section_key("Menu","invert_y"):
		get_node("Menu/InvertY").set_pressed(config.get_value("Menu","invert_y"))

func save_config():
	config.set_value("Menu","last_path",get_node("Menu/Path").get_text())
	var idx = get_node("Menu/Scene").get_selected()
	config.set_value("Menu","scene",get_node("Menu/Scene").get_item_text(idx))
	var invert_x = get_node("Menu/InvertX").is_pressed()
	config.set_value("Menu","invert_x",invert_x)
	var invert_y = get_node("Menu/InvertY").is_pressed()
	config.set_value("Menu","invert_y",invert_y)
	var err = config.save(CFG_PATH)
	return err

