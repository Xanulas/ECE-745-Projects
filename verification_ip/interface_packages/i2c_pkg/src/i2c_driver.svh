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
  bit complete;
  i2c_op_t i2c_op;
  bit [I2C_DATA_WIDTH-1:0] i2c_data [];

  $display({get_full_name()," ",trans.convert2string()});

  if(trans.op == I2C_READ) bus.provide_read_data(trans.data, trans.transfer_complete);

  bus.wait_for_i2c_transfer(i2c_op, i2c_data);



  endtask 

endclass

