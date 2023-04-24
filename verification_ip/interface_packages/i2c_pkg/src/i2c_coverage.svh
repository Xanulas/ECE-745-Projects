class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration configuration;
//   	header_type_t     header_type;
//   	header_sub_type_t header_sub_type;
//   	trailer_type_t    trailer_type;

//   covergroup i2c_transaction_cg;
//   	option.per_instance = 1;
//     option.name = get_full_name();

  i2c_op_t opcodes;
  bit [I2C_DATA_WIDTH-1:0] data_vals;
  bit [I2C_ADDR_WIDTH-1:0] addresses;

  covergroup coverage_i2c_cg;
  	// option.per_instance = 1;
    // option.name = get_full_name();
    opcodes:                              coverpoint opcodes;
    data_vals:                            coverpoint data_vals;
    addresses:                            coverpoint addresses;
    opcodes_x_data_vals:      cross opcodes, data_vals;
    opcodes_x_addresses:      cross opcodes, addresses;    
  endgroup

  
//   	header_type:     coverpoint header_type
//   	{
//   	bins ROUTING_TABLE = {ROUTING_TABLE};
//   	bins STATISTICS = {STATISTICS};
//   	bins PAYLOAD = {PAYLOAD};
//   	bins SECURE_PAYLOAD = {SECURE_PAYLOAD};
//   	}

//   	header_sub_type: coverpoint header_sub_type
//   	{
//   	bins CONTROL = {CONTROL};
//   	bins DATA = {DATA};
//   	bins RESET = {RESET};
//   	}

//   	trailer_type:    coverpoint trailer_type
//   	{
//   	bins ZEROS = {ZEROS};
//   	bins ONES = {ONES};
//   	bins SYNC = {SYNC};
//   	bins PARITY = {PARITY};
//   	bins ECC = {ECC};
//   	bins CRC = {CRC};  	
//   	} 

//   	header_x_header_sub: cross header_type, header_sub_type
//   	  {
//   	   illegal_bins routing_table_sub_types_illegal = 
//   	           binsof(header_type.ROUTING_TABLE) && 
//   	           binsof(header_sub_type.DATA);
//   	   illegal_bins payload_sub_types_illegal = 
//   	           binsof(header_type.PAYLOAD) && 
//   	           ( binsof(header_sub_type.CONTROL) || 
//   	           	 binsof(header_sub_type.RESET));
//   	   illegal_bins secure_payload_sub_types_illegal = 
//   	           binsof(header_type.SECURE_PAYLOAD) && 
//   	           binsof(header_sub_type.RESET);
//   	  }

//   	  header_x_trailer: cross header_type, trailer_type;
//   endgroup

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    coverage_i2c_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    // $display("===== I2C COVERAGE ====");

    opcodes = trans.op;
    addresses = trans.addr;    

    for(int i = 0; i < trans.data.size(); i++) begin
      data_vals = trans.data[i];
      coverage_i2c_cg.sample();  
    end

  endfunction

endclass