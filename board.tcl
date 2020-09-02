package require Tk

namespace eval ::board {
	variable settings
	array set settings {}
	variable color
	array set color {}
	variable font
	array set font {}
}

proc ::board::create { id parent {type full} } {
	variable settings
	set settings(size_$id) 1
	set settings(flipped_$id) false
	set settings(sqrborder_$id) 0
	set settings(framewidth_$id) 0.5 
	set settings(sqrsize_$id) 1
	set settings(name_white_$id) ""
	set settings(name_black_$id) ""
	set settings(arrow_$id) ""
	frame .boardFrame_$id
	canvas .boardFrame_$id.board -relief raised -borderwidth 2
	if { $type eq "full"} {
		set settings(full_$id) true
		foreach name {top bottom} {
			frame .boardFrame_$id.$name
			label .boardFrame_$id.$name.think -width 3 -bg white
			grid .boardFrame_$id.$name.think -row 0 -column 0 -sticky nws
			grid columnconfigure .boardFrame_$id.$name 0 -weight 0
			label .boardFrame_$id.$name.name -text " "
			grid .boardFrame_$id.$name.name -row 0 -column 1 -sticky news
			grid columnconfigure .boardFrame_$id.$name 1 -weight 1
			label .boardFrame_$id.$name.time -width 6 -text "0:00" -bg white -anchor e
			grid .boardFrame_$id.$name.time -row 0 -column 2 -sticky nes
			grid columnconfigure .boardFrame_$id.$name 2 -weight 0
		}
		pack .boardFrame_$id.top -fill x 
		pack .boardFrame_$id.bottom  -fill x
		pack .boardFrame_$id.board -after .boardFrame_$id.top
	} else {
		set settings(full_$id) false
		pack .boardFrame_$id.board
	}	
	placeInParent .boardFrame_$id $parent
	createSquares $id
	createCoord $id
	createPieces $id
	
	resize $id
	writeLog "board $id created"
	return .boardFrame_$id.board
}

proc ::board::createArrow {id num {clr red}} {
	if {[.boardFrame_$id.board gettags "arrow_$id\_$num"] eq "" } {
		.boardFrame_$id.board create line 0 0 0 0 -fill $clr \
						-tags [list "arrow" "arrow_$id\_$num"] -state hidden -arrow last
		resize main true
	}
}

proc ::board::destroyArrow {id num} {
	.boardFrame_$id.board delete "arrow_$id\_$num"
}

proc ::board::loadSettings {} {
	variable font
	variable color
	if { [catch { source "./data/board.dat"} ] } {
		writeLog "Loading ./data/board.dat failed. Using backup ./data/board.bak"
		source "./data/board.bak"
	}
}

proc ::board::saveSettings {} {
	variable font
	variable color
	#store in temp file, if program crashes it will not erase anything
	set file [open "./data/board.tmp" w]
	foreach name [array names color] {
		puts $file "set color($name) \"$color($name)\""
	}
	foreach name [array names font] {
		puts $file "set font($name) \"$font($name)\""
	}
	close $file
	#don't save an empty file
	if {[file size "./data/board.tmp"] == 0 } {
		file delete "./data/board.tmp"
		return 
	}
	# safety copy
	if { [file exists "./data/board.dat"] &&  [file size "./data/board.dat"] > 0 } {
		file rename -force "./data/board.dat" "./data/board.bak"
	}
	#finally, rename new file
	file rename -force "./data/board.tmp" "./data/board.dat"
}

#proc ::board::setColor { arg } {
	#variable settings
	#foreach name value [$argv] {
		#set settings($name) $value
	#}
#}

#proc ::board::setFont { { name Arial } { fill false } } {
	#variable font
	#set font(fontpiece) $name
	#set font(fill) $fill
#}

proc ::board::pickFont { id type } {
	variable font
	set sel "*"
    #selction for piece font
	#if {$type eq "piece"} {set sel "CB *"}
	set f [::fontdialog::fontDialog $font(font$type) .bOpt_$id $sel]
	if {$f ne ""} {
		set font(font$type) $f
		resize $id true
	}
}

