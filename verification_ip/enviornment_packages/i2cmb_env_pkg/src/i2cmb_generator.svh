// class i2cmb_generator #(type GEN_TRANS)  extends ncsu_component#(.T(i2c_transaction));
class i2cmb_generator extends ncsu_component#(.T(i2c_transaction));

  i2c_transaction transaction[10];
  ncsu_component #(T) agent;
  string trans_name;

  bit [7:0] trans [$];  // unsure about this

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
      foreach (transaction[i]) begin  
        $cast(transaction[i],ncsu_object_factory::create(trans_name));
        assert (transaction[i].randomize());
        agent.bl_put(transaction[i]);
        $display({get_full_name()," ",transaction[i].convert2string()});
      end
    end
    begin
      foreach(transaction[i])
          agent.bl_put(trans[i]);     
    end
    join
  endtask

  function void set_agent(ncsu_component #(T) agent);
    this.agent = agent;
  endfunction

// write_wb(data, addr) begin
//     wb_if.write

// end

endclass

