// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component;

  wb_transaction wb_trans_queue [$];
  i2c_transaction i2c_trans_queue [$];  

  i2c_transaction i2c_trans[10];
  wb_transaction wb_trans[10];  

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

  // task write_wb(input [7:0] data, input [1:0] addr);
  //     wb_bus.master_write(DPR, data);
  //     wb_bus.master_write(CMDR, 8'bxxxx_x001);
  //     wait(irq);
  //     wb_bus.master_read(CMDR, cmdr_temp);

  //     wb_transaction wb_trans_insert;
  //     wb_trans_insert.op = 1'b0 // "write"
  //     wb_trans_insert.addr = addr;
  //     wb_trans_insert.data = data;

  //     wb_trans_queue.push_front(wb_trans_insert);
  // endtask

  // task sync()
    
  // endtask

endclass