proc ::board::pickColor { id type } {
	variable color
	set c [tk_chooseColor -initialcolor $color($type)]
	if {$c ne ""} {
		set color($type) $c
		switch $type {
			lightsqrcolor { 
				.boardFrame_$id.board itemconfigure c_light -fill $c 
				.bOpt_$id.main.light configure -bg $c -fg [contrastColor $c]
			}
			darksqrcolor { 
				.boardFrame_$id.board itemconfigure c_dark -fill $color($type) 
				.bOpt_$id.main.dark configure -bg $c -fg [contrastColor $c]
			}
			border { 
				.boardFrame_$id.board itemconfigure frame -outline $color($type) 
				.bOpt_$id.main.border configure -bg $c -fg [contrastColor $c]
			}
			frontwhite { 
				.boardFrame_$id.board itemconfigure frontpiecewhite -fill $color($type) 
				.bOpt_$id.main.w1 configure -bg $c -fg [contrastColor $c]
			}
			frontblack { 
				.boardFrame_$id.board itemconfigure frontpieceblack -fill $color($type) 
				.bOpt_$id.main.b1 configure -bg $c -fg [contrastColor $c]
			}
			backwhite { 
				.boardFrame_$id.board itemconfigure backpiecewhite -fill $color($type) 
				.bOpt_$id.main.w2 configure -bg $c -fg [contrastColor $c]
			}
			backblack { 
				.boardFrame_$id.board itemconfigure backpieceblack -fill $color($type) 
				.bOpt_$id.main.b2 configure -bg $c -fg [contrastColor $c]
			}
			highlighted {
				.bOpt_$id.main.high configure -bg $c -fg [contrastColor $c]
			}
		}	
		::board::resize $id true
	}
}

proc ::board::revert {id} {
	variable color
	loadSettings
	.boardFrame_$id.board itemconfigure c_light -fill $color(lightsqrcolor)
	.boardFrame_$id.board itemconfigure c_dark -fill $color(darksqrcolor)
	.boardFrame_$id.board itemconfigure frame -outline $color(border)
	.boardFrame_$id.board itemconfigure frontpiecewhite -fill $color(frontwhite)
	.boardFrame_$id.board itemconfigure frontpieceblack -fill $color(frontblack)
	.boardFrame_$id.board itemconfigure backpiecewhite -fill $color(backwhite)
	.boardFrame_$id.board itemconfigure backpieceblack -fill $color(backblack) 
	resize $id true
}

