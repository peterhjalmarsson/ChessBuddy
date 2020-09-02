namespace eval graph {
	variable plotValue
	variable plotCount
	variable active false
}

proc initgraph {} {}

proc menugraph {} {
	.mainmenu.menuWindows add checkbutton -label "Graph" -underline 0 \
			-variable ::graph::active -offvalue false -onvalue true \
			-command {::graph::setActive}
}

proc ::graph::setActive {} {
	variable active
	if {$active} {
		createGraph main .pndl
	} else {
		closeGraph main 
	}
}

proc ::graph::createGraph { id parent } {
	variable plotValue
	set plotValue Score
	frame .graph_$id
	frame .graph_$id.buttons
	tk_optionMenu .graph_$id.buttons.value ::graph::plotValue Score Depth Seldepth Time
	pack .graph_$id.buttons.value -side left
	button .graph_$id.buttons.close -image ::img::close -command "::graph::closeGraph $id"
	pack .graph_$id.buttons.close -side left
	pack .graph_$id.buttons -fill x
	canvas .graph_$id.canvas -bg white
	pack .graph_$id.canvas -fill both
	placeInParent .graph_$id $parent
	trace add variable ::graph::plotValue write "::graph::renew $id"
	.graph_$id.canvas create rectangle 0 0 0 0 -outline black -tags frame
	.graph_$id.canvas create line 0 0 0 0 -fill #7070FF -width 3 -tags linew
	.graph_$id.canvas create line 0 0 0 0 -fill #800000 -width 3 -tags lineb
	addCommand repaint "::graph::renew $id"
	addCommand update "::graph::renew $id"
	update idletasks
	.pndl sash place 0 400 400
}

proc ::graph::closeGraph {id} {
	removeCommand repaint "::graph::renew $id"
	removeCommand update "::graph::renew $id"
	trace remove variable ::graph::plotValue write "::graph::renew $id"
	update idletasks
	destroy .graph_$id
	
}

proc ::graph::setLimit {} {
	variable plotCount
	variable plotValue
	switch $plotValue {
		Score {
			set min -1
			set maxlimit 5
		}
		Depth {
			set min 0
			set maxlimit 40
		}
		Seldepth {
			set min 0
			set maxlimit 200
		}
		Time {
			set min 0
			set maxlimit 1000000
		}
	}
	set max 1
	set plotCount 1
	foreach item $::game::moveList {
		if { [expr [lindex $item 0]&1] == 1 } {set pos false} else {set pos true}
		incr plotCount
		set num [getValue $item]
		if {$plotValue eq "Score" && $pos} {set num [expr -$num]}
		if {$num > $max} {set max $num}
		if {$num < $min} {set min $num}
	}
	if {$max > $maxlimit} { set max $maxlimit }
	if {$min < [expr -$maxlimit]} { set min [expr -$maxlimit] }
	set max [expr $max*1.1]
	set min [expr $min*1.1]
	return "$min $max"		
}

proc ::graph::getValue { item } {
	variable plotValue
	set num 0
	switch $plotValue {
		Score {set num [::game::getComment $item plainscore]}
		Depth {set num [::game::getComment $item depth]}
		Seldepth {set num [::game::getComment $item seldepth]}
		Time {set num [::game::getComment $item time]}
	}
	return $num
}

proc ::graph::renew { id args } {
	if { [winfo exists .graph_$id] == 0 } {return}
	variable plotCount
	variable plotValue
	set w [winfo width .graph_$id]
	set h [expr [winfo height .graph_$id] - [winfo height .graph_$id.buttons]]
	.graph_$id.canvas configure -width $w -height $h
	set top [expr $h/15]
	set bot [expr 14*$h/15]
	set left [expr $w/15]
	set right [expr 14*$w/15]
	.graph_$id.canvas coords frame $left $top $right $bot
	set limits [setLimit]
	# 100* to avoid problem with strange scaling on small canvas
	# (when fractions of "step" matters)
	set step [expr 100*[expr $right-$left]/$plotCount]
	set winh [expr $bot -$top]
	setGrid $id $limits $top $bot $left $right
	set start [translateY 0 {*}$limits $winh $top]
	set coordListW [list $left $start $left $start]
	set coordListB [list $left $start $left $start]
	foreach item $::game::moveList {
		if { [expr [lindex $item 0]&1] == 1 } {set pos false} else {set pos true}
		set num [getValue $item]
		if {$pos && $plotValue eq "Score"} {set num [expr -$num]}
		set num [translateY $num {*}$limits $winh $top]
		set dist [expr $step*[lindex $item 0]/100+$left]
		if {$pos} {
			lappend coordListB $dist $num
		} else {	
			lappend coordListW $dist $num
		}
	}	
	.graph_$id.canvas coords linew $coordListW
	.graph_$id.canvas coords lineb $coordListB
}

proc ::graph::translateY { value min max winh offset} {
	return [expr $offset + $winh - [expr $value -$min]*$winh/[expr $max-$min]]
}

proc ::getScale { start min max } {
	set top $start
	foreach val { 100 50 20 10 5 2 1 0.5 0.2 0.1 } {
		if {$val < $start } {break}
		if { $max > $val } {set top $val ; break }
		if { [expr -$min] > $val } {set top $val ; break }
	}
	return $top
}

proc ::graph::setGrid {id limits top bot start end} {
	variable plotCount
	.graph_$id.canvas delete sctext scline
	set winh [expr $bot -$top]
	set sz [expr $winh/20]
	set step [getScale 0.5 [expr [lindex $limits 0]/3] [expr [lindex $limits 1]/3]]
	for {set v 0.0} {$v <= [lindex $limits 1] } { set v [expr $v + $step] } {
		set h [translateY $v {*}$limits $winh $top]
		.graph_$id.canvas create text 0 $h -font [list Arial $sz] \
				-text $v -anchor w -tags sctext
		.graph_$id.canvas create line $start $h $end $h -fill black -tags scline
	}
	for {set v [expr -$step]} {$v >= [lindex $limits 0] } { set v [expr $v - $step] } {
		set h [translateY $v {*}$limits $winh $top]
		.graph_$id.canvas create text 0 $h -font [list Arial $sz] \
				-text $v -anchor w -tags sctext
		.graph_$id.canvas create line $start $h $end $h -fill black -tags scline
	}
	set dist [expr 100*[expr $end - $start]/$plotCount]
	set step [getScale 1 0 [expr $plotCount/6]]
	for { set i $step } { [expr $i*2-1] <= $plotCount } { incr i $step } {
		set w [expr $dist*[expr $i*2-1]/100+$start]
		.graph_$id.canvas create text $w 0 -font [list Arial $sz] \
				-text $i -anchor n -tags sctext
		.graph_$id.canvas create line $w $top $w $bot -fill black -tags scline
	}
}

	
