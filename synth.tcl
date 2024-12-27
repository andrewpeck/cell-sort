read_verilog {cell.sv cell_sort.sv}

synth_design -top cell_sort -part xc7a12tcpg238-3

report_utilization -hierarchical -file "utilization.txt"

start_gui
