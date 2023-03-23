class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if bus;
  i2c_configuration configuration;
  i2c_transaction trans;



  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);

  if(trans.op == 1'b0) bus.wait_for_i2c_transfer(trans.op, trans.data);
  else
      begin
      bus.provide_read_data(trans.data, trans.transfer_complete);
      bus.wait_for_i2c_transfer(trans.op, trans.data);
      end

    $display({get_full_name()," ",trans.convert2string()});
    // bus.drive(trans.op, 
    //           trans.addr, 
    //           trans.data
    //           );
  endtask 

endclass

