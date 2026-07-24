class avalon_bridge_coverage;
    int read_count;
    int write_count;
    int w_first_count;
    int simultaneous_count;
    int full_be_count;
    int partial_be_count;
    int delay_count;

    function new();
        read_count = 0;
        write_count = 0;
        w_first_count = 0;
        simultaneous_count = 0;
        full_be_count = 0;
        partial_be_count = 0;
        delay_count = 0;
    endfunction

    function void sample(avalon_bridge_transaction tr);
        case (tr.kind)
            avalon_bridge_transaction::TR_READ: read_count++;
            avalon_bridge_transaction::TR_WRITE: write_count++;
            avalon_bridge_transaction::TR_WRITE_W_FIRST: w_first_count++;
            avalon_bridge_transaction::TR_SIMULTANEOUS_RW: simultaneous_count++;
            default: write_count++;
        endcase

        if (tr.be == 4'b1111) begin
            full_be_count++;
        end else begin
            partial_be_count++;
        end

        if ((tr.aw_delay != 0) || (tr.w_delay != 0) || (tr.resp_delay != 0)) begin
            delay_count++;
        end
    endfunction

    function void report();
        $display("Coverage summary: read=%0d write=%0d w_first=%0d simultaneous=%0d full_be=%0d partial_be=%0d delayed=%0d",
                 read_count, write_count, w_first_count, simultaneous_count, full_be_count, partial_be_count, delay_count);
    endfunction
endclass
