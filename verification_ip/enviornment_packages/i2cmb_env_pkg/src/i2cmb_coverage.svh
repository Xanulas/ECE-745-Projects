class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration     configuration;
  wb_transaction  coverage_transaction;
  // header_type_t         header_type;
  // bit                   loopback;
  // bit                   invert;
  wb_agent wb_agent_cov;


  bit [7:0] bus_vals;
  logic [3:0] FSM_state;

covergroup coverage_i2cmb_FSM_cg;
    FSM_state: coverpoint FSM_state
    {
        illegal_bins invalid_states = { 
            4'b1000,
            4'b1001,
            4'b1010,
            4'b1011,
            4'b1100,
            4'b1101,
            4'b1110,
            4'b1111 
        };
    }
    bus_vals:      coverpoint bus_vals;
  endgroup  

  function void set_wb_agent(wb_agent agent);
  	wb_agent_cov = agent;
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
  	configuration = cfg;
  endfunction

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    coverage_i2cmb_FSM_cg = new;
  endfunction

  virtual function void nb_put(T trans);
    // $display({get_full_name()," ",trans.convert2string()});

    // TODO: turn FSM_state into a queue that populates multiples times in driver::nb_put and for loop here

    FSM_state = wb_agent_cov.get_FSMR_val();
    bus_vals = 8'h05;
    coverage_i2cmb_FSM_cg.sample();
  endfunction

endclass