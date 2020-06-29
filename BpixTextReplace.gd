extends MarginContainer
#A simple string splitter script that rapidly collects image links from the source of a Bpix album page.
#Written by The Flying Twybil

var update_textedit : TextEdit
var links_textedit : TextEdit
var result_textedit : TextEdit

var tagtype_optionbutton : OptionButton
var numericsafety_button : CheckButton
#var exclude_textedit : TextEdit

var delim

var hyperlink_header : String = "https://bpix.lpbeach.co.uk/"

# Called when the node enters the scene tree for the first time.
func _ready():
	update_textedit = get_node("HBoxContainer/VBoxContainer/txtentry/VBoxContainer/UpdateEntry")
	links_textedit = get_node("HBoxContainer/VBoxContainer/txtlinks/VBoxContainer/LinkList")
	result_textedit = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/txtResult/MarginContainer/VBoxContainer/Result")
	
	tagtype_optionbutton = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer2/vbox/MarginContainer2/OptionButton")
	numericsafety_button = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/NumericSafetyButton")
	#exclude_textedit = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/VBoxContainer/TextEdit")
	
	#var string1 = "#001"
	#var string2 = "#001 #002"
	
	#print(string1.split("#"))
	#print(string2.split("#"))
	
	pass

#https://bpix.lpbeach.co.uk/_data/i/upload/2020/06/26/20200626211719-21a21aba-xs.jpg

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#This populates the text edit with the 
func resolve_delim():
	var option = tagtype_optionbutton.selected
	
	if option == -1:
		return false
	elif option == 1:
		return "#"
	elif option == 2:
		return "[IMG"
	else:
		return false


#func generate_excluded_numbers():
#	
#	pass

#This calculates based on the found number of image tags and their value which images are missing in the sequence
#Thus it can space out the actual Tag->link list to acommodate.

func fix_img_bbcode_tags(link : String):
	
	link = link.to_lower()
		
	var add_front : bool = false
	var add_back : bool = false
	
	if not link.ends_with("[/img]"):
		var split = link.rsplit("[", true, 1)
		if split.size() == 2:
			link = split[0]
			add_back = true
		else:
			add_back = true
	
	if not link.begins_with("[img]"):
		var split = link.split("]", true, 1)
		
		if split.size() == 2:
			link = split[1]
			add_front = true
		else:
			add_front = true
	
	if add_back:
		link = link + "[/img]"
	if add_front:
		link = "[img]" + link
	
	return link


#NOTE: At the moment, images that are on the same line must be separated by a space. 
func form_exclude_list():
	var text : String = update_textedit.text
	var located_number_arr : Array
	#located_number_arr.resize(300)
	
	var result_dict : Dictionary
	
	var first_split = text.split("\n")
	
	for split in first_split:
		var second_split = split.split(" ")
		#breakpoint
		for split_two in second_split:	
			if split_two.begins_with(delim):
				#it's a valid tag number
				var num = int(split_two)
				#Automatically expand the array to fit, though leave some extra room as a hack
				if num > located_number_arr.size() - 1:
					located_number_arr.resize(num + 1)
				located_number_arr[num] = "Valid"
		
	var i : int = 0
	if located_number_arr.size() > 0:
		for value in located_number_arr: #Go through the list and make a cleaner dictionary.
			if located_number_arr[i] == null:
				result_dict[i] = "Invalid"
			else:
				result_dict[i] = located_number_arr[i]
				
			i = i + 1
		
		return result_dict
	pass

func form_link_list(excl_list : Dictionary):
	var text : String = links_textedit.text
	
	if text and text != "":
		
		var split : Array = text.split("\n")
		#split.push_front(null) #this spaces it out to index on 1, not 0
		
		var dict : Dictionary
		var i : int = 0 #This is the iterator through the link list
		var excl_idx : int = 1 #this is the iterator through the exclude list
		#var excl_max : int
		
		if excl_list:
			#excl_max = excl_list.size() + 1
			#while excl_idx <= excl_max:
			#	if excl_list[excl_idx] == "Valid":
			#		dict[i] = fix_img_bbcode_tags(split[i])
			#		i = i + 1
			#	else:
			#		print("Found invalid or link == null")
			#	excl_idx = excl_idx + 1
			
			for val in excl_list:
				if i < split.size():
					var link = split[i]
					print(excl_idx)
					if excl_list.has(excl_idx) and excl_list[excl_idx] == "Valid":
						print(link)
						dict[excl_idx] = fix_img_bbcode_tags(link)
						i = i + 1
					else:
						print("Found invalid")
					excl_idx = excl_idx + 1
				
	
		#	for link in split:
		#		print(excl_idx)
		#		if excl_list[excl_idx] == "Valid":
		#			print(link)
		#			dict[i] = fix_img_bbcode_tags(link)
		#			i = i + 1
		#		else:
		#			print("Found invalid")
		#		excl_idx = excl_idx + 1
		
		else:
			for link in split:
				i = i + 1
				if link:
					dict[i] = fix_img_bbcode_tags(link)
		
		return dict
	
	else:
		return
	
	pass

func replace_text(link_list : Dictionary):
	#So now, with the exclude list and link list made, the link list should have its keys correspond to all
	#of the image tags only. Now we just do a quick replace.
	var finaltext : String = ""
	
	var text = update_textedit.text
	var first_split = text.split("\n")
	#First we split on newline to read the document line by line
	for line in first_split:
		var second_split = line.split(" ")
		#We do this to separate each word
		for word in second_split:
			print(word)
			if word.find(delim) != -1 and link_list.has(int(word)):
				#Extra safety check, just in case portraits have numbers in them:
				if numericsafety_button.pressed == true and word.split(delim)[1].is_valid_integer():
					finaltext = finaltext + link_list[int(word)] + " "
				elif numericsafety_button.pressed == true:
					pass #Alternate check to prevent the below from going through regardless
				else:
					finaltext = finaltext + link_list[int(word)] + " "
				#breakpoint
				#This replaces the tag with the assigned link from the list
			else:
				finaltext = finaltext + word + " " #We have to replace the spacing anyways
				#Support for non spaced pictures may come someday, but will involve a tertiary split
				#and accounting for that
		#Now that we've properly rebuilt the line, here's our newline to restore that
		#and cut off that trailing space
		var split = finaltext.rsplit(" ", true, 1)
		finaltext = split[0] + "\n"
		
	return finaltext
	pass


func _on_ReplaceButton_pressed():
	
	#var txt = "#034_e"
	#The below returns false; useful for inline photos maybe?
	#if txt.is_valid_integer():
	#	print(int("#034_e"))
	#	pass
	
	
	if update_textedit.text and update_textedit.text != null:
		var text : String = update_textedit.text
		
		delim = resolve_delim()
		
		var exclude_list : Dictionary = form_exclude_list()
		#breakpoint
		var link_list : Dictionary = form_link_list(exclude_list)
		#breakpoint
		result_textedit.text = replace_text(link_list)
		
	pass


func _on_CopyButton_pressed():
	OS.clipboard = result_textedit.text
	pass


func _on_ClearButton_pressed():
	update_textedit.text = ""
	links_textedit.text = ""
	result_textedit.text = ""
	pass # Replace with function body.
