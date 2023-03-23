class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  i2cmb_scoreboard scoreboard;
  i2c_transaction transport_trans;
  i2cmb_env_configuration configuration;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void set_scoreboard(i2cmb_scoreboard scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  virtual function void nb_put(T trans);
    $display({get_full_name()," ",trans.convert2string()});
    // scoreboard.nb_transport(trans, transport_trans);
  endfunction

endclass