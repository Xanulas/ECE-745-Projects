// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component;

  class random_i2c_transaction;
    rand bit [I2C_ADDR_WIDTH-1:0] addr;
    rand bit [I2C_DATA_WIDTH-1:0] data;
  endclass

  wb_transaction wb_trans_queue [$];
  i2c_transaction i2c_trans_queue [$];  

  i2c_transaction i2c_trans;
  wb_transaction wb_trans;  
  i2cmb_predictor pred;

  i2c_agent i2c_agent_gen;
  wb_agent wb_agent_gen;
  string trans_name;

  bit [WB_DATA_WIDTH-1:0] test_two_data [32];
  bit [WB_DATA_WIDTH-1:0] test_three_data [64];  

  wb_transaction wb_trans_insert;
  int size;

  bit [I2C_DATA_WIDTH-1:0] i2c_data [];

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_agent_i2c(i2c_agent agent);
    this.i2c_agent_gen = agent;
  endfunction

  function void set_agent_wb(wb_agent agent);
    this.wb_agent_gen = agent;
  endfunction  

  function void set_predictor(i2cmb_predictor pred);
    this.pred = pred;
  endfunction

  virtual task run();

    send_to_wb_bl_put("csr init", WB_WRITE, CSR, CSR_INIT);
    send_to_wb_bl_put("choose bus", WB_WRITE, DPR, (8'h05));
    send_to_wb_bl_put("perform write to bus", WB_WRITE, CMDR, CMDR_SET_BUS);   

    // $display("+------------------------------------------------------+");
    // $display("|                 BEGIN TEST 1                         |");
    // $display("+------------------------------------------------------+");

    i2c_trans = new("TEST 1 WRITE DATA");
    i2c_data = new[32];
    i2c_trans.addr = 8'h22;
    i2c_trans.data = i2c_data;
    i2c_trans.op = I2C_WRITE;
 
    fork
      begin
        size = wb_trans_queue.size();
        for(int i = 0; i < size; i++)
          wb_agent_gen.bl_put(wb_trans_queue.pop_back());     
      end
      begin
        i2c_agent_gen.bl_put(i2c_trans);
      end
    join

    // $display("+------------------------------------------------------+");
    // $display("|                   END TEST 1                         |");
    // $display("+------------------------------------------------------+\n\n\n");    

    // $display("+------------------------------------------------------+");
    // $display("|                 BEGIN TEST 2                         |");
    // $display("+------------------------------------------------------+");

    this.read_wb(test_two_data, 8'h22);

    i2c_trans = new("TEST 2 READ DATA");
    i2c_data = new[32];
    for(int i = 0; i < 32; i++)
      i2c_data[i] = 100 + i;

    i2c_trans.addr = 8'h22;
    i2c_trans.data = i2c_data;
    i2c_trans.op = I2C_READ;
    pred.populate_pred_rd_queue(i2c_data);

    fork
      begin
        size = wb_trans_queue.size();
        for(int i = 0; i < size; i++)
          wb_agent_gen.bl_put(wb_trans_queue.pop_back());     
      end
      begin
        i2c_agent_gen.bl_put(i2c_trans);
      end
    join

    // $display("+------------------------------------------------------+");
    // $display("|                   END TEST 2                         |");
    // $display("+------------------------------------------------------+\n\n\n");   

    // $display("+------------------------------------------------------+");
    // $display("|                 BEGIN TEST 3                         |");
    // $display("+------------------------------------------------------+");    

    this.alternate_rw_wb(test_three_data, 8'h22);

    i2c_trans = new("TEST 3 READ DATA");
    i2c_data = new[64];
    for(int i = 0; i < 64; i++)
      i2c_data[i] = 63 - i;
    i2c_trans.addr = 8'h22;
    i2c_trans.data = i2c_data;
    i2c_trans.op = I2C_READ;
    pred.populate_pred_rd_queue(i2c_data);    

    fork
      begin
        size = wb_trans_queue.size();
        for(int i = 0; i < size; i++)
          wb_agent_gen.bl_put(wb_trans_queue.pop_back());     
      end
      begin
        i2c_agent_gen.bl_put(i2c_trans);
      end
    join

    // $display("+------------------------------------------------------+");
    // $display("|                   END TEST 3                         |");
    // $display("+------------------------------------------------------+\n\n\n");      
    
  endtask

  task write_wb(input bit [7:0] data [], input bit [1:0] addr);
      // sent start bit
      push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
      // set address in DPR
      push_to_wb_queue("B", WB_WRITE, DPR, (addr << 1));
      // take address from DPR and drive it on the bus
      push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);

      for(int i = 0; i < 32; i++) begin
        // set data in DPR
        push_to_wb_queue("D", WB_WRITE, DPR, i);
        // take data from DPR and drive it on the bus
        push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_WRITE);
     
      end
      // sent stop bit
      push_to_wb_queue("F", WB_WRITE, CMDR, CMDR_STOP);

  endtask

  task read_wb(input bit [7:0] data [], input bit [1:0] addr);
      // sent start bit
      push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
      // set address in DPR
      push_to_wb_queue("B", WB_WRITE, DPR, ((addr << 1) | 1'b1));
      // take address from DPR and drive it on the bus
      push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);

      for(int i = 0; i < 31; i++) begin

      push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_READ_ACK);
      
      end

      push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_READ_NACK);
      // sent stop bit
      push_to_wb_queue("F", WB_WRITE, CMDR, CMDR_STOP);

  endtask

  task alternate_rw_wb(input bit [7:0] data [], input bit [1:0] addr);

      for(int i = 0; i < 64; i++) begin

        // 1 write
        push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
        push_to_wb_queue("B", WB_WRITE, DPR, (addr << 1));
        push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);   
        push_to_wb_queue("D", WB_WRITE, DPR, (i+64));
        push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_WRITE);

        // 1 read
        push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
        push_to_wb_queue("B", WB_WRITE, DPR, ((addr << 1) | 1'b1));
        push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);     
        push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_READ_NACK);
     
      end

      // sent stop bit
      push_to_wb_queue("F", WB_WRITE, CMDR, CMDR_STOP);

  endtask  

  task initialize_wb_bus(logic [7:0] bus_number);

    send_to_wb_bl_put("csr init", WB_WRITE, CSR, CSR_INIT);
    send_to_wb_bl_put("choose bus", WB_WRITE, DPR, bus_number);
    send_to_wb_bl_put("perform write to bus", WB_WRITE, CMDR, CMDR_SET_BUS);

  endtask

  function void single_write_transaction(logic [7:0] data, logic [7:0] addr);

    push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_START);   
    push_to_wb_queue("B", WB_WRITE, DPR, ((addr << 1) | 1'b0));
    push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);     
    push_to_wb_queue("D", WB_WRITE, DPR, data);
    push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_WRITE);  
    push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_STOP);        

  endfunction

  function void single_read_transaction(logic [7:0] addr);

    push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
    push_to_wb_queue("B", WB_WRITE, DPR, ((addr << 1) | 1'b1));
    push_to_wb_queue("C", WB_WRITE, CMDR, CMDR_WRITE);     
    push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_READ_NACK);    
    push_to_wb_queue("E", WB_WRITE, CMDR, CMDR_STOP);         

  endfunction  

  function void push_to_wb_queue(string name, bit op, bit [1:0] addr, bit [7:0] data);

      wb_trans_insert = new(name);
      wb_trans_insert.op = op;
      wb_trans_insert.addr = addr;
      wb_trans_insert.data = data;      
      wb_trans_queue.push_front(wb_trans_insert); 

  endfunction

  task send_to_wb_bl_put(string name, bit op, bit [1:0] addr, bit [7:0] data);

      wb_trans_insert = new(name);
      wb_trans_insert.op = op;
      wb_trans_insert.addr = addr;
      wb_trans_insert.data = data;      
      wb_agent_gen.bl_put(wb_trans_insert); 

  endtask  

// =================================================================
//                         TEST 2 RUN
// =================================================================

  task run_test_i2cmb_consecutive_starts();
    int queue_size;

    $display("\n\nSending consective start commands. Expecting DUT error...");

    initialize_wb_bus(8'h04);
    push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);
    
    push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_START);    

    queue_size = wb_trans_queue.size();

    for(int i = 0; i < queue_size; i++)
      wb_agent_gen.bl_put(wb_trans_queue.pop_back());

  endtask  


