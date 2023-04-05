class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration     configuration;
  wb_transaction  coverage_transaction;
  // header_type_t         header_type;
  // bit                   loopback;
  // bit                   invert;

  bit [7:0] bus_vals;
  bit [WB_DATA_WIDTH-1:0] waits;


  covergroup coverage_i2cmb_FSM_cg;
  	// option.per_instance = 1;
    // option.name = get_full_name();
    waits:         coverpoint waits;
    bus_vals:      coverpoint bus_vals;
  endgroup  

  function void set_configuration(i2cmb_env_configuration cfg);
  	configuration = cfg;
  endfunction

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    coverage_i2cmb_FSM_cg = new;
  endfunction

  virtual function void nb_put(T trans);
    // $display({get_full_name()," ",trans.convert2string()});
    waits = coverage_transaction.data;
    bus_vals = 8'h05;

    coverage_i2cmb_FSM_cg.sample();
  endfunction

endclass