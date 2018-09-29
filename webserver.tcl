package require Tk
package require BWidget

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

grid [ttk::button .c.start -text "Start" -command {server $port}] -column 2 -row 2 -sticky w
grid [ttk::button .c.stop -text "Stop" -style "TButton" -command {stopServer $port}] -column 4 -row 2 -sticky w
	
listbox .lb -selectmode multiple -height 4
scrollbar .sb -command [list .lb yview]
.lb configure -yscrollcommand [list .sb set]
.lb insert 0 "Logs"
grid .lb .sb -sticky news
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1
.lb itemconfigure 0 -foreground black

set lb_count 1

foreach w [winfo children .c] {grid configure $w -padx 5 -pady 5}

proc server {port} {
	.c.status configure -foreground "green"
	.c.status configure -text "Running"
	puts "\n\nActivatet\n"
	uplevel set test "test"
	uplevel set server [socket -server answer $port]
}

proc stopServer {port} {
	.c.status configure -foreground "red"
	.c.status configure -text "Stoped"
	puts "\n\nDeactivatet\n"
	upvar server server
	close $server
}

proc bgerror {trouble} {puts stdout "bgerror: $trouble"}

proc answer {socketChannel addr port2} {
  fileevent $socketChannel readable [list readIt $socketChannel $addr]
}

proc readIt {socketChannel addr} {
  set systemTime [clock seconds]
  
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

  puts "[clock format $systemTime -format %H:%M:%S] $addr"
  upvar lb_count lb_count
  .lb insert $lb_count "[clock format $systemTime -format %H:%M:%S] $addr $wholeName"
  
  if {[catch {set fileChannel [open $wholeName RDONLY] } ]} {
    puts $socketChannel "HTTP/1.0 404 Not found"
    puts $socketChannel ""
    puts $socketChannel "<html><head><title><No such URL.></title></head>"
    puts $socketChannel "<body><center>"
    puts $socketChannel "The URL you requested does not exist on this site."
    puts $socketChannel "</center></body></html>"
    close $socketChannel
	.lb itemconfigure $lb_count -foreground orange
  } else {
    fconfigure $fileChannel -translation binary
    fconfigure $socketChannel -translation binary -buffering full
    puts $socketChannel "HTTP/1.0 200 OK"
    puts $socketChannel ""
    fcopy $fileChannel $socketChannel -command [list done $fileChannel $socketChannel]
	.lb itemconfigure $lb_count -foreground green
  }
   set lb_count [expr {$lb_count + 1}] 
}

proc done {inChan outChan args} {
  close $inChan
  close $outChan
}
