cd [file dirname [file normalize [info script]]]

set origin_dir "."
source -notrace [file normalize "$origin_dir/../procedures.tcl"]
set _xil_proj_name_ [suggested_project_name]

safe_close_project

rescue\
	[file normalize "$origin_dir/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1"]\
	[file normalize "$origin_dir/source/"]

rescue\
	[file normalize "$origin_dir/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sim_1"]\
	[file normalize "$origin_dir/testbench/"]

cleanse [list\
	[file normalize "$origin_dir/${_xil_proj_name_}"]\
	[file normalize "$origin_dir/.Xil/"]\
	[file normalize "$origin_dir/NA/"]\
]
