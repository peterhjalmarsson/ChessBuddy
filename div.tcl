#remove words from a list
proc lremove { lst args } {
	foreach word $args {
		set lst [lsearch -inline -all -not -exact $lst $word]
	}
	return $lst
}

proc removeWhiteSpace {str} {
	regsub -all {[ \r\t\n]+} $str "" outstr
	return $outstr
}

proc quotedStrings { str } {
	return [regexp -all -inline {(?:[^ "]|\"[^"]*\")+} $str]
}

variable sleepend
proc sleep {time} {
	global sleepend
	set sleepend 0
	after $time set sleepend 1
	vwait sleepend
}

proc modalWindow { name { parent ""} } {
	tkwait visibility $name
	grab $name
	wm transient $name $parent
	raise $name
	tkwait window $name
}

proc renewModal {name} {
	grab $name
	raise $name
}

proc placeInParent { child parent {minsize 0} {pos end} } {
	switch [winfo class $parent] {
		Panedwindow {
			set win [$parent panes] 
			if {$pos ne "end" && $pos < [llength $win]} {
				$parent add $child -before [lindex $win $pos] -minsize $minsize
			} else {
				$parent add $child -minsize $minsize
			}
			writeLog "$child placed in panedwindow $parent"
		}
		Frame { 
			pack $child -in $parent -fill both
			writeLog "$child placed in frame $parent"
		}
	}
}

proc contrastColor { clr } {
	scan $clr "\#%2x%2x%2x" r g b
	if {  [expr $r+$g+$b] > [expr 3*0x80] } {return #000000} else {return #FFFFFF}
}

proc setButtonColor { btn clr } {
	$btn configure -bg $clr -fg [contrastColor $clr]
}
