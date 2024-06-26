`timescale 1ns / 10ps
import data_pkg::*;

module top();

bit [I2C_DATA_WIDTH] i2c_write_data [];
bit [I2C_DATA_WIDTH] i2c_read_data [];
bit [7:0] wb_data;
bit [7:0] cmdr_temp;
bit i2c_op;


bit [7:0] monitor_i2c_addr;
i2c_op_t monitor_i2c_op;
bit [7:0] monitor_i2c_data [];

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
// Monitor Wishbone bus and display transfers in the transcript

initial
  begin : wb_monitoring
    wb_bus.master_monitor(monitor_addr,monitor_data,monitor_we);
    $display("addr: %x\ndata: %x\nwe: %x\n", monitor_addr, monitor_data, monitor_we);
  end

// ****************************************************************************
// Call i2c_bus.monitor

initial
  forever begin : monitor_i2c_bus
      i2c_bus.monitor(monitor_i2c_addr, monitor_i2c_op, monitor_i2c_data);

      if (monitor_i2c_op == I2C_READ) $display("I2C_BUS READ Transfer: ADDR - %x", monitor_i2c_addr);
      else $display("I2C_BUS WRITE Transfer: ADDR - %x", monitor_i2c_addr);

      $write("DATA - ");
      for (int i; i < monitor_i2c_data.size(); i++) $write("%d ", $unsigned(monitor_i2c_data[i]));
      $write("\n");

      // $display("monitor_i2c_addr: %x\nmonitor_i2c_op: %x\nmonitor_i2c_data: %d\n", monitor_i2c_addr, monitor_i2c_op, monitor_i2c_data);
  end

// ****************************************************************************
// Define the flow of the simulation

initial
  begin : test_flow
  while(rst) @(clk) 
  begin
  #1000


  // ==========================================================
  // ================= test stimulus #1 =======================
  // Write 32 incrementing values, from 0 to 31, to the i2c_bus
  // ==========================================================
  $display("===== START TEST 1 =====");
  fork
    begin
      set_bus(8'h05); // set bus 5
      issue_start();
      write_data(8'h44); // set address 22 + 0      
      for (int i = 0; i < 32; i++) begin
        wb_data = i;
        write_data(wb_data);
      end
      issue_stop();
    end
    begin
      i2c_bus.wait_for_i2c_transfer(i2c_op, i2c_write_data);
    end
  join

  #1000

  $display("===== FINISH TEST 1 =====\n\n");
  
  $display("===== START TEST 2 =====");

  // ==========================================================
  // ================= test stimulus #2 =======================
  // Read 32 values from the i2c_bus (expecting 100 - 131)
  // ==========================================================  
  fork
    begin // TASK 1: SET THE DATA TO BE READ
      bit transfer_complete;
      bit [7:0] insert_byte;
      bit [7:0] read_set [32];
      for (int i = 0; i < 32; i++) begin
        insert_byte = i + 100;
        read_set[i] = insert_byte;
      end
      transfer_complete = 1'b0;
      i2c_bus.provide_read_data(read_set, transfer_complete);
      end
    begin // TASK 2: ISSUE THE WISHBONE READ COMMANDS
      set_bus(8'h05); // set bus 5
      issue_start();
      write_data(8'h45); // set address 22 + 1          
      read_data(i2c_read_data, 32);
      issue_stop();
    end
    begin // TASK 3: I2C DRIVES THE SDA
      i2c_bus.wait_for_i2c_transfer(i2c_op, i2c_write_data);
    end
  join

#1000;

  $display("===== FINISH TEST 2 =====\n\n");
  
  $display("===== START TEST 3 =====");

  // =========================================================
  // ================= test stimulus #3 =======================
  // Alternate writes and reads for 64 transfers (W: 64-127) / (R: 63-0)
  // ==========================================================  
  fork
    begin // TASK 1: SET THE DATA TO BE READ
      bit transfer_complete;
      bit [7:0] insert_byte;
      bit [7:0] read_set [64];
      for (int i = 0; i < 63; i++) begin
        insert_byte = 63 - i;
        read_set[i] = insert_byte;
      end
      transfer_complete = 1'b0;
      i2c_bus.provide_read_data(read_set, transfer_complete);
    end
    begin // TASK 2: ISSUE THE WISHBONE READ COMMANDS

      set_bus(8'h05); // set bus 5
      
      for(int i; i < 64; i++ ) begin

        // do 1 write
        issue_start();
        write_data(8'h44); // set address 22 + 0  
        wb_data = 64 + i;
        write_data(wb_data);

        // do 1 read
        issue_start();
        write_data(8'h45); // set address 22 + 1          
        read_data(i2c_read_data, 1);


      end
    issue_stop();

    end
    begin // TASK 3: I2C DRIVES THE SDA
      i2c_bus.wait_for_i2c_transfer(i2c_op, i2c_write_data);
    end
  join

  #1000;

  $display("===== FINISH TEST 3 =====\n\n");

end // while loop
end // test flow initial block

// ==========================================================
// ==========   task to send read from slave ================
// ==========================================================
task read_data(output bit [I2C_DATA_WIDTH-1:0] data [], input int num_reads );
    bit [WB_DATA_WIDTH-1:0] temp;

    data = new[num_reads];
    temp = 8'h45;

    for (int i = 0; i < (num_reads - 1); i++) begin
        wb_bus.master_write(CMDR, 8'bxxxx_x010);
        wait(irq);
        wb_bus.master_read(DPR, temp);
        data[i] = temp;
        //$display("data[%d]: %d", i, data[i])
        wb_bus.master_read(CMDR, temp);
    end

    wb_bus.master_write(CMDR, 8'bxxxx_x011);
    wait(irq);
    wb_bus.master_read(DPR, temp);
    data[num_reads] = temp;
    //$display("data[%d]: %d", i, data[i])
    wb_bus.master_read(CMDR, temp);    

endtask

// ==========================================================
// =============  task to set the i2c bus ===================
// ==========================================================
task set_bus(input [7:0] bus_number);

  wb_bus.master_write(CSR,8'b11xx_xxxx); // one time initialization
  wb_bus.master_write(DPR, bus_number); // data to go to bus, either address or data
  wb_bus.master_write(CMDR,8'bxxxx_x110); // "do a bus set to bus 5" - the only bus we will 
  wait(irq); // the dut agreed, will use bus 5
  wb_bus.master_read(CMDR, cmdr_temp);

endtask

task issue_start(); 

  wb_bus.master_write(CMDR,8'bxxxx_x100); // one time "we are starting now"
  wait(irq); // DUT agrees that i2c is started
  wb_bus.master_read(CMDR, cmdr_temp);
  // wait(irq);

endtask

// ==========================================================
// =========  task to put data on the i2c bus ===============
// ==========================================================
task write_data(input [7:0] data);

  wb_bus.master_write(DPR, data); // arbitrary address to send data to
  wb_bus.master_write(CMDR,8'bxxxx_x001); // put the addresss on the bus "write"
  wait(irq); // wait for the DUT to indicate that it knows we are using address 22
  wb_bus.master_read(CMDR, cmdr_temp);
  // wait(irq);

endtask

// ==========================================================
// ===========   task to send the stop bit  =================
// ==========================================================
task issue_stop();

  wb_bus.master_write(CMDR,8'bxxxx_x101);
  wait(irq);
  wb_bus.master_read(CMDR, cmdr_temp);
  // wait(irq);  

endtask


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


// INSTANTIATIONS

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

endmodule