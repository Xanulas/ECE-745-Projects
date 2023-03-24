class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)

    
       bit transfer_complete;
       i2c_op_t op;
       bit [6:0] addr;
       bit [7:0] data [];

  // rand bit [5:0]  delay;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("op:0x%x addr:0x%p data:%d", op, addr, data)};
  endfunction

  function bit compare(i2c_transaction rhs);
    return ((this.op  == rhs.op ) && 
            (this.addr == rhs.addr) &&
            (this.data == rhs.data) );
  endfunction

  // virtual function void add_to_wave(int transaction_viewing_stream_h);
  //    super.add_to_wave(transaction_viewing_stream_h);
  //    $add_attribute(transaction_view_h,op,"op");
  //    $add_attribute(transaction_view_h,addr,"addr");
  //    $add_attribute(transaction_view_h,data,"data");
  //    $end_transaction(transaction_view_h,end_time);
  //    $free_transaction(transaction_view_h);
  // endfunction

endclass