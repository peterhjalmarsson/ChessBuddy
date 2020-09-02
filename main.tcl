#!/bin/sh
#The next line executes wish - wherever it is \
exec wish "$0" "$@"

package require Tk
package require Img
variable plugins {}
variable board

namespace eval img {}

source config.tcl
#load configs and open log if it's activated
loadGlobalConfig
initLog

#load ./bin/libchessboard.so
foreach file [glob -nocomplain -directory ./bin/ *.*] {
	writeLog "Loading $file"
    load  $file
}


source engine.tcl
source player.tcl
source board.tcl
source game.tcl
source div.tcl
source file.tcl
source fontdialog.tcl

#load plugins
foreach file [glob -nocomplain -directory ./plugins/ *.tcl] {
	if { [catch {
		writeLog "loading plugin $file"
		source $file
		set file [file tail $file]
		set file [file rootname $file]
		init$file
		lappend plugins $file
	} errorMessage] } { 
		writeLog "error loading image \"$errorMessage\""
	}
}

#load images
foreach file [glob -nocomplain -directory ./pic/ *] {
	if { [catch {
		writeLog "loading image $file"
		set f [file tail $file]
		set f [file rootname $f] 
		image create photo ::img::$f
		::img::$f read $file
	} errorMessage] } { 
		writeLog "error loading image \"$errorMessage\""
	}
}

proc init {} {
	global command
	foreach name {engine player game board} {
		if { [catch {::$name\::loadSettings} errorMessage] } {
			writeLog "error loading settings $name \"$errorMessage\""
		}
	}
	foreach cmd $command(create) {
		if { [catch {{*}$cmd} errorMessage] } {
			writeLog "error creating plugin \"$errorMessage\""
		}
	}
}

proc makeMove { move } {
	if { $move != "" } {
		while { [catch {
			writeLog "trying to make human move $move"
			::game::makeMove human unsorted {*}$move
		} errorMessage] } {
			writeLog "error human move \"$errorMessage\""
		}
		renew 
	}
}

proc engineMove {args} {
	if { $::game::endresult eq "" } { 
		update idletasks 
		::game::playMove
	}
	renew
}

proc renew {} {
	global command
	::game::renew
	foreach cmd $command(update) {{*}$cmd}
}

proc canMove {} {
	if { [lindex $::game::game(status) 0] eq "play" && \
		$::game::game(player_[libboard::position color]) ne "human" } { 
			writeLog "error cannot move piece"
			return false
		}
	return true
}

proc enableMenu { {men "all" } } {
	foreach name { File Position Game Board Player Engine Options } {
		if {$men eq "all" || [lsearch $men $name] >= 0} {
			.mainmenu entryconfigure $name -state normal
		} else {.mainmenu entryconfigure $name -state disabled}
	}
}

proc setSubMenu { sub men state } {
	foreach name $men {
		.mainmenu.menu$sub entryconfigure $name -state $state
	}
}

proc repaint {} {
	global command
	::board::resize main
	foreach id $::engine::activeEngines { 
		::engine::resize $id
	}
	foreach cmd $command(repaint) {{*}$cmd}
}

proc closeProg {} {
	global command
	after cancel [after info]
	foreach name {board engine player game} {
		::$name\::saveSettings
	}
	saveGlobalConf   
	foreach id $::engine::activeEngines { ::engine::quit $id }
	foreach cmd $command(savefile) {{*}$cmd}
	closeLog
    exit
}

proc createWindows {} {
	global board
	set board [::board::create main .pndl]
}


init

menu .mainmenu
. config -menu .mainmenu

foreach {name u} { File 0 Position 0 Game 0 Board 0 Player 1 Engine 0 Plugins 2 Options 0 Windows 0 Help 0 } {
	.mainmenu add cascade -label $name -underline $u \
			-menu [menu .mainmenu.menu$name -tearoff 0]
}

foreach plugin $plugins {
	menu$plugin
}

.mainmenu.menuFile add cascade -label "EPD" -underline 0 \
		-menu [menu .mainmenu.menuFile.epd -tearoff 0]
.mainmenu.menuFile.epd add command -label "Load" -underline 0 \
       -command { ::epdfile::openEpd epd .pndr }
.mainmenu.menuFile add cascade -label "PGN" -underline 0 \
		-menu [menu .mainmenu.menuFile.pgn -tearoff 0]
