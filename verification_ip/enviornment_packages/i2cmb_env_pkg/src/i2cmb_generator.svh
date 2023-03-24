// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component;

  wb_transaction wb_trans_queue [$];
  i2c_transaction i2c_trans_queue [$];  

  i2c_transaction i2c_trans[];
  wb_transaction wb_trans[];  

  i2c_agent i2c_agent_gen;
  wb_agent wb_agent_gen;
  string trans_name;
  
  parameter 
    CSR = 8'h00,
    DPR = 8'h01,
    CMDR = 8'h02,
    FSMR = 8'h03;  

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    // if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
    //   $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
    //   $fatal;
    // end
    // $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
  endfunction


  wb_transaction wb_trans_insert;
  bit [7:0] cmdr_temp;
  int size;
  bit [7:0] insert_byte;  

  virtual task run();

      wb_trans_insert = new("csr init");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CSR;
      wb_trans_insert.data = CSR_INIT;
      wb_agent_gen.bl_put(wb_trans_insert);

      wb_trans_insert = new("choose bus");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = DPR;
      wb_trans_insert.data = 8'h05;
      wb_agent_gen.bl_put(wb_trans_insert);

      wb_trans_insert = new("perform write to bus");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_SET_BUS;      
      wb_agent_gen.bl_put(wb_trans_insert);


    fork
    begin
      size = wb_trans_queue.size();
      for(int i = 0; i < size; i++)
        wb_agent_gen.bl_put(wb_trans_queue.pop_back());     
    end
    join
  endtask

  function void set_agent_i2c(i2c_agent agent);
    this.i2c_agent_gen = agent;
  endfunction

  function void set_agent_wb(wb_agent agent);
    this.wb_agent_gen = agent;
  endfunction  

  // function void set_transactions_i2c(i2c_transaction trans);  
  //   this.i2c_trans = trans;
  // endfunction

  // function void set_transactions_wb(wb_transaction trans);
  //   this.wb_trans = trans;
  // endfunction 

  task write_wb(input bit [7:0] data [], input bit [1:0] addr);

      wb_trans_insert = new("A");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_START;      
      wb_trans_queue.push_front(wb_trans_insert); 

      wb_trans_insert = new("B");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = DPR;
      wb_trans_insert.data = addr << 1;
      wb_trans_queue.push_front(wb_trans_insert);


      wb_trans_insert = new("C");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_WRITE;
      wb_trans_queue.push_front(wb_trans_insert);

      for(int i = 0; i < 32; i++) begin
        wb_trans_insert = new("D");
        wb_trans_insert.op = WB_WRITE;
        wb_trans_insert.addr = DPR;
        wb_trans_insert.data = i; 
        wb_trans_queue.push_front(wb_trans_insert);       

        wb_trans_insert = new("E");
        wb_trans_insert.op = WB_WRITE;
        wb_trans_insert.addr = CMDR;
        wb_trans_insert.data = CMDR_WRITE;      
        wb_trans_queue.push_front(wb_trans_insert);      
      end


      wb_trans_insert = new("F");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_STOP;      
      wb_trans_queue.push_front(wb_trans_insert);

  endtask

endclass

