import data_pkg::*;

interface i2c_if       #(
      int I2C_ADDR_WIDTH = 7,                                
      int I2C_DATA_WIDTH = 8                                
      )
(
  // signals
  input tri scl_i,
  input tri sda_i,
  output tri scl_o,
  output tri sda_o
  );

reg sda_reg = 1'b1;
bit sda_put = 1'b0;

assign sda_o = sda_put ? sda_reg : 1'bz;

task drive_sda(input bit data);
  sda_reg = data;
  @(posedge scl_i) sda_put = 1'b1;
  @(negedge scl_i) sda_put = 1'b0;
endtask

task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
  int listen_counter;
  listen_states_t listen_state;
  bit [6:0] addr_heard;
  bit [7:0] data_heard;

  listen_state = IDLE;

  while(1)
  begin  
    //$display("===== while begin =====");
    case(listen_state)
    IDLE  : begin
      listen_state = IDLE;
      @(negedge sda_i) 
        if(scl_i) listen_state = ADDR;
    end
    ADDR  : begin
      wait(scl_i); wait(!scl_i);
      for (int i = 0; i < 7; i++) begin
        wait(scl_i); 
          addr_heard[6-i] = sda_i;
        wait(!scl_i);
      end
      $display("addr heard: %h", addr_heard);
      wait(scl_i); 
        if(sda_i) op = I2C_READ;
        else op = I2C_WRITE;
      wait(!scl_i);  
      // wait(scl_i); wait(!scl_i);
        listen_state = WRITE;
        drive_sda(1'b0); // ack
    end
    WRITE : begin
      for (int i = 0; i < 8; i++) begin
        wait(scl_i); 
          data_heard[7-i] = sda_i;
        wait(!scl_i);
      end
        $display("data heard: %d", data_heard);
        listen_state = WRITE;
        // wait(scl_i); wait(!scl_i); 
        drive_sda(1'b0); // ack
    end
    READ  : begin
    end
    default : listen_state = IDLE;
    endcase
 end

endtask

task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);

endtask

task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);

endtask

endinterface