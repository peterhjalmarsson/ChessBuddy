namespace eval player {
	variable player
	array set player {
		nick_0 		"guest"
		firstname_0 ""
		slastname_0 ""
		location_0 	""
	}
	variable pMenu
	variable playerList ""
	variable selected ""
	variable allPlayers ""
}

proc ::player::playerMenu { title {parentmodal false} {parent .}} {
	variable player
	variable selected
	variable allPlayers
	variable playerList
	set selected ""
	toplevel .pMenu
	wm title .pMenu "Player list"
	frame .pMenu.frame
	pack .pMenu.frame -fill both
	listbox .pMenu.frame.list -width 38 -height 20 -relief sunken \
			-listvariable ::player::playerList \
			-yscrollcommand ".pMenu.frame.scroll_y set" 
	grid .pMenu.frame.list -row 0 -column 0 -sticky news
	scrollbar .pMenu.frame.scroll_y -command ".pMenu.frame.list yview" -orient v
	grid .pMenu.frame.scroll_y -row 0 -column 1 -sticky ns
	frame .pMenu.buttonFrame -height 40 -relief raised
	pack .pMenu.buttonFrame -fill x
	button .pMenu.new -text " New  " -command {::player::playerNew .pMenu}
	pack .pMenu.new -in .pMenu.buttonFrame -side left -fill y 
	button .pMenu.edit -text " Edit " -command {
		::player::playerEdit [::player::findName] .pMenu
	}
	pack .pMenu.edit -in .pMenu.buttonFrame -after .pMenu.new -side left -fill y
	button .pMenu.delete -text "Delete" -command {
		set answer [tk_messageBox -message "Do you want to delete the player?" -type yesno -icon question]
		if {$answer eq "yes" } {
			foreach sel [::player::findName multiple] {
				set pos [lsearch $::player::playerList "$::player::player(name_$sel)"]
				set ::player::playerList [lreplace $::player::playerList $pos $pos]
				set pos [lsearch $::player::allPlayers "$sel"]
				set ::player::allPlayers [lreplace $::player::allPlayers $pos $pos]
				array unset ::player::player *_$sel	
			}
		}	
	}
	pack .pMenu.delete -in .pMenu.buttonFrame -after .pMenu.edit -side left -fill y
	button .pMenu.cancel -text "Cancel" -command { destroy .pMenu }
	pack .pMenu.cancel -in .pMenu.buttonFrame -after .pMenu.delete -side left -fill y 
	button .pMenu.ok -text "  Ok  " -command { 
		set ::player::selected [::player::findName]
		destroy .pMenu
	}
	pack .pMenu.ok -in .pMenu.buttonFrame -after .pMenu.cancel -side left -fill y 
	wm resizable .pMenu 0 0
	set playerList ""
	foreach id $::player::allPlayers {
		lappend playerList $player(nick_$id)	
	}
	set playerList [lsort -dictionary $playerList]
	if {$parentmodal} {renewModal $parent}
	saveSettings
	modalWindow .pMenu
}

proc ::player::findName {{sel "single"}} {
	variable player
	variable playerList
	set id ""
	foreach item [.pMenu.frame.list curselection] {
		set sel [.pMenu.frame.list get $item]
		foreach name [array names playerList nick_*] {
			if { $playerList($name) eq $sel } {
				lappend id [string range $name 5 end]
			}
		}
	}
	if { $sel eq "single" } { set id [lindex $id 0] }
	return $id
}

proc ::player::playerNew {parent} {
	variable playerList
	variable pMenu
	for {set id 0} {[lsearch $playerList $id] >=0} {incr id} {}
	foreach name {nick firstname lastname location} {
		set pMenu($name) ""
	}
	playerEditMenu "New player" $id $parent
}

proc ::player::playerEditMenu {title id parent} {
	variable player
	variable pMenu
	toplevel .pNew
	wm title .pNew "$title"
	frame .pNew.frame
	set pos 0
	foreach {txt name} {"Screen name" nick "First name" firstname "Last name" lastname "Location" location} {
		label .pNew.frame.label$name -text $txt
		grid .pNew.frame.label$name -row $pos -column 0 -sticky w
		entry .pNew.frame.entry$name -textvariable ::player::pMenu($name) \
				-width 40
		grid .pNew.frame.entry$name -row $pos -column 1 -sticky news
		incr pos
	}
	pack .pNew.frame
	frame .pNew.buttons
	button .pNew.buttons.cancel -text "Cancel" -command "destroy .pNew"
	pack .pNew.buttons.cancel -side left
	button .pNew.buttons.ok -text "  OK  " -command "::player::saveNew $id"
	pack .pNew.buttons.ok -side right
	pack .pNew.buttons
	modalWindow .pNew
	renewModal $parent
	array unset pMenu
}

proc ::player::saveNew {id} {
	variable pMenu
	variable player
	variable allPlayers
	variable playerList
	if { $pMenu(nick) eq "" } {
		.pNew.frame.entrynick configure -bg #FF8080
		return
	}
	foreach name {nick firstname lastname location} {
		set player($name\_$id) $pMenu($name)
	}
	lappend allPlayers $id
	lappend playerList $player(nick_$id)	
	destroy .pNew
}

proc ::player::playerEdit { id parent } {
	variable player
	variable playerList
	#id 0 reserved for guest
	if {$id == 0 } {return}
	foreach name {nick firstname lastname location} {
		set pMenu($name) $player($name)
	}
	playerEditMenu "Edit player" $id $parent
}
 
 proc ::player::saveSettings {} {
	variable player
	variable allPlayers
	#store in temp file, if program crashes it will not erase anything
	set file [open "./data/players.tmp" w]
	foreach id [lsort -integer $allPlayers] {
		#guest id, no need to store
		if {$id == 0} {continue}
		puts $file "# Player $id"
		foreach name [array names player *_$id] {
			puts $file "set player($name) \"$player($name)\""
		}
	}
	close $file
	#if file is empty don't save
	if {[file size "./data/players.tmp"] == 0 } {
		file delete "./data/players.tmp"
		return 
	}
	# safety copy
	if { [file exists "./data/players.dat"] && [file size "./data/players.dat"] > 0 } {
		file rename -force "./data/players.dat" "./data/players.bak"
	}
	file rename -force "./data/players.tmp" "./data/players.dat"
	writeLog "./data/players.dat saved."	
}

 
 proc ::player::loadSettings {} {
	variable player
	variable allPlayers
	if { [catch { source "./data/players.dat"} ] } {
		writeLog "Loading ./data/players.dat failed. Using backup ./data/players.bak"
		source "./data/players.bak"
	}
	foreach name [array names player nick_*] {
		lappend allPlayers [string range $name 5 end ]
	}
 }


