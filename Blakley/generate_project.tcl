cd [file dirname [file normalize [info script]]]
set origin_dir "."
source -notrace [file normalize "${origin_dir}/../procedures.tcl"]

set _xil_proj_name_ [suggested_project_name]

set top_design $_xil_proj_name_
set top_design_testbench "${top_design}_tb"
set IP_directory ""


set source_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/"] -type f *] \
	{*}[include_from_file $origin_dir [file normalize "$origin_dir/include.txt"]] \
]

set sim_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/testbench/"] -type f *]\
]

genProj $_xil_proj_name_ $top_design $top_design_testbench $source_files $sim_files $IP_directory