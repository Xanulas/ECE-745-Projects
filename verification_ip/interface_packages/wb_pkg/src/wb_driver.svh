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

    case(trans.addr)
    2'h0: bus.master_write(trans.addr, trans.data);
    2'h1: bus.master_write(trans.addr, trans.data);
    2'h2: begin
      bus.master_write(trans.addr, trans.data);
      bus.wait_for_interrupt();
      bus.master_read(trans.addr, trans.data);
    end
    2'h3: bus.master_write(trans.addr, trans.data);
    default: bus.master_write(trans.addr, trans.data);
    endcase

    $display({get_full_name()," ",trans.convert2string()});
    bus.master_write(trans.addr, trans.data);

  endtask

  // virtual task bl_get(T trans);
  //   $display({get_full_name()," ",trans.convert2string()});
  //   bus.master_read(trans.addr, trans.data);
  // endtask

endclass