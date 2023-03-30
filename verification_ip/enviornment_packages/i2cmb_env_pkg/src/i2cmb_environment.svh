class i2cmb_environment extends ncsu_component#(.T(i2c_transaction));

  i2cmb_env_configuration configuration;
  i2c_agent               i2c_agent_env;
  wb_agent                wb_agent_env;
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          coverage;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    i2c_agent_env = new("i2c_agent_env",this);
    i2c_agent_env.set_configuration(configuration.i2c_agent_config);
    i2c_agent_env.build();
    wb_agent_env = new("wb_agent_env",this);
    wb_agent_env.set_configuration(configuration.wb_agent_config);
    wb_agent_env.build();
    pred  = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    coverage = new("coverage", this);
    coverage.set_configuration(configuration);
    coverage.build();
    // i2c_agent_env.connect_subscriber(coverage);
    wb_agent_env.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    i2c_agent_env.connect_subscriber(scbd);
  endfunction

  function i2c_agent get_i2c_agent();
    return i2c_agent_env;
  endfunction

  function wb_agent get_wb_agent();
    return wb_agent_env;
  endfunction

  virtual task run();
     i2c_agent_env.run();
     wb_agent_env.run();
  endtask

endclass