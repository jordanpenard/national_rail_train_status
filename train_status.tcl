#!/bin/bash
#\
exec wish $0 $*

set path [file dirname [file normalize [info script]]]

if {$argc < 3} {
  puts "Usage : [info script] <from> <to> <number of trains>"
  puts "e.g. : [info script] KGL WFJ 4"
  exit
}

set request_from [lindex $argv 0]
set request_to [lindex $argv 1]
set request_nb_trains [lindex $argv 2]
set timestamp ""

proc every {ms cmd} {
  {*}$cmd
  after $ms [list after idle [namespace code [info level 0]]]
}

proc get_section {string tag} {
  
  set tag_length [string length $tag]
  set trains {}
  
  for {} {[string match "*<${tag}>*" $string]} {} {
        
    set a [string first "<${tag}>" $string]
    set b [string first "</${tag}>" $string]
    
    set train [string range $string [expr $a + $tag_length + 2] [expr $b - 1]]
    lappend trains $train
        
    set string [string range $string [expr $b + $tag_length + 3] end]
    
  }
  
  return $trains
}

proc get_field {string field} {
  return [lindex [regexp -all -inline "<${field}>(.*)</${field}>" $string] 1]
}

proc refresh {} {
  
  global request_from
  global request_to
  global request_nb_trains
  global path
  global timestamp
  
  set response [exec $path/request.sh $request_from $request_to $request_nb_trains]
  set header [string range $response 0 [string first "<lt5:trainServices>" $response]]

  catch {
    set timestamp "[clock format [clock scan [string range [get_field $header lt4:generatedAt] 0 18] -format {%Y-%m-%dT%T}] -format {%T %d/%m/%Y}]"
  }
  set info [string map {"&amp;amp;" "&" "&lt;" "<" "&gt;" ">" "&quot;" "\""} [join [get_section $response "lt:message"] "\n"]]
  set from [get_field $header "lt4:locationName"]
  set to [get_field $header "lt4:filterLocationName"]

  # For each train
  set trains [get_section $response "lt5:service"]
  for {set i 0} {$i < [llength $trains]} {incr i} {
    set item [lindex $trains $i]
    
    set std($i) [get_field $item "lt4:std"]
    set etd($i) [get_field $item "lt4:etd"]

    set platform($i) [get_field $item "lt4:platform"]
    if {$platform($i) != ""} {
      set platform($i) "Platform $platform($i)"
    }
    
    set isCancelled [get_field $item "lt4:isCancelled"]
    set filterLocationCancelled [get_field $item "lt4:filterLocationCancelled"]
    set cancelReason [get_field $item "lt4:cancelReason"]
    set delayReason [get_field $item "lt4:delayReason"]
    
    set train_message($i) ""
    if {$delayReason != ""} {
      set train_message($i) $delayReason
    }
    if {$isCancelled != "" || $filterLocationCancelled != ""} {
      if {$cancelReason != ""} {
        set train_message($i) "Cancel : $cancelReason"
      } else {
        set train_message($i) "Cancel"
      }
    }    
  }

  # Remove old widgets
  foreach w [winfo children .header] {
    destroy $w
  }
  foreach w [winfo children .trains] {
    destroy $w
  }

  label .header.timestamp -text "Latest update : $timestamp"
  grid .header.timestamp -column 0 -row 0
  label .header.route -text "$from to $to"
  grid .header.route -column 0 -row 2

  if {$info != ""} {
    message .header.info -text "$info"
    grid .header.info -column 0 -row 1  
  }  

  for {set i 0} {$i < [llength $trains]} {incr i} {
    grid rowconfigure .trains $i -weight 1
    frame .trains.train${i} -bd 1 -relief groove
    grid .trains.train${i} -column 0 -row ${i} -sticky nsew
    grid columnconfigure .trains.train${i} 0 -weight 1
    grid columnconfigure .trains.train${i} 1 -weight 1
    grid rowconfigure .trains.train${i} 2 -weight 1

    label .trains.train${i}.std -text $std($i)
    label .trains.train${i}.etd -text $etd($i)
    grid .trains.train${i}.std -column 0 -row 0 -sticky w
    grid .trains.train${i}.etd -column 1 -row 0 -sticky e

    if {$etd($i) != "On time"} {
      .trains.train${i}.etd configure -fg red
    }

    if {$platform($i) != ""} {
      label .trains.train${i}.platform -text "$platform($i)"
      grid .trains.train${i}.platform -column 0 -row 1 -columnspan 2 -sticky e
    }
    
    if {$train_message($i) != ""} {
      message .trains.train${i}.train_message -text $train_message($i) -fg red -aspect 400
      grid .trains.train${i}.train_message -column 0 -row 2 -columnspan 2
    }
  }
}


wm title . "Trains status"

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

frame .header -borderwidth 10
grid .header -column 0 -row 0 -sticky nsew
grid columnconfigure .header 0 -weight 1

frame .trains -borderwidth 10
grid .trains -column 0 -row 1 -sticky ew
grid columnconfigure .trains 0 -weight 1

frame .footer -borderwidth 10
grid .footer -column 0 -row 2 -sticky nsew
grid columnconfigure .footer 0 -weight 1
grid rowconfigure .footer 0 -weight 1

button .footer.refresh -text "Refresh" -command refresh
grid .footer.refresh -column 0 -row 0

every 60000 refresh
