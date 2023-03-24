package data_pkg;
    typedef enum bit{
        I2C_WRITE=1'b0,
        I2C_READ=1'b1
    } i2c_op_t;

    typedef enum bit{
        WB_WRITE=1'b0,
        WB_READ=1'b1
    } wb_op_t;    

    typedef enum bit [1:0] {
        IDLE=2'b00,
        ADDR=2'b01,
        WRITE=2'b10,
        READ=2'b11
    } listen_states_t;

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

parameter 
    CSR = 8'h00,
    DPR = 8'h01,
    CMDR = 8'h02,
    FSMR = 8'h03;

parameter 
    CSR_INIT = 8'b11xxxxxx,
    CSR_DISABLE = 8'b00xxxxxx,
    CMDR_SET_BUS = 8'bxxxxx110,
    CMDR_START = 8'bxxxxx100,
    CMDR_STOP = 8'bxxxxx101,
    CMDR_WRITE = 8'bxxxxx001,
    CMDR_READ_ACK = 8'bxxxxx010,
    CMDR_READ_NACK = 8'bxxxxx011;

endpackage

