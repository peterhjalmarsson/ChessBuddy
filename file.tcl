namespace eval epdfile {
	variable epd
	array set epd {}
}

proc ::epdfile::openEpd { id {parent ""} } {
	if {[winfo exists .epd_$id]} {return}
	variable epd
	set epd(list_$id) ""
	set epd(curr_$id) ""
	set epdfile [tk_getOpenFile -filetypes {{{EPD files} {.epd}}} -initialdir [getConfig epddir .]]
	if {$epdfile eq ""} {return}
	setConfig epddir [file dirname $epdfile]
	set in [open $epdfile r]
	set cnt 0
	while {[gets $in line] != -1} {
		if {$line eq ""} {continue}
		splitStr $id $cnt $line
		lappend epd(list_$id) "[expr 1+$cnt]. $line"
		incr cnt
	}
	close $in
	frame .epd_$id
	frame .epd_$id.buttons -height 16 -relief raised
	label .epd_$id.buttons.move -relief sunken -width 30 -font {Arial 10 bold}
	pack .epd_$id.buttons.move -fill y -side left
	button .epd_$id.buttons.close -image ::img::close -font [list Arial 10] \
			-fg red -activeforeground red -command "::epdfile::close $id"
	pack .epd_$id.buttons.close -fill y -side left -after .epd_$id.buttons.move
	grid .epd_$id.buttons -row 0 -column 0 -sticky news
	listbox .epd_$id.list -listvariable ::epdfile::epd(list_$id)\
			-yscrollcommand ".epd_$id.scrolly set"
	scrollbar .epd_$id.scrolly -command ".epd_$id.list yview" -orient v
	grid .epd_$id.list -row 1 -column 0 -sticky news
	grid .epd_$id.scrolly -row 1 -column 1 -sticky ns
	grid rowconfigure .epd_$id 0 -weight 0
	grid columnconfigure .epd_$id 0 -weight 1
	grid rowconfigure .epd_$id 1 -weight 1
	bind .epd_$id.list <ButtonRelease> "::epdfile::pickLine $id" 
	placeInParent .epd_$id $parent 100
}

proc ::epdfile::close { id } {
	variable epd
	destroy .epd_$id
	array unset epd *_$id
} 

proc ::epdfile::pickLine {id} {
	variable epd
	if { [.epd_$id.list curselection] eq "" } { return }
	set num [.epd_$id.list curselection]
	if { [catch {set pos $epd(pos_$num\_$id)} errorMessage] } {
		writeLog "error picking epd line <$errorMessage>"
		return
	} 
	if {$pos == $epd(curr_$id)} {return}
	set epd(curr_$id) $pos
	::game::new $pos 
	if { [array get epd bm_$num\_$id] ne "" } {
		.epd_$id.buttons.move configure -text "Best move: $epd(bm_$num\_$id)"
	} elseif { [array get epd am_$num\_$id] ne "" } {
		.epd_$id.buttons.move configure -text "Avoid move: $epd(am_$num\_$id)"
	} else {
		.epd_$id.buttons.move configure -text ""
	}
}

