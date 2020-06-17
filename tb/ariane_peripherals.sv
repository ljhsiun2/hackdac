// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Xilinx Peripehrals
module ariane_peripherals #(
    parameter int AxiAddrWidth = -1,
    parameter int AxiDataWidth = -1,
    parameter int AxiIdWidth   = -1,
    parameter int AxiUserWidth = 1,
    parameter bit InclUART     = 1,
    parameter bit InclSPI      = 0,
    parameter bit InclEthernet = 0,
    parameter bit InclGPIO     = 0,
    parameter bit InclTimer    = 1
) (
    input  logic       clk_i                    , // Clock
    input  logic       rst_ni                   , // Asynchronous reset active low
    input  logic       srst_ni                  ,
    AXI_BUS.Slave      plic                     ,
    AXI_BUS.Slave      uart                     ,
    AXI_BUS.Slave      aes                      ,
    AXI_BUS.Slave      sha256                   ,
    AXI_BUS.Slave      pkt                      ,
    AXI_BUS.Slave      acct                     ,
    AXI_BUS.Slave      spi                      ,
    AXI_BUS.Slave      ethernet                 ,
    AXI_BUS.Slave      timer                    ,
    AXI_BUS.Slave      dma                      ,
    AXI_BUS.Slave      reglk                    ,
    AXI_BUS.Slave      hmac                     ,
    output ariane_axi::req_t   dma_axi_req_o    ,
    input  ariane_axi::resp_t  dma_axi_resp_i   ,

    output logic [255:0]  jtag_key_o,
    output logic [1:0] irq_o           ,
    // UART
    input  logic       rx_i            ,
    output logic       tx_o            ,
    // Ethernet
    input  wire        eth_txck        ,
    input  wire        eth_rxck        ,
    input  wire        eth_rxctl       ,
    input  wire [3:0]  eth_rxd         ,
    output wire        eth_rst_n       ,
    output wire        eth_tx_en       ,
    output wire [3:0]  eth_txd         ,
    inout  wire        phy_mdio        ,
    output logic       eth_mdc         ,
    // MDIO Interface
    inout              mdio            ,
    output             mdc             ,
    // SPI
    output logic       spi_clk_o       ,
    output logic       spi_mosi        ,
    input  logic       spi_miso        ,
    output logic       spi_ss          ,
    output logic [ariane_soc::NrSlaves-1:0][4*ariane_soc::NB_PERIPHERALS-1 :0]   access_ctrl_reg
);

    logic [8*ariane_soc::NB_PERIPHERALS-1 :0]   reglk_ctrl; // Access control values

    // ---------------
    // 1. PLIC
    // ---------------
    logic [ariane_soc::NumSources-1:0] irq_sources;

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus (clk_i);

    logic         plic_penable;
    logic         plic_pwrite;
    logic [31:0]  plic_paddr;
    logic         plic_psel;
    logic [31:0]  plic_pwdata;
    logic [31:0]  plic_prdata;
    logic         plic_pready;
    logic         plic_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_plic (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( plic.aw_id     ),
        .AWADDR_i  ( plic.aw_addr   ),
        .AWLEN_i   ( plic.aw_len    ),
        .AWSIZE_i  ( plic.aw_size   ),
        .AWBURST_i ( plic.aw_burst  ),
        .AWLOCK_i  ( plic.aw_lock   ),
        .AWCACHE_i ( plic.aw_cache  ),
        .AWPROT_i  ( plic.aw_prot   ),
        .AWREGION_i( plic.aw_region ),
        .AWUSER_i  ( plic.aw_user   ),
        .AWQOS_i   ( plic.aw_qos    ),
        .AWVALID_i ( plic.aw_valid  ),
        .AWREADY_o ( plic.aw_ready  ),
        .WDATA_i   ( plic.w_data    ),
        .WSTRB_i   ( plic.w_strb    ),
        .WLAST_i   ( plic.w_last    ),
        .WUSER_i   ( plic.w_user    ),
        .WVALID_i  ( plic.w_valid   ),
        .WREADY_o  ( plic.w_ready   ),
        .BID_o     ( plic.b_id      ),
        .BRESP_o   ( plic.b_resp    ),
        .BVALID_o  ( plic.b_valid   ),
        .BUSER_o   ( plic.b_user    ),
        .BREADY_i  ( plic.b_ready   ),
        .ARID_i    ( plic.ar_id     ),
        .ARADDR_i  ( plic.ar_addr   ),
        .ARLEN_i   ( plic.ar_len    ),
        .ARSIZE_i  ( plic.ar_size   ),
        .ARBURST_i ( plic.ar_burst  ),
        .ARLOCK_i  ( plic.ar_lock   ),
        .ARCACHE_i ( plic.ar_cache  ),
        .ARPROT_i  ( plic.ar_prot   ),
        .ARREGION_i( plic.ar_region ),
        .ARUSER_i  ( plic.ar_user   ),
        .ARQOS_i   ( plic.ar_qos    ),
        .ARVALID_i ( plic.ar_valid  ),
        .ARREADY_o ( plic.ar_ready  ),
        .RID_o     ( plic.r_id      ),
        .RDATA_o   ( plic.r_data    ),
        .RRESP_o   ( plic.r_resp    ),
        .RLAST_o   ( plic.r_last    ),
        .RUSER_o   ( plic.r_user    ),
        .RVALID_o  ( plic.r_valid   ),
        .RREADY_i  ( plic.r_ready   ),
        .PENABLE   ( plic_penable   ),
        .PWRITE    ( plic_pwrite    ),
        .PADDR     ( plic_paddr     ),
        .PSEL      ( plic_psel      ),
        .PWDATA    ( plic_pwdata    ),
        .PRDATA    ( plic_prdata    ),
        .PREADY    ( plic_pready    ),
        .PSLVERR   ( plic_pslverr   )
    );

    apb_to_reg i_apb_to_reg (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( plic_penable ),
        .pwrite_i  ( plic_pwrite  ),
        .paddr_i   ( plic_paddr   ),
        .psel_i    ( plic_psel    ),
        .pwdata_i  ( plic_pwdata  ),
        .prdata_o  ( plic_prdata  ),
        .pready_o  ( plic_pready  ),
        .pslverr_o ( plic_pslverr ),
        .reg_o     ( reg_bus      )
    );

    reg_intf::reg_intf_resp_d32 plic_resp;
    reg_intf::reg_intf_req_a32_d32 plic_req;

    assign plic_req.addr  = reg_bus.addr;
    assign plic_req.write = reg_bus.write;
    assign plic_req.wdata = reg_bus.wdata;
    assign plic_req.wstrb = reg_bus.wstrb;
    assign plic_req.valid = reg_bus.valid;

    assign reg_bus.rdata = plic_resp.rdata;
    assign reg_bus.error = plic_resp.error;
    assign reg_bus.ready = plic_resp.ready;

    plic_top #(
      .N_SOURCE    ( ariane_soc::NumSources  ),
      .N_TARGET    ( ariane_soc::NumTargets  ),
      .MAX_PRIO    ( ariane_soc::MaxPriority )
    ) i_plic (
      .clk_i,
      .rst_ni,
      .req_i         ( plic_req    ),
      .resp_o        ( plic_resp   ),
      .le_i          ( '0          ), // 0:level 1:edge
      .irq_sources_i ( irq_sources ),
      .eip_targets_o ( irq_o       )
    );

    // ---------------
    // 2. UART
    // ---------------
    logic         uart_penable;
    logic         uart_pwrite;
    logic [31:0]  uart_paddr;
    logic         uart_psel;
    logic [31:0]  uart_pwdata;
    logic [31:0]  uart_prdata;
    logic         uart_pready;
    logic         uart_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
        .AXI4_ID_WIDTH      ( AxiIdWidth   ),
        .AXI4_USER_WIDTH    ( AxiUserWidth ),
        .BUFF_DEPTH_SLAVE   ( 2            ),
        .APB_ADDR_WIDTH     ( 32           )
    ) i_axi2apb_64_32_uart (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( uart.aw_id     ),
        .AWADDR_i  ( uart.aw_addr   ),
        .AWLEN_i   ( uart.aw_len    ),
        .AWSIZE_i  ( uart.aw_size   ),
        .AWBURST_i ( uart.aw_burst  ),
        .AWLOCK_i  ( uart.aw_lock   ),
        .AWCACHE_i ( uart.aw_cache  ),
        .AWPROT_i  ( uart.aw_prot   ),
        .AWREGION_i( uart.aw_region ),
        .AWUSER_i  ( uart.aw_user   ),
        .AWQOS_i   ( uart.aw_qos    ),
        .AWVALID_i ( uart.aw_valid  ),
        .AWREADY_o ( uart.aw_ready  ),
        .WDATA_i   ( uart.w_data    ),
        .WSTRB_i   ( uart.w_strb    ),
        .WLAST_i   ( uart.w_last    ),
        .WUSER_i   ( uart.w_user    ),
        .WVALID_i  ( uart.w_valid   ),
        .WREADY_o  ( uart.w_ready   ),
        .BID_o     ( uart.b_id      ),
        .BRESP_o   ( uart.b_resp    ),
        .BVALID_o  ( uart.b_valid   ),
        .BUSER_o   ( uart.b_user    ),
        .BREADY_i  ( uart.b_ready   ),
        .ARID_i    ( uart.ar_id     ),
        .ARADDR_i  ( uart.ar_addr   ),
        .ARLEN_i   ( uart.ar_len    ),
        .ARSIZE_i  ( uart.ar_size   ),
        .ARBURST_i ( uart.ar_burst  ),
        .ARLOCK_i  ( uart.ar_lock   ),
        .ARCACHE_i ( uart.ar_cache  ),
        .ARPROT_i  ( uart.ar_prot   ),
        .ARREGION_i( uart.ar_region ),
        .ARUSER_i  ( uart.ar_user   ),
        .ARQOS_i   ( uart.ar_qos    ),
        .ARVALID_i ( uart.ar_valid  ),
        .ARREADY_o ( uart.ar_ready  ),
        .RID_o     ( uart.r_id      ),
        .RDATA_o   ( uart.r_data    ),
        .RRESP_o   ( uart.r_resp    ),
        .RLAST_o   ( uart.r_last    ),
        .RUSER_o   ( uart.r_user    ),
        .RVALID_o  ( uart.r_valid   ),
        .RREADY_i  ( uart.r_ready   ),
        .PENABLE   ( uart_penable   ),
        .PWRITE    ( uart_pwrite    ),
        .PADDR     ( uart_paddr     ),
        .PSEL      ( uart_psel      ),
        .PWDATA    ( uart_pwdata    ),
        .PRDATA    ( uart_prdata    ),
        .PREADY    ( uart_pready    ),
        .PSLVERR   ( uart_pslverr   )
    );

    if (InclUART) begin : gen_uart
        apb_uart i_apb_uart (
            .CLK     ( clk_i           ),
            .RSTN    ( rst_ni          ),
            .PSEL    ( uart_psel       ),
            .PENABLE ( uart_penable    ),
            .PWRITE  ( uart_pwrite     ),
            .PADDR   ( uart_paddr[4:2] ),
            .PWDATA  ( uart_pwdata     ),
            .PRDATA  ( uart_prdata     ),
            .PREADY  ( uart_pready     ),
            .PSLVERR ( uart_pslverr    ),
            .INT     ( irq_sources[0]  ),
            .OUT1N   (                 ), // keep open
            .OUT2N   (                 ), // keep open
            .RTSN    (                 ), // no flow control
            .DTRN    (                 ), // no flow control
            .CTSN    ( 1'b0            ),
            .DSRN    ( 1'b0            ),
            .DCDN    ( 1'b0            ),
            .RIN     ( 1'b0            ),
            .SIN     ( rx_i            ),
            .SOUT    ( tx_o            )
        );
    end else begin
        assign irq_sources[0] = 1'b0;
        /* pragma translate_off */
        mock_uart i_mock_uart (
            .clk_i     ( clk_i        ),
            .rst_ni    ( rst_ni       ),
            .penable_i ( uart_penable ),
            .pwrite_i  ( uart_pwrite  ),
            .paddr_i   ( uart_paddr   ),
            .psel_i    ( uart_psel    ),
            .pwdata_i  ( uart_pwdata  ),
            .prdata_o  ( uart_prdata  ),
            .pready_o  ( uart_pready  ),
            .pslverr_o ( uart_pslverr )
        );
        /* pragma translate_on */
    end

///////////////////////////////////////////////////////////////////////////////////////

    // ---------------
    // 3. AES
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_aes (clk_i);
    
    //logic [191:0] aes_key_in;
    logic         aes_penable;
    logic         aes_pwrite;
    logic [31:0]  aes_paddr;
    logic         aes_psel;
    logic [31:0]  aes_pwdata;
    logic [31:0]  aes_prdata;
    logic         aes_pready;
    logic         aes_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_aes (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( aes.aw_id     ),
        .AWADDR_i  ( aes.aw_addr   ),
        .AWLEN_i   ( aes.aw_len    ),
        .AWSIZE_i  ( aes.aw_size   ),
        .AWBURST_i ( aes.aw_burst  ),
        .AWLOCK_i  ( aes.aw_lock   ),
        .AWCACHE_i ( aes.aw_cache  ),
        .AWPROT_i  ( aes.aw_prot   ),
        .AWREGION_i( aes.aw_region ),
        .AWUSER_i  ( aes.aw_user   ),
        .AWQOS_i   ( aes.aw_qos    ),
        .AWVALID_i ( aes.aw_valid  ),
        .AWREADY_o ( aes.aw_ready  ),
        .WDATA_i   ( aes.w_data    ),
        .WSTRB_i   ( aes.w_strb    ),
        .WLAST_i   ( aes.w_last    ),
        .WUSER_i   ( aes.w_user    ),
        .WVALID_i  ( aes.w_valid   ),
        .WREADY_o  ( aes.w_ready   ),
        .BID_o     ( aes.b_id      ),
        .BRESP_o   ( aes.b_resp    ),
        .BVALID_o  ( aes.b_valid   ),
        .BUSER_o   ( aes.b_user    ),
        .BREADY_i  ( aes.b_ready   ),
        .ARID_i    ( aes.ar_id     ),
        .ARADDR_i  ( aes.ar_addr   ),
        .ARLEN_i   ( aes.ar_len    ),
        .ARSIZE_i  ( aes.ar_size   ),
        .ARBURST_i ( aes.ar_burst  ),
        .ARLOCK_i  ( aes.ar_lock   ),
        .ARCACHE_i ( aes.ar_cache  ),
        .ARPROT_i  ( aes.ar_prot   ),
        .ARREGION_i( aes.ar_region ),
        .ARUSER_i  ( aes.ar_user   ),
        .ARQOS_i   ( aes.ar_qos    ),
        .ARVALID_i ( aes.ar_valid  ),
        .ARREADY_o ( aes.ar_ready  ),
        .RID_o     ( aes.r_id      ),
        .RDATA_o   ( aes.r_data    ),
        .RRESP_o   ( aes.r_resp    ),
        .RLAST_o   ( aes.r_last    ),
        .RUSER_o   ( aes.r_user    ),
        .RVALID_o  ( aes.r_valid   ),
        .RREADY_i  ( aes.r_ready   ),
        .PENABLE   ( aes_penable   ),
        .PWRITE    ( aes_pwrite    ),
        .PADDR     ( aes_paddr     ),
        .PSEL      ( aes_psel      ),
        .PWDATA    ( aes_pwdata    ),
        .PRDATA    ( aes_prdata    ),
        .PREADY    ( aes_pready    ),
        .PSLVERR   ( aes_pslverr   )
    );

    apb_to_reg i_apb_to_reg_aes (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( aes_penable ),
        .pwrite_i  ( aes_pwrite  ),
        .paddr_i   ( aes_paddr   ),
        .psel_i    ( aes_psel    ),
        .pwdata_i  ( aes_pwdata  ),
        .prdata_o  ( aes_prdata  ),
        .pready_o  ( aes_pready  ),
        .pslverr_o ( aes_pslverr ),
        .reg_o     ( reg_bus_aes )
    );

    aes_wrapper #(
    ) i_aes_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni                 ),
        .reglk_ctrl_i       ( reglk_ctrl[8*ariane_soc::AES+8-1:8*ariane_soc::AES] ),
        .external_bus_io    ( reg_bus_aes            )
    );

///////////////////////////////////////////////////////////////////////////////////////

    // ---------------
    // 4. SHA256
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_sha256 (clk_i);
    
    logic         sha256_penable;
    logic         sha256_pwrite;
    logic [31:0]  sha256_paddr;
    logic         sha256_psel;
    logic [31:0]  sha256_pwdata;
    logic [31:0]  sha256_prdata;
    logic         sha256_pready;
    logic         sha256_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_sha256 (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( sha256.aw_id     ),
        .AWADDR_i  ( sha256.aw_addr   ),
        .AWLEN_i   ( sha256.aw_len    ),
        .AWSIZE_i  ( sha256.aw_size   ),
        .AWBURST_i ( sha256.aw_burst  ),
        .AWLOCK_i  ( sha256.aw_lock   ),
        .AWCACHE_i ( sha256.aw_cache  ),
        .AWPROT_i  ( sha256.aw_prot   ),
        .AWREGION_i( sha256.aw_region ),
        .AWUSER_i  ( sha256.aw_user   ),
        .AWQOS_i   ( sha256.aw_qos    ),
        .AWVALID_i ( sha256.aw_valid  ),
        .AWREADY_o ( sha256.aw_ready  ),
        .WDATA_i   ( sha256.w_data    ),
        .WSTRB_i   ( sha256.w_strb    ),
        .WLAST_i   ( sha256.w_last    ),
        .WUSER_i   ( sha256.w_user    ),
        .WVALID_i  ( sha256.w_valid   ),
        .WREADY_o  ( sha256.w_ready   ),
        .BID_o     ( sha256.b_id      ),
        .BRESP_o   ( sha256.b_resp    ),
        .BVALID_o  ( sha256.b_valid   ),
        .BUSER_o   ( sha256.b_user    ),
        .BREADY_i  ( sha256.b_ready   ),
        .ARID_i    ( sha256.ar_id     ),
        .ARADDR_i  ( sha256.ar_addr   ),
        .ARLEN_i   ( sha256.ar_len    ),
        .ARSIZE_i  ( sha256.ar_size   ),
        .ARBURST_i ( sha256.ar_burst  ),
        .ARLOCK_i  ( sha256.ar_lock   ),
        .ARCACHE_i ( sha256.ar_cache  ),
        .ARPROT_i  ( sha256.ar_prot   ),
        .ARREGION_i( sha256.ar_region ),
        .ARUSER_i  ( sha256.ar_user   ),
        .ARQOS_i   ( sha256.ar_qos    ),
        .ARVALID_i ( sha256.ar_valid  ),
        .ARREADY_o ( sha256.ar_ready  ),
        .RID_o     ( sha256.r_id      ),
        .RDATA_o   ( sha256.r_data    ),
        .RRESP_o   ( sha256.r_resp    ),
        .RLAST_o   ( sha256.r_last    ),
        .RUSER_o   ( sha256.r_user    ),
        .RVALID_o  ( sha256.r_valid   ),
        .RREADY_i  ( sha256.r_ready   ),
        .PENABLE   ( sha256_penable   ),
        .PWRITE    ( sha256_pwrite    ),
        .PADDR     ( sha256_paddr     ),
        .PSEL      ( sha256_psel      ),
        .PWDATA    ( sha256_pwdata    ),
        .PRDATA    ( sha256_prdata    ),
        .PREADY    ( sha256_pready    ),
        .PSLVERR   ( sha256_pslverr   )
    );

    apb_to_reg i_apb_to_reg_sha256 (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( sha256_penable ),
        .pwrite_i  ( sha256_pwrite  ),
        .paddr_i   ( sha256_paddr   ),
        .psel_i    ( sha256_psel    ),
        .pwdata_i  ( sha256_pwdata  ),
        .prdata_o  ( sha256_prdata  ),
        .pready_o  ( sha256_pready  ),
        .pslverr_o ( sha256_pslverr ),
        .reg_o     ( reg_bus_sha256 )
    );

    sha256_wrapper #(
    ) i_sha256_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni                 ),
        .reglk_ctrl_i       ( reglk_ctrl[8*ariane_soc::SHA256+8-1:8*ariane_soc::SHA256] ),
        .external_bus_io    ( reg_bus_sha256         )
    );