proc ::board::boardOption { id  {parent "" } } {
	variable font
	variable color
	toplevel .bOpt_$id
	wm title .bOpt_$id "Board options"
	frame .bOpt_$id.main
	button .bOpt_$id.main.fontp -text "Piece font" -command "::board::pickFont $id piece"
	grid .bOpt_$id.main.fontp -row 0 -column 0 -sticky news
	checkbutton .bOpt_$id.main.fill -text "Fill font" -offvalue "false" -onvalue "true" \
			-variable ::board::font(fill) \
			-command "::board::fillFont $id"
	grid .bOpt_$id.main.fill -row 0 -column 1 -sticky news
	tk_optionMenu .bOpt_$id.main.style ::board::font(style) "Style 1" "Style 2" "Style 3"
	grid .bOpt_$id.main.style -row 0 -column 2 -sticky news
	button .bOpt_$id.main.w1 -text "White color 1" -command "::board::pickColor $id frontwhite"
	grid .bOpt_$id.main.w1 -row 1 -column 0 -sticky news
	button .bOpt_$id.main.w2 -text "White color 2" -command "::board::pickColor $id backwhite"
	grid .bOpt_$id.main.w2 -row 1 -column 1 -sticky news
	button .bOpt_$id.main.wf -text "Flip white color" -command "::board::flipColor $id white"
	grid .bOpt_$id.main.wf -row 1 -column 2 -sticky news
	button .bOpt_$id.main.b1 -text "Black color 1" -command "::board::pickColor $id frontblack"
	grid .bOpt_$id.main.b1 -row 2 -column 0 -sticky news
	button .bOpt_$id.main.b2 -text "Black color 2" -command "::board::pickColor $id backblack"
	grid .bOpt_$id.main.b2 -row 2 -column 1 -sticky news
	button .bOpt_$id.main.bf -text "Flip black color" -command "::board::flipColor $id black"
	grid .bOpt_$id.main.bf -row 2 -column 2 -sticky news
	button .bOpt_$id.main.fontn -text "Name font" -command "::board::pickFont $id name"
	grid .bOpt_$id.main.fontn -row 3 -column 0 -sticky news
	button .bOpt_$id.main.fontth -text "Timeglass font" -command "::board::pickFont $id think"
	grid .bOpt_$id.main.fontth -row 3 -column 1 -sticky news
	button .bOpt_$id.main.fontt -text "Time font" -command "::board::pickFont $id time"
	grid .bOpt_$id.main.fontt -row 3 -column 2 -sticky news
	button .bOpt_$id.main.dark -text "Dark square" -command "::board::pickColor $id darksqrcolor"
	grid .bOpt_$id.main.dark -row 4 -column 0 -sticky news
	button .bOpt_$id.main.light -text "Light square" -command "::board::pickColor $id lightsqrcolor"
	grid .bOpt_$id.main.light -row 4 -column 1 -sticky news
	button .bOpt_$id.main.border -text "Frame" -command "::board::pickColor $id border"
	grid .bOpt_$id.main.border -row 4 -column 2 -sticky news
	button .bOpt_$id.main.high -text "Highlighted" -command "::board::pickColor $id highlighted"
	grid .bOpt_$id.main.high -row 5 -column 0 -sticky news
	button .bOpt_$id.main.rev -text Revert -command "::board::revert $id ; ::board::optionButtonColors $id"
	grid .bOpt_$id.main.rev -row 5 -column 2 -sticky news
	button .bOpt_$id.main.ok -text OK -command "destroy .bOpt_$id"
	grid .bOpt_$id.main.ok -row 6 -column 1 -sticky news
	pack .bOpt_$id.main
	trace add variable ::board::font(style) write "::board::changeStyle $id"
	optionButtonColors $id
	modalWindow .bOpt_$id $parent
	saveSettings
}

proc ::board::optionButtonColors { id } {
	variable color
	setButtonColor .bOpt_$id.main.w1 $color(frontwhite)
	setButtonColor .bOpt_$id.main.w2 $color(backwhite)
	setButtonColor .bOpt_$id.main.b1 $color(frontblack)
	setButtonColor .bOpt_$id.main.b2 $color(backblack)
	setButtonColor .bOpt_$id.main.dark $color(darksqrcolor)
	setButtonColor .bOpt_$id.main.light $color(lightsqrcolor)
	setButtonColor .bOpt_$id.main.border $color(border)
	setButtonColor .bOpt_$id.main.high $color(highlighted)
}

proc ::board::fillFont { id } {
	variable font
	puts $::board::font(fill)
	.boardFrame_$id.board delete piece
	createPieces $id
	::board::setBoard $id 
	::board::resize $id true
}

proc ::board::flipColor { id col } {
	variable color 
	set temp $color(front$col)
	set color(front$col) $color(back$col)
	set color(back$col) $temp
	.boardFrame_$id.board itemconfigure backpiece$col -fill $color(back$col)
	.boardFrame_$id.board itemconfigure frontpiece$col -fill $color(front$col)
}

proc ::board::changeStyle {id args} {
	variable font
	set font(backblack) "0x265A"
    #"0xE254"
	set font(backwhite) "0x265A"
    #"0xE254"
	switch $font(style) {
		"Style 1" {
			set font(frontblack) "0x2654"
			set font(frontwhite) "0x2654"
		}
		"Style 2" {
			set font(frontblack) "0x265A"
			set font(frontwhite) "0x2654"
		}
		"Style 3" {
			set font(frontblack) "0x265A"
			set font(frontwhite) "0x265A"
		}
	}
	setBoard $id
	::board::resize $id true
}

