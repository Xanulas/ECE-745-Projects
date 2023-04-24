class test_i2cmb_directed extends ncsu_component#(.T(i2c_transaction));

  i2cmb_env_configuration  cfg;
  i2cmb_environment        env;
  i2cmb_generator          gen;

  bit [WB_DATA_WIDTH-1:0] test_one_data [32];

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    cfg = new("cfg");
    // cfg.sample_coverage();
    env = new("env",this);
    env.set_configuration(cfg);
    env.build();
    gen = new("gen",this);
    gen.set_agent_i2c(env.get_i2c_agent());
    gen.set_agent_wb(env.get_wb_agent());
    gen.set_predictor(env.get_predictor());    
  endfunction

  virtual task run();

     env.run();
     gen.run_test_i2cmb_directed();
  endtask

endclass