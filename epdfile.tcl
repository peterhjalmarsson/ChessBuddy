namespace eval epdfile {
	variable epd
	array set epd {}
}

proc ::epdfile::create { id {parent ""} } {
	variable epd
	set epd(list_$id) ""
	set epd(curr_$id) ""
	set epdfile [tk_getOpenFile]
	if {$epdfile eq ""} {return}
	set in [open $epdfile r]
	set cnt 0
	while {[gets $in line] != -1} {
		splitStr $id $cnt $line
		lappend epd(list_$id) "[expr 1+$cnt]. $line"
		incr cnt
	}
	close $in
	frame .epd_$id
	frame .epd_$id.buttons -height 20 -relief raised
	label .epd_$id.buttons.move -relief sunken -width 20
	pack .epd_$id.buttons.move -fill y -side left
	button .epd_$id.buttons.close -text " \u2A02 " -font [list Arial 12 bold] \
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
	set pos $epd(pos_$num\_$id)
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
	foreach word $str {
		set w [lsearch -inline $com $word]
		if {$w ne ""} { 
			set tag $w
			set epd($tag\_$cnt\_$id) ""
		} else { lappend epd($tag\_$cnt\_$id) $word }
	}
}