proc ::board::createSquares { id } {
	variable color
	.boardFrame_$id.board create rectangle 0 0 1 1 \
			-outline $color(border) -tags "frame"
	variable settings
	for {set i 0} {$i<64} {incr i} {
			if { [expr { 1 & [expr {$i/8 + $i%8} ] } ] == 0 } {
				set clr $color(darksqrcolor)
				set clrName c_dark
			} else {
				set clr $color(lightsqrcolor)
				set clrName c_light
			}
			.boardFrame_$id.board create rectangle 0 0 1 1 -fill $clr \
					-tags "sqr_$i $clrName"
	}
}

proc ::board::createCoord { id } {
	variable color
	for {set i 0} {$i<8} {incr i} {
		.boardFrame_$id.board create text 0 0 -tags "coord_num_$i"
		.boardFrame_$id.board create text 0 0 -tags "coord_txt_$i" \
				-text [string index "ABCDEFGH" $i]
	}
	.boardFrame_$id.board create text 0 0 -width 1 -fill $color(backblack) \
			-tags "bpiece bpiece_b"
	.boardFrame_$id.board create text 0 0 -width 1 -fill $color(backwhite) \
			-tags "wpiece wpiece_b"
	.boardFrame_$id.board create text 0 0 -width 1 -fill $color(frontblack) \
			-tags "bpiece bpiece_t"
	.boardFrame_$id.board create text 0 0 -width 1 -fill $color(frontwhite) \
			-tags "wpiece wpiece_t"
}

proc ::board::createPieces { id } {
	variable color
	variable font
	for {set i 0} {$i<16} {incr i} {
		if {$font(fill) } {
			.boardFrame_$id.board create text 0 0 -text "" \
					-fill $color(backwhite) \
					-tags "backpiecewhite backpiecewhite_$i piece piecewhite_$i p_s_0"
			.boardFrame_$id.board create text 0 0 -text "" \
					-fill $color(backblack) \
					-tags "backpieceblack backpieceblack_$i piece pieceblack_$i p_s_63"
		}
		.boardFrame_$id.board create text 0 0 -text "" \
				-fill $color(frontwhite) \
				-tags "frontpiecewhite frontpiecewhite_$i piece piecewhite_$i p_s_0"
		.boardFrame_$id.board create text 0 0 -text "" \
				-fill $color(frontblack) \
				-tags "frontpieceblack frontpieceblack_$i piece pieceblack_$i p_s_63"
	}
	.boardFrame_$id.board lower p_back
}

proc ::board::setNames { id } {
	variable settings
	if {$settings(flipped_$id)} {
		set white top
		set black bottom
	} else { 
		set black top
		set white bottom
	}
	foreach item {think name time} {
		.boardFrame_$id.$white.$item configure -textvariable \
				::board::settings($item\_white_$id)
		.boardFrame_$id.$black.$item configure -textvariable \
				::board::settings($item\_black_$id)
	}
}

proc ::board::boardNames { id fontSize topfg topbg botfg botbg} {
	variable font
	.boardFrame_$id.top.think configure \
			-font [lreplace $font(fontthink) 1 1 $fontSize]
	.boardFrame_$id.top.name configure \
			-font [lreplace $font(fontname) 1 1 $fontSize] -fg $topfg -bg $topbg
	.boardFrame_$id.top.time configure \
			-font [lreplace $font(fonttime) 1 1 $fontSize]
	.boardFrame_$id.bottom.think configure \
			-font [lreplace $font(fontthink) 1 1 $fontSize]
	.boardFrame_$id.bottom.name configure \
			-font [lreplace $font(fontname) 1 1 $fontSize] -fg $botfg -bg $botbg
	.boardFrame_$id.bottom.time configure \
			-font [lreplace $font(fonttime) 1 1 $fontSize]
}

