// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component;

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

  task push_to_wb_queue(string name, bit op, bit [1:0] addr, bit [7:0] data);

      wb_trans_insert = new(name);
      wb_trans_insert.op = op;
      wb_trans_insert.addr = addr;
      wb_trans_insert.data = data;      
      wb_trans_queue.push_front(wb_trans_insert); 

  endtask

  task send_to_wb_bl_put(string name, bit op, bit [1:0] addr, bit [7:0] data);

      wb_trans_insert = new(name);
      wb_trans_insert.op = op;
      wb_trans_insert.addr = addr;
      wb_trans_insert.data = data;      
      wb_agent_gen.bl_put(wb_trans_insert); 

  endtask  

endclass