class test_i2cmb_reg_vals extends ncsu_component#(.T(i2c_transaction));

  // i2cmb_env_configuration  cfg;
  // i2cmb_environment        env;
  // i2cmb_generator          gen;

  // bit [WB_DATA_WIDTH-1:0] test_one_data [32];

  // function new(string name = "", ncsu_component_base parent = null); 
  //   super.new(name,parent);
  //   cfg = new("cfg");
  //   // cfg.sample_coverage();
  //   env = new("env",this);
  //   env.set_configuration(cfg);
  //   env.build();
  //   gen = new("gen",this);
  //   gen.set_agent_i2c(env.get_i2c_agent());
  //   gen.set_agent_wb(env.get_wb_agent());
  // endfunction

  // virtual task run();
  //    gen.write_wb(test_one_data, 8'h22);

  //    env.run();
  //    gen.run();
  // endtask

endclass