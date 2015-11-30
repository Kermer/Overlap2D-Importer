tool
extends Node

var TO_PATH = "res://overlap_import"
var EXT = ".dt"
var DATA = {}
var COMPOSITES = {}
var RESOLUTION = Vector2(800,600)
var ATLAS

var drag = false

func reset():
	TO_PATH = "res://overlap_import"
	EXT = ".dt"
	DATA = {}
	COMPOSITES = {}
	RESOLUTION = Vector2(800,600)

func _enter_tree():
#	self.hide()
	ATLAS = preload("atlas.gd").new()
	print("-OI- Overlap2D Projects Importer")
#	print("-OI- User path check: ",Globals.globalize_path("user://"))
#	print("-OI- Res path check: ",Globals.globalize_path("res://"))
#	print("-OI- Script path: ",get_script().get_path())
	
	var fd = get_node("FileDialog")
	fd.set_mode(FileDialog.MODE_OPEN_FILE)
	fd.set_access(FileDialog.ACCESS_FILESYSTEM)
	fd.add_filter("*.dt")
	fd.connect("file_selected",self,"_file_selected")
	
	get_node("BSelect").connect("pressed",get_node("FileDialog"),"popup")
	get_node("Path").connect("text_changed",self,"_check_file")
#	get_node("BImport").connect("pressed",get_parent(),"save_config")
	get_node("BImport").connect("pressed",self,"_import_project")
	get_node("BClose").connect("pressed",self,"hide")
	
	set_process_input(true)

func _input(ev):
	if ev.type == InputEvent.MOUSE_BUTTON and ev.button_index == 1 and !ev.is_echo():
		if ev.is_pressed():
			var mpos = ev.pos; var pos = get_pos(); var size = get_size()
			if mpos.x > pos.x and mpos.x < pos.x+size.x and mpos.y > pos.y and mpos.y < pos.y+size.y:
				drag = true
		else:
			drag = false
	elif ev.type == InputEvent.MOUSE_MOTION and drag == true:
		set_pos(get_pos()+ev.relative_pos)

func _file_selected(path):
	get_node("Path").set_text(path)
	get_node("Path").set_cursor_pos(path.length())
	_check_file(path)

func _check_file(path):
	get_node("FileDialog").call_deferred("set_current_path",path)
	var f = File.new()
	var err = f.open(path,File.READ)
	f.close()
	get_node("BImport").set_disabled(true)
	if err != OK:
		return
	if check_project( path ) != OK:
		dprint("Invalid project file.")
		return
	var sc_list = import_scenes_list()
	if sc_list.size() == 0:
		dprint("There's no scenes defined in the project!")
		return
	
	get_node("BImport").set_disabled(false)

func _import_project():
	var err_save = get_parent().save_config()
	if err_save == OK:
		dprint("Config saved")
	else:
		dprint(str("Failed to save config. Error code: ",err_save))
	var path = get_node("Path").get_text()
	path = path.get_base_dir()
	
	RESOLUTION.x = DATA.originalResolution.width
	RESOLUTION.y = DATA.originalResolution.height
	if copy_atlas(path,TO_PATH) != OK:
		epopup("Failed to copy image packs!")
		return FAILED
	dprint("Importing images data from atlas...")
	ATLAS.import(TO_PATH)
	
	var scene = get_node("Scene")
	scene = scene.get_item_text( scene.get_selected() )
	import_scene(path,scene)

func check_project( path, check_all=true ): # TO DO5
	var f = File.new()
	var err = f.open(path,File.READ)
	if err != OK:
		dprint(str("Failed to open \"",path,"\" Error code: ",err," (at check_project())"))
		return FAILED
	var data = {}
	data.parse_json(f.get_as_text())
#	var pos = path.find_last("/")
	var project_path = path.get_base_dir()
	var file_name = path.get_file()
	dprint("")
	dprint(str("Project Path: \"",project_path,"\""))
	dprint(str("Checking \"",file_name,"\" for errors:"),1)
# project.dt
# 1| can read data?
	dprint(str("Can read as JSON?"),2)
	if !data.empty():
		dprint("OK",4)
	else:
		dprint("FAILED",4)
		dprint("Parser value: ",4)
		dprint(data)
		return FAILED
