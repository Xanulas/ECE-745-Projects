`timescale 1ns / 10ps

module top();

  initial

    begin

      int array[5];

      int sum;

      array = { 0, 1, 2, 3, 4};

      sum = array.sum with ( int'( (item%2) == 0) ? 2 : 0);

      $display(sum);

    end

endmodule
