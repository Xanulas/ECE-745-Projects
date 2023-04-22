class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration     configuration;
  wb_transaction  coverage_transaction;
  // header_type_t         header_type;
  // bit                   loopback;
  // bit                   invert;
  wb_agent wb_agent_cov;

  logic [WB_DATA_WIDTH-1:0] FSMR_vals [];
  logic [3:0] FSM_state;
  logic [3:0] FSM_state_transitions;  
  // int queue_size;

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
    FSM_state_transitions: coverpoint FSM_state_transitions;
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

    wb_agent_cov.get_FSMR_vals(FSMR_vals);
    FSM_state_transitions = 4'b0;

    for(int i = 0; i < FSMR_vals.size(); i++) begin
      FSM_state = FSMR_vals[i][7:4];
      coverage_i2cmb_FSM_cg.sample();
    end

  endfunction

endclass