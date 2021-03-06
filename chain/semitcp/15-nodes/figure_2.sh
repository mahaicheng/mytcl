#!/usr/bin/gnuplot
#set title "SemiTcp, TCP-AP and TCP Throughput, 9 hops"
set xlabel "Node #"
set ylabel "RTSC ratio (%)"
set y2label "RTSC dropping ratio (%)"

set y2tics
set ytics nomirror

set title " "

#set key right bottom
set key right top right
set term postscript eps monochrome blacktext "Helvetica" 20 
#set term postscript eps enhanced color blacktext "Helvetica" 16
set output 'figure_2.eps'
set autoscale
set grid
set boxwidth 20
set xrange [1:15]
#set yrange [0:4]
#set y2range　[0:50000]

plot    './RTSC_rate' u 1:2 t 'RTSC ratio' with linespoints axis x1y1 lt 3 pt 4, \
        './RTS_drop_rate' u 1:2 t 'RTS dropping ratio' with linespoints axis x1y2 lt 5 pt 6

    set output
quit

   
#set tmargin 0
#set bmargin 0
   
#set term post eps enhan "Helvetica" 60   
#set out "combine-curve-time.eps"
#set nomultiplot

