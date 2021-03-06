set Program [lindex $argv 0]

if {$Program == 0} {
    #using semitcp
	Mac/802_11 set RTT_ 0.006; # an estimation of the time for a 4-way handshaking
		set NodeNum [lindex $argv 1]
		set Duration [lindex $argv 2]
		Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
        Mac/802_11 set CALLRT_ [lindex $argv 4]
        Agent/TCPSink set no_dupack_ [lindex $argv 5]

        Queue/DropTail/PriQueue set localThreshold_ [lindex $argv 6]
		Queue/DropTail/PriQueue set neighborThreshold_ [lindex $argv 7]
		Mac/802_11 set K_ [lindex $argv 8]
} elseif {$Program == 1} {
    #using matcp
        Mac/802_11 set RTT_ 0.006
		set NodeNum [lindex $argv 1]
		set Duration [lindex $argv 2]
		Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
        Mac/802_11 set CALLRT_ [lindex $argv 4]
        Agent/TCPSink set no_dupack_ [lindex $argv 5]

        Queue/DropTail/PriQueue set CongestionThreshold_ [lindex $argv 6]
        Mac/802_11 set K_ [lindex $argv 7]
} elseif { $Program == 2 } {
    #using tcpap
    set NodeNum [lindex $argv 1]
    set Duration [lindex $argv 2]
    Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
} elseif { $Program == 3 } {
    #using ns
    set NodeNum [lindex $argv 1]
    set Duration [lindex $argv 2]
    Mac/802_11 set ShortRetryLimit_ [lindex $argv 3]
} else {
    exit 1
}

Mac/802_11 set basicRate_ 1Mb
Mac/802_11 set dataRate_ 2Mb

Mac/802_11 set RTSThreshold_ 300

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

#set namtracefd  [open chain.nam w]	;# The name of the nam trace file               
#$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)

# Close the trace files
proc finish {} {
        global ns_ tracefd ;#namtracefd
        $ns_ flush-trace
        close $tracefd
        #close $namtracefd
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
	
    if {$Program <= 1} {
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
		# 3. IFQ--->AODV
		#attatch route agent to ifq
		set myifq($i) [$node_($i) set ifq_(0)]
		$myifq($i) ifq-get-aodv $rt($i)
	}
}
proc create_tcp_connection {id src dst} {
    global ns_ node_ Program
    
    if {$Program == 0 || $Program == 1 } {
		set tcp_($id) [new Agent/TCP/Semi]
	} elseif {$Program == 2} {
		set tcp_($id) [new Agent/TCP/Newreno/AP]
    } elseif {$Program == 3} {
        set tcp_($id) [new Agent/TCP/Newreno]
    } else {
        exit 1
    }

    set sink_($id) [new Agent/TCPSink]

	$ns_ attach-agent $node_($src) $tcp_($id)
	$ns_ attach-agent $node_($dst) $sink_($id)
	$ns_ connect $tcp_($id) $sink_($id)
	set ftp_($id) [new Application/FTP]
	$ftp_($id) attach-agent $tcp_($id)
	$tcp_($id) set packetSize_ 512;
	$tcp_($id) set fid_ $id
	$ns_ at 1.0 "$ftp_($id) start"
	
	if {$Program <= 1} {
		# 5.1 SEMITCP--->MAC
		set mymac($src) [$node_($src) set mac_(0)]
		$tcp_($id) semitcp-get-mac $mymac($src)
        # 6.1 MAC--->MATCP
        $mymac($src) mac-get-matcp $tcp_($id)
	}
}

source RWP.ns_movements
set src0 [expr $val(nn)-4]
set dst0 [expr $val(nn)-3]
set src1 [expr $val(nn)-2]
set dst1 [expr $val(nn)-1]
$ns_ at 0.0 "$node_($src0) color red"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($src0) shape hexagon"
$ns_ at 0.0 "$node_($dst0) color red"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($dst0) shape hexagon"
$ns_ at 0.0 "$node_($src1) color red"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($src1) shape hexagon"
$ns_ at 0.0 "$node_($dst1) color red"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($dst1) shape hexagon"
$node_($src0) set X_ 200
$node_($src0) set Y_ 150
$node_($src0) set Z_ 0.0
$node_($dst0) set X_ 1300
$node_($dst0) set Y_ 150
$node_($dst0) set Z_ 0.0
$node_($src1) set X_ 200
$node_($src1) set Y_ 200
$node_($src1) set Z_ 0.0
$node_($dst1) set X_ 1300
$node_($dst1) set Y_ 200
$node_($dst1) set Z_ 0.0
source RWP.ns_movements
$ns_ at 0.0 "$node_($src0) color black"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($src0) shape hexagon"
$ns_ at 0.0 "$node_($dst0) color black"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($dst0) shape hexagon"
$ns_ at 0.0 "$node_($src1) color black"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($src1) shape hexagon"
$ns_ at 0.0 "$node_($dst1) color black"          ;# 改变节点颜色，以方便观察
$ns_ at 0.0 "$node_($dst1) shape hexagon"
create_tcp_connection 0 $src0 $dst1
#create_tcp_connection 1 $dst0 $src1

# Set up the size of nodes in nam
#for {set i 0} {$i < $val(nn)} {incr i} {
#                   $ns_ initial_node_pos $node_($i) 30
#}

# Reset all the nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}

if {$Program <= 1} {
# Call the mac procedure to print the average queue length
set t2 [expr $val(stop) -0.0000001]
for {set i 0} {$i < $val(nn) } {incr i} {
	$ns_ at $t2 "set mymac($i) [$node_($i) set mac_(0)] 
	$mymac($i) printavgqlen"
}
}
$ns_ at  $val(stop).002 "finish" ; # Call the finish procedure

$ns_ run ; # Start to run
 