///////////////////////////////////////////////////////////////////////////////////////


    // ---------------
    // 5. PKT
    // ---------------

    logic                   fuse_req;
    logic [31:0]            fuse_addr;
    logic [31:0]            fuse_rdata;
    parameter  FUSE_MEM_SIZE = 34; // change this size when ever no of entries in FUSE mem is changed

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_pkt (clk_i);
    
    //logic [191:0] pkt_key_in;
    logic         pkt_penable;
    logic         pkt_pwrite;
    logic [31:0]  pkt_paddr;
    logic         pkt_psel;
    logic [31:0]  pkt_pwdata;
    logic [31:0]  pkt_prdata;
    logic         pkt_pready;
    logic         pkt_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_pkt (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( pkt.aw_id     ),
        .AWADDR_i  ( pkt.aw_addr   ),
        .AWLEN_i   ( pkt.aw_len    ),
        .AWSIZE_i  ( pkt.aw_size   ),
        .AWBURST_i ( pkt.aw_burst  ),
        .AWLOCK_i  ( pkt.aw_lock   ),
        .AWCACHE_i ( pkt.aw_cache  ),
        .AWPROT_i  ( pkt.aw_prot   ),
        .AWREGION_i( pkt.aw_region ),
        .AWUSER_i  ( pkt.aw_user   ),
        .AWQOS_i   ( pkt.aw_qos    ),
        .AWVALID_i ( pkt.aw_valid  ),
        .AWREADY_o ( pkt.aw_ready  ),
        .WDATA_i   ( pkt.w_data    ),
        .WSTRB_i   ( pkt.w_strb    ),
        .WLAST_i   ( pkt.w_last    ),
        .WUSER_i   ( pkt.w_user    ),
        .WVALID_i  ( pkt.w_valid   ),
        .WREADY_o  ( pkt.w_ready   ),
        .BID_o     ( pkt.b_id      ),
        .BRESP_o   ( pkt.b_resp    ),
        .BVALID_o  ( pkt.b_valid   ),
        .BUSER_o   ( pkt.b_user    ),
        .BREADY_i  ( pkt.b_ready   ),
        .ARID_i    ( pkt.ar_id     ),
        .ARADDR_i  ( pkt.ar_addr   ),
        .ARLEN_i   ( pkt.ar_len    ),
        .ARSIZE_i  ( pkt.ar_size   ),
        .ARBURST_i ( pkt.ar_burst  ),
        .ARLOCK_i  ( pkt.ar_lock   ),
        .ARCACHE_i ( pkt.ar_cache  ),
        .ARPROT_i  ( pkt.ar_prot   ),
        .ARREGION_i( pkt.ar_region ),
        .ARUSER_i  ( pkt.ar_user   ),
        .ARQOS_i   ( pkt.ar_qos    ),
        .ARVALID_i ( pkt.ar_valid  ),
        .ARREADY_o ( pkt.ar_ready  ),
        .RID_o     ( pkt.r_id      ),
        .RDATA_o   ( pkt.r_data    ),
        .RRESP_o   ( pkt.r_resp    ),
        .RLAST_o   ( pkt.r_last    ),
        .RUSER_o   ( pkt.r_user    ),
        .RVALID_o  ( pkt.r_valid   ),
        .RREADY_i  ( pkt.r_ready   ),
        .PENABLE   ( pkt_penable   ),
        .PWRITE    ( pkt_pwrite    ),
        .PADDR     ( pkt_paddr     ),
        .PSEL      ( pkt_psel      ),
        .PWDATA    ( pkt_pwdata    ),
        .PRDATA    ( pkt_prdata    ),
        .PREADY    ( pkt_pready    ),
        .PSLVERR   ( pkt_pslverr   )
    );

    apb_to_reg i_apb_to_reg_pkt (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( pkt_penable ),
        .pwrite_i  ( pkt_pwrite  ),
        .paddr_i   ( pkt_paddr   ),
        .psel_i    ( pkt_psel    ),
        .pwdata_i  ( pkt_pwdata  ),
        .prdata_o  ( pkt_prdata  ),
        .pready_o  ( pkt_pready  ),
        .pslverr_o ( pkt_pslverr ),
        .reg_o     ( reg_bus_pkt )
    );

    pkt_wrapper #(
        .FUSE_MEM_SIZE(FUSE_MEM_SIZE)
    ) i_pkt_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni                 ),
        .fuse_req_o         ( fuse_req               ),
        .fuse_addr_o        ( fuse_addr              ),
        .fuse_rdata_i       ( fuse_rdata             ),
        .external_bus_io    ( reg_bus_pkt            )
    );

    fuse_mem # (
        .MEM_SIZE(FUSE_MEM_SIZE)
    ) i_fuse_mem        (
        .clk_i          ( clk_i      ),
        .jtag_key_o     ( jtag_key_o ),
        .req_i          ( fuse_req   ),
        .addr_i         ( fuse_addr  ),
        .rdata_o        ( fuse_rdata ) 
    );

