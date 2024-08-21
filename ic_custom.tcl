###################################################################################
###################################   INITLIB   ###################################
###################################################################################

set_host_options -max_cores 16
source common_setup.tcl
set DESIGN "des3"

set link_library   $LINK_LIBRARY_FILES
set target_library $TARGET_LIBRARY_FILES

create_lib  -ref_libs $NDM_REFERENCE_LIB_DIRS  -technology $TECH_FILE ${IP}/asic/work/${DESIGN}

read_parasitic_tech -tlup $TLUPLUS_MAX_FILE  -layermap  $MAP_FILE
read_parasitic_tech -tlup $TLUPLUS_MIN_FILE  -layermap  $MAP_FILE


####################################################################################
###################################   FLOORPLAN   ##################################
####################################################################################

set gate_verilog "${IP}/asic/${DESIGN}_icc.v"

read_verilog -top $DESIGN $gate_verilog

current_design $DESIGN

read_sdc ${IP}/asic/${DESIGN}.sdc

#load_upf ../../dc/output/compile.upf

#commit_upf

source mcmm.tcl

save_block -as ${DESIGN}_1_imported

############################################################
set_attribute [get_layers M1] routing_direction vertical
set_attribute [get_layers M2] routing_direction horizontal
set_attribute [get_layers M3] routing_direction vertical
set_attribute [get_layers M4] routing_direction horizontal
set_attribute [get_layers M5] routing_direction vertical
set_attribute [get_layers M6] routing_direction horizontal
set_attribute [get_layers M7] routing_direction vertical
set_attribute [get_layers M8] routing_direction horizontal
set_attribute [get_layers M9] routing_direction vertical
set_attribute [get_layers MRDL] routing_direction horizontal

set_wire_track_pattern -site_def unit -layer M1  -mode uniform -mask_constraint {mask_two mask_one} \
	-coord 0.037 -space 0.074 -direction vertical


#./output/ChipTop_pads.v
initialize_floorplan -core_utilization 0.60 -side_ratio {15 33} -core_offset {10 10 10 10}
#initialize_floorplan \
#  -flip_first_row true \
#  -boundary {{0 0} {700 700}} \
#  -core_offset {15 15 15 15}

place_pins -ports [get_ports *]

save_block -as ${DESIGN}_2_floorplan

create_net -power $NDM_POWER_NET
create_net -ground $NDM_GROUND_NET

connect_pg_net -net $NDM_POWER_NET [get_pins -hierarchical "*/VDD"]
connect_pg_net -net $NDM_GROUND_NET [get_pins -hierarchical "*/VSS"]

create_placement -floorplan -timing_driven
legalize_placement

####################################################################################
###################################  POWER PLAN  ###################################
####################################################################################

############################
########  PG RINGS  ########
############################

remove_pg_via_master_rules -all
remove_pg_patterns -all
remove_pg_strategies -all
remove_pg_strategy_via_rules -all

set top_ring_width 5
set top_offset 2
set top_ring_spacing 5
set gprs_ring_width 1.5
set gprs_offset -5
set gprs_ring_spacing 2
set hm_gprs M7
set vm_gprs M8
set hm_top M6
set vm_top M5


create_pg_region top_power_ring_region -core -expand_by_edge  \
	"{{side: 1} {offset: $top_offset}} {{side: 2} {offset: $top_offset}} {{side: 3} {offset: $top_offset}} {{side: 4} {offset: $top_offset}}"

create_pg_ring_pattern \
	ring \
	-horizontal_layer $hm_top -vertical_layer $vm_top \
	-horizontal_width $top_ring_width -vertical_width $top_ring_width \
	-horizontal_spacing $top_ring_spacing -vertical_spacing $top_ring_spacing

set_pg_strategy  ring -pg_regions { top_power_ring_region } -pattern {{ name: ring} { nets: "VSS VDD" }}

