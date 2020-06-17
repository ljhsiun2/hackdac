onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/ADDR_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/DATA_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/CONF_START
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/CONF_CLR_DONE
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/AXI_ADDR_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/AXI_DATA_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/AXI_LEN_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/AXI_SIZE_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/AXI_ID_WIDTH
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/clk_i
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/rst_ni
add wave -noupdate -group dma -expand -subitemconfig {/ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_req_o.aw -expand /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_req_o.w -expand} /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_req_o
add wave -noupdate -group dma -expand -subitemconfig {/ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_resp_i.b -expand /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_resp_i.r -expand} /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/axi_resp_i
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/config_reg
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/length_reg
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/source_addr_reg
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/dest_addr_reg
add wave -noupdate -group dma /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/state_w
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/ADDR_WIDTH
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/DATA_WIDTH
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/clk_i
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/rst_ni
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/start
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/p_c
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/state
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key0
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key1
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key2
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key_sel
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/p_c_big
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/state_big
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key_big
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key_big0
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key_big1
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/key_big2
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/ct
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/ct_valid
add wave -noupdate -group aes /ariane_tb/dut/i_ariane_peripherals/i_aes_wrapper/reglk_ctrl_i
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/ADDR_WIDTH
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/DATA_WIDTH
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/clk_i
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/rst_ni
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/reglk_ctrl_i
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/newMessage_r
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/startHash_r
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/startHash
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/newMessage
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/data
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/bigData
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/hash
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/ready
add wave -noupdate -group sha /ariane_tb/dut/i_ariane_peripherals/i_sha256_wrapper/hashValid
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/ADDR_WIDTH
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/DATA_WIDTH
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/FUSE_MEM_SIZE
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/clk_i
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/rst_ni
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/fuse_req_o
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/fuse_addr_o
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/fuse_rdata_i
add wave -noupdate -expand -group pkt /ariane_tb/dut/i_ariane_peripherals/i_pkt_wrapper/pkey_loc
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/clk_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/rst_ni
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/config_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/length_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/source_addr_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/dest_addr_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/state_o
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/axi_ad_axi_req_o
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/axi_resp_i
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/config_d
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/length_d
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/source_addr_d
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/dest_addr_d
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/req_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/req_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/req_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/we_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/we_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/we_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/addr_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/addr_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/addr_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/be_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/be_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/be_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/len_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/len_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/len_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/size_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/size_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/size_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/type_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/type_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/type_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/id_axi_ad_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/id_axi_ad_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/id_axi_ad_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/dma_ctrl_reg
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/dma_ctrl_new
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/dma_ctrl_en
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/start
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/clr_done
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/axi_ad_gnt
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_dma_wrapper/u_dma/axi_ad_valid
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_axi2apb_64_32_aes/RLAST_o
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_axi2apb_64_32_aes/RDATA_o
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_axi2apb_64_32_aes/RVALID_o
add wave -noupdate -group dma1 /ariane_tb/dut/i_ariane_peripherals/i_axi2apb_64_32_aes/ARLEN_i
add wave -noupdate /ariane_tb/dut/i_ariane_peripherals/i_apb_to_reg_aes/paddr_i
add wave -noupdate /ariane_tb/dut/i_ariane_peripherals/i_apb_to_reg_aes/pwrite_i
add wave -noupdate /ariane_tb/dut/i_ariane_peripherals/i_apb_to_reg_aes/pwdata_i
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/NB_SLAVE
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/AcCt_MEM_SIZE
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/clk_i
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/rst_ni
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/reglk_ctrl_i
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/acc_ctrl_o
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/acct_mem
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/reglk_ctrl
add wave -noupdate -expand -group accrt /ariane_tb/dut/i_ariane_peripherals/i_acct_wrapper/j
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {97364312 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 264
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {162050606 ns}
