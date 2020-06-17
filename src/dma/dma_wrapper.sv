///////////////////////////////////////////
//
// File Name : dma_wrapper.sv
//
// Version info : 
//
// Assumptions : 
//      1) ADDR_WIDTH == DATA_WIDTH
//      2) Max length == 255        
///////////////////////////////////////////


import ariane_axi::*;

module dma_wrapper #(
    parameter int ADDR_WIDTH         = 32,   // width of external address bus
    parameter int DATA_WIDTH         = 32   // width of external data bus
)
(
    clk_i,
    rst_ni,
    external_bus_io, 

    axi_req_o, 
    axi_resp_i
);

    // parameters
    localparam CONF_START = 0; 
    localparam CONF_CLR_DONE = 1;
    localparam AXI_ADDR_WIDTH = ariane_axi::AddrWidth; 
    localparam AXI_DATA_WIDTH = ariane_axi::DataWidth;
    localparam AXI_LEN_WIDTH = 8; 
    localparam AXI_SIZE_WIDTH = 3; 
    localparam AXI_ID_WIDTH = ariane_soc::IdWidth;


    input  logic                   clk_i;
    input  logic                   rst_ni;
    REG_BUS.in                     external_bus_io;

    output ariane_axi::req_t  axi_req_o;
    input  ariane_axi::resp_t axi_resp_i;

    // internal signals
    
    logic [DATA_WIDTH-1:0] config_reg; 
    logic [DATA_WIDTH-1:0] length_reg;
    logic [DATA_WIDTH-1:0] source_addr_reg; 
    logic [DATA_WIDTH-1:0] dest_addr_reg; 
    logic [DATA_WIDTH-1:0] state_w;
    
    assign external_bus_io.ready = 1'b1;
    assign external_bus_io.error = 1'b0;
    
    ///////////////////////////////////////////////////////////////////////////
    // Implement APB I/O map to DMA interface
    // Write side
    always @(posedge clk_i)
        begin
            if(~rst_ni)
                begin
                    config_reg <= 'b0; 
                    length_reg <= 'b0; 
                    source_addr_reg<= 'b0; 
                    dest_addr_reg  <= 'b0; 
                end
            else if(external_bus_io.write)
                case(external_bus_io.addr[4:2])
                    0:
                        config_reg <= external_bus_io.wdata;
                    1:
                        length_reg <= external_bus_io.wdata;
                    2:
                        source_addr_reg <= external_bus_io.wdata;
                    3:
                        dest_addr_reg <= external_bus_io.wdata;
                    default:
                        ;
                endcase
        end // always @ (posedge wb_clk_i)
    
    // Implement APB I/O memory map interface
    // Read side
    //always @(~external_bus_io.write)
    always @(*)
        begin
            case(external_bus_io.addr[4:2])
                0:
                    external_bus_io.rdata = config_reg; 
                1:
                    external_bus_io.rdata = length_reg; 
                2:
                    external_bus_io.rdata = source_addr_reg; 
                3:
                    external_bus_io.rdata = dest_addr_reg; 
                4: 
                    external_bus_io.rdata = state_w; 
                default:
                    external_bus_io.rdata = 32'b0;
            endcase
        end // always @ (*)
    
    
    ///////////////////////////////////////////////////////////////////////////
    // Instantiate the DMA module containing the DAM controller and the AXI master interf
    dma #(
        .CONF_START     ( CONF_START     ),  
        .CONF_CLR_DONE  ( CONF_CLR_DONE  ),
        .DATA_WIDTH     ( DATA_WIDTH     ),  
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_LEN_WIDTH  ( AXI_LEN_WIDTH  ),
        .AXI_SIZE_WIDTH ( AXI_SIZE_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ) 
    ) u_dma (
       .clk_i         ( clk_i           ),
       .rst_ni        ( rst_ni          ),
       .config_i      ( config_reg      ), 
       .length_i      ( length_reg      ), 
       .source_addr_i ( source_addr_reg ), 
       .dest_addr_i   ( dest_addr_reg   ), 
       .state_o       ( state_w         ),

       .axi_ad_axi_req_o( axi_req_o  ),
       .axi_resp_i      ( axi_resp_i )  
    );
    
//    always @*
//    begin
//    if(external_bus_io.wdata != 0)
//        $display("DMA WDATA: %h", external_bus_io.wdata);
//    if(external_bus_io.rdata != 0)
//        $display("DMA RDATA: %h", external_bus_io.rdata);
//    end
//

endmodule