.mainmenu.menuFile.pgn add command -label "Load" -underline 0 \
       -command {::pgnfile::loadPgn }
.mainmenu.menuFile.pgn add command -label "Save" -underline 0 \
       -command { 
		   if {$::game::moveList ne ""} {::pgnfile::savePgn }
	   }
.mainmenu.menuGame add command -label "Play" -underline 0 \
       -command { ::game::play main .pndr .playlist .pndr }
       
.mainmenu.menuGame add cascade -label Adjudication -underline 0 \
		        -menu [menu .mainmenu.menuGame.adj -tearoff 0]
foreach {res u} { "1-0" 0 "0-1" 0 "1/2-1/2" 2 } {
	.mainmenu.menuGame.adj add command -label $res -underline $u \
			-command [list ::game::stopPlay "$res \"User adjudication.\""]
}  
.mainmenu.menuGame add checkbutton -label "Show comments" -underline 0 \
       -variable ::game::game(showcomments) -offvalue false -onvalue true \
       -command {::game::renew}
.mainmenu.menuGame add command -label "Close" -underline 0 \
       -command { ::game::endPlay }
	
.mainmenu.menuPosition add command -label "New" -underline 0 \
       -command { ::game::new ; ::game::renew }
.mainmenu.menuPosition add command -label "Step back" -underline 5 \
       -command { ::game::back ; renew }
.mainmenu.menuPosition add command -label "Step forward" -underline 5 \
       -command { ::game::forward ; renew }
.mainmenu.menuBoard add checkbutton -label "Flip board" -underline 0 \
		-variable ::board::settings(flipped_main) -offvalue false -onvalue true \
       -command {::board::resize main true}
.mainmenu.menuPlayer add command -label "List" -underline 0 \
		-command {::player::playerMenu "Player list"}
.mainmenu.menuEngine add command -label "List" -underline 0 \
		-command {::engine::engineMenu "Engine list"}
.mainmenu.menuEngine add command -label "Analyze" -underline 0 \
       -command { 
			if {[catch {
				set id [::engine::engineMenu "Engine list"]
				if {$id ne ""} "::engine::start $id .pndr analyze"
			} errorMessage] } {writeLog "analyze error \"$errorMessage\""}
		}

.mainmenu.menuOptions add command -label "Board" -underline 0 \
       -command { ::board::boardOption main }
.mainmenu.menuOptions add command -label "Engine" -underline 0 \
       -command { ::engine::engineOption }
.mainmenu.menuOptions add command -label "Game" -underline 0 \
       -command { ::game::gameOption }
#note: every time log is turned on the log file is erased
.mainmenu.menuOptions add checkbutton -label "Log" -underline 0 \
		-variable globalconf(log) -offvalue false -onvalue true -command {changeLog}
		
panedwindow .pnd -orient h -opaqueresize 0 -width 800 -height 600 \
		-sashrelief groove -sashwidth 6

panedwindow .pndl -orient v -opaqueresize 0 \
		-sashrelief groove -sashwidth 8
panedwindow .pndr -orient v -opaqueresize 0 \
		-sashrelief groove -sashwidth 8
.pnd add .pndl
.pnd add .pndr
pack .pnd -fill both -expand 1
wm  title . "Chess Buddy"
createWindows
bind . <Configure> { 
	repaint
}
bind $board <Button-1> { 
    writeLog "button press"
	if {[canMove]} { 
		makeMove [::board::selectPiece main %x %y [libboard::position color]] 
	}
}
bind $board <B1-Motion> {
	if {[canMove]} {::board::movePiece main %x %y}
}
bind $board <ButtonRelease-1> {
    writeLog "button release"
	if {[canMove]} {makeMove [::board::targetSquare main %x %y highlighted]}
}
bind $board <Button-4> {::game::back}
bind $board <Button-5> {::game::forward}
trace add variable ::game::game(move) write engineMove
bind . <Destroy> {
	set w %W
	if { $w eq "." } {closeProg}
}

update idletasks
.pnd sash place 0 400 400

#hidden files should not show up by default
#we have to create a dummy menu for the changes to take effect
catch {tk_getOpenFile foo bar}
set ::tk::dialog::file::showHiddenVar 0
set ::tk::dialog::file::showHiddenBtn 1 
::game::new
::board::setBoard main
setSubMenu Game Adjudication disabled
libboard::book open "./book.bin"
vwait forever