proc ::board::resize { id {force false} } {
	variable settings
	variable font
	set w [winfo width .boardFrame_$id]
	set h [winfo height .boardFrame_$id]
	if { [winfo exists .engine_5.boardframe] } {
		writeLog ".engine_5.boardframe [winfo width .engine_5.boardframe]x[winfo width .engine_5.boardframe]"
	}
	if {$settings(full_$id)} { set h [expr { 7*$h/8} ] }
	if { $w < $h } { set size $w } else { set size $h }
	writeLog "board $id size set to $size ($w\x$h)"
	if { $settings(size_$id) != $size || $force } {
		if { [winfo exists .boardFrame_$id.top] } {
			.boardFrame_$id.top configure -width $size
			.boardFrame_$id.bottom configure -width $size
			setNames $id
		}
		.boardFrame_$id.board configure -width $size -height $size
		set settings(size_$id) $size	
		set sqrsize [expr int($settings(size_$id) / [expr {8 + 2*$settings(framewidth_$id)} ] ) ]
		set settings(sqrsize_$id) $sqrsize
		#font 3/4 of square
		set fontsize [expr {3 * $sqrsize / 4}]
		set framew [expr int(3+$settings(framewidth_$id)*$sqrsize) ]
		set topleft [expr { $framew/2} ] 
		set bottomright [expr {$topleft + $framew + 8 * $sqrsize } ] 
		.boardFrame_$id.board coords frame $topleft $topleft $bottomright $bottomright
		.boardFrame_$id.board itemconfigure frame -width [expr 2*$framew]
		if {$settings(flipped_$id)} {
			if { [winfo exists .boardFrame_$id.top] } {
				boardNames  $id [expr {$framew/2} ] black white white black
			}
			.boardFrame_$id.board coords wpiece_t $bottomright [expr $topleft+$framew/2]
			.boardFrame_$id.board coords wpiece_b $bottomright [expr $topleft+$framew/2]
			.boardFrame_$id.board itemconfigure wpiece -anchor n \
					-font [lreplace $font(fontpiece) 1 1 [expr {2*$framew/3} ] ]
			.boardFrame_$id.board coords bpiece_t $bottomright [expr $bottomright-$framew/2]
			.boardFrame_$id.board coords bpiece_b $bottomright [expr $bottomright-$framew/2]
			.boardFrame_$id.board itemconfigure bpiece -anchor s \
					-font [lreplace $font(fontpiece) 1 1 [expr {2*$framew/3} ] ]
		} else {
			if { [winfo exists .boardFrame_$id.top] } {
				boardNames  $id [expr {$framew/2} ] white black black white
			}
			.boardFrame_$id.board coords bpiece_t $bottomright [expr $topleft+$framew/2]
			.boardFrame_$id.board coords bpiece_b $bottomright [expr $topleft+$framew/2]
			.boardFrame_$id.board itemconfigure bpiece -anchor n \
					-font [lreplace $font(fontpiece) 1 1 [expr {2*$framew/3} ] ]
			.boardFrame_$id.board coords wpiece_t $bottomright [expr $bottomright-$framew/2]
			.boardFrame_$id.board coords wpiece_b $bottomright [expr $bottomright-$framew/2]
			.boardFrame_$id.board itemconfigure wpiece -anchor s \
					-font [lreplace $font(fontpiece) 1 1 [expr {2*$framew/3} ] ]
		}
		for {set i 0} {$i<8} {incr i} {
			if {$settings(flipped_$id)} {
				set num "12345678"
				set txt "HGFEDCBA"
			} else {
				set num "87654321"
				set txt "ABCDEFGH"
			}
			.boardFrame_$id.board coords coord_txt_$i [expr {$sqrsize/2+ $i*$sqrsize+ $framew} ] $bottomright
			.boardFrame_$id.board itemconfigure coord_txt_$i -text [string index $txt $i] -font [list Arial [expr {$framew/2} ] bold]
			.boardFrame_$id.board coords coord_num_$i $topleft [expr {$sqrsize/2+ $i*$sqrsize+ $framew} ] 
			.boardFrame_$id.board itemconfigure coord_num_$i -text [string index $num $i] -font [list Arial [expr {$framew/2} ] bold]
		}
		for {set i 0} {$i<64} {incr i} {
			if {$settings(flipped_$id)} {
				set x [expr {7-$i%8} ]
				set y [expr {$i/8} ]
			} else {
				set x [expr {$i%8} ]
				set y [expr {7-$i/8} ]
			}
			.boardFrame_$id.board coords sqr_$i [expr { $x*$sqrsize +$framew } ] \
					[expr { $y*$sqrsize +$framew } ] \
					[expr { $x*$sqrsize +$framew +$sqrsize} ] \
					[expr { $y*$sqrsize +$framew +$sqrsize} ]
		}
		set newfont [lreplace $font(fontpiece) 1 1 $fontsize]
		.boardFrame_$id.board itemconfigure "piece" -font $newfont
		foreach tag [.boardFrame_$id.board find withtag piece] {
			if { [.boardFrame_$id.board itemcget $tag -text]!="" } { 
				placePiece $id $tag
			}
		}
		set aw [expr $settings(sqrsize_$id)/6]
		.boardFrame_$id.board itemconfigure "arrow" -width $aw -arrowshape [list [expr $aw*2] [expr $aw*3] [expr $aw/2]]
		foreach item [array names settings arrow_$id\_*] {
			if { $settings($item) ne "" } { 
				set sc [.boardFrame_$id.board coords sqr_[lindex $settings($item) 0] ]
				set coo [list [expr [expr [lindex $sc 0] + [lindex $sc 2]] / 2] \
						[expr [expr [lindex $sc 1]+[lindex $sc 3]]/2] ]
				set sc [.boardFrame_$id.board coords sqr_[lindex $settings($item) 1] ]
				lappend coo [expr [expr [lindex $sc 0] + [lindex $sc 2]] / 2] 
				lappend coo [expr [expr [lindex $sc 1] + [lindex $sc 3]] / 2] 
				.boardFrame_$id.board coords $item $coo
			}
		}
	}
}