compile_pg -strategies ring
####Connect P/G Pins and Create Power Rails#################
create_pg_mesh_pattern P_top_two \
	-layers { \
		{ {horizontal_layer: M7} {width: 0.2} {spacing: interleaving} {pitch: 30} {offset: 0.856} {trim : true} } \
		{ {vertical_layer: M6}   {width: 0.2} {spacing: interleaving} {pitch: 30} {offset: 6.08}  {trim : true} } \
	}

	set_pg_strategy S_default_vddvss \
	-core \
	-pattern   { {name: P_top_two} {nets:{VSS VDD}} } \
	-extension { {{stop:design_boundary_and_generate_pin}} }

compile_pg -strategies {S_default_vddvss}


## Create std rail
#VDD VSS
create_pg_std_cell_conn_pattern std_rail_conn1 -rail_width 0.094 -layers M1

set_pg_strategy  std_rail_1 -pattern {{name : std_rail_conn1} {nets: "VDD VSS"}} -core

compile_pg -strategies std_rail_1

save_block -as ${DESIGN}_3_after_pns
############################################################
set_app_options -name time.disable_recovery_removal_checks -value false
set_app_options -name time.disable_case_analysis -value false
set_app_options -name place.coarse.continue_on_missing_scandef -value true
set_app_options -name opt.common.user_instance_name_prefix -value place

place_opt
legalize_placement
check_legality -verbose
save_block -as ${DESIGN}_4_placed
############################################################


create_routing_rule ROUTE_RULES_1 \
	-widths {M3 0.2 M4 0.2 } \
	-spacings {M3 0.42 M4 0.63 }

set_clock_routing_rules -default_rule -min_routing_layer M2 -max_routing_layer M4
set_clock_tree_options -target_latency 0.000 -target_skew 0.000

clock_opt

write_verilog ${IP}/asic/work/${DESIGN}.cts.gate.v

report_qor > ${IP}/asic/work/${DESIGN}.clock_qor.rpt

report_clock_timing  -type skew > ${IP}/asic/work/${DESIGN}.clock_skew.rpt

save_block -as ${DESIGN}_5_cts
############################################################
remove_ignored_layers -all
set_ignored_layers \
	-min_routing_layer  $MIN_ROUTING_LAYER \
	-max_routing_layer  $MAX_ROUTING_LAYER

route_auto
route_opt

check_routability

save_block -as ${DESIGN}_6_routed
############################################################

## std filler
set pnr_std_fillers "SAEDRVT14_FILL*"
set std_fillers ""
foreach filler $pnr_std_fillers { lappend std_fillers "*/${filler}" }
create_stdcell_filler -lib_cell $std_fillers

connect_pg_net -net $NDM_POWER_NET [get_pins -hierarchical "*/VDD"]
connect_pg_net -net $NDM_GROUND_NET [get_pins -hierarchical "*/VSS"]

############################################################

write_verilog ${IP}/asic/work/${DESIGN}.icc2.gate.v

############################################################
##NAR STREAMOUT-I U VERILOG OUT-I PAHY SCRIPTUM CHKA, BAITS AVELATSNENQ CHE EREVI?

report_timing
report_power

save_block -as ${DESIGN}_7_finished


change_names -rules verilog -verbose
write_verilog \
	-include {pg_netlist unconnected_ports} \
	${IP}/asic/${DESIGN}_pnr.v

write_gds -design ${DESIGN}_7_finished \
	-layer_map $GDS_MAP_FILE \
	-keep_data_type \
	-fill include \
	-output_pin all \
	-merge_files "$STD_CELL_GDS $SRAMLP_SINGLELP_GDS" \
	-long_names \
	${IP}/asic/${DESIGN}_pnr.gds

write_parasitics -output    ${IP}/asic/${DESIGN}_pnr.spf

############## Reports ##################

report_timing -max_paths 1 -delay_type max -sort_by slack -scenarios func_fast > ${IP}/asic/reports/max_crit_path_for_icc2.txt
report_timing -max_paths 1 -delay_type min -sort_by slack -scenarios func_fast > ${IP}/asic/reports/min_crit_path_for_icc2.txt
report_utilization > ${IP}/asic/reports/utilizatoin_icc2.txt
report_power > ${IP}/asic/reports/power_icc2.txt
report_clock_qor > ${IP}/asic/reports/clock_qor_icc2.txt
report_placement_ir_drop_target > ${IP}/asic/reports/voltage_drop_icc2.txt


#close_block
#close_lib

#exit