///////////////////////////////////////////////////////////////////////////////////////
    // ---------------
    // 6. Access control peripheral
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_acct (clk_i);
    
    logic         acct_penable;
    logic         acct_pwrite;
    logic [31:0]  acct_paddr;
    logic         acct_psel;
    logic [31:0]  acct_pwdata;
    logic [31:0]  acct_prdata;
    logic         acct_pready;
    logic         acct_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_acct (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( acct.aw_id     ),
        .AWADDR_i  ( acct.aw_addr   ),
        .AWLEN_i   ( acct.aw_len    ),
        .AWSIZE_i  ( acct.aw_size   ),
        .AWBURST_i ( acct.aw_burst  ),
        .AWLOCK_i  ( acct.aw_lock   ),
        .AWCACHE_i ( acct.aw_cache  ),
        .AWPROT_i  ( acct.aw_prot   ),
        .AWREGION_i( acct.aw_region ),
        .AWUSER_i  ( acct.aw_user   ),
        .AWQOS_i   ( acct.aw_qos    ),
        .AWVALID_i ( acct.aw_valid  ),
        .AWREADY_o ( acct.aw_ready  ),
        .WDATA_i   ( acct.w_data    ),
        .WSTRB_i   ( acct.w_strb    ),
        .WLAST_i   ( acct.w_last    ),
        .WUSER_i   ( acct.w_user    ),
        .WVALID_i  ( acct.w_valid   ),
        .WREADY_o  ( acct.w_ready   ),
        .BID_o     ( acct.b_id      ),
        .BRESP_o   ( acct.b_resp    ),
        .BVALID_o  ( acct.b_valid   ),
        .BUSER_o   ( acct.b_user    ),
        .BREADY_i  ( acct.b_ready   ),
        .ARID_i    ( acct.ar_id     ),
        .ARADDR_i  ( acct.ar_addr   ),
        .ARLEN_i   ( acct.ar_len    ),
        .ARSIZE_i  ( acct.ar_size   ),
        .ARBURST_i ( acct.ar_burst  ),
        .ARLOCK_i  ( acct.ar_lock   ),
        .ARCACHE_i ( acct.ar_cache  ),
        .ARPROT_i  ( acct.ar_prot   ),
        .ARREGION_i( acct.ar_region ),
        .ARUSER_i  ( acct.ar_user   ),
        .ARQOS_i   ( acct.ar_qos    ),
        .ARVALID_i ( acct.ar_valid  ),
        .ARREADY_o ( acct.ar_ready  ),
        .RID_o     ( acct.r_id      ),
        .RDATA_o   ( acct.r_data    ),
        .RRESP_o   ( acct.r_resp    ),
        .RLAST_o   ( acct.r_last    ),
        .RUSER_o   ( acct.r_user    ),
        .RVALID_o  ( acct.r_valid   ),
        .RREADY_i  ( acct.r_ready   ),
        .PENABLE   ( acct_penable   ),
        .PWRITE    ( acct_pwrite    ),
        .PADDR     ( acct_paddr     ),
        .PSEL      ( acct_psel      ),
        .PWDATA    ( acct_pwdata    ),
        .PRDATA    ( acct_prdata    ),
        .PREADY    ( acct_pready    ),
        .PSLVERR   ( acct_pslverr   )
    );

    apb_to_reg i_apb_to_reg_acct (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( acct_penable ),
        .pwrite_i  ( acct_pwrite  ),
        .paddr_i   ( acct_paddr   ),
        .psel_i    ( acct_psel    ),
        .pwdata_i  ( acct_pwdata  ),
        .prdata_o  ( acct_prdata  ),
        .pready_o  ( acct_pready  ),
        .pslverr_o ( acct_pslverr ),
        .reg_o     ( reg_bus_acct )
    );
    
    acct_wrapper #(
        .NB_SLAVE(ariane_soc::NrSlaves)
    ) i_acct_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni                 ),
        .reglk_ctrl_i       ( reglk_ctrl[((8*ariane_soc::ACCT)+8-1):((8*ariane_soc::ACCT))] ),
        .acc_ctrl_o         ( access_ctrl_reg        ),
        .external_bus_io    ( reg_bus_acct           )
    );


