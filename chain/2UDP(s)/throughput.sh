#!/usr/bin/gnuplot
#set title "SemiTcp, TCP-AP and TCP Throughput, 9 hops"
set xlabel "Hops length"
set ylabel "Throughput(Kbps)"
#set key right bottom
set key right top Right
#set term postscript eps monochrome blacktext "Helvetica" 24
set term postscript eps enhanced color blacktext "Helvetica" 24
set output 'throughput.eps'
set autoscale
set grid
set boxwidth 20
#set xrange [0:4]
set yrange [:400]

plot    './throughput_0' u 1:2 t 'UDP(s)(flow 0)' with linespoints, \
        './throughput_1' u 1:2 t 'UDP(s)(flow 1)' with linespoints, \
        './throughput' u 1:2 t 'UDP(s)(sum)' with linespoints

set output
quit

   
#set tmargin 0
#set bmargin 0
   
#set term post eps enhan "Helvetica" 60   
#set out "combine-curve-time.eps"
#set nomultiplot