proc ::epdfile::splitStr { id cnt str } {
	variable epd
	set com {acn acs am bm c0 c1 c2 c3 c4 c5 c6 c7 c8 c9\
			ce dm draw_accept draw_claim draw_offer draw_reject\
			eco fmvn hmvc id nic noop pm pv rc resign sm tcgs\
			tcri tcsi v0 v1 v2 v3 v4 v5 v6 v7 v8 v9}
	set tag pos
	set epd(pos_$id) "fen"
	regsub -all {;} $str "" str
	set str [regexp -all -inline {(?:[^ "]|\"[^"]*\")+} $str]
	foreach word $str {
		set w [lsearch -inline $com $word]
		if {$w ne ""} { 
			set tag $w
			set epd($tag\_$cnt\_$id) ""
		} else { lappend epd($tag\_$cnt\_$id) $word }
	}
}

namespace eval pgnfile {
	variable pgnDialog
	array set pgnDialog {}
}

proc ::pgnfile::savePgn { } {
	variable pgnDialog
	toplevel .pgn
	frame .pgn.frame
	set pos 0
	foreach item {Event Site Date TimeControl Round White Black Result Termination Dir File} {
		label .pgn.frame.label$item -text $item
		grid .pgn.frame.label$item -row $pos -column 0
		entry .pgn.frame.entry$item -text $item -textvariable ::pgnfile::pgnDialog($item) \
				-width 40
		grid .pgn.frame.entry$item -row $pos -column 1
		incr pos
	}
	set pgnDialog(Event) "Buddy tournament"
	set pgnDialog(Site) "Unknown"
	set pgnDialog(Date) [clock format [clock seconds] -format %Y.%m.%d]
	set pgnDialog(TimeControl) [timeControl]
	set pgnDialog(Round) "1"
	#TODO handle human players
	set pgnDialog(White) $::engine::engineList(alias_$::game::game(player_white_id))
	set pgnDialog(Black) $::engine::engineList(alias_$::game::game(player_black_id))
	set pgnDialog(Result) [lindex $::game::endresult 0]
	set pgnDialog(Termination) [lindex $::game::endresult 1]
	set pgnDialog(Dir) [getConfig pgndir .]
	button .pgn.frame.dirbutton -text "..." -command { set ::pgnfile::pgnDialog(Dir) [tk_chooseDirectory] }
	grid .pgn.frame.dirbutton -row 9 -column 2
	button .pgn.frame.filebutton -text "..." -command { set ::pgnfile::pgnDialog(File) [tk_getOpenFile] }
	grid .pgn.frame.filebutton -row 10 -column 2
	pack .pgn.frame
	frame .pgn.buttons
	button .pgn.buttons.cancel -text Cancel -command { destroy .pgn }
	pack .pgn.buttons.cancel
	button .pgn.buttons.ok -text OK -command {
		if { $::pgnfile::pgnDialog(File) eq "" } {
			 .pgn.frame.entryFile configure -bg #FFCCCC
			 writeLog "No file name entered when saving."
			 return
		}
		set file ""
		regexp {.*\.(pgn)} $::pgnfile::pgnDialog(File) -> file
		if {$file ne "pgn"} { set ::pgnfile::pgnDialog(File) "$::pgnfile::pgnDialog(File).pgn" }
		if { [catch {::pgnfile::writeToFile} errorMessage] } {
			writeLog "<$errorMessage> saving pgn file."
		} else { destroy .pgn }
	}
	pack .pgn.buttons.ok
	pack .pgn.buttons -fill x
	modalWindow .pgn
}

proc ::pgnfile::writeToFile {} {
	variable pgnDialog
	if { [catch {set file [open "$pgnDialog(Dir)/$pgnDialog(File)" a]} res] } { 
		tk_messageBox -message "File cannot be opened. Check directory and file name." \
				-type ok -icon error
		return $res
	}
	writeLog "Start writing pgn file $pgnDialog(Dir)/$pgnDialog(File)"
	setConfig pgndir $pgnDialog(Dir)
	foreach item {Event Site Date TimeControl Round White Black Result Termination} {
		puts $file "\[$item \"$pgnDialog($item)\"\]"
	}
	foreach { item } $::game::moveList {
		puts -nonewline $file "[::game::getComment $item move] "
		if {[::game::getComment $item depth] > 0 } {
			set score [::game::getComment $item fullscore]
			if { [string first "M" $score] > -1 } { 
				set score "Mate in [string range $score 1 end]"
			}
			puts -nonewline $file "\{$score/[::game::getComment $item depth]\
					[::game::getComment $item time]s [::game::getComment $item pv]\} " 
		} else { 
			puts -nonewline $file "\{[lindex $item 2]s\} "
		}
	}
	puts $file "[lindex $::game::endresult 0]\n"
	close $file
	return 0
}

proc ::pgnfile::timeControl {} {
	if {$::game::game(time_white) ne $::game::game(time_black) } {
		return "White: [timeControlByColor white] Black: [timeControlByColor black]"
	} else {
		return [timeControlByColor white]
	}
}

proc ::pgnfile::timeControlByColor { color } {
	switch [lindex $::game::game(time_$color) 0] {
		"time" {
			set t ""
			if { [lindex $::game::game(time_$color) 1] > 0 } { set t "[lindex $::game::game(time_$color) 1]/" }
			if { [expr [lindex $::game::game(time_$color) 2] % 1000] == 0 } {set div 1000} else {set div 1000.0}
			set t "$t[expr [lindex $::game::game(time_$color) 2]/$div]"
			if { [lindex $::game::game(time_$color) 3] > 0 } {
				if { [expr [lindex $::game::game(time_$color) 2] % 1000] == 0 } {set div 1000} else {set div 1000.0}
				set t "$t+[expr [lindex $::game::game(time_$color) 3]/$div]" 
			}
			return $t
		}
		fixed {
			if { [lindex $::game::game(time_$color) 2] >= 1000 } {set div 1000} else {set div 1000.0}
			return "[expr [lindex $::game::game(time_$color) 2]/$div]/move"
		}
		depth {return "Depth [lindex $::game::game(time_$color) 1]"}
		nodes {return "[expr [lindex $::game::game(time_$color) 2]*1000] nodes/move"}
	}
}

proc ::pgnfile::loadPgn {} {
	set file [tk_getOpenFile -filetypes {{{PGN files} {.pgn}}}  -initialdir [getConfig pgnopen .]]
	setConfig pgnopen [file dirname $file]
}


