extends MarginContainer
#A simple string splitter script that rapidly collects image links from the source of a Bpix album page.
#Written by The Flying Twybil

var update_textedit : TextEdit
var links_textedit : TextEdit
var result_textedit : TextEdit

var tagtype_optionbutton : OptionButton
var tagtype_extraidentifier : TextEdit

var numericsafety_button : CheckButton
var sequentialtags_button : CheckButton
#var exclude_textedit : TextEdit

var delim

var hyperlink_header : String = "https://bpix.lpbeach.co.uk/"

# Called when the node enters the scene tree for the first time.
func _ready():
	update_textedit = get_node("HBoxContainer/VBoxContainer/txtentry/VBoxContainer/UpdateEntry")
	links_textedit = get_node("HBoxContainer/VBoxContainer/txtlinks/VBoxContainer/LinkList")
	result_textedit = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/txtResult/MarginContainer/VBoxContainer/Result")
	
	tagtype_optionbutton = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer2/vbox/MarginContainer2/OptionButton")
	tagtype_extraidentifier = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer2/vbox/MarginContainer/HBoxContainer/IdentifierBox")
	
	numericsafety_button = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer/NumericSafetyButton")
	sequentialtags_button = get_node("HBoxContainer/MarginContainer2/VBoxContainer2/MarginContainer4/SequentialButton")
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
	elif option == 3:
		return "[" + tagtype_extraidentifier.text + "."
	else:
		return false


#func generate_excluded_numbers():
#	
#	pass

#This calculates based on the found number of image tags and their value which images are missing in the sequence
#Thus it can space out the actual Tag->link list to acommodate.

func fix_https_address(link : String):
	link = link.to_lower()
	
	if link.begins_with(hyperlink_header + "upload"):
		#The link should be fine, so we leave doing this
		return link
	
	#Proper Structure: https://bpix.lpbeach.co.uk/upload/2020/06/30/20200630033119-f86c2a40.jpg
	#Bad Structure: https://bpix.lpbeach.co.uk/_data/i/upload/2020/06/30/20200630033746-f86c2a40-xs.jpg
	#Alt Bad Structure; https://bpix.lpbeach.co.uk/i.php?/upload/2020/06/30/20200630033931-4ed5fc27-xs.jpg
	
	#Removes filepath and saves it for the end
	var presplit = link.rsplit(",", false, 1)
	if presplit.size() > 1:
		#if we did remove the filepath
		link = presplit[1]
	
	
	var split = link.split("/_data/i/", true, 1)
	
	if split.size() == 1:
		split = link.split("/i.php?/", true, 1)
	
	var second_split = split[1].rsplit(".", true, 1)
	
	#Take the semi-correct right side and get the proper image type
	var img_type : String = "." + second_split[1].split("[", true, 1)[0]
	
	#Now rip off that damn thumbnail tag
	var third_split = second_split[0].rsplit("-", true, 1)
	
	if presplit.size() > 1:
		link = presplit[0] + "," + hyperlink_header + third_split[0] + img_type 
	else:
		link = hyperlink_header + third_split[0] + img_type
	return link


func fix_img_bbcode_tags(link : String):
	
	link = link.to_lower()
	
	#link = fix_https_address(link)
	
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
				#if num >= located_number_arr.size() - 1:
				located_number_arr.resize(num + 1)
				located_number_arr[num] = "Valid"
		
	var i : int = 0
	
	var debug_invalid_count : int = 0
	
	if located_number_arr.size() > 0:
		for value in located_number_arr: #Go through the list and make a cleaner dictionary.
			if located_number_arr[i] == null:
				debug_invalid_count = debug_invalid_count + 1
				result_dict[i] = "Invalid"
			else:
				result_dict[i] = located_number_arr[i]
				
			i = i + 1
		
		print(debug_invalid_count)
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
			#breakpoint
			for val in excl_list:
				if i < split.size() and excl_idx <= excl_list.size():
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

