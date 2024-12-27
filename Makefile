synth:
	vivado -mode batch -source synth.tcl -notrace

test:
	SIM=verilator pytest
