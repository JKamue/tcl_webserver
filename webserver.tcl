package require Tk
set root "c:/html"
set default "index.html"
set port 82

wm title . "JKamue Webserver"

grid [ttk::frame .c -padding "2 6 12 12"] -column 0 -row 0 -sticky nwes 

grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1

grid [ttk::entry .c.root -width 7 -textvariable root] -column 2 -row 1 -sticky we
grid [ttk::entry .c.default -width 7 -textvariable default] -column 4 -row 1 -sticky we
grid [ttk::entry .c.port -width 7 -textvariable port] -column 6 -row 1 -sticky we

grid [ttk::label .c.roottxt -text "Directory"] -column 1 -row 1 -sticky w
grid [ttk::label .c.defaulttxt -text "Index"] -column 3 -row 1 -sticky w
grid [ttk::label .c.porttxt -text "Port"] -column 5 -row 1 -sticky w

grid [ttk::label .c.status -text "Status"] -column 6 -row 2 -sticky w

grid [ttk::button .c.start -text "Start" -command {set ::until_time_to_start "now, please"}] -column 2 -row 2 -sticky w
grid [ttk::button .c.stop -text "Stop" -style "TButton" -command {set ::until_time_to_stop "now, please"}] -column 4 -row 2 -sticky w

foreach w [winfo children .c] {grid configure $w -padx 5 -pady 5}

proc bgerror {trouble} {puts stdout "bgerror: $trouble"}

proc answer {socketChannel addr port2} {
  fileevent $socketChannel readable [list readIt $socketChannel $addr]
}

proc readIt {socketChannel addr} {
  set systemTime [clock seconds]
  puts "[clock format $systemTime -format %H:%M:%S] $addr"
  global root default
  fconfigure $socketChannel -blocking 0
  set gotLine [gets $socketChannel]
  if { [fblocked $socketChannel] } then {return}
  fileevent $socketChannel readable ""
  set shortName "/"
  regexp {/[^ ]*} $gotLine shortName
  set many [string length $shortName]
  set last [string index $shortName [expr {$many-1}] ]
  if {$last=="/"} then {set shortName $shortName$default }
  set wholeName $root$shortName

  if {[catch {set fileChannel [open $wholeName RDONLY] } ]} {
    puts $socketChannel "HTTP/1.0 404 Not found"
    puts $socketChannel ""
    puts $socketChannel "<html><head><title><No such URL.></title></head>"
    puts $socketChannel "<body><center>"
    puts $socketChannel "The URL you requested does not exist on this site."
    puts $socketChannel "</center></body></html>"
    close $socketChannel
	set ::until_time_to_stop "now, please"
  } else {
    fconfigure $fileChannel -translation binary
    fconfigure $socketChannel -translation binary -buffering full
    puts $socketChannel "HTTP/1.0 200 OK"
    puts $socketChannel ""
    fcopy $fileChannel $socketChannel -command [list done $fileChannel $socketChannel]
  }

}

proc done {inChan outChan args} {
  close $inChan
  close $outChan
}

while {1} {
.c.status configure -foreground "red"
.c.status configure -text "Stopped"
vwait until_time_to_start
.c.status configure -foreground "green"
.c.status configure -text "Running"
puts "\n\nActivatet\n";
set server [socket -server answer $port]
vwait until_time_to_stop
puts "\n\nDeactivaten\n";
close $server
}