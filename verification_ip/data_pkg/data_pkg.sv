package data_pkg;
    typedef enum bit{
        I2C_WRITE=1'b0,
        I2C_READ=1'b1
    } i2c_op_t;

    typedef enum bit [1:0] {
        IDLE=2'b00,
        ADDR=2'b01,
        WRITE=2'b10,
        READ=2'b11
    } listen_states_t;


endpackage