func form_link_list_new():
	var text : String = links_textedit.text
	#Sample: C:\projects\BPixUploader\TestData\002.jpg,https://bpix.lpbeach.co.uk/upload/1592-f0b77467.jpg
	#1. Separate each link from one another
	#2. Separate the image name from the link per link
	#2-a. Add bbcode tags to image if needed, save as linkvar
	#3. Separate tag from both its image name and file location 
	
	if text and text != "":
		var dict : Dictionary
		var split_one : Array = text.split("\n", false)
		
		var backslash_str : String = "\n"
		backslash_str = backslash_str.split("n", false, 1)[0]
		
		for linkset in split_one:
			var link : String
			var tag : String
			
			var split_two = linkset.split(",", false, 1)
			if split_two.size() != 2:
				print("Split Two missing comma delimiter. Not a BPIX link?")
				return false
			link = fix_img_bbcode_tags(split_two[1])
			
			var split_three = split_two[0].rsplit(backslash_str, false, 1)
			#breakpoint
			if split_three.size() != 2:
				print("Split Three too small! Not an actual filepath? Faking it anyways...")
				#It's not a real filepath in this case, so we'll just fake it
				#by duplicating to the expected result
				split_three.append(split_three[0])
				#return false
			
			#We rsplit here because some methods use . in the filename
			var split_four = split_three[1].rsplit(".", false, 1)
			
			#Now we need finalize the tag based on the chosen tag style:
			if tagtype_optionbutton.selected == 1:
				tag = delim + split_four[0].split("-", false, 1)[0]
			elif tagtype_optionbutton.selected == 2:
				pass
			elif tagtype_optionbutton.selected == 3:
				#Bracket Tagging - [Filename]
				#Since we're brute force replacing anyhow, most of the work in this
				#style is just adding the bracket delimiters.
				tag =  "[" + split_three[0] + "]"
				pass
			
			#breakpoint
			dict[tag] = link
			
		return dict
		pass
		
	else:
		return false
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
			#print(word)
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

func replace_text_new(link_list : Dictionary):
	var final_text : String = ""
	
	var text = update_textedit.text #we've already done a safety check on this in OnReplaceButton, no need for another
	var first_split = text.split("\n")
	#First we split on newline to read the document line by line
	for line in first_split:
		for key in link_list:
			#breakpoint
			print(line.findn(key))
			if line.findn(key) != -1:
				#breakpoint
				line = line.replacen(key, link_list[key])
				#breakpoint
		
		final_text = final_text + line + "\n"
		
	
	#Should be all that's necessary, though it may be intensive.
	return final_text
	pass

func _on_ReplaceButton_pressed():
	
	#var txt = "#034_e"
	#The below returns false; useful for inline photos maybe?
	#if txt.is_valid_integer():
	#	print(int("#034_e"))
	#	pass
	
	
	if update_textedit.text and update_textedit.text != null and tagtype_optionbutton.selected != -1:
		var text : String = update_textedit.text
		
		delim = resolve_delim()
		
		if sequentialtags_button.pressed:
			var exclude_list : Dictionary = form_exclude_list()
			#breakpoint
			var link_list : Dictionary = form_link_list(exclude_list)
			#breakpoint
			result_textedit.text = replace_text(link_list)
		
		else:
			var link_list = form_link_list_new()
			print(link_list)
			if link_list:
				result_textedit.text = replace_text_new(link_list)
		
	pass


func _on_CopyButton_pressed():
	OS.clipboard = result_textedit.text
	pass


func _on_ClearButton_pressed():
	update_textedit.text = ""
	links_textedit.text = ""
	result_textedit.text = ""
	pass # Replace with function body.


func _on_FixLinksButton_pressed():
	
	if links_textedit.text and links_textedit.text != "":
		var newtext : String
		var split = links_textedit.text.split("\n")
		
		for link in split:
			var txt = fix_https_address(link)
			newtext = newtext + txt + "\n"
			
		links_textedit.text = newtext
		
	pass # Replace with function body.
