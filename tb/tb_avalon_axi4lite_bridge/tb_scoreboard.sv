class avalon_bridge_scoreboard;
    int errors;

    function new();
        errors = 0;
    endfunction

    function void check(input string name, input bit ok);
        if (!ok) begin
            errors++;
            $error("FAIL: %s", name);
        end else begin
            $display("PASS: %s", name);
        end
    endfunction

    function void finish(input string test_name);
        if (errors == 0) begin
            $display("%s PASSED", test_name);
            $finish;
        end
        $fatal(1, "%s FAILED with %0d errors", test_name, errors);
    endfunction
endclass
