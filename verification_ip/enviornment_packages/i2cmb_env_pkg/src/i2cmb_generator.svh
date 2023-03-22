// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component#(.T(i2c_transaction));

  i2c_transaction i2c_trans[10];
  wb_transaction wb_trans[10];
  bit [7:0] wb_trans_queue [$];

  ncsu_component #(T) agent;
  string trans_name;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
      $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
      $fatal;
    end
    $display("%m found +GEN_TRANS_TYPE=%s", trans_name);
  endfunction

  virtual task run();
    fork
    begin
      foreach (wb_trans[i]) begin  
        $cast(wb_trans[i],ncsu_object_factory::create(trans_name));
        assert (wb_trans[i].randomize());
        agent.bl_put(wb_trans[i]);
        $display({get_full_name()," ",wb_trans[i].convert2string()});
      end
    end
    begin
      foreach(wb_trans[i])
          agent.bl_put(wb_trans_queue[i]);     
    end
    join
  endtask

  function void set_agent(ncsu_component #(T) agent);
    this.agent = agent;
  endfunction

  task write_wb(input [7:0] data, input [1:0] addr)
      wb_bus.master_write(DPR, data);
      wb_bus.master_write(CMDR, 8'bxxxx_x001);
      wait(irq);
      wb_bus.master_read(CMDR, cmdr_temp);
      wb_trans_queue.push_front(data);
  endtask

  task sync()
    
  endtask

endclass