///////////////////////////////////////////////////////////////////////////////////////

    // ---------------
    // 7. DMA
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_dma (clk_i);
    
    //logic [191:0] sha256_key_in;
    logic         dma_penable;
    logic         dma_pwrite;
    logic [31:0]  dma_paddr;
    logic         dma_psel;
    logic [31:0]  dma_pwdata;
    logic [31:0]  dma_prdata;
    logic         dma_pready;
    logic         dma_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_dma (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( dma.aw_id     ),
        .AWADDR_i  ( dma.aw_addr   ),
        .AWLEN_i   ( dma.aw_len    ),
        .AWSIZE_i  ( dma.aw_size   ),
        .AWBURST_i ( dma.aw_burst  ),
        .AWLOCK_i  ( dma.aw_lock   ),
        .AWCACHE_i ( dma.aw_cache  ),
        .AWPROT_i  ( dma.aw_prot   ),
        .AWREGION_i( dma.aw_region ),
        .AWUSER_i  ( dma.aw_user   ),
        .AWQOS_i   ( dma.aw_qos    ),
        .AWVALID_i ( dma.aw_valid  ),
        .AWREADY_o ( dma.aw_ready  ),
        .WDATA_i   ( dma.w_data    ),
        .WSTRB_i   ( dma.w_strb    ),
        .WLAST_i   ( dma.w_last    ),
        .WUSER_i   ( dma.w_user    ),
        .WVALID_i  ( dma.w_valid   ),
        .WREADY_o  ( dma.w_ready   ),
        .BID_o     ( dma.b_id      ),
        .BRESP_o   ( dma.b_resp    ),
        .BVALID_o  ( dma.b_valid   ),
        .BUSER_o   ( dma.b_user    ),
        .BREADY_i  ( dma.b_ready   ),
        .ARID_i    ( dma.ar_id     ),
        .ARADDR_i  ( dma.ar_addr   ),
        .ARLEN_i   ( dma.ar_len    ),
        .ARSIZE_i  ( dma.ar_size   ),
        .ARBURST_i ( dma.ar_burst  ),
        .ARLOCK_i  ( dma.ar_lock   ),
        .ARCACHE_i ( dma.ar_cache  ),
        .ARPROT_i  ( dma.ar_prot   ),
        .ARREGION_i( dma.ar_region ),
        .ARUSER_i  ( dma.ar_user   ),
        .ARQOS_i   ( dma.ar_qos    ),
        .ARVALID_i ( dma.ar_valid  ),
        .ARREADY_o ( dma.ar_ready  ),
        .RID_o     ( dma.r_id      ),
        .RDATA_o   ( dma.r_data    ),
        .RRESP_o   ( dma.r_resp    ),
        .RLAST_o   ( dma.r_last    ),
        .RUSER_o   ( dma.r_user    ),
        .RVALID_o  ( dma.r_valid   ),
        .RREADY_i  ( dma.r_ready   ),
        .PENABLE   ( dma_penable   ),
        .PWRITE    ( dma_pwrite    ),
        .PADDR     ( dma_paddr     ),
        .PSEL      ( dma_psel      ),
        .PWDATA    ( dma_pwdata    ),
        .PRDATA    ( dma_prdata    ),
        .PREADY    ( dma_pready    ),
        .PSLVERR   ( dma_pslverr   )
    );

    apb_to_reg i_apb_to_reg_dma (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( dma_penable ),
        .pwrite_i  ( dma_pwrite  ),
        .paddr_i   ( dma_paddr   ),
        .psel_i    ( dma_psel    ),
        .pwdata_i  ( dma_pwdata  ),
        .prdata_o  ( dma_prdata  ),
        .pready_o  ( dma_pready  ),
        .pslverr_o ( dma_pslverr ),
        .reg_o     ( reg_bus_dma )
    );

    dma_wrapper #(
    ) i_dma_wrapper (
        .clk_i              ( clk_i       ),
        .rst_ni             ( rst_ni      ),
        .external_bus_io    ( reg_bus_dma ), 
        
        .axi_req_o          ( dma_axi_req_o  ),
        .axi_resp_i         ( dma_axi_resp_i )  
    );

