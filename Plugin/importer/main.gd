tool
extends FileDialog

var TO_PATH = "res://overlap_import"
var FROM_PATH
var EXT = ".dt"
var DATA = {}
var COMPOSITES = {}
var RESOLUTION = Vector2(800,600)
var SCENES = []
var ATLAS
var ROOT

func reset():
	TO_PATH = "res://overlap_import"
	FROM_PATH = ""
	EXT = ".dt"
	DATA = {}
	COMPOSITES = {}
	RESOLUTION = Vector2(800,600)
	SCENES = []

func _enter_tree():
	ROOT = get_tree().get_edited_scene_root()
	ATLAS = preload("atlas.gd").new()
	print("-OI- Overlap2D Projects Importer")
	print("-OI- User path check: ",Globals.globalize_path("user://"))
	print("-OI- Res path check: ",Globals.globalize_path("res://"))
	print("-OI- Script path: ",get_script().get_path())
	set_mode(FileDialog.MODE_OPEN_FILE)
	set_access(FileDialog.ACCESS_FILESYSTEM)
	add_filter("*"+EXT)
	#set_current_dir(custom_path)
	if !is_connected("file_selected",self,"_file_selected"):
		connect("file_selected",self,"_file_selected")
	set_pos(Vector2(100,100))
	set_size(Vector2(500,450))
	set_exclusive(true)

func _file_selected( path ): # TO DO4
	FROM_PATH = path.get_base_dir()
	if check_project( path ) != OK:
		epopup("Failed to import a project. Check debug window for a clue.")
		return
	
	if DATA.empty():
		epopup("DATA is empty?! (at _file_selected())")
		return
	
	import_project()# test

func check_project( path, check_all=true ): # TO DO5
	var f = File.new()
	var err = f.open(path,File.READ)
	if err != OK:
		dprint(str("Failed to open \"",path,"\" Error code: ",err," (at check_project())"))
		return FAILED
	var data = {}
	data.parse_json(f.get_as_text())
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
	SCENES = list
	dprint(str("Scenes list: ",list))

func data_has_scene(scene_name):
	for scene in DATA.scenes:
		if scene.sceneName == scene_name:
			return true
	return false

func import_project(): # TO DO3 add debug
	RESOLUTION.x = DATA.originalResolution.width
	RESOLUTION.y = DATA.originalResolution.height
	if copy_atlas(FROM_PATH,TO_PATH) != OK:
		epopup("Failed to copy image packs!")
		return FAILED
	dprint("Importing images data from atlas...")
	ATLAS.import(TO_PATH)
	dprint("Importing scenes list...")
	import_scenes_list()
	import_scene(SCENES[0]) # TO DO add choice option
	return OK

func copy_atlas(from, to):
	dprint(str("Copying image packs \nfrom: \"",from+"/orig","\"\nto: \"",to,"\""))
	var path = from+"/orig/pack.atlas"
	dprint(str(ATLAS.get_packs(path)),1)
	var return_string = ATLAS.copy(path,to)
	dprint(str(return_string),2)
	
	if return_string.begins_with("OK"):
		return OK
	return FAILED
	
	
	

func import_scene( scene_name ): # TO DO2
	dprint(str("Importing scene \'",scene_name,"\'..."))
	if !DATA.has("scenes"):
		dprint("FAILED. DATA doesn't contain main key \"scenes\"",2)
		# This error SHOULD never popup
		return FAILED
	if !data_has_scene(scene_name):
		dprint(str("FAILED. There's no \'",scene_name,"\' scene!"),2)
		# scene with that name doesn't exist
		return FAILED
	
# Open scene file
	var f = File.new()
	var sfile_path = FROM_PATH+"/scenes/"+scene_name+EXT
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
	if import_scene_sprites( scene, sdata, root ) != OK:
		epopup("Failed to load a scene's sprites. Check debug window for a clue.")
		return FAILED
	
	dprint("Importing scene done.")
	f.close()
	return OK

func check_scene_data( sdata ): # TO DO3 add debugging
	return OK

func import_scene_sprites( scene, sdata, owner ): # TO DO2 add textures
	dprint("Importing sprites...",1)
	if sdata.empty():
		dprint("FAILED. sdata is empty?!",3)
		return FAILED
	if !sdata.has("composite"):
		dprint("FAILED. sdata doesn't contain \"composite\" key",3)
		return FAILED
	if !sdata.composite.has("sImages"):
		dprint("FAILED. sdata doesn't contain \"sImages\" key",3)
		return FAILED
	dprint(str("Sprites count: ",sdata.composite.sImages.size()),1)
	
	for idata in sdata.composite.sImages:
		var sprite = Sprite.new()
		#sprite.set_centered(false)
		# name
		var uid = idata.uniqueId
		var iname = idata.imageName
		sprite.set_name(str(uid,"_",iname))
		# pos
		var pos = Vector2(0,RESOLUTION.y)
		if idata.has("x"):
			pos.x = idata.x
		if idata.has("y"):
			pos.y = RESOLUTION.y - idata.y
		sprite.set_pos(pos)
		# origin?
		var offset = Vector2()
		if idata.has("originX"):
			offset.x = idata.originX
		if idata.has("originY"):
			offset.y = -idata.originY
		sprite.set_offset(offset)
		# scale
		var scale = Vector2(1,1)
		if idata.has("scaleX"):
			scale.x = idata.scaleX
		if idata.has("scaleY"):
			scale.y = idata.scaleY
		scale *= 0.8
		sprite.set_scale(scale)
		# z
		#sprite.set_z_as_relative(false)
		if idata.has("zIndex"):
			sprite.set_z(-idata.zIndex)
		# tags / groups
		if idata.has("tags"):
			for tag in idata.tags:
				sprite.add_to_group(tag)
		# add texture
		var tex_data = ATLAS.get_sprite_data(iname)
		var tex = tex_data.pack
		sprite.set_texture(tex)
		sprite.set_region(true)
		sprite.set_region_rect(tex_data.region)
		
		# layers
		var lay = idata.layerName
		if !scene.has_node(lay):
			var new_lay = Node2D.new()
			new_lay.set_name(lay)
			scene.add_child(new_lay)
			new_lay.set_owner(owner)
		# add to correct layer
		lay = scene.get_node(lay)
		lay.add_child(sprite)
		sprite.set_owner(owner)
		dprint(str("Created \'",iname,"\' (uid:",uid,")"),2)
	
	dprint("Importing sprites done.",1)
	return OK

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