// =================================================================
//                         TEST 3 RUN
// =================================================================
  task run_test_i2cmb_consecutive_stops();
    int queue_size;

    $display("\n\nSending consective stop commands. Expecting NO DUT error...");

    initialize_wb_bus(8'h03);
    push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_STOP);
    push_to_wb_queue("A", WB_WRITE, CMDR, CMDR_STOP);

    queue_size = wb_trans_queue.size();

    for(int i = 0; i < queue_size; i++)
      wb_agent_gen.bl_put(wb_trans_queue.pop_back());

  endtask  


// =================================================================
//                         TEST 4 RUN
// =================================================================
  task run_test_i2cmb_reg_addr();
    logic [7:0] register_contents;

    $display("\n\nReading DUT registers WITH CSR init. Expecting NOT all 1's...");    

    // initialize the DUT so registers contain valid contents
    send_to_wb_bl_put("csr init", WB_WRITE, CSR, CSR_INIT);

    // verify valid contents in all registers (anything except all 1's)
    wb_agent_gen.bus.master_read(CSR, register_contents);
    if(&register_contents) $error("INVALID CSR CONTENTS");
    else                   $display("VALID CSR CONTENTS");

    wb_agent_gen.bus.master_read(DPR, register_contents);
    if(&register_contents) $error("INVALID DPR CONTENTS");
    else                   $display("VALID DPR CONTENTS");

    wb_agent_gen.bus.master_read(CMDR, register_contents);
    if(&register_contents) $error("INVALID CMDR CONTENTS");
    else                   $display("VALID CMDR CONTENTS");

    wb_agent_gen.bus.master_read(FSMR, register_contents);
    if(&register_contents) $error("INVALID FSMR CONTENTS");
    else                   $display("VALID FSMR CONTENTS");            

  endtask   

