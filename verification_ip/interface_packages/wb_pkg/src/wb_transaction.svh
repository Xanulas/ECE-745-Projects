class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)

       bit op;
       bit [WB_ADDR_WIDTH-1:0] addr;
       bit [WB_DATA_WIDTH-1:0] data;

  // rand bit [5:0]  delay;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("op:0x%x addr:0x%p data:0x%x", op, addr, data)};
  endfunction

  // function bit compare(wb_transaction rhs);
  //   return ((this.header  == rhs.header ) &&
  //           (this.payload == rhs.payload) &&
  //           (this.trailer == rhs.trailer) );
  // endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
     super.add_to_wave(transaction_viewing_stream_h);
     $add_attribute(transaction_view_h,op,"op");
     $add_attribute(transaction_view_h,addr,"addr");
     $add_attribute(transaction_view_h,data,"data");
     $end_transaction(transaction_view_h,end_time);
     $free_transaction(transaction_view_h);
  endfunction

endclass