///////////////////////////////////////////////////////////////////////////////////////
    // ---------------
    // 8. Register lock peripheral
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_reglk (clk_i);
    
    logic         reglk_penable;
    logic         reglk_pwrite;
    logic [31:0]  reglk_paddr;
    logic         reglk_psel;
    logic [31:0]  reglk_pwdata;
    logic [31:0]  reglk_prdata;
    logic         reglk_pready;
    logic         reglk_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_reglk (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( reglk.aw_id     ),
        .AWADDR_i  ( reglk.aw_addr   ),
        .AWLEN_i   ( reglk.aw_len    ),
        .AWSIZE_i  ( reglk.aw_size   ),
        .AWBURST_i ( reglk.aw_burst  ),
        .AWLOCK_i  ( reglk.aw_lock   ),
        .AWCACHE_i ( reglk.aw_cache  ),
        .AWPROT_i  ( reglk.aw_prot   ),
        .AWREGION_i( reglk.aw_region ),
        .AWUSER_i  ( reglk.aw_user   ),
        .AWQOS_i   ( reglk.aw_qos    ),
        .AWVALID_i ( reglk.aw_valid  ),
        .AWREADY_o ( reglk.aw_ready  ),
        .WDATA_i   ( reglk.w_data    ),
        .WSTRB_i   ( reglk.w_strb    ),
        .WLAST_i   ( reglk.w_last    ),
        .WUSER_i   ( reglk.w_user    ),
        .WVALID_i  ( reglk.w_valid   ),
        .WREADY_o  ( reglk.w_ready   ),
        .BID_o     ( reglk.b_id      ),
        .BRESP_o   ( reglk.b_resp    ),
        .BVALID_o  ( reglk.b_valid   ),
        .BUSER_o   ( reglk.b_user    ),
        .BREADY_i  ( reglk.b_ready   ),
        .ARID_i    ( reglk.ar_id     ),
        .ARADDR_i  ( reglk.ar_addr   ),
        .ARLEN_i   ( reglk.ar_len    ),
        .ARSIZE_i  ( reglk.ar_size   ),
        .ARBURST_i ( reglk.ar_burst  ),
        .ARLOCK_i  ( reglk.ar_lock   ),
        .ARCACHE_i ( reglk.ar_cache  ),
        .ARPROT_i  ( reglk.ar_prot   ),
        .ARREGION_i( reglk.ar_region ),
        .ARUSER_i  ( reglk.ar_user   ),
        .ARQOS_i   ( reglk.ar_qos    ),
        .ARVALID_i ( reglk.ar_valid  ),
        .ARREADY_o ( reglk.ar_ready  ),
        .RID_o     ( reglk.r_id      ),
        .RDATA_o   ( reglk.r_data    ),
        .RRESP_o   ( reglk.r_resp    ),
        .RLAST_o   ( reglk.r_last    ),
        .RUSER_o   ( reglk.r_user    ),
        .RVALID_o  ( reglk.r_valid   ),
        .RREADY_i  ( reglk.r_ready   ),
        .PENABLE   ( reglk_penable   ),
        .PWRITE    ( reglk_pwrite    ),
        .PADDR     ( reglk_paddr     ),
        .PSEL      ( reglk_psel      ),
        .PWDATA    ( reglk_pwdata    ),
        .PRDATA    ( reglk_prdata    ),
        .PREADY    ( reglk_pready    ),
        .PSLVERR   ( reglk_pslverr   )
    );

    apb_to_reg i_apb_to_reg_reglk (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( reglk_penable ),
        .pwrite_i  ( reglk_pwrite  ),
        .paddr_i   ( reglk_paddr   ),
        .psel_i    ( reglk_psel    ),
        .pwdata_i  ( reglk_pwdata  ),
        .prdata_o  ( reglk_prdata  ),
        .pready_o  ( reglk_pready  ),
        .pslverr_o ( reglk_pslverr ),
        .reg_o     ( reg_bus_reglk )
    );
   

 
    reglk_wrapper #(
        .NB_SLAVE(ariane_soc::NrSlaves)
    ) i_reglk_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni && srst_ni      ),
        .reglk_ctrl_o       ( reglk_ctrl             ),
        .external_bus_io    ( reg_bus_reglk          )
    );



