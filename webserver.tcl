set root "c:/html"
set default "index.html"
set port 82

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


set server [socket -server answer $port]
vwait forever