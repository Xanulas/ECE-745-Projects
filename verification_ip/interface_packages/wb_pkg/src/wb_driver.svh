// parameter 
//     CSR = 8'h00,
//     DPR = 8'h01,
//     CMDR = 8'h02,
//     FSMR = 8'h03;


class wb_driver extends ncsu_component#(.T(wb_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if bus;
  wb_configuration configuration;
  wb_transaction trans;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);

    bus.master_write(trans.addr, trans.data);

    if(trans.addr == CMDR)
      begin
      $display("CMDR A");
      bus.wait_for_interrupt();
      bus.master_read(trans.addr, trans.data);
      $display("CMDR B");
      end

    $display({get_full_name()," ",trans.convert2string()});
    bus.master_write(trans.addr, trans.data);

  endtask

  // virtual task bl_get(T trans);
  //   $display({get_full_name()," ",trans.convert2string()});
  //   bus.master_read(trans.addr, trans.data);
  // endtask

endclass