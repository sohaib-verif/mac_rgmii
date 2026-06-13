TEST=transfer_test_32_lsb
TIME_OUT=10000000
build:
	vcs -lca -kdb -timescale=1ns/1ps -f ./results/build_eth.f -top testbench -ntb_opts uvm-1.2 -sverilog -cm line+cond+tgl+fsm -cm_hier config_covg.cfg -LDFLAGS -Wl,--no-as-needed -full64 -assert svaext -debug_all
	cd ./results && rm -rf $(TEST)_build
	cd ./results && mkdir -p $(TEST)_build
	mv csrc* simv* -t ./results/$(TEST)_build
	cd ./results/$(TEST)_build && ./simv +UVM_TESTNAME=${TEST} -cm line+cond+tgl+assert  +UVM_TIMEOUT=${TIME_OUT} -> log_${TEST}_build.txt
gui: 
	cd ./results/$(TEST)_build && dve -vpd eth_waveform.vpd
cov:
	vcs -f ./results/build_spi.f -ntb_opts uvm-1.2 -sverilog -cm line+cond+tgl+assert -LDFLAGS -Wl,--no-as-needed -full64 -debug_all
	cd ./results && rm -rf $(TEST)_cov
	cd ./results && mkdir -p $(TEST)_cov
	mv -f csrc* simv* ./results/$(TEST)_cov/
	cd ./results/$(TEST)_cov && ./simv +UVM_TESTNAME=${TEST} -cm line+cond+tgl+assert +UVM_TIMEOUT=${TIME_OUT} ->log_${TEST}_cov.txt
func_cov:
	urg -report ./results/func_coverage_report -dir ./results/*_build/*.vdb
code_cov:
	# dve -full64 -covdir *_cov/*.vdb
	urg -report ./results/code_coverage_report_new -dir ./results/*_build/*.vdb
allclean:
	clear
	rm -rf csrc *.daidir urgReport tr_db.log ucli.key vc_hdrs.h *.vdb DVEfiles urgReport *_test *.txt
clean: 
	rm -rf csrc DVEfiles inter.vpd simv simv.daidir simv.vdb tr_db.log ucli.key vc_hdrs.h novas.conf novas_dump.log *.txt *.vdb *.daidir test *.cst *.log 
asrt:
	vcs -f ./results/build_spi.f -ntb_opts uvm-1.2 -sverilog -assert enable_diag \+define+ASSERT_ON +define+check1+check2+check3+check4+check5+check6+check7 -LDFLAGS -Wl,--no-as-needed -full64 -debug_all +lint=TFIPC-L -cm assert
	cd ./results && rm -rf $(TEST)_asrt
	cd ./results && mkdir -p $(TEST)_asrt
	mv csrc* simv* -t ./results/$(TEST)_asrt
	cd ./results/$(TEST)_asrt && ./simv +UVM_TESTNAME=${TEST} +UVM_TIMEOUT=${TIME_OUT} ->log_${TEST}_asrt.txt
all_func:
	make build TEST=eth_tx_test
	make build TEST=eth_tx_rx_test
	make build TEST=eth_rx_test
	make build TEST=eth_rx_1518_byte_test
	make build TEST=eth_tx_padding_issue_test
	make build TEST=eth_tx_tstrb_issue_test
	make build TEST=eth_tx_tuser_error_test
	make build TEST=eth_tx_throughput_test
	make build TEST=eth_tx_1518B_test
	make build TEST=eth_tx_2000B_test
	make build TEST=eth_tx_padding_test
	make build TEST=eth_rand_pkt_test
	make build TEST=eth_tx_1000_pkt_test
	make build TEST=eth_tx_64_pkt_test
	make build TEST=eth_tx_diff_speed_test
	make build TEST=eth_tx_downsizer_cov_test
	make build TEST=eth_tx_fibonacci_test
	make build TEST=eth_tx_galoice_test
	make build TEST=eth_tx_invalid_lfsr_cfg_test
	make build TEST=eth_rx_multiple_packet_test
	make build TEST=eth_rx_64B_pkt_test
	make build TEST=eth_rx_1000B_pkt_test
	make build TEST=eth_rx_40B_pkt_padding_test
	make build TEST=eth_rx_promiscous_test
	make build TEST=eth_rx_disable_promiscous_test
	make build TEST=eth_rx_2000_byte_test
	make build TEST=eth_rx_1520_byte_test
	make build TEST=eth_rx_broadcast_test
	make build TEST=eth_rx_multicast_test
	make build TEST=eth_rx_reg_config_test
	make build TEST=transfer_test_8_msb
	make build TEST=transfer_test_msb_lsb_toggle
	make build TEST=transfer_test_lsb_msb_toggle
all_cov:
	make cov TEST=fully_random_test
	make cov TEST=transfer_test_random_all_ass
	make cov TEST=transfer_test_random_all_interrupt
	make cov TEST=transfer_test_random_rnd_sb_rnd_edge
	make cov TEST=transfer_test_random_rnd_sb_posedge
	make cov TEST=transfer_test_random_rnd_sb_negedge
	make cov TEST=transfer_test_random_msb_posedge
	make cov TEST=transfer_test_random_msb_negedge
	make cov TEST=transfer_test_random_lsb_negedge
	make cov TEST=transfer_test_random_lsb_posedge
	make cov TEST=transfer_test_127_lsb_negedge
	make cov TEST=transfer_test_128_msb_negedge
	make cov TEST=transfer_test_128_lsb_negedge
	make cov TEST=transfer_test_128_msb
	make cov TEST=transfer_test_128_lsb
	make cov TEST=transfer_test_128_lsb
	make cov TEST=transfer_test_64_lsb
	make cov TEST=transfer_test_32_lsb
	make cov TEST=transfer_test_127_msb
	make cov TEST=transfer_test_96_msb
	make cov TEST=transfer_test_64_msb
	make cov TEST=transfer_test_8_msb
	make cov TEST=transfer_test_msb_lsb_toggle
	make cov TEST=transfer_test_lsb_msb_toggle

