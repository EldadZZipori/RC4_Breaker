onerror {exit -code 1}
vlib work
vlog -work work rom_reader.vo
vlog -work work rom_reader_simulator.vwf.vt
vsim -novopt -c -t 1ps -L cyclonev_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate_ver -L altera_lnsim_ver work.rom_reader_vlg_vec_tst
vcd file -direction rom_reader.msim.vcd
vcd add -internal rom_reader_vlg_vec_tst/*
vcd add -internal rom_reader_vlg_vec_tst/i1/*
proc simTimestamp {} {
    echo "Simulation time: $::now ps"
    if { [string equal running [runStatus]] } {
        after 2500 simTimestamp
    }
}
after 2500 simTimestamp
run -all
quit -f
