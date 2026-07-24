class axi_register_bank_coverage;
    int ctrl_count;
    int status_count;
    int operand_a_count;
    int operand_b_count;
    int opcode_count;
    int result_count;
    int invalid_count;
    int full_strb_count;
    int partial_strb_count;

    function new();
        ctrl_count = 0;
        status_count = 0;
        operand_a_count = 0;
        operand_b_count = 0;
        opcode_count = 0;
        result_count = 0;
        invalid_count = 0;
        full_strb_count = 0;
        partial_strb_count = 0;
    endfunction

    function void sample(axi_register_bank_transaction tr);
        case (tr.addr)
            ADDR_CTRL: ctrl_count++;
            ADDR_STATUS: status_count++;
            ADDR_A: operand_a_count++;
            ADDR_B: operand_b_count++;
            ADDR_OPCODE: opcode_count++;
            ADDR_RESULT: result_count++;
            default: invalid_count++;
        endcase

        if (tr.strb == 4'b1111) begin
            full_strb_count++;
        end else begin
            partial_strb_count++;
        end
    endfunction

    function void report();
        $display("Coverage summary: ctrl=%0d status=%0d operand_a=%0d operand_b=%0d opcode=%0d result=%0d invalid=%0d full_strb=%0d partial_strb=%0d",
                 ctrl_count, status_count, operand_a_count, operand_b_count, opcode_count, result_count, invalid_count, full_strb_count, partial_strb_count);
    endfunction
endclass