// =================================================================
//                         TEST 5 RUN
// =================================================================
  task run_test_i2cmb_reg_vals();
    logic [7:0] register_contents;

    $display("\n\nReading DUT registers with NO CSR INIT. Expecting specified defaults...");    

    // verify valid contents in all registers (anything except all 1's)
    wb_agent_gen.bus.master_read(CSR, register_contents);
    if(register_contents != 8'b0000_0000) $error("INVALID DEFAULT CSR CONTENTS");
    else                                  $display("VALID DEFAULT CSR CONTENTS");

    wb_agent_gen.bus.master_read(DPR, register_contents);
    if(register_contents != 8'b0000_0000) $error("INVALID DEFAULT DPR CONTENTS");
    else                                  $display("VALID DEFAULT DPR CONTENTS");

    wb_agent_gen.bus.master_read(CMDR, register_contents);
    if(register_contents != 8'b1000_0000) $error("INVALID DEFAULT CMDR CONTENTS");
    else                                  $display("VALID DEFAULT CMDR CONTENTS");

    wb_agent_gen.bus.master_read(FSMR, register_contents);
    if(register_contents != 8'b0000_0000) $error("INVALID DEFAULT FSMR CONTENTS");
    else                                  $display("VALID DEFAULT FSMR CONTENTS");            

  endtask    


// =================================================================
//                         TEST 6 RUN
// =================================================================
  task run_test_i2cmb_rw_ability();
    logic [7:0] register_contents_pre = 8'bxxxx_xxxx;
    logic [7:0] register_contents_post;

    $display("\n\nTesting DUT register access permissions. Expecting:");   
    $display("CSR[7:6] - RW; CSR[5:0] - RO");
    $display("DPR[7:0]: RW");
    $display("CMDR[7:6] - RW; CMDR[5:3] - RO; CMDR[2:0] - RW");
    $display("DPR[7:0]: RO");                    

    // verify proper read/write permissions
    wb_agent_gen.bus.master_read(CSR, register_contents_pre);
    wb_agent_gen.bus.master_write(CSR, ~register_contents_pre);  
    wb_agent_gen.bus.master_read(CSR, register_contents_post);
    if(register_contents_pre[7:6] != register_contents_post[7:6]) $display("PASS - CAN R/W CSR[7:6]");
    else $error("FAIL - CAN NOT WRITE TO CSR[7:6]");   
    if(register_contents_pre[5:0] == register_contents_post[5:0]) $display("PASS - CAN RO CSR[5:0]");
    else $error("FAIL - CAN WRITE TO CSR[5:0]");

    wb_agent_gen.bus.master_read(DPR, register_contents_pre);
    wb_agent_gen.bus.master_write(DPR, ~register_contents_pre);  
    wb_agent_gen.bus.master_read(DPR, register_contents_post);
    if(register_contents_post[7:0] ==  8'b0000_0000) $display("PASS - CAN R/W DPR[7:0]");
    else $error("FAIL - CAN NOT WRITE TO DPR[7:0]");   

    wb_agent_gen.bus.master_read(CMDR, register_contents_pre);
    wb_agent_gen.bus.master_write(CMDR, ~register_contents_pre);  
    wb_agent_gen.bus.wait_for_interrupt();
    wb_agent_gen.bus.master_read(CMDR, register_contents_post);
    if(register_contents_pre[7:6] != register_contents_post[7:6]) $display("PASS - CAN R/W CMDR[7:6]");
    else $error("FAIL - CAN NOT WRITE TO CMDR[7:6]");   
    if(register_contents_pre[5:3] != ~register_contents_post[5:3]) $display("PASS - CAN RO CMDR[5:3]");
    else $error("FAIL - CAN WRITE TO CMDR[5:3]");
    if(register_contents_pre[2:0] != register_contents_post[2:0]) $display("PASS - CAN R/W CMDR[2:0]");
    else $error("FAIL - CAN WRITE TO CMDR[2:0]");    

    wb_agent_gen.bus.master_read(FSMR, register_contents_pre);
    wb_agent_gen.bus.master_write(FSMR, ~register_contents_pre);  
    wb_agent_gen.bus.master_read(FSMR, register_contents_post);
    if(register_contents_pre[7:0] == register_contents_post[7:0]) $display("PASS - CAN RO FSMR[7:0]");
    else $error("FAIL - CAN WRITE TO FSMR[7:0]");               
  endtask 

// =================================================================
//                         TEST 7 RUN
// =================================================================
  task run_test_i2cmb_busses();
    logic [7:0] bus_number;
    int queue_size;

    $display("Writing to all possible busses (1-16)...");

    for (int i = 1; i <= 16; i++) begin
      bus_number = i;
      initialize_wb_bus(bus_number);
      single_write_transaction(i, 8'h22);

      queue_size = wb_trans_queue.size();

      for(int j = 0; j < queue_size; j++)
        wb_agent_gen.bl_put(wb_trans_queue.pop_back());
    end

    $display("Finished writing to all possible busses (1-16)");  

  endtask


// =================================================================
//                         TEST 8 RUN
// =================================================================
  task run_test_i2cmb_directed();
    int queue_size;
    wb_transaction wb_trans;
    i2c_transaction i2c_trans;
    bit [I2C_DATA_WIDTH-1:0] i2c_data [];

    $display("Writing and reading from all possible addresses (0-127)...");

    initialize_wb_bus(8'h05);

    // single write to all possible addresses
    for (int i = 0; i < 128; i++) begin
      i2c_trans = new("i2c transaction");
      i2c_data = new[1];       
      i2c_data[0] = i; 
      i2c_trans.addr = i;
      i2c_trans.data = i2c_data;
      i2c_trans.op = I2C_WRITE;

      single_write_transaction(i, i);
      queue_size = wb_trans_queue.size();

      fork
        begin
          for(int j = 0; j < queue_size; j++)
            wb_agent_gen.bl_put(wb_trans_queue.pop_back());
        end
        begin
          i2c_agent_gen.bl_put(i2c_trans);
        end
      join
    end

    // single read to all possible addresses
    for (int i = 0; i < 128; i++) begin
      i2c_trans = new("i2c transaction");
      i2c_data = new[1];       
      i2c_data[0] = i + 128; 
      i2c_trans.addr = i;
      i2c_trans.data = i2c_data;
      i2c_trans.op = I2C_READ;

      single_read_transaction(i);
      queue_size = wb_trans_queue.size();

      fork
        begin
          for(int j = 0; j < queue_size; j++)
            wb_agent_gen.bl_put(wb_trans_queue.pop_back());
        end
        begin
          pred.populate_pred_rd_queue(i2c_data);
          i2c_agent_gen.bl_put(i2c_trans);
        end
      join
    end

    $display("Finished writing and reading from all possible addresses.");  

  endtask

// =================================================================
//                         TEST 9 RUN
// =================================================================

  task run_test_i2cmb_randomized();
    random_i2c_transaction rand_trans = new();
    int queue_size;
    wb_transaction wb_trans;
    i2c_transaction i2c_trans;
    bit [I2C_DATA_WIDTH-1:0] i2c_data [];

    $display("Writing and reading from RANDOM addresses and data...");

    initialize_wb_bus(8'h05);

    // single write to all possible addresses
    for (int i = 0; i < 1024; i++) begin
      rand_trans.randomize();
      i2c_trans = new("i2c transaction");
      i2c_data = new[1];       
      i2c_data[0] = rand_trans.data; 
      i2c_trans.addr = rand_trans.addr;
      i2c_trans.data = i2c_data;
      i2c_trans.op = I2C_WRITE;

      single_write_transaction(rand_trans.data, rand_trans.addr);
      queue_size = wb_trans_queue.size();

      fork
        begin
          for(int j = 0; j < queue_size; j++)
            wb_agent_gen.bl_put(wb_trans_queue.pop_back());
        end
        begin
          i2c_agent_gen.bl_put(i2c_trans);
        end
      join
    end

    // single read to all possible addresses
    for (int i = 0; i < 1024; i++) begin
      rand_trans.randomize();
      i2c_trans = new("i2c transaction");
      i2c_data = new[1];       
      i2c_data[0] = rand_trans.data; 
      i2c_trans.addr = rand_trans.addr;
      i2c_trans.data = i2c_data;
      i2c_trans.op = I2C_READ;

      single_read_transaction(rand_trans.data);
      queue_size = wb_trans_queue.size();

      fork
        begin
          for(int j = 0; j < queue_size; j++)
            wb_agent_gen.bl_put(wb_trans_queue.pop_back());
        end
        begin
          pred.populate_pred_rd_queue(i2c_data);
          i2c_agent_gen.bl_put(i2c_trans);
        end
      join
    end

    $display("Finished writing and reading from RANDOM addresses and data.");  


  endtask


endclass