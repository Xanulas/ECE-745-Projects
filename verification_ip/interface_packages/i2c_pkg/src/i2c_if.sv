import data_pkg::*;

interface i2c_if       #(
      // interface parameters
      int I2C_ADDR_WIDTH = 7,                                
      int I2C_DATA_WIDTH = 8                                
      )
(
  // interface ports
  input triand scl_i,
  input triand sda_i,
  output triand scl_o,
  output triand sda_o
  );

logic sda_reg = 1'b1;
logic sda_put = 1'b0;
bit [I2C_DATA_WIDTH-1:0] read_in [$];


// *********************************************
// drive_sda: used for driving values on bus
assign sda_o = sda_put ? sda_reg : 1'bz;
task drive_sda(input bit data);
  sda_reg = data;
  @(posedge scl_i) sda_put = 1'b1;
  @(negedge scl_i) sda_put = 1'b0;
endtask

// *********************************************
// check_read: used to check for start/stop
// conditions and taking in data from SDA
task check_read(output bit meaning, output bit data);
  bit posedge_sda;
  bit negedge_sda;

  wait(scl_i);
  posedge_sda = sda_i;
  wait(!scl_i || (sda_i != posedge_sda));
  negedge_sda = sda_i;

  // initially assume we are just reading data
  meaning = 1'b0; 
  data = posedge_sda;

  // update output if start or stop condition noticed
  if(posedge_sda && !negedge_sda) begin meaning = 1'b1; data = 1'b1; wait(!scl_i); end // START condition
  if(!posedge_sda && negedge_sda) begin meaning = 1'b1; data = 1'b0; end // STOP condition

endtask





bit [6:0] addr_heard;
i2c_op_t op_heard;
bit [I2C_DATA_WIDTH-1:0] data_in [$];

// *********************************************
// wait_for_i2c_transfer: primary listening FSM
// will drive bus / respond
task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
  listen_states_t listen_state;
  
  bit [7:0] data_heard;
  bit [7:0] byte_out;
  bit meaning; // 0 if data, 1 if start/stop
  bit data;
  bit finished;
  bit gotostart;
  int size;

  finished = 1'b0;
  gotostart = 1'b0;
  listen_state = IDLE;

  while(1)
  begin
    case(listen_state)
    IDLE  : begin
      check_read(meaning, data);
      if(meaning) begin if(data) listen_state = ADDR; end
    end
    ADDR  : begin
      gotostart = 0;
      // check_read(meaning, data);
      for (int i = 0; i < 7; i++) begin
        check_read(meaning, data);
        if(meaning) begin if(data) begin
          listen_state = ADDR; 
          trigger_monitor(); end
          else begin 
            listen_state = IDLE;
            $display("STOP received");
            trigger_monitor();
            finished = 1'b1; break; 
            end end 
        else
          addr_heard[6-i] = data;
      end
      if(finished) break;
      // $display("addr heard: %h", addr_heard);
        check_read(meaning, data);
        if(meaning) begin if(data) begin
          listen_state = ADDR; 
          trigger_monitor(); end
          else begin 
            listen_state = IDLE;
            $display("STOP received");
            trigger_monitor();
            finished = 1'b1; break; 
            end end 
        else 
          begin 
            if (data) begin op = I2C_READ; op_heard = I2C_READ; listen_state = READ; end
            else begin op = I2C_WRITE; op_heard = I2C_WRITE; listen_state = WRITE; end 
            drive_sda(1'b0); // ack
          end
    end
    WRITE : begin
      for (int i = 0; i < 8; i++) begin
        check_read(meaning, data); 
        if(meaning) begin if(data) begin
          listen_state = ADDR; 
          gotostart = 1; 
          trigger_monitor(); 
          break; end
          else begin // stop condition (write data back)
            $display("STOP received");
            listen_state = IDLE; 
            size = data_in.size();
            write_data = new[size];
            trigger_monitor();
            finished = 1'b1; break; end
        end
        data_heard[7-i] = sda_i;
      end
      if(gotostart) continue;
      if(finished) break;
      data_in.push_front(data_heard);
      // $display("data heard: %d", data_heard);
      listen_state = WRITE;
      drive_sda(1'b0); // ack
    end
    READ  : begin
      byte_out = read_in.pop_back();

      data_in.push_front(byte_out);

      // $display("byte out: %d", byte_out);

      for(int i = 0; i<8; i++)begin
        drive_sda(byte_out[7-i]);
      end

    // $display("DEBUG 1");
      
    check_read(meaning, data);
    if(data) begin 
      // $display("DEBUG 2");
      check_read(meaning, data);
      // $display("DEBUG 3");
        if(meaning & !data) begin
          // $display("DEBUG 4");
          listen_state = IDLE; 
          finished = 1'b1;
          $display("STOP received"); 
          trigger_monitor();
          break; end
        else if(meaning & data) begin
          // $display("DEBUG 5");
          listen_state = ADDR;
          trigger_monitor();
          continue; end
        end
    end
    default : listen_state = IDLE;
    endcase
    if(finished) break;
 end
endtask

task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);

    transfer_complete = 1'b0;

    for(int i = 0; i < read_data.size(); i++)
      read_in.push_front(read_data[i]);

    transfer_complete = 1'b1;
endtask

bit monitor_enable = 0;
bit monitor_busy = 0;

task trigger_monitor ();

  if(monitor_enable) begin
    monitor_busy = 1;
    wait(!monitor_enable);
    monitor_busy = 0;
  end

endtask


// ***********************************************
// wait_for_i2c_transfer: secondary listening FSM
// only records activity
task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
  integer num_bytes;

  monitor_enable = 1;

  wait(monitor_busy);

  addr = addr_heard;
  op = op_heard;
  num_bytes = data_in.size();
  data = new[num_bytes];
  for ( int i = 0; i < num_bytes; i++) data[i] = data_in.pop_back();

  monitor_enable = 0;
  wait(!monitor_busy);

endtask

endinterface