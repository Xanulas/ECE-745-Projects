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

  virtual task run();
    fork
    begin
      foreach (wb_trans[i]) begin
        $cast(wb_trans[i],ncsu_object_factory::create(trans_name));
        assert (wb_trans[i].randomize());
        wb_agent_gen.bl_put(wb_trans[i]);
        $display({get_full_name()," ",wb_trans[i].convert2string()});
      end
    end
    begin
      foreach(wb_trans[i])
          wb_agent_gen.bl_put(wb_trans_queue[i]);     
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


  
  wb_transaction wb_trans_insert;
  bit [7:0] cmdr_temp;
  task write_wb(input bit [7:0] data [], input bit [1:0] addr);

      wb_trans_insert = new("set i2c_address in DPR");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = DPR;
      wb_trans_insert.data = addr << 1;
      wb_trans_queue.push_front(wb_trans_insert);

      wb_trans_insert = new("perform write of address from DPR to bus");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_WRITE;      
      wb_trans_queue.push_front(wb_trans_insert);

      foreach(data[i]) begin
      wb_trans_insert = new("write data to DPR");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = DPR;
      wb_trans_insert.data = data[i]; 
      wb_trans_queue.push_front(wb_trans_insert);       

      wb_trans_insert = new("perform write of data from DPR to bus");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_WRITE;      
      wb_trans_queue.push_front(wb_trans_insert);      
      end

      wb_trans_insert = new("write stop command to DPR");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = DPR;
      wb_trans_insert.data = CMDR_STOP; 
      wb_trans_queue.push_front(wb_trans_insert); 

      wb_trans_insert = new("perform write of stop command from DPR to bus");
      wb_trans_insert.op = WB_WRITE;
      wb_trans_insert.addr = CMDR;
      wb_trans_insert.data = CMDR_WRITE;      
      wb_trans_queue.push_front(wb_trans_insert);

  endtask

    task cast_to_array();
      int size;
      size = wb_trans_queue.size();
      wb_trans = new[size];
      for(int i = 0; i < size; i++)
        wb_trans[i] = wb_trans_queue.pop_back();
    endtask
      

  // task sync()
    
  // endtask

endclass