///////////////////////////////////////////////////////////////////////////////////////
  
    // ---------------
    // 9. HMAC
    // ---------------

    REG_BUS #(
        .ADDR_WIDTH ( 32 ),
        .DATA_WIDTH ( 32 )
    ) reg_bus_hmac (clk_i);
    
    logic         hmac_penable;
    logic         hmac_pwrite;
    logic [31:0]  hmac_paddr;
    logic         hmac_psel;
    logic [31:0]  hmac_pwdata;
    logic [31:0]  hmac_prdata;
    logic         hmac_pready;
    logic         hmac_pslverr;

    axi2apb_64_32 #(
        .AXI4_ADDRESS_WIDTH ( AxiAddrWidth  ),
        .AXI4_RDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_WDATA_WIDTH   ( AxiDataWidth  ),
        .AXI4_ID_WIDTH      ( AxiIdWidth    ),
        .AXI4_USER_WIDTH    ( AxiUserWidth  ),
        .BUFF_DEPTH_SLAVE   ( 2             ),
        .APB_ADDR_WIDTH     ( 32            )
    ) i_axi2apb_64_32_hmac (
        .ACLK      ( clk_i          ),
        .ARESETn   ( rst_ni         ),
        .test_en_i ( 1'b0           ),
        .AWID_i    ( hmac.aw_id     ),
        .AWADDR_i  ( hmac.aw_addr   ),
        .AWLEN_i   ( hmac.aw_len    ),
        .AWSIZE_i  ( hmac.aw_size   ),
        .AWBURST_i ( hmac.aw_burst  ),
        .AWLOCK_i  ( hmac.aw_lock   ),
        .AWCACHE_i ( hmac.aw_cache  ),
        .AWPROT_i  ( hmac.aw_prot   ),
        .AWREGION_i( hmac.aw_region ),
        .AWUSER_i  ( hmac.aw_user   ),
        .AWQOS_i   ( hmac.aw_qos    ),
        .AWVALID_i ( hmac.aw_valid  ),
        .AWREADY_o ( hmac.aw_ready  ),
        .WDATA_i   ( hmac.w_data    ),
        .WSTRB_i   ( hmac.w_strb    ),
        .WLAST_i   ( hmac.w_last    ),
        .WUSER_i   ( hmac.w_user    ),
        .WVALID_i  ( hmac.w_valid   ),
        .WREADY_o  ( hmac.w_ready   ),
        .BID_o     ( hmac.b_id      ),
        .BRESP_o   ( hmac.b_resp    ),
        .BVALID_o  ( hmac.b_valid   ),
        .BUSER_o   ( hmac.b_user    ),
        .BREADY_i  ( hmac.b_ready   ),
        .ARID_i    ( hmac.ar_id     ),
        .ARADDR_i  ( hmac.ar_addr   ),
        .ARLEN_i   ( hmac.ar_len    ),
        .ARSIZE_i  ( hmac.ar_size   ),
        .ARBURST_i ( hmac.ar_burst  ),
        .ARLOCK_i  ( hmac.ar_lock   ),
        .ARCACHE_i ( hmac.ar_cache  ),
        .ARPROT_i  ( hmac.ar_prot   ),
        .ARREGION_i( hmac.ar_region ),
        .ARUSER_i  ( hmac.ar_user   ),
        .ARQOS_i   ( hmac.ar_qos    ),
        .ARVALID_i ( hmac.ar_valid  ),
        .ARREADY_o ( hmac.ar_ready  ),
        .RID_o     ( hmac.r_id      ),
        .RDATA_o   ( hmac.r_data    ),
        .RRESP_o   ( hmac.r_resp    ),
        .RLAST_o   ( hmac.r_last    ),
        .RUSER_o   ( hmac.r_user    ),
        .RVALID_o  ( hmac.r_valid   ),
        .RREADY_i  ( hmac.r_ready   ),
        .PENABLE   ( hmac_penable   ),
        .PWRITE    ( hmac_pwrite    ),
        .PADDR     ( hmac_paddr     ),
        .PSEL      ( hmac_psel      ),
        .PWDATA    ( hmac_pwdata    ),
        .PRDATA    ( hmac_prdata    ),
        .PREADY    ( hmac_pready    ),
        .PSLVERR   ( hmac_pslverr   )
    );

    apb_to_reg i_apb_to_reg_hmac (
        .clk_i     ( clk_i        ),
        .rst_ni    ( rst_ni       ),
        .penable_i ( hmac_penable ),
        .pwrite_i  ( hmac_pwrite  ),
        .paddr_i   ( hmac_paddr   ),
        .psel_i    ( hmac_psel    ),
        .pwdata_i  ( hmac_pwdata  ),
        .prdata_o  ( hmac_prdata  ),
        .pready_o  ( hmac_pready  ),
        .pslverr_o ( hmac_pslverr ),
        .reg_o     ( reg_bus_hmac )
    );

    hmac_wrapper #(
    ) i_hmac_wrapper (
        .clk_i              ( clk_i                  ),
        .rst_ni             ( rst_ni                 ),
        .reglk_ctrl_i       ( reglk_ctrl[8*ariane_soc::HMAC+8-1:8*ariane_soc::HMAC] ),
        .external_bus_io    ( reg_bus_hmac         )
    );


