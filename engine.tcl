namespace eval ::engine {
	variable settings 
	array set settings {
		boardsize 160
	}
	variable clr
	array set clr {
		active ""
		0	#FF8800
		1	#FF0000
		2	#0000FF
		3	#00CC00
	}
	variable selectedEngine ""
	variable engineMenu
	array set engineMenu {}
	variable allEngines [list ]
	variable activeEngines [list ]
	variable engineButton
	array set engineButton {}
	variable showComments true
	variable engineList
	array set engineList {
	}
	variable BasicOptions [list command wine protocol spawn alias]
	variable options 
	#these options are used for both uci and xboard
	#although some of them are only used in one protocol
	array set options {
		hash 			128
		ponder 			false
		ownBook 		false
		multiPv 		1
		nalimovPath 	"/home/peter/chess/tb/nalimov/"
		nalimovCache 	"32"
		threads 		1
	}
}

proc ::engine::engineOption {{parent ""}} {
	toplevel .eOpt
	wm title .eOpt "Engine options"
	frame .eOpt.main
	for {set i 0} {$i < 4} {incr i} {
		button .eOpt.main.arrowbttn$i -text "Color arrow $i" \
				-command "::engine::arrowColor $i" \
				-bg $::engine::clr($i) -fg [contrastColor $::engine::clr($i)]
		grid .eOpt.main.arrowbttn$i -row $i -column 0
	}
	button .eOpt.main.ok -text "  OK  " -command "destroy .eOpt"
	grid .eOpt.main.ok -row 4 -column 0
	pack .eOpt.main
	modalWindow .eOpt $parent
}

proc ::engine::arrowColor { i } {
	variable clr
	set col [tk_chooseColor -initialcolor $::engine::clr($i)]
	if {$col ne ""} { set clr($i) $col}
	.eOpt.main.arrowbttn$i configure -bg $col -fg [contrastColor $col]
}

proc ::engine::engineMenu { title { parentmodal false } {parent .}} {
	variable engineList
	variable engineMenu
	variable selectedEngine
	set selectedEngine ""
	toplevel .eMenu
	wm title .eMenu $title
	frame .eMenu.frame
	pack .eMenu.frame -fill both
	listbox .eMenu.frame.list -width 38 -height 20 -relief sunken \
			-listvariable ::engine::engineMenu(list) \
			-yscrollcommand ".eMenu.frame.scroll_y set" 
	grid .eMenu.frame.list -row 0 -column 0 -sticky news
	scrollbar .eMenu.frame.scroll_y -command ".eMenu.frame.list yview" -orient v
	grid .eMenu.frame.scroll_y -row 0 -column 1 -sticky ns
	frame .eMenu.buttonFrame -height 40 -relief raised
	pack .eMenu.buttonFrame -fill x
	button .eMenu.new -text " New  " -command "::engine::engineNew .eMenu"
	pack .eMenu.new -in .eMenu.buttonFrame -side left -fill y 
	button .eMenu.edit -text " Edit " -command {
		::engine::engineEdit [::engine::findAlias] .eMenu
	}
	pack .eMenu.edit -in .eMenu.buttonFrame -after .eMenu.new -side left -fill y
	button .eMenu.delete -text "Delete" -command {
		foreach sel [::engine::findAlias multiple] {
			set answer [tk_messageBox -message \
					"Do you really want to delete $::engine::engineList(alias_$sel)?"\
					-type yesno -icon question]
			if {$answer eq "yes" } {
				set pos [lsearch $::engine::engineMenu(list) "$::engine::engineList(alias_$sel)"]
				set ::engine::engineMenu(list) [lreplace $::engine::engineMenu(list) $pos $pos]
				set pos [lsearch $::engine::allEngines "$sel"]
				set ::engine::allEngines [lreplace $::engine::allEngines $pos $pos]
				array unset ::engine::engineList *_$sel	
			}
		}	
	}
	pack .eMenu.delete -in .eMenu.buttonFrame -after .eMenu.edit -side left -fill y
	button .eMenu.cancel -text "Cancel" -command { destroy .eMenu }
	pack .eMenu.cancel -in .eMenu.buttonFrame -after .eMenu.delete -side left -fill y 
	button .eMenu.ok -text "  Ok  " -command { 
		set ::engine::selectedEngine [::engine::findAlias]
		destroy .eMenu
	}
	pack .eMenu.ok -in .eMenu.buttonFrame -after .eMenu.cancel -side left -fill y 
	wm resizable .eMenu 0 0
	set engineMenu(list) ""
	foreach id $::engine::allEngines {
		lappend engineMenu(list) $engineList(alias_$id)	
	}
	set engineMenu(list) [lsort -dictionary $engineMenu(list)]
	modalWindow .eMenu
	if {$parentmodal} {renewModal $parent}
	array unset engineMenu 
	#saveSettings
	return $selectedEngine
}

proc ::engine::findAlias { { sel "single" } } {
	variable engineList
	set id ""
	foreach item [.eMenu.frame.list curselection] {
		set alias [.eMenu.frame.list get $item]
		foreach name [array names ::engine::engineList alias_*] {
			if { $engineList($name) eq $alias } {
				set eng [string replace $name 0 5]
				if { [array get engineList pipe_$eng] eq "" \
				|| $engineList(pipe_$eng) eq "" } {
					lappend id $eng
				} else {
					 puts [llength [.eMenu.frame.list curselection]]
					 if {[llength [.eMenu.frame.list curselection]] == 1} {
						 tk_messageBox -message \
								"$::engine::engineList(alias_$eng) is active.\
								Close the engine first." -type ok 
					 }
					 .eMenu.frame.list select clear $item $item
				}
			}
		}
	}
	if { $sel eq "single" } { set id [lindex $id 0] }
	return $id
}

proc ::engine::engineEdit { id {parent "."}} {
	variable engineList
	variable engineMenu
	if { $id eq "" } { return }
	toplevel .eEdit
	wm title .eEdit $engineList(alias_$id)
	#load all settings
	if {[array get engineList pipe_$id] eq ""} {
		start $id eEdit
		quit $id
	}
	frame .eEdit.mainFrame
	foreach {name row column var} { Alias 0 0 alias \
			Parameters 0 3 param Directory 1 0 dir Picture 1 3 pic} {
		label .eEdit.mainFrame.label$name -text $name
		grid .eEdit.mainFrame.label$name -row $row -column $column 
		entry .eEdit.mainFrame.entry$name -width 20 -textvariable ::engine::engineList($var\_$id)
		set engineMenu(new$name) ""
		grid .eEdit.mainFrame.entry$name -row $row -column [expr 1+$column]
	}
	label .eEdit.mainFrame.labelelo -text Elo
	grid .eEdit.mainFrame.labelelo -row 2 -column 0
	spinbox .eEdit.mainFrame.elo -width 15 -from 0 -to 4000 \
			-textvariable ::engine::engineList(elo_$id)
	grid .eEdit.mainFrame.elo -row 2 -column 1
	#radiobutton .eEdit.uci -value "uci" -text "UCI" -variable ::engine::engineList(protocol_$id)
	#grid .eEdit.uci -in .eEdit.mainFrame -row 3 -column 1
	#radiobutton .eEdit.xboard -value "xboard" -text "Xboard" -variable ::engine::engineList(protocol_$id)
	#grid .eEdit.xboard -in .eEdit.mainFrame -row 3 -column 2
	#checkbutton .eEdit.wine -offvalue "false" -onvalue "true" -text "WINE" -variable ::engine::engineList(wine_$id)
	#grid .eEdit.wine -in .eEdit.mainFrame -row 3 -column 3
	button .eEdit.mainFrame.picb -text "..." -command "::engine::choosePicture $id"
	grid .eEdit.mainFrame.picb  -row 1 -column 5
	button .eEdit.mainFrame.dir -text "dir" -command "::engine::chooseDir $id"
	grid .eEdit.mainFrame.dir -row 1 -column 2
	::engine::$engineList(protocol_$id)::optionMenu $id eEdit mainFrame 5
	pack .eEdit.mainFrame
	frame .eEdit.buttonFrame -height 40
	pack .eEdit.buttonFrame
	button .eEdit.ok -text "   OK   " -command { destroy .eEdit }
	pack .eEdit.ok -in .eEdit.buttonFrame -fill y
	writeLog "engine edit menu created"
	modalWindow .eEdit $parent
	renewModal $parent
	foreach opt [array names options] {
		if {$options($opt) ne ""} {continue}
		if { [array get ::engine::$engineList(protocol_$id)]::$engineList(protocol_$id)]Settings $opt] eq ""} {continue}
		set std $::engine::$engineList(protocol_$id)]::$engineList(protocol_$id)]Settings($opt)
		if { [array get engineList $std\_$id] ne "" && [array get engineMenu $std\_$id] ne ""} {
			set engineList($std\_$id) [lreplace $engineList($std\_$id) 2 2 $engineMenu($std\_$id)]
			array unset engineMenu $std\_$id
		}
	}
	foreach opt [array names engineMenu option_*] {
		if { [llength $engineList($opt)] > 2 } {
			set engineList($opt) [lreplace $engineList($opt) 2 2 $engineMenu($opt)]
			array unset engineMenu $opt
		}
	}
	if {$engineList(pipe_$id) ne ""} {
		::engine::$engineList(protocol_$id)::sendOption $id
	}
}

