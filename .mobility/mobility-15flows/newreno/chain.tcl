set UseSemitcp [lindex $argv 0];
if {$UseSemitcp > 0} {
	Mac/802_11 set RTT_ 0.006; # an estimation of the time for a 4-way handshaking
	if {$argc == 8} {
		set NodeNum [lindex $argv 1];
		set Duration [lindex $argv 2];
		Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
		Mac/802_11 set CALLRT_ [lindex $argv 4]
		Agent/TCPSink set no_dupack_ [lindex $argv 5]

		Queue/DropTail/PriQueue set CongestionThreshold_ [lindex $argv 6]
		Mac/802_11 set K_ [lindex $argv 7]
	} else {
		if {$argc == 3} {
			set NodeNum [lindex $argv 1];
			set Duration [lindex $argv 2];
		} else {
			set NodeNum 5;
			set Duration 10;
		}
		Queue/DropTail/PriQueue set CongestionThreshold_ 1
		Mac/802_11 set K_ 1
		Mac/802_11 set ShortRetryLimit_ 7
		Mac/802_11 set CALLRT_ 1
		Agent/TCPSink set no_dupack_ 1
	}
} else {
	if {$argc == 6} {
		set NodeNum [lindex $argv 1];
		set Duration [lindex $argv 2];
		Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
		Mac/802_11 set CALLRT_ [lindex $argv 4]
		Agent/TCPSink set no_dupack_ [lindex $argv 5]
	} else {
		if {$argc == 3} {
			set NodeNum [lindex $argv 1];
			set Duration [lindex $argv 2];
		} else {
			set NodeNum 3;
			set Duration 10;
		}
		Mac/802_11 set ShortRetryLimit_ 7
		Mac/802_11 set CALLRT_ 1
		Agent/TCPSink set no_dupack_ 1
	}
}

set val(chan)       Channel/WirelessChannel  ;# Channel Model
set val(prop)       Propagation/TwoRayGround ;# Wireless Propagation Model
set val(netif1)     Phy/WirelessPhy          ;# Network Interface
set val(mac)        Mac/802_11               ;# MAC Protocol
set val(ifq)        Queue/DropTail/PriQueue  ;# Interface Queue Type
set val(ll)         LL                       ;# Link Layer 
set val(ant)        Antenna/OmniAntenna      ;# Antena Type
set val(x)              1520                 ;# Size of the Scenario
set val(y)              320 
set val(ifqlen)         50                	;# Maximum Queue Length in Interface Queue
set val(seed)           0.0
set val(adhocRouting)	AODV					;# Routing Protocol
set val(nn)           $NodeNum               	;# Node Number
set val(stop)         $Duration	              ;# Simulation Time
set chan [new $val(chan)]                    	;# Set up the wireless channel

set ns_       [new Simulator]                 ;# New a Simulator object, and name it ns_

# Initialize the SharedMedia interface with parameters to make it work like at 2.4GHz
Phy/WirelessPhy set CPThresh_ 10.0
Phy/WirelessPhy set CSThresh_ 1.55924e-11		;# Inference Range = 550m
Phy/WirelessPhy set RXThresh_ 3.65262e-10		;# Transmision Range = 250m
Phy/WirelessPhy set bandwidth_ 2e6
Phy/WirelessPhy set Pt_ 0.28183815
Phy/WirelessPhy set freq_ 2.4e+9
Phy/WirelessPhy set L_ 1.0  

set topo [new Topography]				;# New a Topography object which make sure all nodes move inside the boundary
$topo load_flatgrid $val(x) $val(y)	;# Set the size of the scenario

$ns_ use-newtrace							;# Use new trace format
set tracefd	[open chain.tr w] 		;# The name of the trace file
$ns_ trace-all $tracefd

set namtracefd  [open chain.nam w]	;# The name of the nam trace file               
$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)

# Close the trace files
proc finish {} {
        global ns_ tracefd namtracefd
        $ns_ flush-trace
        close $tracefd
        close $namtracefd
        exit 0
}

# The God object: contains the shortest path informaiton and so on.
set god_ [create-god [expr $val(nn)]]

# Configure the nodes
$ns_ node-config -adhocRouting $val(adhocRouting) \
		-llType $val(ll) \
		-macType $val(mac) \
		-ifqType $val(ifq) \
		-ifqLen $val(ifqlen) \
		-antType $val(ant) \
		-propType $val(prop) \
		-phyType $val(netif1) \
		-topoInstance $topo \
		-channel $chan \
		-topoIns_tance $topo \
		-agentTrace ON \
		-routerTrace ON \
		-macTrace ON

for {set i 0} {$i < $val(nn) } {incr i} {     ;# Create the nodes
	set node_($i) [$ns_ node]
	$node_($i) label "WN_($i)"
	$node_($i) color black	
	$node_($i) shape circle
	$node_($i) random-motion 0		      
	$ns_ at 0.0 "$node_($i) color red"   
	$ns_ at 0.0 "$node_($i) shape hexagon"
	$node_($i) set X_ [expr 50 + $i * 200]
	$node_($i) set Y_ 400
	$node_($i) set Z_ 0.0
	
	# MAC GET IFQ AND ROUTE, JUST TO GET THE INFORMATION NEEDED
	# 1. MAC--->IFQ
	# get the mac tcl object
	set mymac($i) [$node_($i) set mac_(0)]
	# attatch ifq to mac
	$mymac($i) mac-get-ifq [$node_($i) set ifq_(0)]
	# 2. MAC--->AODV
	# get route agent tcl object
	set rt($i) [$node_($i) agent 255]
	# attatch route agent tcl object to mac
	$mymac($i) mac-get-aodv $rt($i)
	if {$UseSemitcp > 0} {
		# 3. IFQ--->AODV
		#attatch route agent to ifq
		set myifq($i) [$node_($i) set ifq_(0)]
		$myifq($i) ifq-get-aodv $rt($i)
	}
}

if {$UseSemitcp > 0} {
	source semitcptraffic
} else {
	source tcptraffic
}

# Set up the size of nodes in nam
for {set i 0} {$i < $val(nn)} {incr i} {
                   $ns_ initial_node_pos $node_($i) 30
}

# Reset all the nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}

# Call the mac procedure to print the average queue length
set t2 [expr $val(stop) -0.0000001]
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns_ at $t2 "set mymac($i) [$node_($i) set mac_(0)] 
	$mymac($i) printavgqlen"
}

$ns_ at  $val(stop).002 "finish" ; # Call the finish procedure

$ns_ run ; # Start to run
 