///////////////////////////////////////////////////////////////////////////////////////



    // ---------------
    // 10. SPI
    // ---------------
    if (InclSPI) begin : gen_spi
        logic [31:0] s_axi_spi_awaddr;
        logic [7:0]  s_axi_spi_awlen;
        logic [2:0]  s_axi_spi_awsize;
        logic [1:0]  s_axi_spi_awburst;
        logic [0:0]  s_axi_spi_awlock;
        logic [3:0]  s_axi_spi_awcache;
        logic [2:0]  s_axi_spi_awprot;
        logic [3:0]  s_axi_spi_awregion;
        logic [3:0]  s_axi_spi_awqos;
        logic        s_axi_spi_awvalid;
        logic        s_axi_spi_awready;
        logic [31:0] s_axi_spi_wdata;
        logic [3:0]  s_axi_spi_wstrb;
        logic        s_axi_spi_wlast;
        logic        s_axi_spi_wvalid;
        logic        s_axi_spi_wready;
        logic [1:0]  s_axi_spi_bresp;
        logic        s_axi_spi_bvalid;
        logic        s_axi_spi_bready;
        logic [31:0] s_axi_spi_araddr;
        logic [7:0]  s_axi_spi_arlen;
        logic [2:0]  s_axi_spi_arsize;
        logic [1:0]  s_axi_spi_arburst;
        logic [0:0]  s_axi_spi_arlock;
        logic [3:0]  s_axi_spi_arcache;
        logic [2:0]  s_axi_spi_arprot;
        logic [3:0]  s_axi_spi_arregion;
        logic [3:0]  s_axi_spi_arqos;
        logic        s_axi_spi_arvalid;
        logic        s_axi_spi_arready;
        logic [31:0] s_axi_spi_rdata;
        logic [1:0]  s_axi_spi_rresp;
        logic        s_axi_spi_rlast;
        logic        s_axi_spi_rvalid;
        logic        s_axi_spi_rready;

        xlnx_axi_clock_converter i_xlnx_axi_clock_converter_spi (
            .s_axi_aclk     ( clk_i              ),
            .s_axi_aresetn  ( rst_ni             ),

            .s_axi_awid     ( spi.aw_id          ),
            .s_axi_awaddr   ( spi.aw_addr[31:0]  ),
            .s_axi_awlen    ( spi.aw_len         ),
            .s_axi_awsize   ( spi.aw_size        ),
            .s_axi_awburst  ( spi.aw_burst       ),
            .s_axi_awlock   ( spi.aw_lock        ),
            .s_axi_awcache  ( spi.aw_cache       ),
            .s_axi_awprot   ( spi.aw_prot        ),
            .s_axi_awregion ( spi.aw_region      ),
            .s_axi_awqos    ( spi.aw_qos         ),
            .s_axi_awvalid  ( spi.aw_valid       ),
            .s_axi_awready  ( spi.aw_ready       ),
            .s_axi_wdata    ( spi.w_data         ),
            .s_axi_wstrb    ( spi.w_strb         ),
            .s_axi_wlast    ( spi.w_last         ),
            .s_axi_wvalid   ( spi.w_valid        ),
            .s_axi_wready   ( spi.w_ready        ),
            .s_axi_bid      ( spi.b_id           ),
            .s_axi_bresp    ( spi.b_resp         ),
            .s_axi_bvalid   ( spi.b_valid        ),
            .s_axi_bready   ( spi.b_ready        ),
            .s_axi_arid     ( spi.ar_id          ),
            .s_axi_araddr   ( spi.ar_addr[31:0]  ),
            .s_axi_arlen    ( spi.ar_len         ),
            .s_axi_arsize   ( spi.ar_size        ),
            .s_axi_arburst  ( spi.ar_burst       ),
            .s_axi_arlock   ( spi.ar_lock        ),
            .s_axi_arcache  ( spi.ar_cache       ),
            .s_axi_arprot   ( spi.ar_prot        ),
            .s_axi_arregion ( spi.ar_region      ),
            .s_axi_arqos    ( spi.ar_qos         ),
            .s_axi_arvalid  ( spi.ar_valid       ),
            .s_axi_arready  ( spi.ar_ready       ),
            .s_axi_rid      ( spi.r_id           ),
            .s_axi_rdata    ( spi.r_data         ),
            .s_axi_rresp    ( spi.r_resp         ),
            .s_axi_rlast    ( spi.r_last         ),
            .s_axi_rvalid   ( spi.r_valid        ),
            .s_axi_rready   ( spi.r_ready        ),

            .m_axi_awaddr   ( s_axi_spi_awaddr   ),
            .m_axi_awlen    ( s_axi_spi_awlen    ),
            .m_axi_awsize   ( s_axi_spi_awsize   ),
            .m_axi_awburst  ( s_axi_spi_awburst  ),
            .m_axi_awlock   ( s_axi_spi_awlock   ),
            .m_axi_awcache  ( s_axi_spi_awcache  ),
            .m_axi_awprot   ( s_axi_spi_awprot   ),
            .m_axi_awregion ( s_axi_spi_awregion ),
            .m_axi_awqos    ( s_axi_spi_awqos    ),
            .m_axi_awvalid  ( s_axi_spi_awvalid  ),
            .m_axi_awready  ( s_axi_spi_awready  ),
            .m_axi_wdata    ( s_axi_spi_wdata    ),
            .m_axi_wstrb    ( s_axi_spi_wstrb    ),
            .m_axi_wlast    ( s_axi_spi_wlast    ),
            .m_axi_wvalid   ( s_axi_spi_wvalid   ),
            .m_axi_wready   ( s_axi_spi_wready   ),
            .m_axi_bresp    ( s_axi_spi_bresp    ),
            .m_axi_bvalid   ( s_axi_spi_bvalid   ),
            .m_axi_bready   ( s_axi_spi_bready   ),
            .m_axi_araddr   ( s_axi_spi_araddr   ),
            .m_axi_arlen    ( s_axi_spi_arlen    ),
            .m_axi_arsize   ( s_axi_spi_arsize   ),
            .m_axi_arburst  ( s_axi_spi_arburst  ),
            .m_axi_arlock   ( s_axi_spi_arlock   ),
            .m_axi_arcache  ( s_axi_spi_arcache  ),
            .m_axi_arprot   ( s_axi_spi_arprot   ),
            .m_axi_arregion ( s_axi_spi_arregion ),
            .m_axi_arqos    ( s_axi_spi_arqos    ),
            .m_axi_arvalid  ( s_axi_spi_arvalid  ),
            .m_axi_arready  ( s_axi_spi_arready  ),
            .m_axi_rdata    ( s_axi_spi_rdata    ),
            .m_axi_rresp    ( s_axi_spi_rresp    ),
            .m_axi_rlast    ( s_axi_spi_rlast    ),
            .m_axi_rvalid   ( s_axi_spi_rvalid   ),
            .m_axi_rready   ( s_axi_spi_rready   )
        );

        xlnx_axi_quad_spi i_xlnx_axi_quad_spi (
            .ext_spi_clk    ( clk_i                  ),
            .s_axi4_aclk    ( clk_i                  ),
            .s_axi4_aresetn ( rst_ni                 ),
            .s_axi4_awaddr  ( s_axi_spi_awaddr[23:0] ),
            .s_axi4_awlen   ( s_axi_spi_awlen        ),
            .s_axi4_awsize  ( s_axi_spi_awsize       ),
            .s_axi4_awburst ( s_axi_spi_awburst      ),
            .s_axi4_awlock  ( s_axi_spi_awlock       ),
            .s_axi4_awcache ( s_axi_spi_awcache      ),
            .s_axi4_awprot  ( s_axi_spi_awprot       ),
            .s_axi4_awvalid ( s_axi_spi_awvalid      ),
            .s_axi4_awready ( s_axi_spi_awready      ),
            .s_axi4_wdata   ( s_axi_spi_wdata        ),
            .s_axi4_wstrb   ( s_axi_spi_wstrb        ),
            .s_axi4_wlast   ( s_axi_spi_wlast        ),
            .s_axi4_wvalid  ( s_axi_spi_wvalid       ),
            .s_axi4_wready  ( s_axi_spi_wready       ),
            .s_axi4_bresp   ( s_axi_spi_bresp        ),
            .s_axi4_bvalid  ( s_axi_spi_bvalid       ),
            .s_axi4_bready  ( s_axi_spi_bready       ),
            .s_axi4_araddr  ( s_axi_spi_araddr[23:0] ),
            .s_axi4_arlen   ( s_axi_spi_arlen        ),
            .s_axi4_arsize  ( s_axi_spi_arsize       ),
            .s_axi4_arburst ( s_axi_spi_arburst      ),
            .s_axi4_arlock  ( s_axi_spi_arlock       ),
            .s_axi4_arcache ( s_axi_spi_arcache      ),
            .s_axi4_arprot  ( s_axi_spi_arprot       ),
            .s_axi4_arvalid ( s_axi_spi_arvalid      ),
            .s_axi4_arready ( s_axi_spi_arready      ),
            .s_axi4_rdata   ( s_axi_spi_rdata        ),
            .s_axi4_rresp   ( s_axi_spi_rresp        ),
            .s_axi4_rlast   ( s_axi_spi_rlast        ),
            .s_axi4_rvalid  ( s_axi_spi_rvalid       ),
            .s_axi4_rready  ( s_axi_spi_rready       ),

            .io0_i          ( '0                     ),
            .io0_o          ( spi_mosi               ),
            .io0_t          ( '0                     ),
            .io1_i          ( spi_miso               ),
            .io1_o          (                        ),
            .io1_t          ( '0                     ),
            .ss_i           ( '0                     ),
            .ss_o           ( spi_ss                 ),
            .ss_t           ( '0                     ),
            .sck_o          ( spi_clk_o              ),
            .sck_i          ( '0                     ),
            .sck_t          (                        ),
            .ip2intc_irpt   ( irq_sources[1]         )
            // .ip2intc_irpt   ( irq_sources[1]         )
        );
        // assign irq_sources [1] = 1'b0;
    end else begin
        assign spi_clk_o = 1'b0;
        assign spi_mosi = 1'b0;
        assign spi_ss = 1'b0;

        assign irq_sources [1] = 1'b0;
        assign spi.aw_ready = 1'b1;
        assign spi.ar_ready = 1'b1;
        assign spi.w_ready = 1'b1;

        assign spi.b_valid = spi.aw_valid;
        assign spi.b_id = spi.aw_id;
        assign spi.b_resp = axi_pkg::RESP_SLVERR;
        assign spi.b_user = '0;

        assign spi.r_valid = spi.ar_valid;
        assign spi.r_resp = axi_pkg::RESP_SLVERR;
        assign spi.r_data = 'hdeadbeef;
        assign spi.r_last = 1'b1;
    end


    // ---------------
    // 11. Ethernet
    // ---------------
    if (0)
      begin
      end
    else
      begin
        assign irq_sources [2] = 1'b0;
        assign ethernet.aw_ready = 1'b1;
        assign ethernet.ar_ready = 1'b1;
        assign ethernet.w_ready = 1'b1;

        assign ethernet.b_valid = ethernet.aw_valid;
        assign ethernet.b_id = ethernet.aw_id;
        assign ethernet.b_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.b_user = '0;

        assign ethernet.r_valid = ethernet.ar_valid;
        assign ethernet.r_resp = axi_pkg::RESP_SLVERR;
        assign ethernet.r_data = 'hdeadbeef;
        assign ethernet.r_last = 1'b1;
    end

    // ---------------
    // 12. Timer
    // ---------------
    if (InclTimer) begin : gen_timer
        logic         timer_penable;
        logic         timer_pwrite;
        logic [31:0]  timer_paddr;
        logic         timer_psel;
        logic [31:0]  timer_pwdata;
        logic [31:0]  timer_prdata;
        logic         timer_pready;
        logic         timer_pslverr;

        axi2apb_64_32 #(
            .AXI4_ADDRESS_WIDTH ( AxiAddrWidth ),
            .AXI4_RDATA_WIDTH   ( AxiDataWidth ),
            .AXI4_WDATA_WIDTH   ( AxiDataWidth ),
            .AXI4_ID_WIDTH      ( AxiIdWidth   ),
            .AXI4_USER_WIDTH    ( AxiUserWidth ),
            .BUFF_DEPTH_SLAVE   ( 2            ),
            .APB_ADDR_WIDTH     ( 32           )
        ) i_axi2apb_64_32_timer (
            .ACLK      ( clk_i           ),
            .ARESETn   ( rst_ni          ),
            .test_en_i ( 1'b0            ),
            .AWID_i    ( timer.aw_id     ),
            .AWADDR_i  ( timer.aw_addr   ),
            .AWLEN_i   ( timer.aw_len    ),
            .AWSIZE_i  ( timer.aw_size   ),
            .AWBURST_i ( timer.aw_burst  ),
            .AWLOCK_i  ( timer.aw_lock   ),
            .AWCACHE_i ( timer.aw_cache  ),
            .AWPROT_i  ( timer.aw_prot   ),
            .AWREGION_i( timer.aw_region ),
            .AWUSER_i  ( timer.aw_user   ),
            .AWQOS_i   ( timer.aw_qos    ),
            .AWVALID_i ( timer.aw_valid  ),
            .AWREADY_o ( timer.aw_ready  ),
            .WDATA_i   ( timer.w_data    ),
            .WSTRB_i   ( timer.w_strb    ),
            .WLAST_i   ( timer.w_last    ),
            .WUSER_i   ( timer.w_user    ),
            .WVALID_i  ( timer.w_valid   ),
            .WREADY_o  ( timer.w_ready   ),
            .BID_o     ( timer.b_id      ),
            .BRESP_o   ( timer.b_resp    ),
            .BVALID_o  ( timer.b_valid   ),
            .BUSER_o   ( timer.b_user    ),
            .BREADY_i  ( timer.b_ready   ),
            .ARID_i    ( timer.ar_id     ),
            .ARADDR_i  ( timer.ar_addr   ),
            .ARLEN_i   ( timer.ar_len    ),
            .ARSIZE_i  ( timer.ar_size   ),
            .ARBURST_i ( timer.ar_burst  ),
            .ARLOCK_i  ( timer.ar_lock   ),
            .ARCACHE_i ( timer.ar_cache  ),
            .ARPROT_i  ( timer.ar_prot   ),
            .ARREGION_i( timer.ar_region ),
            .ARUSER_i  ( timer.ar_user   ),
            .ARQOS_i   ( timer.ar_qos    ),
            .ARVALID_i ( timer.ar_valid  ),
            .ARREADY_o ( timer.ar_ready  ),
            .RID_o     ( timer.r_id      ),
            .RDATA_o   ( timer.r_data    ),
            .RRESP_o   ( timer.r_resp    ),
            .RLAST_o   ( timer.r_last    ),
            .RUSER_o   ( timer.r_user    ),
            .RVALID_o  ( timer.r_valid   ),
            .RREADY_i  ( timer.r_ready   ),
            .PENABLE   ( timer_penable   ),
            .PWRITE    ( timer_pwrite    ),
            .PADDR     ( timer_paddr     ),
            .PSEL      ( timer_psel      ),
            .PWDATA    ( timer_pwdata    ),
            .PRDATA    ( timer_prdata    ),
            .PREADY    ( timer_pready    ),
            .PSLVERR   ( timer_pslverr   )
        );

        apb_timer #(
                .APB_ADDR_WIDTH ( 32 ),
                .TIMER_CNT      ( 2  )
        ) i_timer (
            .HCLK    ( clk_i            ),
            .HRESETn ( rst_ni           ),
            .PSEL    ( timer_psel       ),
            .PENABLE ( timer_penable    ),
            .PWRITE  ( timer_pwrite     ),
            .PADDR   ( timer_paddr      ),
            .PWDATA  ( timer_pwdata     ),
            .PRDATA  ( timer_prdata     ),
            .PREADY  ( timer_pready     ),
            .PSLVERR ( timer_pslverr    ),
            .irq_o   ( irq_sources[6:3] )
        );
    end
endmodule
