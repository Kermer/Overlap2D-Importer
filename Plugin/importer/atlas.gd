tool

# "name":{"pack":"path_to_png","region":Rect2()}
var SPRITES = {}

func get_sprite_data( sname ):
	if SPRITES.has(sname):
		return SPRITES[sname]
	else:
		return null

func reset():
	SPRITES = {}

func import( path ):
	var f = File.new()
	f.open(path+"/pack.atlas",File.READ)
	var data = f.get_as_text()
	var pos = 0
	var loaded_packs = {}
	while(data.findn(".png",pos) != -1):
		var epos = data.findn(".png",pos)
		var spos = data.rfindn("\n",epos)+1
		var pack = data.substr(spos,epos-spos)+".png"
		#print(pack)
		pack = load( Globals.localize_path(path+"/"+pack) )
		pos = epos+2
		var next_pos = data.findn(".png",pos+4)
		while(data.findn("  rot",pos) != -1):
			if next_pos != -1 and data.findn(".png",pos) != next_pos: # check if we haven't passed another pack
				pos = data.rfindn(".png",pos)-2
				break
			epos = data.findn("  rot",pos)-1
			spos = data.rfindn("\n",epos-2)+1
			var sname = data.substr(spos,epos-spos)
			
			spos = data.findn("  xy",epos)+6
			epos = data.findn("\n",spos)
			var xy = data.substr(spos,epos-spos)
			xy = xy.split(", ")
			xy = Vector2(xy[0],xy[1])
			
			spos = data.findn("  size",epos)+8
			epos = data.findn("\n",spos)
			var size = data.substr(spos,epos-spos)
			size = size.split(", ")
			size = Vector2(size[0],size[1])
			
			var reg = Rect2(xy, size)
			SPRITES[sname] = {"pack":pack,"region":reg}
			#print(sname,": ",pack," | ",reg)
			
			pos = epos+1
	
#	print(SPRITES.keys())
	return OK



func get_packs( path ): # TO DO debugging/protection
	var f = File.new()
	f.open(path,File.READ)
	var data = f.get_as_text()
	var packs = []
	var pos = 0
	while(data.findn(".png",pos) != -1):
		var epos = data.findn(".png",pos)
		var spos = data.rfindn("\n",epos)+1
		var pack = data.substr(spos,epos-spos)
		packs.append(pack)
		pos = epos+2
	f.close()
	return packs

func copy( from, to ): # might not work (unsure if Directory works properly atm.)
	var packs = get_packs( from )
	var d = Directory.new()
	d.make_dir_recursive(to)
	d.copy(from,to+"/pack.atlas")
	from = from.get_base_dir()
	for pack in packs:
		var pack_path = from+"/"+pack+".png"
		if !d.file_exists(pack_path):
			return "FAILED. Missing file \""+pack_path+"\""
		var dest_path = to+"/"+pack+".png"
		d.copy(pack_path,dest_path)
	return "OK?"
