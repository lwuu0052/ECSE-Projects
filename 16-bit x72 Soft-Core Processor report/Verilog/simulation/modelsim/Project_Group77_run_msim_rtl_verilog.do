transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/wulim/Desktop/2072\ X72\ PROJECT {C:/Users/wulim/Desktop/2072 X72 PROJECT/proc_extension_tb.v}
vlog -vlog01compat -work work +incdir+C:/Users/wulim/Desktop/2072\ X72\ PROJECT {C:/Users/wulim/Desktop/2072 X72 PROJECT/BCD_decoder.v}
vlog -vlog01compat -work work +incdir+C:/Users/wulim/Desktop/2072\ X72\ PROJECT {C:/Users/wulim/Desktop/2072 X72 PROJECT/proc_extension.v}
vlog -vlog01compat -work work +incdir+C:/Users/wulim/Desktop/2072\ X72\ PROJECT {C:/Users/wulim/Desktop/2072 X72 PROJECT/BCD_sign.v}
vlog -vlog01compat -work work +incdir+C:/Users/wulim/Desktop/2072\ X72\ PROJECT {C:/Users/wulim/Desktop/2072 X72 PROJECT/components.v}

