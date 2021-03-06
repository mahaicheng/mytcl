#!/usr/bin/gnuplot
#set title "SemiTcp, TCP-AP and TCP Throughput, 9 hops"
set xlabel "Node Length"
set ylabel "Throghput(Kbps)"
#set key right bottom
set key right top Right
#set term postscript eps monochrome blacktext "Helvetica" 24
set term postscript eps enhanced color blacktext "Helvetica" 24
set output 'throughput(2).eps'
set autoscale
set grid
set boxwidth 20
#set xrange [1:20]
#set yrange [:400]

plot    './HopsResultInst.txt_0(hops=2)' u 5:6 t 'hops=2,flow=0' with linespoints, \
        './HopsResultInst.txt_1(hops=2)' u 5:6 t 'hops=2,flow=1' with linespoints
    
    set output
quit

   
#set tmargin 0
#set bmargin 0
   
#set term post eps enhan "Helvetica" 60   
#set out "combine-curve-time.eps"
#set nomultiplot

