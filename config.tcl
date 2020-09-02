variable globalconf
array set globalconf {}
variable log ""
variable command
array set command {
	repaint ""
	"update" ""
	create ""
	savefile ""
}

variable errorLine "\"line [dict get [info frame 2] line]\""

proc initLog {} {
	global log
	global globalconf
	if {$log ne ""} {close $log}
	if { $globalconf(log) } {
		set log [open "./log/main.log" w]
	}
}
proc closeLog {} {
	global log
	global globalconf
    writeLog "Log is closing."
	if { $globalconf(log) && $log ne ""} {close $log}
	set log ""
}

proc changeLog {} {
	global globalconf
	if { $globalconf(log) } {initLog} else {closeLog}
}

proc writeLog { txt } {	
	global log
	if {$log ne "" } {
		set tracelvl ""
		for {set lvl [expr [info level]-1]} {$lvl > 0} {incr lvl -1} {
			set tracelvl "$tracelvl <[info level $lvl]>"
		}
		puts $log "$txt\nTrace:\n$tracelvl\n" 
        #\nCall:\n[dict get [info frame -2] cmd]
	}
}

proc saveGlobalConf {} {
	variable globalconf	
	set file [open "./data/global.tmp" w]	
	foreach item [lsort -dictionary [array names globalconf]] {
		puts $file "set globalconf($item) \"$globalconf($item)\""
	}
	close $file
	if {[file size "./data/global.tmp"] == 0 } {
		file delete "./data/global.tmp"
		return 
	}
	# safety copy
	if { [file exists "./data/global.dat"] && [file size "./data/global.dat"] > 0 } {
		file rename -force "./data/global.dat" "./data/global.bak"
	}
	file rename -force "./data/global.tmp" "./data/global.dat"
	writeLog "./data/global.dat saved."
}

proc loadGlobalConfig {} {
	variable globalconf	
	if { [catch {source "./data/global.dat"} ] } {
		writeLog "Loading ./data/global.dat failed. Using backup ./data/global.bak"
		source "./data/global.bak"
	}
}

proc getConfig { name defaultvalue } {
	global globalconf
	if { [array get globalconf $name] eq "" } { return $defaultvalue }
	return $globalconf($name)
}

proc setConfig { name value } {
	global globalconf
	if { $value ne "" && $value ne "."} {
		set globalconf($name) $value
	}
}

proc addCommand { name cmd } {
	global command
	lappend command($name) $cmd
}

proc removeCommand { name cmd } {
	global command
	set pos [lsearch $command($name) $cmd]
	set command($name) [lreplace $command($name) $pos $pos]
}
