set datafile separator ','
set key top left

set xlabel 'Threads'
set ylabel 'Speedup  (T1 / Tn)'
set xtics 0,4
set grid

# baseline time from the 1-thread row of results.csv
t1 = 89.1998

set terminal pngcairo size 900,600
set output 'speedup.png'

plot ARGV[1] skip 1 using 1:(t1 / $2) with linespoints lw 2 pt 7 title 'Measured speedup', \
     x lw 1 dt 2 lc rgb 'gray50' title 'Ideal linear'