#to use for arrow
proc ::board::uciToCoord { move } {
	set p [string index $move 0]
	set p [string first $p "abcdefgh"]
	set from [expr $p+[string index $move 1]*8-8]
	set p [string index $move 2]
	set p [string first $p "abcdefgh"]
	set to [expr $p+[string index $move 3]*8-8]
	return [list $from $to]
}

proc ::board::placePiece { id tag } {
	variable settings
	set pos [lsearch -inline [.boardFrame_$id.board gettags $tag] p_s_*]
	set pos [string replace $pos 0 3 ]
	set x [expr {7-$pos%8} ]
	set y [expr {$pos/8} ]
	if {!$settings(flipped_$id)} {
		set x [expr {$pos%8} ]
		set y [expr {7-$y} ]
	}
	set framew [expr int(3+$settings(framewidth_$id)*$settings(sqrsize_$id)) ]
	.boardFrame_$id.board coords $tag \
			[expr { $x*$settings(sqrsize_$id) +$framew +$settings(sqrsize_$id)/2} ] \
			[expr { $y*$settings(sqrsize_$id) +$framew +$settings(sqrsize_$id)/2} ] 
}

proc ::board::setBoard { id {pos ""} } {
	variable settings
	variable font
	if {$pos eq ""} {set pos [libboard::position single]}
	set w 0
	set b 0
	for {set i 0} {$i < 64} {incr i} {
		set p [string index $pos $i] 
		if { $p == "-" } { continue }
		if { [string is lower $p] } {
			set tagList [.boardFrame_$id.board gettags "pieceblack_$b"]
			.boardFrame_$id.board dtag pieceblack_$b [lsearch -inline $tagList p_s_*]
			.boardFrame_$id.board addtag "p_s_$i" withtag "pieceblack_$b"
			set p [string first $p "kqrbnp" ]
			if {$font(fill) } {
				.boardFrame_$id.board itemconfigure frontpieceblack_$b -text [format "%c" [expr { $font(frontblack) + $p } ] ]
				.boardFrame_$id.board itemconfigure backpieceblack_$b -text [format "%c" [expr { $font(backblack) + $p } ] ]	
			} else {
				.boardFrame_$id.board itemconfigure pieceblack_$b -text [format "%c" [expr { $font(nofillblack) + $p } ] ]		
			}
			incr b
		} else {
			set tagList [.boardFrame_$id.board gettags "piecewhite_$w"]
			.boardFrame_$id.board dtag piecewhite_$w [lsearch -inline $tagList p_s_*]
			.boardFrame_$id.board addtag "p_s_$i" withtag "piecewhite_$w"
			set p [string first $p "KQRBNP"]
			if {$font(fill) } {
				.boardFrame_$id.board itemconfigure frontpiecewhite_$w -text [format "%c" [expr { $font(frontwhite) + $p } ] ]
				.boardFrame_$id.board itemconfigure backpiecewhite_$w -text [format "%c" [expr { $font(backwhite) + $p } ] ]	
			} else {
				.boardFrame_$id.board itemconfigure piecewhite_$w -text [format "%c" [expr { $font(nofillwhite) + $p } ] ]	
			}
			incr w
		}
	}
	while { $w < 16 } {
		.boardFrame_$id.board itemconfigure piecewhite_$w -text ""
		incr w
	}
	while { $b < 16 } {
		.boardFrame_$id.board itemconfigure pieceblack_$b -text ""
		incr b
	}
	foreach tag [.boardFrame_$id.board find withtag piece] {
		if { [.boardFrame_$id.board itemcget $tag -text]!="" } { 
			placePiece $id $tag
		}
	}
	set tt ""
	set bt ""
	if {$settings(full_$id)} {
		foreach l [libboard::position pieces white] {
			set tt "$tt[format "%c" [expr $l+$font(frontwhite)]] "
			set bt "$bt[format "%c" [expr $l+$font(backwhite)]] "
		}
	}
	.boardFrame_$id.board itemconfigure wpiece_t -text $tt
	.boardFrame_$id.board itemconfigure wpiece_b -text $bt
	set tt ""
	set bt ""
	if {$settings(full_$id)} {
		foreach l [libboard::position pieces black] {
			set tt "$tt[format "%c" [expr $l+$font(frontblack)]] "
			set bt "$bt[format "%c" [expr $l+$font(backblack)]] "
		}
	}
	.boardFrame_$id.board itemconfigure bpiece_t -text $tt
	.boardFrame_$id.board itemconfigure bpiece_b -text $bt
	highlightSquare $id none
}