proc ::engine::chooseCommand { id } {
	variable engineList
	set engineList(command_$id) [tk_getOpenFile -initialdir [getConfig enginenew .]]
	setConfig enginenew [file dirname $engineList(command_$id)]
}

proc ::engine::choosePicture { id } {
	variable engineList
	set engineList(pic_$id) [tk_getOpenFile -initialdir [getConfig enginenew .]]
	setConfig enginenew [file dirname $engineList(pic_$id)]
}

proc ::engine::chooseDir { id } {
	variable engineList
	set engineList(dir_$id) [tk_chooseDirectory -initialdir [getConfig enginenew .]]
	setConfig enginenew [$engineList(dir_$id)
}

proc ::engine::engineNew {{parent "."}} {
	variable engineList
	variable engineMenu
	variable allEngines
	toplevel .eNew
	wm title .eNew "New engine"
	frame .eNew.mainFrame
	pack .eNew.mainFrame
	set row 1
	foreach name { Alias Command Parameters Directory Picture} {
		label .eNew.mainFrame.label$name -text $name
		grid .eNew.mainFrame.label$name -row $row -column 0 
		entry .eNew.mainFrame.entry$name -width 20 -textvariable ::engine::engineMenu(new$name)
		set engineMenu(new$name) ""
		grid .eNew.mainFrame.entry$name -row $row -column 1
		incr row
	}
	set engineMenu(newElo) 0
	label .eNew.mainFrame.labelelo -text Elo
	grid .eNew.mainFrame.labelelo -row 6 -column 0
	spinbox .eNew.mainFrame.elo -width 4 -from 0 -to 4000 \
			-textvariable ::engine::engineMenu(newElo)
	grid .eNew.mainFrame.elo -row 6 -column 1 -sticky e
	set engineMenu(newProtocol) "uci"
	radiobutton .eNew.mainFrame.uci -value "uci" -text "UCI" -variable ::engine::engineMenu(newProtocol)
	grid .eNew.mainFrame.uci -row 7 -column 0
	radiobutton .eNew.mainFrame.xboard -value "xboard" -text "Xboard" -variable ::engine::engineMenu(newProtocol)
	grid .eNew.mainFrame.xboard -row 7 -column 1
	checkbutton .eNew.mainFrame.wine -offvalue "false" -onvalue "true" -text "WINE" -variable ::engine::engineMenu(newWine)
	grid .eNew.mainFrame.wine -row 8 -column 0
	button .eNew.mainFrame.cmd -text "cmd" -command { 
		set ::engine::engineMenu(newCommand) [tk_getOpenFile -initialdir [getConfig enginenew .]]
		setConfig enginenew [file dirname $::engine::engineMenu(newCommand)]
	}
	grid .eNew.mainFrame.cmd -row 2 -column 2
	button .eNew.mainFrame.dir -text "dir" -command { 
		set ::engine::engineMenu(newDirectory) [tk_chooseDirectory -initialdir [getConfig enginenew .]] 
		setConfig enginenew $::engine::engineMenu(newDirectory)
	}
	grid .eNew.mainFrame.dir -row 4 -column 2
	button .eNew.mainFrame.pic -text "..." -command { 
		set ::engine::engineMenu(newPicture) [tk_getOpenFile -initialdir [getConfig enginenew .]] 
		setConfig enginenew [file dirname $::engine::engineMenu(newPicture)]
	}
	grid .eNew.mainFrame.pic -row 5 -column 2
	frame .eNew.buttonFrame -height 40 -relief raised
	pack .eNew.buttonFrame
	button .eNew.buttonFrame.cancel -text "Cancel" -command { destroy .eNew }
	pack .eNew.buttonFrame.cancel -side left -fill y 
	button .eNew.buttonFrame.ok -text "  Ok  " -command {
		if { $::engine::engineMenu(newCommand) eq "" } {
			.eNew.entryCommand configure -bg #FF8080
			return
		}
		#find new id
		set id 0 
		while { [lsearch $::engine::allEngines $id] != -1 } { incr id }
		if { $::engine::engineMenu(newDirectory) eq "" } {
			regexp -all (/.*/) $::engine::engineMenu(newCommand) dummy dir
			set ::engine::engineMenu(newDirectory) $dir
		}
		set currdir [pwd]
		set ::engine::engineList(wine_$id) $::engine::engineMenu(newWine)
		set ::engine::engineList(command_$id) $::engine::engineMenu(newCommand)
		set ::engine::engineList(protocol_$id) $::engine::engineMenu(newProtocol)
		set ::engine::engineList(dir_$id) $::engine::engineMenu(newDirectory)
		set ::engine::engineList(pic_$id) $::engine::engineMenu(newPicture)
		set ::engine::engineList(param_$id) $::engine::engineMenu(newParameters)
		set ::engine::engineList(elo_$id) $::engine::engineMenu(newElo)
		set ::engine::engineList(alias_$id) "New engine"
		if { [catch {::engine::start $id eNew} errorMessage ]  } {
			array unset ::engine::engineList *_$id
			tk_messageBox -message "Engine cannot be started. <$errorMessage>" -type ok -icon error
			return
		}
		if { $::engine::engineMenu(newAlias) eq "" } {
			if { [catch {
				set ::engine::engineMenu(newAlias) $::engine::engineList(name_$id)	
			} errorMessage] } {
				writeLog "<$errorMessage> engine didn't send it's name"
				tk_messageBox -message "Engine didn't send a name." -type ok -icon error
				array unset ::engine::engineList *_$id
				return
			}
		}	
		set ::engine::engineList(alias_$id) $::engine::engineMenu(newAlias)
		if {$::engine::engineList(protocol_$id) eq "xboard" } {
			set ::engine::engineList(absscore_$id) false
			set ::engine::engineList(playcolor_$id) white
		}
		::engine::quit $id
		lappend ::engine::allEngines $id
		lappend ::engine::engineMenu(list) $::engine::engineList(alias_$id)
		destroy .eNew
	}
	pack .eNew.buttonFrame.ok -side right -fill y 
	wm resizable .eNew 0 0
	modalWindow .eNew .eMenu
	renewModal $parent
	array unset ::engine::engineMenu new*
}

proc ::engine::eng_send { id txt } {
	variable engineList
	global log
	if {[catch {
		puts $engineList(pipe_$id) $txt
		#pipe must be flushed in non-blocking mode
		flush $engineList(pipe_$id)
		writeLog "$engineList(alias_$id) << $txt"
		if { [winfo exists .engwait_$id] } {
			.engwait_$id.text insert end "$id << $txt\n" 
			.engwait_$id.text yview moveto 1.0 
		}
	} errorMessage ]} { writeLog "::engine::eng_send <$errorMessage>"}
}

proc ::engine::eng_read { id } {
	variable engineList	
	global log
	set res -1
	if { [catch {set res [gets $engineList(pipe_$id) line]} errorMessage]} {
		writeLog "failed reading form engine $id <$errorMessage>"
	}
	if { $res >= 0 } {
		#update idletasks
		writeLog "$engineList(alias_$id) >> $line"
		#don't delay return of move command
		if { [lindex $line 0] eq "bestmove" || [lindex $line 0] eq "move"} {
			set engineList(status_$id) idle
			if { $engineList(move_$id) eq "" } {
				writeLog "set engine $id move to [lindex $line 1]"
				set engineList(move_$id) [lindex $line 1]
				if { [llength $line] > 3 } { set engineList(ponder_$id) [lindex $line 3] }
				set type uci
				if { $engineList(protocol_$id) eq "xboard" } {
					incr engineList(pos_$id)
					#can't rely on feature san=1
					switch -regexp $engineList(move_$id) {
						{^[a-z][0-9][a-z][0-9][nbrq]?$} {set type uci}
						default {set type san}
					}
				}
				if { $engineList(mode_$id) eq "play" } {
					if {[catch {::game::makeMove computer $type $engineList(move_$id)} errorMessage]} {
						writeLog "error making move \"$errorMessage\""
					}
					if {$type eq "uci"} {::board::setArrow main $id ""}
				} elseif { $engineList(mode_$id) eq "analyzing" } {
					#engines should not end search in analyze mode but some do
					set m $engineList(move_$id)
					if {$type eq "uci"} {set m [lindex 1 [::engine::uci::formatPv $m]]}
					.engine_$id.text insert end "Found move $m"
					writeLog "engine returned move $m in analyze mode"
				}		
			}
		} else {
			after idle "::engine::$engineList(protocol_$id)::readInput $id [list $line]"
		}
		if { [winfo exists .engwait_$id] } {
			.engwait_$id.text insert end "$id >> $line\n" 
			.engwait_$id.text yview moveto 1.0 
		}
	}
	#return $line
}

proc ::engine::start { id parent  {mode "" } } {
	variable activeEngines
	variable engineList
	writeLog "Trying to start $engineList(alias_$id)."
	set engineList(status_$id) off
	set currdir [pwd]
	if { [catch {
		cd $::engine::engineList(dir_$id)
		if { $engineList(wine_$id) } {
			set cmnd $engineList(command_$id)
			if { $engineList(param_$id) ne "" } { set cmnd "$cmnd $engineList(param_$id)"}
			set command "wine $cmnd"
			set engineList(pipe_$id) [open "| wine $engineList(command_$id) $engineList(param_$id)" r+]
		} else {
			set engineList(pipe_$id) [open "| $engineList(command_$id) $engineList(param_$id)" r+ ]
		}
		cd $currdir
		fconfigure $engineList(pipe_$id) -blocking 0 -buffering full	
	} errorMessage] } {
		writeLog "cannot open $engineList(alias_$id). <$errorMessage>"
		return -code error "Cannot open $engineList(alias_$id)."
	}
	set engineList(frame_$id) false
	fileevent $engineList(pipe_$id) readable [list ::engine::eng_read $id]
	set engineList(mode_$id) $mode
	toplevel .engwait_$id
	text .engwait_$id.text -width 50 -height 30
	pack .engwait_$id.text
	wm title .engwait_$id "$engineList(alias_$id)"
	.engwait_$id.text insert end "Starting engine...\n"
	sleep 500
	set timeout [after 20000 set ::engine::engineList(status_$id) timeout]
	::engine::$engineList(protocol_$id)::init $id $timeout
	after 500 destroy .engwait_$id
	if { $engineList(status_$id) eq "timeout" } {
		if { [catch {
			close $engineList(pipe_$id)
		} errorMessage] } { writeLog "error closing pipe" }
		set engineList(pipe_$id) ""
		writeLog "Cannot initialize engine."
		return -code error "Cannot initialize engine."
	}
	::engine::setPosition $id true
	if { $mode eq "analyze" && \
			$engineList(protocol_$id) eq "xboard" && \
			[array get engineList feature_analyze_$id] ne "feature_analyze_$id 1" } {
		tk_messageBox -message "Engine does not support analysis." -type ok -icon info
		set engineList(mode_$id) ""
		quit $id
		writeLog "Engine does not support analysis."
		return -code error "Engine does not support analysis."
	}
	lappend activeEngines $id
	writeLog "$engineList(alias_$id) started as $engineList(pipe_$id)."
	reset $id
	if { $mode ne "" } { startFrame $mode $id $parent }
}

#proc ::engine::startPlay { id parent } {
	#variable engineButton
	#variable engineList
	#lappend activeEngines $id
	#set font [list Arial 10]
	#frame .engine_$id
	#frame .engine_buttonframe_$id -background lightgrey -relief raised -width 120 -height 10
	#label .engine_name_$id -font [concat $font "bold"] -text " $engineList(name_$id) " \
			#-relief sunken -bg #44AA44
	#pack .engine_name_$id -in .engine_buttonframe_$id -side left -fill y 
	#text .engine_info_$id -background darkgrey -width 120 -height 10 -font $font
	#grid .engine_buttonframe_$id -in .engine_$id -row 1 -column 1 
	#grid .engine_info_$id -in .engine_$id -row 2 -column 1 
	#.$parent add .engine_$id
	#.$parent paneconfigure .engine_$id -minsize 75
#}

proc ::engine::startFrame { mode id parent {buttons true} } {
	variable settings
	variable engineList
	variable engineButton
	set engineList(color_$id) [getColor]
	set font [list Arial 10]
	set engineButton(analyze_$id) 0
	set engineList(arrow_$id) false
	frame .engine_$id
	frame .engine_$id.buttonframe -background lightgrey -width 120
	label .engine_$id.buttonframe.name -font [concat $font bold] -text " $engineList(name_$id) " \
			-relief sunken -bg $engineList(color_$id)
	pack .engine_$id.buttonframe.name -side left -fill y
	if { $mode eq "analyze" } { 		
		checkbutton .engine_$id.buttonframe.analyze -image ::img::play -selectimage ::img::pause \
				-variable ::engine::engineButton(analyze_$id) -indicatoron false \
				-command "::engine::analyzeButton $id"
		pack .engine_$id.buttonframe.analyze -side left
		menubutton .engine_$id.buttonframe.menubutton -image ::img::option -relief raised
		menu .engine_$id.buttonframe.menubutton.menu
		.engine_$id.buttonframe.menubutton config -menu .engine_$id.buttonframe.menubutton.menu 
		if {$engineList(protocol_$id) eq "uci"} {
			if {[array get engineList MultiPV_$id] ne "" } {
				set engineList(MultiPV_curr_$id) 1
				label .engine_$id.buttonframe.multilabel -text "MultiPV"
				pack .engine_$id.buttonframe.multilabel -side left
				spinbox .engine_$id.buttonframe.multi -width 3 -from 1 -to 10 \
						-textvariable ::engine::engineList(MultiPV_curr_$id) \
						-command "::engine::uci::sendMultiPv $id"
				pack .engine_$id.buttonframe.multi -side left
			}
			foreach option [array names engineList option*_$id] {
				if {[lindex $engineList($option) 1] eq "button"} {
					.engine_$id.buttonframe.menubutton.menu add command -label [lindex $engineList($option) 0] \
							-command "::engine::eng_send $id \"setoption name [lindex $engineList($option) 0]\""
				}
			}
		}
		.engine_$id.buttonframe.menubutton.menu add command -label "Settings" -command "::engine::engineEdit $id"
		pack .engine_$id.buttonframe.menubutton -side left
		button .engine_$id.buttonframe.close -image ::img::close \
				-command "::engine::quit $id"
		pack .engine_$id.buttonframe.close -side left
	}
	if {$buttons} {
		checkbutton .engine_$id.buttonframe.board -image ::img::board \
				-variable ::engine::engineButton(board_$id) \
				-indicatoron false -command "::engine::createBoard $id"
		checkbutton .engine_$id.buttonframe.arrow -image ::img::arrow \
				-variable ::engine::engineButton(arrow_$id) \
				-indicatoron false -command "::engine::createArrow $id"
		if { $mode eq "analyze" } { 
			pack .engine_$id.buttonframe.board -after .engine_$id.buttonframe.analyze -side left
		} else { 
			pack .engine_$id.buttonframe.board -side left
		}
		pack .engine_$id.buttonframe.arrow -after .engine_$id.buttonframe.board -side left
	}
	frame .engine_$id.info -relief raised
	foreach {name item row col} {Score score 1 1 Time time 1 3 knodes nodes 1 5 \
			kn/s nps 1 7 Move move 2 1 Depth depth 2 3 Hash hash 2 5 Tbhits tb 2 7} {
		label .engine_$id.info.name$item -text $name -width 6 -anchor w -relief sunken
		label .engine_$id.info.$item -background darkgrey -relief sunken \
				-width 10 -height 1 -font $font -anchor e
		grid .engine_$id.info.name$item -row $row -column $col -sticky w
		grid .engine_$id.info.$item -row $row -column [expr 1+$col] -sticky w 
	}
	text .engine_$id.text -width 120 -height 10 -yscrollcommand ".engine_$id.scroll_y set" \
			-xscrollcommand ".engine_$id.scroll_x set" -wrap none -font $font
	.engine_$id.text tag configure multi -foreground blue -font {Arial 10 bold}
	scrollbar .engine_$id.scroll_y -command ".engine_$id.text yview" -orient v
	scrollbar .engine_$id.scroll_x -command ".engine_$id.text xview" -orient h
	if { $engineList(pic_$id) eq ""} {
		grid .engine_$id.buttonframe -row 0 -column 0 -sticky w
		grid .engine_$id.info -row 1 -column 0 -sticky w
		grid .engine_$id.text -row 2 -column 0 -sticky news
		grid .engine_$id.scroll_y -row 2 -column 1 -sticky ns
		grid .engine_$id.scroll_x -row 3 -column 0 -sticky ew
		grid columnconfigure .engine_$id 0  -weight 1
		grid columnconfigure .engine_$id 1 -weight 0
	} else {
		writeLog "Loading image <$engineList(pic_$id)>"
		if { [catch {
			image create photo pic_$id
			image create photo temp1
			temp1 read $engineList(pic_$id)
			set factor [image height temp1]
			if {$factor > 70} {
				image create photo temp2
				temp2 copy temp1 -zoom 70
				pic_$id copy temp2 -subsample $factor
				image delete temp2
			} else {
				pic_$id copy temp1
			}
			image delete temp1
			label .engine_$id.pic -image pic_$id -relief raised
			grid .engine_$id.pic -row 0 -column 0 -sticky w -rowspan 2
		} errorMessage ] } { writeLog "startframe creat picture <$errorMessage>"}
		grid .engine_$id.buttonframe -row 0 -column 1 -sticky w
		grid .engine_$id.info -row 1 -column 1 -sticky w
		grid .engine_$id.text -row 2 -column 0 -columnspan 2 -sticky news
		grid .engine_$id.scroll_y -row 2 -column 2 -sticky ns
		grid .engine_$id.scroll_x -row 3 -column 0 -sticky ew -columnspan 2
		grid columnconfigure .engine_$id 0 -weight 0
		grid columnconfigure .engine_$id 1 -weight 1
		grid columnconfigure .engine_$id 2 -weight 0
	}
	grid rowconfigure .engine_$id 0 -weight 0
	grid rowconfigure .engine_$id 1 -weight 0
	grid rowconfigure .engine_$id 2 -weight 1
	grid rowconfigure .engine_$id 3 -weight 0
	placeInParent .engine_$id $parent [expr $settings(boardsize)+10] 0
	set engineList(frame_$id) true
}

proc ::engine::createArrow { id } {
	variable engineButton
	variable engineList
	if {$engineButton(arrow_$id) == 0} {
		set engineList(arrow_$id) false
		::board::destroyArrow main $id
	} else {
		set engineList(arrow_$id) true
		::board::createArrow main $id $engineList(color_$id)
		::board::setArrow main $id $engineList(bestpvmove_$id)
	}
}

proc ::engine::getColor {} {
	variable clr
	for {set i 0} {$i < 6} {incr i} {
		if { [lsearch $clr(active) $clr($i)] < 0 } {
			lappend clr(active) $clr($i)
			writeLog "Choosing color $i $clr($i)."
			return $clr($i)
		}
	}
	writeLog "Couldn't find color. Using default color."
	return #FF0000
}

proc ::engine::removeColor {col} {
	variable clr
	writeLog "Trying to remove color $col."
	set pos [lsearch $clr(active) $col]
	if { $pos >= 0 } {
		set clr(active) [lreplace $clr(active) $pos $pos]
		writeLog "Removing color $col successful. Active colors: $clr(active)"
	} else {return code -error "Failed to remove engine color."}
}

proc ::engine::createBoard { id } {
	variable engineButton
	variable engineList
	if {$engineButton(board_$id) == 0} {
		if { [winfo exists .boardFrame_$id] } {
			destroy .boardFrame_$id
			destroy .engine_$id.boardframe
		}
	} else {
		if { [winfo exists .boardFrame_$id] == 0 } {
			frame .engine_$id.boardframe
			::board::create $id .engine_$id.boardframe simple
			if { $engineList(posstr_$id) ne "" } {
				::board::setBoard $id $engineList(posstr_$id)
			} else {
				::board::setBoard $id
			}
			::board::resize $id true
			if { $engineList(pic_$id) eq ""} {
				grid .engine_$id.boardframe -row 0 -column 2 -rowspan 4 -sticky news
			} else {
				grid .engine_$id.boardframe -row 0 -column 3 -rowspan 4 -sticky news
			}
		}
	}
}

proc ::engine::analyzeButton { id } {
	variable engineButton
	if { $engineButton(analyze_$id) == 1 } { 
			::engine::analyze $id false
		} else {
			::engine::stop $id
	}
}

proc ::engine::quit { id } {
	variable activeEngines
	variable engineButton
	variable engineList
	if {[array names engineList color_$id] ne ""} {
		removeColor $engineList(color_$id)
		array unset engineList color_$id
	}
	if { [catch {
		#both uci and xboard has "quit" as command
		eng_send $id "quit"
		update idletasks
		#give engine some time to finish before closing
		after 500 ::engine::eng_close $id
		set pos [lsearch $activeEngines $id]
		set activeEngines [lreplace $activeEngines $pos $pos]
		vwait ::engine::engineList(pipe_$id)
		destroy .engine_$id
		array unset engineButton *_$id
		if { $engineList(pic_$id) ne ""} {image delete pic_$id}
		if { [winfo exists .boardFrame_$id] } {
			destroy .boardFrame_$id
			destroy .engine_$id.boardframe
		}
		::board::destroyArrow main $id
	} errorMessage]} { writeLog "::engine::quit \"$errorMessage\" closing id $id" }
}

proc ::engine::eng_close { id } {
	variable ::engine::engineList
	if {[catch {
		writeLog "Closing pipe $engineList(pipe_$id) (engine $id)"	
		close $engineList(pipe_$id)
	} errorMessage]} { 
		writeLog "::engine::eng_close <$errorMessage> closing <$id>" 
	}
	set engineList(pipe_$id) ""
}
	

proc ::engine::setStandardOption {  id name value } {
	variable engineList
	::engine::$engineList(protocol_$id)::standardOption $id $name $value
}

proc ::engine::setPosition {id newGame } {
	variable engineList	
	writeLog "set position $engineList(alias_$id)"
	ready $id
	::engine::$engineList(protocol_$id)::setPosition $id $newGame
}

proc ::engine::analyze { id newGame} {
	variable engineList
	if { $engineList(status_$id) eq "analyzing" } { return }
	set engineList(move_$id) ""
	::engine::$engineList(protocol_$id)::analyze $id 
}

proc ::engine::move { id } {
	variable engineList
	if { $engineList(status_$id) eq "moving" } { return }
	set bookMove [libboard::book move uci random]
	reset $id
	#one engine reset position to startpos after isready,
	#not correct, but we probably don't need to check for
	#ready here
	#ready $id
	.engine_$id.text delete 1.0 end
	::engine::$engineList(protocol_$id)::move $id 
}

proc ::engine::reset {id} {
	variable engineList
	set engineList(pv_$id) ""
	set engineList(depth_$id) 0
	set engineList(seldepth_$id) 0
	set engineList(score_$id) 0
	set engineList(time_$id) 0
	set engineList(nodes_$id) 0
	set engineList(nps_$id) 0
	set engineList(string_$id) ""
	set engineList(move_$id) ""
	set engineList(lastpv_$id) ""
	set engineList(bestpvmove_$id) ""
	set engineList(posstr_$id) ""
	set engineList(string_$id) ""
}

proc ::engine::stop { id } {
	variable engineList
	if { $engineList(status_$id) eq "analyzing" \
			|| $engineList(status_$id) eq "moving" } {
		if { $engineList(protocol_$id) eq"uci" } {
			eng_send $id "stop"
		} else {
			switch $engineList(status_$id) {
				analyzing { eng_send $id "exit" }
				moving { eng_send $id "?" }	
			}
			eng_send $id "force"	
		}
	}
	set engineList(status_$id) idle
}

proc ::engine::ready { id } {
	variable engineList
	set engineList(status_$id) wait

	#keep sending ready signal until status is ready
	for {set i 0} {$engineList(status_$id) ne "ready"  && $i < 5} {incr i} {
		if { $engineList(protocol_$id) eq "uci" } {
			eng_send $id "isready"
		} else {
			#if engine doesn't support ping just set it to ready
			if { [array get engineList feature_ping_$id] eq "feature_ping_$id 1" } { 
				eng_send $id "ping 1"
			} else {
				set engineList(status_$id) ready
				break
			}
		}
		#make sure we don't get stuck
		after 1000 set ::engine::engineList(status_$id) noresponse
		writeLog "waiting for ready $engineList(status_$id)"
		vwait ::engine::engineList(status_$id)
		after cancel set ::engine::engineList(status_$id) noresponse
		if {$engineList(status_$id) eq "noresponse"} {
			writeLog "engine gives no response $i"
		}
	}
	if {$engineList(status_$id) ne "ready"} {
		writeLog "engine not responding"
		return -code error "engine not responding"
	}
}

proc ::engine::saveSettings { } {
	variable engineList
	variable allEngines
	variable clr
	#store in temp file, if program crashes it will not erase anything
	set file ""
	if { [catch {set file [open "./data/engines.tmp" w]} errorMessage]} {
		writeLog "currdir [pwd] error writing engines.tmp <errorMessage>"
		return -code error "Failed to create ./data/engines.tmp"
	}
	for {set i 0} {$i < 4} {incr i} {
		puts $file "set clr($i) $clr($i)"
	}
	foreach id [lsort -integer $allEngines] {
		if { [array get engineList command_$id] eq ""} {continue}
		puts $file "# Engine $id"
		foreach {name dflt} { alias "-" command "" protocol "uci" param "" dir "." wine false pic "" elo 0} {
			if {[catch { 
				puts $file "set engineList($name\_$id) \{$engineList($name\_$id)\}"
			} errorMessage]} {
				writeLog "<$errorMessage> writing engineList($name\_$id). Saving default value."
				set engineList($name\_$id) $dflt
				puts $file "set engineList($name\_$id) \{$dflt\}"
			}
		}
		::engine::$engineList(protocol_$id)::saveSettings $id $file
	}
	close $file
	#if file is empty don't save
	if {[file size "./data/engines.tmp"] == 0 } {
		file delete "./data/engines.tmp"
		writeLog "./data/engines.tmp is empty, file not saved"
		return 
	}
	# safety copy
	if { [file exists "./data/engines.dat"] && [file size "./data/engines.dat"] > 0 } {
		file rename -force "./data/engines.dat" "./data/engines.bak"
	}
	file rename -force "./data/engines.tmp" "./data/engines.dat"	
	writeLog "./data/engines.dat saved"
}

proc ::engine::loadSettings {} {
	variable engineList
	variable allEngines
	variable clr
	if { [catch { source "./data/engines.dat"} ] } {
		writeLog "Loading ./data/engines.dat failed. Using backup ./data/engines.bak"
		source "./data/engines.bak"
	}
	foreach alias [array names engineList alias_*] {
		lappend allEngines [string replace $alias 0 5 ]
	}
}

proc ::engine::resize { id } {
	variable settings
	variable engineList
	if { $engineList(mode_$id) eq "" } { return }
	set w [winfo width .engine_$id]
	set h [winfo height .engine_$id]
	set font [.engine_$id.text cget -font]
	set fontH [expr {[lindex $font 1] + 2*[font metrics $font -displayof .engine_$id.text -descent] }]
	set width [font measure $font 0 ]
	set textW [expr {$w/$width-2}]
	
	#.engine_$id.buttonframe configure -width [expr $width*$textW] -height [expr 2*$fontH]
	#.engine_$id.info configure -width $textW -height 2
	#if { $engineList(mode_$id) eq "analyze" } { 
		.engine_$id.text configure -width $textW -height [expr { $h/$fontH -5}]
		
	#}
	if { [winfo exists .engine_$id.boardframe] } { 
		.engine_$id.boardframe configure -width $settings(boardsize) -height $settings(boardsize)
		.boardFrame_$id configure -width $settings(boardsize) -height $settings(boardsize)
		::board::resize $id 
	}
}

proc ::engine::comment { id } {
	variable engineList
	#make sure all info has been processed
	update idletasks
	#if { $engineList(score_$id) == 0 && \
				#$engineList(depth_$id) == 0 && \
				#$engineList(time_$id) == 0 } { return {} }
	return "[::engine::$engineList(protocol_$id)::confScore $id plain]\
			[::engine::$engineList(protocol_$id)::confScore $id full]\
			$engineList(depth_$id) $engineList(seldepth_$id) $engineList(lastpv_$id)"
}

#procs in namespaces ::uci and ::xboard are not called directly
#instead they're called from common procs in ::engine

namespace eval ::engine::uci {
	variable uciStandardOptions [list Threads Hash NalimovPath NalimovCache \
			Ponder OwnBook MultiPV UCI_ShowCurrLine UCI_ShowRefutations \
			UCI_LimitStrength UCI_Elo UCI_AnalyseMode UCI_Opponent]
			
	variable uciSettings
	#Hash should always be sent first according to standard
	array set uciSettings {
		hash 			Hash
		ponder 			Ponder
		ownBook			OwnBook
		multiPv 		MultiPV
		nalimovPath 	NalimovPath
		nalimovCache 	NalimovCache
		threads 		Threads
	}
}

proc ::engine::uci::init { id timeout } {
	variable ::engine::engineList
	::engine::eng_send $id "uci"
	vwait ::engine::engineList(status_$id)
	after cancel $timeout
	sendOption $id
	switch $engineList(mode_$id) {
		analyze {
			if { [array names engineList UCI_AnalyzeMode_$id] ne "" } {
				::engine::eng_send $id "setoption name UCI_AnalyzeMode value true"
			}
			if { [array names engineList OwnBook_$id] ne "" } {
				::engine::eng_send $id "setoption name OwnBook value false"
			}
		}
		play {
			if { [array names engineList UCI_AnalyzeMode_$id] ne "" } {
				::engine::eng_send $id "setoption name UCI_AnalyzeMode value false"
			}
		}
	}
}

proc ::engine::uci::readInput { id str } {
	variable ::engine::engineList
	variable uciStandardOptions
	switch [lindex $str 0] {
		id {
			switch [lindex $str 1] {
				name { set engineList(name_$id) [lreplace $str 0 1] }
				author { set engineList(author_$id) [lreplace $str 0 1] }
			}
		}
		"option" {
			array set opt {
				name ""
				type ""
				value ""
				"default" ""
				min ""
				max ""
				var ""		
			}
			set n ""
			foreach word [lrange $str 1 end] {
				set w [lsearch -inline {name type default min max var} $word]
				if {$w ne ""} { set n $w } else { set opt($n) [concat $opt($n) $word] }
			}
			regsub -all {\W} $opt(name) "_" name
			if { [lsearch $uciStandardOptions $opt(name)] == -1 } {
				set name "option_$name\_$id"
			} else {
				#standard options does not have option_ in name
				#they are handled separately
				set name "$opt(name)\_$id"
			}
			if { $opt(type) ne "button" } {
				#syntax of list is: name, set value, default, (min, max) or (var, var...)
				#button has no default value and is ignored
				#check to see if option already exists, and in that case set given value
				if { [array get engineList $name] ne "" } {
					#set only the first value, default and rest is kept
					set opt(value) [lindex $engineList($name) 2 ]
				} else {
					#set value to default
					set opt(value) $opt(default)
				}
			}
			switch $opt(type) {
				check { set engineList($name) [list $opt(name) $opt(type) $opt(value) $opt(default)] }
				spin { set engineList($name) [list $opt(name) $opt(type) $opt(value) $opt(default) $opt(min) $opt(max)] }
				combo { set engineList($name) [list $opt(name) $opt(type) $opt(value) $opt(default) $opt(var)] }
				"button" { set engineList($name) [list $opt(name) $opt(type)] }
				"string" { set engineList($name) [list $opt(name) $opt(type) $opt(value) $opt(default)] }
			}
			#puts "setting     $name $engineList($name)"
		}
		uciok { 
			set engineList(status_$id) idle
		}
		"info" {
			set cmd ""
			for { set i 1 } { $i < [llength $str] } { incr i } {
				set infocmd "depth seldepth time nodes pv multipv \
						score currmove currmovenumber hashfull nps \
						tbhits cpuload refutation currline string"
				set c [lsearch -inline $infocmd [lindex $str $i]]	
				if { $c ne "" } {
					if { $c eq "string" } {
						#string is always rest of line
						set engineList(string_$id) [lreplace $str 0 $i]
						break
					}
					if { $cmd ne "" } { 
						set engineList($cmd\_$id) $value 
					}
					set cmd $c 
					set value ""
				} else {
					lappend value [lindex $str $i]
				}
			}
			if { $cmd ne "" } { 
				set engineList($cmd\_$id) $value 
			}
			::engine::uci::updateText $id
		}
		readyok { set engineList(status_$id) ready }
		default { writeLog "unknown uci <$str>"}
	}
}
proc ::engine::uci::confTime { id } {
	variable ::engine::engineList
	return "[format %.2f [expr $engineList(time_$id)/1000.0]]"
}	

proc ::engine::uci::updateText { id } {
	variable ::engine::settings
	variable ::engine::engineList
	variable ::engine::showComments
	if {$engineList(frame_$id) ne "true"} {return}
	if { $engineList(mode_$id) eq "" } {
		set set engineList(lastpv_$id) ""
		return 
	}
	.engine_$id.info.score configure -text "[confScore $id]  "
	.engine_$id.info.time configure -text "[confTime $id] s"
	.engine_$id.info.nodes configure -text	"[expr $engineList(nodes_$id)/1000]  "
	.engine_$id.info.nps configure -text "[expr $engineList(nps_$id)/1000]  "
	if { $engineList(seldepth_$id) > 0 } {
		set depth "$engineList(depth_$id)/$engineList(seldepth_$id)"
	} else {
		set depth $engineList(depth_$id)
	}
	if {$showComments} {
		.engine_$id.info.move configure -text \
				"$engineList(currmovenumber_$id):$engineList(currmove_$id)  "
	}
	.engine_$id.info.depth configure -text "$depth  "
	.engine_$id.info.hash configure -text "[expr $engineList(hashfull_$id)/10] %"
	#.engine_$id.info insert end "Move \
		#\t\t$depth\t\thash \n"
	#if { $engineList(mode_$id) eq "play" } { 
		#set engineList(lastpv_$id) $engineList(pv_$id)
		#return 
	#}
	if { $engineList(string_$id) ne ""} {
		if {$showComments} { 
			.engine_$id.text insert end "$engineList(string_$id) \n"
		}
		set engineList(string_$id) ""
	}
	set pv [formatPv $engineList(pv_$id)]
	set pos [lindex $pv 0]
	set pv [lrange $pv 1 end]
	if { [array get engineList MultiPV_curr_$id] eq "" || $engineList(MultiPV_curr_$id) == 1 } {	
		if { $pv ne "" } {
			set engineList(bestpvmove_$id) [lindex $engineList(pv_$id) 0] 
			if {$engineList(arrow_$id)} {
				::board::setArrow main $id $engineList(bestpvmove_$id)
			} else { 
				::board::setArrow main $id ""
			}
			set engineList(lastpv_$id) $pv
			set engineList(posstr_$id) $pos 
			if {$showComments} {
				if { [winfo exists .engine_$id.boardframe] } {::board::setBoard $id $pos}
				.engine_$id.text insert end "[confScore $id]\t$depth\t\
						$pv \([format %.2f [expr $engineList(time_$id)/1000.0]]s\) \n"
				.engine_$id.text yview moveto 1.0
				.engine_$id.text yview scroll -1 units
			}
		}
	} else {
		if { $pv ne "" } { 
			.engine_$id.text delete 1.0 end
			if {$engineList(multipv_$id) == 1} {
				set engineList(bestpvmove_$id) [lindex $engineList(pv_$id) 0]
				if {$engineList(arrow_$id)} {
					::board::setArrow main $id $engineList(bestpvmove_$id)
				} else { 
					::board::setArrow main $id ""
				}
				set engineList(lastpv_$id) $pv
				set engineList(posstr_$id) $pos 
				if { [winfo exists .engine_$id.boardframe] && $showComments} {
					::board::setBoard $id $pos
				}
			}
		}
		set engineList(multi_$engineList(multipv_$id)_$id)  "[confScore $id]\t$depth\t\
				$pv \([format %.2f [expr $engineList(time_$id)/1000.0]]s\) \n"
		if { $engineList(pv_$id) ne "" && $showComments} {
			for {set i 1} {$i <= $engineList(MultiPV_curr_$id)} {incr i} {
				if { [array get engineList multi_$i\_$id] ne "" } {
					.engine_$id.text insert end "$i\. " multi
					.engine_$id.text insert end "$engineList(multi_$i\_$id)"
				}
			}
		}
	}
	if {$engineList(string_$id) ne "" && $showComments} {
		.engine_$id.text insert end $engineList(string_$id)
		set engineList(string_$id) ""
		.engine_$id.text yview moveto 1.0
		.engine_$id.text yview scroll -1 units
	}
	set engineList(pv_$id) ""
}

proc ::engine::uci::formatPv { pv } {
	set result [libboard::ucitoformat number san {*}$pv]
	return $result
}

proc ::engine::uci::confScore { id {style full} } {
	variable ::engine::engineList
	set score ""
	set num 0
	set cent false
	for { set i 0 } { $i < [expr [llength $engineList(score_$id)]]} {incr i} {
		switch [lindex $engineList(score_$id) $i ] {
			cp {
				set cent true
				incr i
				set num [lindex $engineList(score_$id) $i]
			}
			mate { 
				if {$style eq "full"} {
					set score "M" 
					incr i
					set num [lindex $engineList(score_$id) $i]
				} else {
					incr i
					set num [lindex $engineList(score_$id) $i]
					if { $num >0 } { 
						set num [expr 300.00-$num/100.0] 
					} else {
						set num [expr -300.00-$num/100.0] 
					}
				}
			}
			lowerbound { if {$style eq "full"} {set score "$score\u2191" } }
			upperbound { if {$style eq "full"} {set score "$score\u2193" } }
		}
	}
	if {$cent} {
		set num [format %.2f [expr $num/100.0]]
	}
	if {$style eq "full"} {
		if {$num > 0 && $cent} {
			set score "$score+$num"
		} elseif {$num == 0 } {
			set score "$score±$num"
		} else {
			set score "$score$num"
		}
	} else { 
		set score $num
	}
	return [concat $score]
}

#options are sent
proc ::engine::uci::sendOption { id  { opt "" } } {
	variable ::engine::engineList
	variable uciSettings
	if { $opt eq "" } {
		foreach setting [array names uciSettings] {
			standardOption $id $setting
		}
		set opt [array names ::engine::engineList "option_*_$id"]
	}
	foreach option $opt {
		#make sure options are in range
		optionInRange $engineList($option)
			set engineList($option) [optionInRange $engineList($option)]
			set val [lindex $engineList($option) 2]
			::engine::eng_send $id \
					"setoption name [lindex $engineList($option) 0] value $val"
	}
}

proc ::engine::uci::optionInRange { lst } {
	switch { [lindex $lst 1] } {
		spin {
			#set spin values in range
			if { [lindex $lst 2] < [lindex $lst 4] } { 
				lset $lst 2 [lindex $lst4] 
			}
			if { [lindex $lst 2] > [lindex $lst 5] } {
				lset $lst 2 [lindex $lst 5] 
			}
		}
		combo {
			#if combo value doesn't exist set default
			if { [lsearch [lreplace $lst 0 3] [lindex $lst 2]] == -1 } {
				lset $lst 2 [lindex $lst 3]
			}
		}
		check {
			#if check is not set to true or false set default
			if { [lindex $lst 2] ne "false" && [lindex $lst 1] ne "true" } {
				lset $lst 2 [lindex $lst 3]
			}
		}
	}
	return $lst
}

proc ::engine::uci::standardOption { id name  {value ""} } {
	variable ::engine::options
	variable ::engine::engineList
	variable uciSettings
	set option "$uciSettings($name)\_$id"
	#don't create options not sent by engine
	if { [array get engineList $option] ne "" } {
		#set new value if given
		if { $value ne "" } {
			lset engineList($option) 2 $value
		} else { 
			set value $options($name) 
			lset engineList($option) 2 $value 
		}
		set engineList($option) [optionInRange $engineList($option)]
		#always send common option if it is not ""
		if { $options($name) ne "" } {
			set value [optionInRange $options($name)]
		}
		::engine::eng_send $id "setoption name $uciSettings($name) value $value"
	}
}

proc ::engine::uci::setPosition {id newGame } {
	variable ::engine::engineList
	::board::setArrow main $id ""
	set engineList(currmovenumber_$id) ""
	set engineList(currmove_$id) ""
	set engineList(hashfull_$id) 0
	set fen [libboard::startpos] 
	set moves [libboard::getmove all uci]
	if { $newGame } { ::engine::eng_send $id "ucinewgame" }
	if { $fen eq "startpos" } { 
		set pos "position startpos"
	} else {
		set pos "position fen $fen"
	}
	if { $moves ne "" } { set pos "$pos moves $moves" }
	::engine::eng_send $id $pos
}

proc ::engine::uci::analyze { id } {
	variable ::engine::engineList
	.engine_$id.text delete 1.0 end
	::engine::eng_send $id "go infinite"
	set engineList(status_$id) analyzing
}

proc ::engine::uci::move { id } {
	variable ::engine::engineList
	set engineList(status_$id) moving
	switch [lindex $::game::game(time_white) 0] {
		"time" {
			set t "wtime $::game::game(currtime_white)\
					btime $::game::game(currtime_black)\
					winc [lindex $::game::game(time_white) 3]\
					binc [lindex $::game::game(time_black) 3]"
			set move $::game::game(currmoves_[libboard::position color])
			if { $move > 0 } { set t "$t movestogo $move" }
		}
		fixed { set t "movetime [lindex $::game::game(time_white) 1]" }
		depth { set t "depth [lindex $::game::game(time_white) 1]" }
		nodes { set t "nodes [lindex $::game::game(time_white) 1]" }
	}
	::engine::eng_send $id "go $t"
}

proc ::engine::uci::saveSettings { id file } {
	variable ::engine::engineList
	foreach std { Threads OwnBook UCI_LimitStrength UCI_Elo } {
		if {[catch {
			if { [array get engineList $std\_$id] ne "" && \
					[lindex $engineList($std\_$id) 1] ne [lindex $engineList($std\_$id) 2] } {
				puts $file "set engineList($std\_$id) \{$engineList($std\_$id)\}"
			}
		} errorMessage]} {writeLog "<$errorMessage> writing engineList($std\_$id)."}
	}
	foreach option [array names engineList option*_$id] {
		if {[catch {
			if { [lindex $engineList($option) 1] ne [lindex $engineList($option) 2] } {
				puts $file "set engineList($option) \{$engineList($option)\}"		
			}
		} errorMessage]} {writeLog "<$errorMessage> writing engineList($option)."}
	}
}

proc ::engine::uci::optionMenu { id top parent row } {
	variable ::engine::engineList
	variable ::engine::engineMenu
	variable uciSettings
	variable ::engine::options
	set row 3
	set column 1
	#puts [array names engineList *_$id]
			
	foreach opt [array names options] {
		if {$options($opt) ne ""} {continue}
		set std $uciSettings($opt)
		if { [array get engineList $std\_$id] ne "" } {
			placeOption $std\_$id $top $parent $row $column
			if { $column == 0 } { set column 3 } else { set column 0 ; incr row } 
		}
	}
	foreach option [array names engineList option_*_$id] {
		if {[lindex $engineList($option) 1] eq "button" } { continue }
		placeOption $option $top $parent $row $column
		if { $column == 0 } { set column 3 } else { set column 0 ; incr row } 	
	}
}

proc ::engine::uci::placeOption {opt top parent row column } {
	variable ::engine::engineList
	variable ::engine::engineMenu
	set engineMenu($opt) [lindex $engineList($opt) 2]
	switch [lindex $engineList($opt) 1] {
		check {
			checkbutton .$top.$parent.op$opt -text [lindex $engineList($opt) 0] -offvalue false -onvalue true \
					-variable ::engine::engineMenu($opt)
			grid .$top.$parent.op$opt -row $row -column $column
		}
		spin {
			label .$top.$parent.lbl$opt -text [lindex $engineList($opt) 0]
			grid .$top.$parent.lbl$opt -row $row -column $column
			spinbox .$top.$parent.op$opt -width 15 \
					-from [lindex $engineList($opt) 4] \
					-to [lindex $engineList($opt) 5] \
					-textvariable ::engine::engineMenu($opt)
			grid .$top.$parent.op$opt -row $row -column [expr 1+$column]
		}
		combo {
			label .$top.$parent.lbl$opt -text [lindex $engineList($opt) 0]
			grid .$top.$parent.lbl$opt -row $row -column $column
			ttk::combobox .$top.$parent.op$opt -textvariable ::engine::engineMenu($opt) -values {*}[lrange $engineList($opt) 4 end]
			grid .$top.$parent.op$opt -row $row -column [expr 1+$column]
		} 
		"string" {
			label .$top.$parent.lbl$opt -text [lindex $engineList($opt) 0]
			grid .$top.$parent.lbl$opt -row $row -column $column
			entry .$top.$parent.op$opt -width 15 \
					-textvariable ::engine::engineMenu($opt)
			grid .$top.$parent.op$opt -row $row -column [expr 1+$column]
		}
	}
	button .$top.$parent.dflt$opt -text Default -command "::engine::uci::default $opt"
	grid .$top.$parent.dflt$opt -row $row -column [expr 2+$column]
}

proc ::engine::uci::setOption { id opt } {
	variable uciStandardOptions
	variable ::engine::engineList
	variable ::engine::engineMenu
	set name [string range $opt 7 end]
	if  { [lsearch $uciStandardOptions $name] == -1 } { set name "option_$name" }
	set engineList($name\_$id) [lreplace $engineList($name\_$id) 1 1 $engineMenu($opt)]
}
proc ::engine::uci::default { name } {
	variable ::engine::engineList
	variable ::engine::engineMenu
	set engineList($name) [lreplace $engineList($name) 2 2 \
			[lindex $engineList($name) 3]]
	set engineMenu($name) [lindex $engineList($name) 3]
	#puts "def $engineList($name\_$id) : $engineMenu(option_$name)"
}

proc ::engine::uci::sendMultiPv { id } {
	variable ::engine::engineList
	.engine_$id.text delete 1.0 end
	::engine::eng_send $id "setoption name MultiPV value $engineList(MultiPV_curr_$id)"
}

namespace eval ::engine::xboard {
	variable xboardSettings
	array set xboardSettings {
		hash 			memory
	}
	variable xboardFeature 
	array set xboardFeature {
		myname			name
		memory			memory
	}
}

proc ::engine::xboard::init { id timeout } {
	variable ::engine::engineList
	::engine::eng_send $id "xboard"
	::engine::eng_send $id "protover 2"
	set loop true
	vwait ::engine::engineList(status_$id)
	after cancel $timeout
	sendOption $id
	foreach setting [array names xboardSettings] {
		standardOption $id $setting
	}
	::engine::eng_send $id "hard"
	::engine::eng_send $id "easy"
	::engine::eng_send $id "post"
}

proc ::engine::xboard::readInput { id str } {
	variable ::engine::engineList
	set str [regexp -inline -all -- {\S+} $str]
	switch -regexp $str {
		{^feature\s.*} { handleFeature $id [featureToList $str] }
		{^pong\s.*} { set engineList(status_$id) ready }	
		{.*resign.*} { 
			if { [lindex $::game::game(status) 0] eq "play" } {	
				set col [libboard::position color]
				if { $col eq "white" } {
					set ::game::endresult [list "0-1" "Resigned by $col."]
				} else {
					set ::game::endresult [list "1-0" "Resigned by $col."]
				}
				set ::game::game(status) "play ended"
				::game::renew	
			}
		}
		{^[0-9]+\s+-?[0-9]+\s+[0-9]+\s+[0-9]+\s+} {
			set engineList(depth_$id) [lindex $str 0]
			set engineList(score_$id) [lindex $str 1]
			set engineList(time_$id) [expr [lindex $str 2]]
			set engineList(nodes_$id) [lindex $str 3]
			set engineList(pv_$id) [lreplace $str 0 3]
			::engine::xboard::updateText $id
		}
		{^[0-9]+[^\d]\s+-?[0-9]+\s+[0-9]+\s+[0-9]+\s+} {
			set engineList(depth_$id) [string replace [lindex $str 0] end end]
			set engineList(score_$id) [lindex $str 1]
			set engineList(time_$id) [expr [lindex $str 2]*100]
			set engineList(nodes_$id) [lindex $str 3]
			set engineList(pv_$id) [lreplace $str 0 3]
			::engine::xboard::updateText $id
		}
		default {}
	}
}

proc ::engine::xboard::handleFeature { id lst } {
	variable ::engine::engineList
	variable xboardFeature 
	foreach {full name value} $lst {
		set value [string trimleft $value {\"}]
		set value [string trimright $value {\"}]
		switch $full {
			"done=1" { set engineList(status_$id) idle }
			"done=0" {}
			default {
				switch $name {
					"option" {puts "handle option..."}
					draw { ::engine::eng_send $id "rejected draw" }
					ics { ::engine::eng_send $id "rejected ics" }
					default {
						if { [array get xboardFeature $name] ne "" } {
							set engineList($xboardFeature($name)\_$id) $value
						} else {
							set engineList(feature_$name\_$id) $value
						}
						::engine::eng_send $id "accepted $name"
					}
				}
			}
		}
	}
}

proc ::engine::xboard::featureToList { str } {
	return [regexp -all -inline {([^ =]*)=(\S*|\\"[^\\"]*\\")}  $str]
} 
#"

proc ::engine::xboard::sendOption { id { opt "" } } {
	variable xboardSettings
	foreach setting [array names xboardSettings] {
		standardOption $id $setting
	}
}

proc ::engine::xboard::standardOption { id name  {value ""} } {
	variable ::engine::options
	variable ::engine::engineList
	variable xboardSettings
	set opt [array get engineList $xboardSettings($name)\_$id]
	if { $opt ne "" && [lindex $opt 1] > 0 } {
		if { $value ne "" } {
			set engineList($xboardSettings($name)\_$id) [list [lindex $opt 1] $value]
		} elseif { [llength $opt] > 2 } {
			set value [lindex $opt 2]
		} 
		#always send common option if it is not ""
		if { $options($name) ne ""} { set value $options($name) }
			::engine::eng_send $id "$xboardSettings($name) $value"
	}
}

proc ::engine::xboard::setPosition { id newGame } {
	variable ::engine::engineList
	set engineList(playcolor_$id) [libboard::position color]
	set fen [libboard::startpos] 
	set pos 1
	if { [array get engineList feature_san_$id] ne "feature_san_$id 1" } {
		set moves [libboard::getmove all uci]
	} else {
		set moves [libboard::getmove all san]
	}
	if { $newGame  || [array get engineList pos_$id] eq "" } {
		::engine::eng_send $id new
		::engine::eng_send $id "force"
		if { $fen ne "startpos" } {
			if {[array get engineList setboard_$id] ne "setboard_$id 1" } {
				puts "Fenstring not supported."
			} else {
				::engine::eng_send $id "setboard $fen"
			}
		}
	} else {
		::engine::eng_send $id "force"
		set pos [expr [libboard::movenumber current]-$engineList(pos_$id)]
		#puts "this is pos $pos $engineList(pos_$id) [libboard::movenumber start]"
		#first element will always be replaced
		set moves [linsert $moves 0 "dummy"]
		set moves [lreplace $moves 0 [expr $engineList(pos_$id)-[libboard::movenumber start]] ]
	}
	if { $pos > 0 } {
		foreach move $moves {
			if { [array get engineList feature_usermove_$id] eq "feature_usermove_$id 1"} {set move "usermove $move" }
			::engine::eng_send $id $move
		}
	} else {
		while { $pos < 0 } {
			::engine::eng_send $id "undo"
			incr pos
		}
	}
	set engineList(pos_$id) [libboard::movenumber current]
}

proc ::engine::xboard::analyze { id } {
	variable ::engine::engineList
	.engine_$id.text delete 1.0 end
	if { [array get engineList feature_analyze_$id] eq "feature_analyze_$id 1" \
			|| [array get engineList feature_analyze_$id] eq "feature_analyse_$id 1"} {
		::engine::eng_send $id post
		::engine::eng_send $id analyze
		set engineList(status_$id) analyzing
	}
}

proc ::engine::xboard::confTime { id } {
	variable ::engine::engineList
	return "[format %.2f [expr $engineList(time_$id)/100.0]]"
}

proc ::engine::xboard::updateText { id } {
	variable ::engine::engineList
	variable ::engine::showComments
	if {$engineList(frame_$id) ne "true"} {return}
	if { $engineList(mode_$id) eq "" } {
		set engineList(lastpv_$id) $engineList(pv_$id)
		return 
	}
	.engine_$id.info.score configure -text "[confScore $id]  "
	.engine_$id.info.time configure -text "[confTime $id] s"
	.engine_$id.info.nodes configure -text	"[expr $engineList(nodes_$id)/1000]  "
	.engine_$id.info.nps configure -text "[expr $engineList(nodes_$id)/[expr 10*$engineList(time_$id)+1]]  "
	.engine_$id.info.move configure -text ""
			#"$engineList(currmovenumber_$id):$engineList(currmove_$id) "
	.engine_$id.info.depth configure -text "$engineList(depth_$id)  "
	if { $engineList(pv_$id) ne "" && $showComments} {
		.engine_$id.text insert end "[confScore $id]\t\
				$engineList(depth_$id)\t\
				$engineList(pv_$id) \([format %.2f [expr $engineList(time_$id)/100.0]] s\) \n"
		.engine_$id.text yview moveto 1.0
		.engine_$id.text yview scroll -1 units
		set engineList(lastpv_$id) $engineList(pv_$id)
		set engineList(pv_$id) ""
	}
}

proc ::engine::xboard::confScore { id {style full} } {
	variable ::engine::engineList
	set num [format %.2f [expr $engineList(score_$id)/100.0]]
	if { $engineList(absscore_$id) \
			&& $engineList(playcolor_$id) eq "black" } { set num [expr -$num] }
	if {$style eq "full"} {
		if {$num > 0} {
			set score "+$num"
		} elseif {$num == 0 } {
			set score "±$num"
		} else {
			set score $num
		}
	} else { set score $num }
	return $score
}

proc ::engine::xboard::move { id } {
	variable ::engine::engineList
	set clr [libboard::position color]
	set engineList(playcolor_$id) $clr
	set oppclr [libboard::position oppcolor]
	::engine::eng_send $id "time [expr {$::game::game(currtime_$clr)/10}]"
	::engine::eng_send $id "otim [expr {$::game::game(currtime_$oppclr)/10}]"
	set engineList(status_$id) moving
	::engine::eng_send $id "go"
}

proc ::engine::xboard::saveSettings { id file } {
	variable ::engine::engineList
	foreach name { absscore } {
		if {[catch {puts $file "set engineList($name\_$id) \{$engineList($name\_$id)\}"}]} {
			writeLog "Error writing engineList($name\_$id)."
		}
	}
}

proc ::engine::xboard::optionMenu { id top parent row } {
	variable ::engine::engineList
	checkbutton .$top.absscore -offvalue "false" -onvalue "true" -text "Absolute score" \
			-variable ::engine::engineList(absscore_$id)
	grid .$top.absscore -in .$top.$parent -row $row -column 0
}



