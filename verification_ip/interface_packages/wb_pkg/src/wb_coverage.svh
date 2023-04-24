class wb_coverage extends ncsu_component#(.T(wb_transaction));

    wb_configuration configuration;
//   	header_type_t     header_type;
//   	header_sub_type_t header_sub_type;
//   	trailer_type_t    trailer_type;

//   covergroup wb_transaction_cg;
//   	option.per_instance = 1;
//     option.name = get_full_name();

  bit opcodes;
  bit [WB_DATA_WIDTH-1:0] data_vals;
  bit [WB_ADDR_WIDTH-1:0] addresses;

  covergroup coverage_wb_cg;
  	// option.per_instance = 1;
    // option.name = get_full_name();
    opcodes:                               coverpoint opcodes;
    data_vals:                             coverpoint data_vals;
    addresses:                             coverpoint addresses;
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
    coverage_wb_cg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    // $display("===== WB COVERAGE ====");

    opcodes = trans.op;
    data_vals = trans.data;
    addresses = trans.addr;

    coverage_wb_cg.sample();
  endfunction

endclass