# 2| main keys
	var given_keys = data.keys()
	given_keys.sort()
	dprint(str("Main keys: ",given_keys),2)
	var keys_array = ["originalResolution","scenes","libraryItems"]
	var ok = true
	for key in keys_array:
		if given_keys.find(key) == -1:
			ok = false
			break
	if ok == true:
		dprint("OK?",4)
	else:
		dprint("FAILED",4)
		dprint("Required main keys: ",4)
		dprint(keys_array)
		return FAILED
# 3| at least 1 scene?
	dprint("Have at least 1 scene?",2)
	if data.scenes.size() > 0:
		dprint("OK",4)
	else:
		dprint("FAILED",4)
		return FAILED
# done project.dt
	dprint(str("\"",file_name,"\" seem to be fine."),1)
	
	dprint("BASIC JSON check complete. It might actually work!")
	
	DATA = data
	f.close()
	return OK


func import_scenes_list(): # TO DO5 add debug
	var list = []
	for scene in DATA.scenes:
		list.append(scene.sceneName)
	list.sort()
	var sc_select = get_node("Scene")
	sc_select.clear()
	for scene in list:
		sc_select.add_item(scene)
		sc_select.set_item_text(sc_select.get_item_count()-1,scene)
	dprint(str("Scenes list: ",list))
	return list

func data_has_scene(scene_name):
	if !DATA.has("scenes"):
		dprint("DATA doesn't contain main key \"scenes\"!")
		return false
	for scene in DATA.scenes:
		if scene.sceneName == scene_name:
			return true
	return false

func copy_atlas(from, to):
	dprint(str("Copying image packs \nfrom: \"",from+"/orig","\"\nto: \"",to,"\""))
	var path = from+"/orig/pack.atlas"
	dprint(str(ATLAS.get_packs(path)),1)
	var return_string = ATLAS.copy(path,to)
	dprint(str(return_string),2)
	
	if return_string.begins_with("OK"):
		return OK
	return FAILED
	
	
	

func import_scene( path, scene_name ): # TO DO2
	dprint(str("Importing scene \'",scene_name,"\'..."))
	if !data_has_scene(scene_name):
		dprint(str("FAILED. There's no \'",scene_name,"\' scene!"),2)
		# scene with that name doesn't exist
		return FAILED
	
# Open scene file
	var f = File.new()
	var sfile_path = path+"/scenes/"+scene_name+EXT
	var err = f.open(sfile_path,File.READ)
	if err != OK:
		epopup(str("Failed to open \"",sfile_path,"\"\n Error code: ",err," (at import_scene())"))
		return FAILED
	
	var sdata = {}
	sdata.parse_json(f.get_as_text())
	if check_scene_data( sdata ) != OK: # custom JSON checks
		epopup("Failed to load a scene. Check debug window for a clue.")
		return FAILED
	
	var scene = Node2D.new()
	scene.set_name(scene_name)
	var root = get_tree().get_edited_scene_root()
	root.add_child(scene) # TO DO3
	scene.set_owner(root)
	dprint("Created root (scene) node",1)
	var invert_x = get_node("InvertX").is_pressed()
	var invert_y = get_node("InvertY").is_pressed()
	if import_layers( scene, sdata ) != OK:
		epopup("Failed to load layers")
		return FAILED
	if import_scene_sprites( scene, sdata, invert_x, invert_y ) != OK:
		epopup("Failed to load scene's sprites. Check debug window for a clue.")
		return FAILED
	if import_scene_composites( scene, sdata, invert_x, invert_y ) != OK:
		epopup("Failed to load scene's composites. Check debug window for a clue.")
		return FAILED
	
	dprint("Importing scene done.")
	f.close()
	call("hide")
	return OK

func check_scene_data( sdata ): # TO DO3 add debugging
	return OK

func import_layers( scene, sdata ):
	dprint("Importing layers...",1)
	if !sdata.composite.has("layers") or sdata.composite.layers.size() == 0:
		return FAILED
	var owner = get_tree().get_edited_scene_root()
	for i in range(sdata.composite.layers.size()):
		var ldata = sdata.composite.layers[i]
		var layer = Node2D.new()
		layer.set_name( ldata.layerName )
		if ldata.isVisible == false:
			layer.hide()
		layer.set_z(1000*i)
		scene.add_child(layer)
		layer.set_owner(owner)
	dprint("Done.",2)
	return OK

