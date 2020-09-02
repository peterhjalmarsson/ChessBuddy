namespace eval analyze {
	variable active false
}

proc initanalyze {} {}

proc menuanalyze {} {
	.mainmenu.menuPlugins add checkbutton -label "Analyze game" -underline 0 \
			-variable ::analyze::active -offvalue false -onvalue true \
			-command {::analyze::setActive}
}

proc ::analyze::setActive {} {
	
}
