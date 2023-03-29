class i2cmb_coverage extends ncsu_component#(.T(i2c_transaction));

  // env_configuration     configuration;
  // i2c_transaction  covergae_transaction;
  // header_type_t         header_type;
  // bit                   loopback;
  // bit                   invert;

  covergroup coverage_i2cmb_cg;
  	// option.per_instance = 1;
    // option.name = get_full_name();
    waits:         coverpoint waits;
    bus_vals:      coverpoint bus_vals;
  endgroup  

  // function void set_configuration(env_configuration cfg);
  // 	configuration = cfg;
  // endfunction

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    coverage_i2cmb_cg = new;
  endfunction

  virtual function void nb_put(T trans);
    $display({get_full_name()," ",trans.convert2string()});
    header_type = header_type_t'(trans.header[63:60]);
    loopback    = configuration.loopback;
    invert      = configuration.invert;
    coverage_cg.sample();
  endfunction

endclass