proc ::board::setArrow {id num move} {
	variable settings
	if {$move ne ""} {
		set c [uciToCoord $move]
		set settings(arrow_$id\_$num) $c
		set sc [.boardFrame_$id.board coords sqr_[lindex $c 0] ]
		set coo [list [expr [expr [lindex $sc 0] + [lindex $sc 2]]/2] \
				[expr [expr [lindex $sc 1]+[lindex $sc 3]]/2] ]
		set sc [.boardFrame_$id.board coords sqr_[lindex $c 1] ]
		lappend coo [expr [expr [lindex $sc 0] + [lindex $sc 2]]/2] 
		lappend coo [expr [expr [lindex $sc 1] + [lindex $sc 3]]/2] 
		.boardFrame_$id.board coords arrow_$id\_$num $coo
		.boardFrame_$id.board itemconfigure arrow_$id\_$num -state normal
		.boardFrame_$id.board lower arrow_$id\_$num
		set p [.boardFrame_$id.board gettags [.boardFrame_$id.board \
				find closest [lindex $coo 0] [lindex $coo 1]]]
		set p [lsearch -inline $p piece*_*]
		.boardFrame_$id.board raise arrow_$id\_$num
		.boardFrame_$id.board raise $p 
	} else {
		set settings(arrow_$id\_$num) ""
		.boardFrame_$id.board itemconfigure arrow_$id\_$num -state hidden
	}
}

