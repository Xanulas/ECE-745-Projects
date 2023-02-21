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

reg sda_reg;
bit sda_put;

assign sda_o = sda_put ? sda_reg : 1'b0;

task drive_sda(input bit data);
  sda_reg = data;
  @(posedge scl_i) sda_put = 1'b1;
  @(negedge scl_i) sda_put = 1'b0;
endtask

task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
  int listen_counter;
  listen_states_t listen_state;
  bit [8:0] addr_heard;
  bit [8:0] data_heard;
  
  sda_reg = 1'b1;
  listen_state = IDLE;

  while(1)
  begin
    @(posedge scl_i)
      $display("while loop");
    case(listen_state)
    IDLE  : begin
      listen_state = IDLE;
      @(negedge sda_i) 
        if(scl_i) listen_state = ADDR;
    end
    ADDR  : begin
      for (int i = 0; i < 9; i++) begin
        @(posedge scl_i)
          addr_heard[i] = sda_i;
        if(i == 8) begin
          drive_sda(1'b0); // ACK (got address)
          $display("address heard: %b", addr_heard);
        end
      end
    end
    WRITE : begin
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