func import_scene_sprites( scene, sdata, invert_x, invert_y ): # TO DO2 add textures
	dprint("Importing sprites...",1)
	if sdata.empty():
		dprint("FAILED. sdata is empty?!",3)
		return FAILED
	if !sdata.has("composite"):
		dprint("FAILED. sdata doesn't contain \"composite\" key",3)
		return FAILED
	if !sdata.composite.has("sImages"):
		dprint("No images data found.",2)
		dprint("Importing sprites done.",1)
		return OK
	dprint(str("Sprites count: ",sdata.composite.sImages.size()),1)
	
	for idata in sdata.composite.sImages:
		var sprite = Sprite.new()
		#sprite.set_centered(false)
		# name
		var uid = idata.uniqueId
		var iname = idata.imageName
		sprite.set_name(str(uid,"_",iname))
		
		load_item( sprite, idata, invert_x, invert_y )
		var layer = idata.layerName
		add_item( scene, sprite, layer )

		dprint(str("Created \'",iname,"\' (uid:",uid,")"),2)
	
	dprint("Importing sprites done.",1)
	return OK

func import_scene_composites( scene, sdata, invert_x, invert_y ):
	dprint("Importing composites...",1)
	sdata = sdata.composite
	if !sdata.has("sComposites") or sdata.sComposites.size() == 0:
		dprint("No composites found.",2)
		dprint("Importing composites done.",1)
		return OK
	var owner = get_tree().get_edited_scene_root()
	for cdata in sdata.sComposites:
		var composite = Node2D.new()
		var uid = cdata.uniqueId
		var name = ""
		if cdata.has("itemIdentifier"):
			name = cdata.itemIdentifier
		elif cdata.has("itemName"):
			name = cdata.itemName
		else:
			name = "NAME_NOT_FOUND"
		composite.set_name(str(uid,"_",name))
		load_item(composite, cdata, invert_x, invert_y,true )
		var layer = cdata.layerName
		add_item( scene, composite, layer )
		
		for idata in cdata.composite.sImages:
			var sprite = Sprite.new()
			sprite.set_name(str(idata.uniqueId,"_",idata.imageName))
			load_item(sprite,idata,invert_x,invert_y,false)
			composite.add_child(sprite)
			sprite.set_owner(owner)
		
		dprint(str("Created \'",name,"\' (uid:",uid,")"),2)
	
	dprint("Importing composites done.",1)
	return OK

func add_item( scene, item, layer ):
	var owner = get_tree().get_edited_scene_root()
	layer = scene.get_node(layer)
	if layer == null:
		dprint(str("Error: non-existing layer \"",layer,"\""))
	layer.add_child(item)
	item.set_owner(owner)

func load_item( item, idata, invert_x, invert_y, relative=false ):
	# pos
	var pos = Vector2(0,RESOLUTION.y)
	if idata.has("x"):
		if invert_x == false:
			pos.x = idata.x
		else:
			pos.x = -idata.x
			if !relative:
				pos.x += RESOLUTION.x
	if idata.has("y"):
		if invert_y == false:
			pos.y = idata.y
		else:
			pos.y = -idata.y
			if !relative:
				pos.y += RESOLUTION.y
	item.set_pos(pos)
	# scale
	var scale = Vector2(1,1)
	if idata.has("scaleX"):
		scale.x = idata.scaleX
	if idata.has("scaleY"):
		scale.y = idata.scaleY
	#scale *= 0.8
	item.set_scale(scale)
	# z
	#item.set_z_as_relative(false)
	if idata.has("zIndex"):
		item.set_z(idata.zIndex)
	# tags / groups
	if idata.has("tags"):
		for tag in idata.tags:
			item.add_to_group(tag)
	# Sprite
	if item extends Sprite:
		# origin?
		var offset = Vector2()
		if idata.has("originX"):
			if invert_x == false:
				offset.x = idata.originX
			else:
				offset.x = -idata.originX
		if idata.has("originY"):
			if invert_y == false:
				offset.y = idata.originY
			else:
				offset.y = -idata.originY
		item.set_offset(offset)
		# texture
		var iname = item.get_name()
		var c_pos = iname.find("_")+1
		iname = iname.substr(c_pos,iname.length()-c_pos+1)
		var tex_data = ATLAS.get_sprite_data(iname)
		var tex = tex_data.pack
		item.set_texture(tex)
		item.set_region(true)
		item.set_region_rect(tex_data.region)
	
	return item

func epopup( s ): # TO DO6
	s = str(s)
	dprint( s )

func dprint( s, spaces=0 ): # TO DO6
	s = str(s)
	spaces += 1
	spaces = max(0,spaces)
	for i in range(spaces):
		s = " "+s
	print("-OI-",s)