proc ::board::selectPiece { id x y { color * } } {
	set returnVal ""
	set h ""
	set p [.boardFrame_$id.board gettags [.boardFrame_$id.board find closest $x $y]]
	set p [lsearch -inline $p piece$color\_*]
	if { $p != "" } {
		.boardFrame_$id.board dtag "selected" 
		.boardFrame_$id.board addtag "selected" withtag $p 
		.boardFrame_$id.board raise "selected"
		set s [lsearch -inline [.boardFrame_$id.board gettags $p] p_s_*]
		regexp {p\_s\_(.*)} $s -> x
		if {$x ne ""} {
            writeLog "canreach sqr <$x>"
			set h [libboard::canreachsquare $x]
		}
	} else {
		set p [.boardFrame_$id.board gettags [.boardFrame_$id.board find closest $x $y 0 "piece"]]
		if { [lsearch $p "highlighted"] != -1 } {
			set pos [string range [lsearch -inline $p sqr_*] 4 5]
			set sqrTag [lsearch -inline [.boardFrame_$id.board gettags "selected"] p_s_*]
			set startSqr [string range $sqrTag 4 5]
			.boardFrame_$id.board dtag "selected" $sqrTag
			set sqrTag "p_s_$pos"
			.boardFrame_$id.board dtag "selected"
			set returnVal "$startSqr $pos"
		}
	}
    writeLog "selected piece $p"
	highlightSquare $id $h
	return $returnVal
}

proc ::board::movePiece { id x y } {
	foreach p [.boardFrame_$id.board find withtag "selected" ] {
		.boardFrame_$id.board coords $p $x $y
	}
}

proc ::board::targetSquare { id x y {targets ""} } {
	variable settings
	#puts release
	set s [.boardFrame_$id.board gettags [.boardFrame_$id.board find closest $x $y 0 "piece"]]
	set s [lsearch -inline $s sqr_*]
	set returnPiece false
	if { $s == "" } { set returnPiece true }
	set pos [string range $s 4 5]
	set sqrTag [lsearch -inline [.boardFrame_$id.board gettags "selected"] p_s_*]
	set startSqr [string range $sqrTag 4 5]
	if { $targets == "highlighted" && [lsearch [.boardFrame_$id.board gettags $s] "highlighted"] ==-1 } {
		set returnPiece true 
	} elseif { $targets != "" && [lsearch $targets $pos] == "" } { set returnPiece true }
	if { !$returnPiece } {
		.boardFrame_$id.board dtag "selected" $sqrTag
		set sqrTag "p_s_$pos"
		.boardFrame_$id.board addtag $sqrTag withtag "selected"
	}
	foreach p [.boardFrame_$id.board find withtag "selected"] {	
		placePiece $id $p
	}
	if { $pos != $startSqr } { .boardFrame_$id.board dtag "selected" }
	if {!$returnPiece} { 
		highlightSquare $id 
		return "$startSqr $pos" 
	}
}

proc ::board::highlightSquare { id { squares "" } } {
	variable color
	foreach s [.boardFrame_$id.board find withtag "highlighted"] {
		if { [lsearch [.boardFrame_$id.board gettags $s] c_dark] == -1 } {
			.boardFrame_$id.board itemconfigure $s -fill $color(lightsqrcolor)
		} else {
			.boardFrame_$id.board itemconfigure $s -fill $color(darksqrcolor)
		}
	}
	if {$squares eq "none"} {return}
	.boardFrame_$id.board dtag "highlighted"
	foreach s $squares {
		.boardFrame_$id.board addtag "highlighted" withtag sqr_$s
		set clr [mixColor  [.boardFrame_$id.board itemcget sqr_$s -fill] $color(highlighted)]
		.boardFrame_$id.board itemconfigure sqr_$s -fill $clr
	}
}

proc ::board::mixColor { color1 color2 } {
	scan $color1 "\#%2x%2x%2x" r1 g1 b1
	scan $color2 "\#%2x%2x%2x" r2 g2 b2
	set red [expr { [expr {$r1 + $r2}] / 2}]
	set green [expr { [expr {$g1 + $g2}] / 2}]
	set blue [expr { [expr {$b1 + $b2}] / 2}]
	return  [format #%02X%02X%02X $red $green $blue]
}

#source start.txt

