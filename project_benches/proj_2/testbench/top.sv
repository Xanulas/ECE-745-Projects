`timescale 1ns / 10ps
import data_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import ncsu_pkg::*;
import i2cmb_env_pkg::*;

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

bit [I2C_DATA_WIDTH] i2c_write_data [];
bit [I2C_DATA_WIDTH] i2c_read_data [];
bit [WB_ADDR_WIDTH-1:0] wb_data;
bit [WB_ADDR_WIDTH-1:0] cmdr_temp;
bit i2c_op;


bit [I2C_ADDR_WIDTH-1:0] monitor_i2c_addr;
i2c_op_t monitor_i2c_op;
bit [I2C_ADDR_WIDTH-1:0] monitor_i2c_data [];

parameter 
  CSR = 8'h00,
  DPR = 8'h01,
  CMDR = 8'h02,
  FSMR = 8'h03;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

bit monitor_we;
reg [WB_ADDR_WIDTH-1:0] monitor_addr;
reg [WB_DATA_WIDTH-1:0] monitor_data;

// ****************************************************************************
// Clock generator

initial
  begin : clk_gen
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

// ****************************************************************************
// Reset generator

initial
  begin : rst_gen
    rst = 1'b1;
    #113 rst = 0;
  end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

// ****************************************************************************
// Instantiate the I2C BFM
i2c_if       #(
      .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
      .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
      )
i2c_bus (
  .scl_i(scl),
  .sda_i(sda),
  .scl_o(scl),
  .sda_o(sda)
);


i2cmb_test test;

initial begin : test_flow
  test = new("test", null);
  ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test.env.wb_agent",wb_bus);
  ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test.env.i2c_agent",i2c_bus);
end

endmodule