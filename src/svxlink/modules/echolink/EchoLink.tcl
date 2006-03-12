###############################################################################
#
# EchoLink module event handlers
#
###############################################################################

#
# This is the namespace in which all functions and variables below will exist.
# The name must match the configuration variable "NAME" in the
# [ModuleEchoLink] section in the configuration file. The name may be changed
# but it must be changed in both places.
#
namespace eval EchoLink {

#
# Extract the module name from the current namespace
#
set module_name [namespace tail [namespace current]];


#
# An "overloaded" playMsg that eliminates the need to write the module name
# as the first argument.
#
proc playMsg {msg} {
  variable module_name;
  ::playMsg $module_name $msg;
}


#
# A convenience function for printing out information prefixed by the
# module name
#
proc printInfo {msg} {
  variable module_name;
  puts "$module_name: $msg";
}


#
# This variable is updated by the EchoLink module when a station connects or
# disconnects. It contains the number of currently connected stations.
#
variable num_connected_stations 0;


#
# Executed when this module is being activated
#
proc activating_module {} {
  variable module_name;
  Module::activating_module $module_name;
}


#
# Executed when this module is being deactivated.
#
proc deactivating_module {} {
  variable module_name;
  Module::deactivating_module $module_name;
}


#
# Executed when the inactivity timeout for this module has expired.
#
proc timeout {} {
  variable module_name;
  Module::timeout $module_name;
}


#
# Executed when playing of the help message for this module has been requested.
#
proc play_help {} {
  variable module_name;
  Module::play_help $module_name;
}


#
# Spell an EchoLink callsign
#
proc spellEchoLinkCallsign {call} {
  global basedir;
  if [regexp {^(\w+)-L$} $call ignored callsign] {
    spellWord $callsign;
    playSilence 50;
    playMsg "link";
  } elseif [regexp {^(\w+)-R$} $call ignored callsign] {
    spellWord $callsign;
    playSilence 50;
    playMsg "repeater";
  } elseif [regexp {^\*(.+)\*$} $call ignored name] {
    playMsg "conference";
    playSilence 50;
    set lc_name [string tolower $name];
    if [file exists "$basedir/EchoLink/conf-$lc_name.raw"] {
      playFile "$basedir/EchoLink/conf-$lc_name.raw";
    } else {
      spellEchoLinkCallsign $name;
    }
  } else {
    spellWord $call;
  }
}


#
# Executed when a request to list all connected stations is received.
# That is, someone press DTMF "1#" when the EchoLink module is active.
#
proc list_connected_stations {connected_stations} {
  playNumber [llength $connected_stations];
  playSilence 50;
  playMsg "connected_stations";
  foreach {call} "$connected_stations" {
    spellEchoLinkCallsign $call;
    playSilence 250;
  }
}


#
# Executed when someone tries to setup an outgoing EchoLink connection but
# the directory server is offline due to communications failure.
#
proc directory_server_offline {} {
  playMsg "directory_server_offline";
}


#
# Executed when the limit for maximum number of QSOs has been reached and
# an outgoing connection request is received.
#
proc no_more_connections_allowed {} {
  # FIXME: Change the message to something that makes more sense...
  playMsg "link_busy";
}


#
# Executed when a status report is requested. This usually happens at
# manual identification when the user press DTMF "*".
#
proc status_report {} {
  variable num_connected_stations;
  variable module_name;
  global active_module;
  
  if {$active_module == $module_name} {
    playNumber $num_connected_stations;
    playMsg "connected_stations";
  }
}


#
# Executed when an EchoLink id cannot be found in an outgoing connect request.
#
proc station_id_not_found {station_id} {
  playNumber $station_id;
  playMsg "not_found";
}


#
# Executed when the lookup of an EchoLink callsign fail in an outgoing connect
# request.
#
proc lookup_failed {station_id} {
  playMsg "operation_failed";
}


#
# Executed when a local user tries to connect to the local node.
#
proc self_connect {} {
  playMsg "operation_failed";
}


#
# Executed when a local user tries to connect to a node that is already
# connected.
#
proc already_connected_to {call} {
  playMsg "already_connected_to";
  playSilence 50;
  spellEchoLinkCallsign $call;
}


#
# Executed when an internal error occurs.
#
proc internal_error {} {
  playMsg "operation_failed";
}


#
# Executed when an outgoing connection has been requested.
#
proc connecting_to {call} {
  playMsg "connecting_to";
  spellEchoLinkCallsign $call;
  playSilence 500;
}


#
# Executed when an EchoLink connection has been terminated
#
proc disconnected {call} {
  spellEchoLinkCallsign $call;
  playMsg "disconnected";
  playSilence 500;
}


#
# Executed when an incoming EchoLink connection has been accepted.
#
proc remote_connected {call} {
  playMsg "connected";
  spellEchoLinkCallsign $call;
  playSilence 500;
}


#
# Executed when an outgoing connection has been established.
#
proc connected {} {
  playMsg "connected";
  playSilence 500;
}


#
# Executed when the EchoLink connection has been idle for too long. The
# connection will be terminated.
#
proc link_inactivity_timeout {} {
  playMsg "timeout";
}


#
# Executed when a too short connect by callsign command is received
#
proc cbc_too_short_cmd {cmd} {
  spellWord $cmd;
  playSilence 50;
  playMsg "operation_failed";
}


#
# Executed when the connect by callsign function cannot find a match
#
proc cbc_no_match {code} {
  playNumber $code;
  playSilence 50;
  playMsg "no_match";
}


#
# Executed when the connect by callsign list has been retrieved
#
proc cbc_list {call_list} {
  playMsg "choose_station";
  set idx 0;
  foreach {call} $call_list {
    incr idx;
    playSilence 500;
    playNumber $idx;
    playSilence 200;
    spellEchoLinkCallsign $call;
  }
}


#
# Executed when the connect by callsign function is manually aborted
#
proc cbc_aborted {} {
  playMsg "aborted";
}


#
# Executed when an out of range index is entered in the connect by callsign
# list
#
proc cbc_index_out_of_range {idx} {
  playNumber $idx;
  playSilence 50;
  playMsg "idx_out_of_range";
}


#
# Executed when there are more than nine matches in the connect by
# callsign function
#
proc cbc_too_many_matches {} {
  playMsg "too_many_matches";
}


#
# Executed when no station have been chosen in 60 seconds in the connect
# by callsign function
#
proc cbc_timeout {} {
  playMsg "aborted";
}



#-----------------------------------------------------------------------------
# The events below are for remote EchoLink announcements. Sounds are not
# played over the local transmitter but are sent to the remote station.
#-----------------------------------------------------------------------------

#
# Executed when an incoming connection is accepted
#
proc remote_greeting {} {
  playSilence 1000;
  playMsg "greeting";
}


#
# Executed when an incoming connection is rejected
#
proc reject_remote_connection {} {
  playSilence 1000;
  playMsg "reject_connection";
  playSilence 1000;
}


#
# Executed when the inactivity timer times out
#
proc remote_timeout {} {
  playMsg "timeout";
  playSilence 1000;
}


# end of namespace
}

#
# This file has not been truncated
#
