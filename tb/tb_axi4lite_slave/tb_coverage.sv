class axi4lite_slave_coverage;
    int aw_first_count;
    int w_first_count;
    int same_cycle_count;
    int read_count;
    int full_strb_count;
    int partial_strb_count;
    int delayed_count;

    function new();
        aw_first_count = 0;
        w_first_count = 0;
        same_cycle_count = 0;
        read_count = 0;
        full_strb_count = 0;
        partial_strb_count = 0;
        delayed_count = 0;
    endfunction

    function void sample(axi4lite_slave_transaction tr);
        case (tr.kind)
            axi4lite_slave_transaction::TR_WRITE_AW_FIRST: aw_first_count++;
            axi4lite_slave_transaction::TR_WRITE_W_FIRST: w_first_count++;
            axi4lite_slave_transaction::TR_WRITE_SAME_CYCLE: same_cycle_count++;
            axi4lite_slave_transaction::TR_READ: read_count++;
            default: same_cycle_count++;
        endcase

        if (tr.strb == 4'b1111) begin
            full_strb_count++;
        end else begin
            partial_strb_count++;
        end

        if ((tr.aw_delay != 0) || (tr.w_delay != 0) || (tr.resp_delay != 0)) begin
            delayed_count++;
        end
    endfunction

    function void report();
        $display("Coverage summary: aw_first=%0d w_first=%0d same_cycle=%0d read=%0d full_strb=%0d partial_strb=%0d delayed=%0d",
                 aw_first_count, w_first_count, same_cycle_count, read_count, full_strb_count, partial_strb_count, delayed_count);
    endfunction
endclass
