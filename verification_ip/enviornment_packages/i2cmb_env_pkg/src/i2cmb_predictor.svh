class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  i2cmb_scoreboard scoreboard;
  i2c_transaction i2c_trans, i2c_predicted_trans;
  i2cmb_env_configuration configuration;


  predictor_state_t predictor_state;
  bit [I2C_DATA_WIDTH-1:0] i2c_data_queue [$];
  bit [I2C_DATA_WIDTH-1:0] rd_data_queue [$];
  bit [7:0] DPR_capture;
  int num_i2c_data_bytes;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  function void populate_pred_rd_queue(input bit [I2C_DATA_WIDTH-1:0] rd_data []);
    rd_data_queue.delete();

    for(int i = 0; i < rd_data.size(); i++) rd_data_queue.push_front(rd_data[i]);
  endfunction  

  virtual function void set_scoreboard(i2cmb_scoreboard scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  virtual function void nb_put(T trans);
    // $display({get_full_name()," ",trans.convert2string()});
    i2c_trans = new("i2c_trans");
    // i2c_predicted_trans = new("i2c_predicted_trans");


    case(predictor_state)
      WAIT_FOR_START : begin
        if(is_start_bit(trans))
            predictor_state = PREDICT_ADDR_AND_OP;
      end
      PREDICT_ADDR_AND_OP : begin
        if(is_write_dpr(trans)) begin
          i2c_predicted_trans = new("i2c_predicted_trans");
          i2c_predicted_trans.op = trans.data[0]? I2C_READ : I2C_WRITE;        
          i2c_predicted_trans.addr = trans.data[7:1];
          predictor_state = WAIT_FOR_CMDR;
        end
        else if(is_start_bit(trans)) predictor_state = PREDICT_ADDR_AND_OP;
        else if(is_stop_bit(trans)) predictor_state = WAIT_FOR_START;
      end
      WAIT_FOR_CMDR : begin
        if(is_write_cmdr(trans) && (trans.data[2:0] == CMDR_WRITE[2:0])) predictor_state = PREDICT_DATA;
        else if(is_start_bit(trans)) predictor_state = PREDICT_ADDR_AND_OP;
        else if(is_stop_bit(trans)) predictor_state = WAIT_FOR_START;
      end
      PREDICT_DATA : begin
        if(is_write_dpr(trans))
          DPR_capture = trans.data;
        else if(is_write_cmdr(trans)) begin
          casex(trans.data[2:0])
            CMDR_WRITE : begin
              i2c_data_queue.push_front(DPR_capture);
            end
            CMDR_READ_ACK, CMDR_READ_NACK : begin
              i2c_data_queue.push_front(rd_data_queue.pop_back());
            end
            CMDR_START, CMDR_STOP : begin
              
              num_i2c_data_bytes = i2c_data_queue.size();
              i2c_predicted_trans.data = new[num_i2c_data_bytes];
              for(int i = 0; i < num_i2c_data_bytes; i++) i2c_predicted_trans.data[i] = i2c_data_queue.pop_back();

              // $display({get_full_name()," ",i2c_predicted_trans.convert2string()});
              scoreboard.nb_transport(i2c_predicted_trans, i2c_trans);
              if(is_start_bit(trans)) predictor_state = PREDICT_ADDR_AND_OP;
              else if(is_stop_bit(trans)) predictor_state = WAIT_FOR_START;
            end
          endcase
        end
      end
    endcase


endfunction

function is_stop_bit(wb_transaction trans);

  if((trans.op == WB_WRITE) && (trans.addr == CMDR) && (trans.data[2:0] == CMDR_STOP[2:0])) return 1'b1; 

  return 1'b0;
endfunction

function is_start_bit(wb_transaction trans);

  if((trans.op == WB_WRITE) && (trans.addr == CMDR) && (trans.data[2:0] == CMDR_START[2:0])) return 1'b1; 

  return 1'b0;
endfunction

function is_write_dpr(wb_transaction trans);

  if((trans.op == WB_WRITE) && (trans.addr == DPR)) return 1'b1;

  return 1'b0;
endfunction

function is_write_cmdr(wb_transaction trans);

  if((trans.op == WB_WRITE) && (trans.addr == CMDR)) return 1'b1; 

  return 1'b0;
endfunction

endclass



        // if(is_write_cmdr(trans)) begin
        //       casex ({5'bxxxxx, trans.data[2:0]})
        //       CMDR_WRITE : begin predictor_state = PREDICT_DATA end 
        //       CMDR_START : begin predictor_state = PREDICT_ADDR_AND_OP end
        //       CMDR_STOP  : begin predictor_state = WAIT_FOR_START end
        //       endcase
        // end