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

  if(trans.header == WRITE) wait_for_i2c_transfer();
  else
      begin
      provide_read_data();
      wait_for_i2c_transfer();
      end

    $display({get_full_name()," ",trans.convert2string()});
    bus.drive(trans.header, 
              trans.payload, 
              trans.trailer, 
              trans.delay
              );
  endtask 

endclass

