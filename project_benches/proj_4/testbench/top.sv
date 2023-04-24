`timescale 1ns / 10ps
import data_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import ncsu_pkg::*;
import i2cmb_env_pkg::*;

module top();

bit [I2C_DATA_WIDTH] i2c_write_data [];
bit [I2C_DATA_WIDTH] i2c_read_data [];
bit [WB_ADDR_WIDTH-1:0] wb_data;
bit [WB_ADDR_WIDTH-1:0] cmdr_temp;
bit i2c_op;


bit [I2C_ADDR_WIDTH-1:0] monitor_i2c_addr;
i2c_op_t monitor_i2c_op;
bit [I2C_ADDR_WIDTH-1:0] monitor_i2c_data [];

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
  .irq_i(irq),
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



i2cmb_test                    test_1;
test_i2cmb_consecutive_starts test_2;
test_i2cmb_consecutive_stops  test_3;
test_i2cmb_reg_addr           test_4;
test_i2cmb_reg_vals           test_5;
test_i2cmb_rw_ability         test_6;
test_i2cmb_busses             test_7;
test_i2cmb_directed           test_8;
test_i2cmb_randomized         test_9;


property i2cmb_arbitration;
  @(posedge clk) 1'b1;
endproperty
assert property(i2cmb_arbitration) else $error("i2cmb_arbitration assertion failed!");

initial begin : test_flow

  string test_name;

  $value$plusargs("GEN_TRANS_TYPE=%s", test_name);


  case(test_name)
    "i2cmb_test" : begin
      $display("====================================================");
      $display("               BEGIN TEST 1: i2cmb_test             ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_1.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_1.env.i2c_agent_env",i2c_bus);       
      test_1 = new("test_1", null);
      test_1.run();

      $display("====================================================");
      $display("               END TEST 1: i2cmb_test               ");
      $display("====================================================");

      $finish;
    end
    "test_i2cmb_consecutive_starts" : begin
      $display("====================================================");
      $display("    BEGIN TEST 2: test_i2cmb_consecutive_starts     ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_2.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_2.env.i2c_agent_env",i2c_bus);       
      test_2 = new("test_2", null);
      test_2.run();

      $display("====================================================");
      $display("    END TEST 2: test_i2cmb_consecutive_starts       ");
      $display("====================================================");

      $finish;        
    end    
    "test_i2cmb_consecutive_stops" : begin
      $display("====================================================");
      $display("    BEGIN TEST 3: test_i2cmb_consecutive_stops      ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_3.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_3.env.i2c_agent_env",i2c_bus);       
      test_3 = new("test_3", null);
      test_3.run(); 

      $display("====================================================");
      $display("    END TEST 3: test_i2cmb_consecutive_stops        ");
      $display("====================================================");

      $finish;          
    end
    "test_i2cmb_reg_addr" : begin
      $display("====================================================");
      $display("         BEGIN TEST 4: test_i2cmb_reg_addr          ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_4.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_4.env.i2c_agent_env",i2c_bus);       
      test_4 = new("test_4", null);
      test_4.run(); 

      $display("====================================================");
      $display("         END TEST 4: test_i2cmb_reg_addr            ");
      $display("====================================================");

      $finish;           
    end
    "test_i2cmb_reg_vals" : begin
      $display("====================================================");
      $display("         BEGIN TEST 5: test_i2cmb_reg_vals          ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_5.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_5.env.i2c_agent_env",i2c_bus);       
      test_5 = new("test_5", null);
      test_5.run(); 

      $display("====================================================");
      $display("         END TEST 5: test_i2cmb_reg_vals            ");
      $display("====================================================");

      $finish;           
    end
    "test_i2cmb_rw_ability" : begin
      $display("====================================================");
      $display("       BEGIN TEST 6: test_i2cmb_rw_ability          ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_6.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_6.env.i2c_agent_env",i2c_bus);       
      test_6 = new("test_6", null);
      test_6.run(); 

      $display("====================================================");
      $display("       END TEST 6: test_i2cmb_rw_ability            ");
      $display("====================================================");

      $finish;         
    end
    "test_i2cmb_busses" : begin
      $display("====================================================");
      $display("          BEGIN TEST 7: test_i2cmb_busses           ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_7.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_7.env.i2c_agent_env",i2c_bus);       
      test_7 = new("test_7", null);
      test_7.run();

      $display("====================================================");
      $display("          END TEST 7: test_i2cmb_busses             ");
      $display("====================================================");

      $finish;         
    end     
    "test_i2cmb_directed" : begin
      $display("====================================================");
      $display("          BEGIN TEST 8: test_i2cmb_directed         ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_8.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_8.env.i2c_agent_env",i2c_bus);       
      test_8 = new("test_8", null);
      test_8.run();

      $display("====================================================");
      $display("          END TEST 8: test_i2cmb_directed           ");
      $display("====================================================");

      $finish;         
    end   
    "test_i2cmb_randomized" : begin
      $display("====================================================");
      $display("          BEGIN TEST 9: test_i2cmb_randomized       ");
      $display("====================================================");      

      ncsu_config_db#(virtual wb_if#(WB_ADDR_WIDTH,WB_DATA_WIDTH))::set("test_9.env.wb_agent_env",wb_bus);
      ncsu_config_db#(virtual i2c_if#(I2C_ADDR_WIDTH,I2C_DATA_WIDTH))::set("test_9.env.i2c_agent_env",i2c_bus);       
      test_9 = new("test_9", null);
      test_9.run();

      $display("====================================================");
      $display("          END TEST 9: test_i2cmb_randomized         ");
      $display("====================================================");

      $finish;         
    end              
  default: $display("specified test not found!");                  
  endcase

end
endmodule