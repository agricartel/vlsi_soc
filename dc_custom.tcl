
set IP [pwd]
set top_mod "des3"
set RTL_SOURCE_FILES {./des/des3.v
	./des/des.v
	./des/crp.v
	./des/key_sel.v
	./des/key_sel3.v
	./des/sbox1.v
	./des/sbox2.v
	./des/sbox3.v
	./des/sbox4.v
	./des/sbox5.v
	./des/sbox6.v
	./des/sbox7.v
	./des/sbox8.v
}

sh mkdir -p asic

sh mkdir -p asic/reports



set_svf "asic/${top_mod}.svf";

set search_path "$search_path SAED_EDK90nm_ccs_models_svt/"
# set search_path "$search_path /umbc/software/design_kits/SAED14nm/lib/stdcell_rvt"


set rvt_library "SAED_EDK90nm_ccs_models_svt/saed90nm_typ_ccs.db"

set link_library "$rvt_library"
set target_library "$rvt_library"


create_mw_lib prototype_$top_mod -technology SAED_EDK90nm/Technology_Kit/milkyway/saed90nm_icc_1p9m.tf  -mw_reference_library { SAED_EDK90nm/Digital_Standard_cell_Library/lef/saed90nm.lef }


open_mw_lib prototype_$top_mod

set_host_options -max_cores 16


define_design_lib work -path ${IP}/asic/work

analyze -define {ASIC=1} -f sverilog -library work "$RTL_SOURCE_FILES"

elaborate -library work ${top_mod}

create_clock -name clk -period 0.72 clk
set_clock_uncertainty 0.072 [get_clock clk]
set_input_delay 0.1 -clock clk [all_inputs]
set_output_delay 0.1 -clock clk [all_outputs]


compile_ultra

uniquify


write -hierarchy -format verilog -output ${IP}/asic/${top_mod}_icc.v ${top_mod}
write_sdc ${IP}/asic/${top_mod}.sdc

change_names -rules verilog -hierarchy
write_sdf -significant_digits 13 ${IP}/asic/${top_mod}.sdf


report_constraint -all_violators > ${IP}/asic/reports/dc_constraint.txt
report_area > ${IP}/asic/reports/dc_area.txt
report_timing -max_paths 1 -delay_type max -sort_by slack > ${IP}/asic/reports/max_crit_path_for_dc.txt
report_timing -max_paths 1 -delay_type min -sort_by slack > ${IP}/asic/reports/min_crit_path_for_dc.txt
report_power -analysis_effort medium > ${IP}/asic/reports/power.txt


quit



