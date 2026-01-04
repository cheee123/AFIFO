`timescale 1ns/1ps

module AFIFO_tb;

// Parameters
parameter DEPTH = 16;
parameter N = 4;
parameter WIDTH = 8;
parameter WR_CLK_PERIOD = 10;  // 100 MHz
parameter RD_CLK_PERIOD = 15;  // 66.67 MHz

// Signals
reg clk_w, clk_r;
reg rst_w, rst_r;
reg [WIDTH-1:0] wdata;
reg push, pop;
wire wfull, rempty;
wire [WIDTH-1:0] rdata;

// Test control
integer error_count = 0;
integer test_num = 0;

// Instantiate AFIFO
AFIFO #(
    .DEPTH(DEPTH),
    .N(N),
    .WIDTH(WIDTH)
) dut (
    .clk_w(clk_w),
    .clk_r(clk_r),
    .rst_w(rst_w),
    .rst_r(rst_r),
    .wdata(wdata),
    .push(push),
    .pop(pop),
    .wfull(wfull),
    .rempty(rempty),
    .rdata(rdata)
);

// Clock generation
initial begin
    clk_w = 0;
    forever #(WR_CLK_PERIOD/2) clk_w = ~clk_w;
end

initial begin
    clk_r = 0;
    forever #(RD_CLK_PERIOD/2) clk_r = ~clk_r;
end

// Test stimulus
initial begin
    // Initialize
    rst_w = 0;
    rst_r = 0;
    push = 0;
    pop = 0;
    wdata = 0;
    
    // Apply reset
    #(WR_CLK_PERIOD * 3);
    rst_w = 1;
    rst_r = 1;
    #(WR_CLK_PERIOD * 2);
    
    $display("========================================");
    $display("Starting AFIFO Tests");
    $display("========================================\n");
    
    // Test 1: Basic write and read
    test_basic_write_read();
    
    // Test 2: Fill FIFO completely
    test_fill_fifo();
    
    // Test 3: Empty FIFO completely
    test_empty_fifo();
    
    // Test 4: Simultaneous read/write
    test_simultaneous_rw();
    
    // Summary
    #(WR_CLK_PERIOD * 10);
    $display("\n========================================");
    $display("Test Summary");
    $display("========================================");
    $display("Total Errors: %0d", error_count);
    if (error_count == 0)
        $display("*** ALL TESTS PASSED ***");
    else
        $display("*** TESTS FAILED ***");
    $display("========================================\n");
    
    $finish;
end

// Task: Basic write and read test
task test_basic_write_read;
    integer i;
    reg [WIDTH-1:0] expected_data;
    begin
        test_num = test_num + 1;
        $display("Test %0d: Basic Write and Read", test_num);
        
        // Write some data
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk_w);
            wdata = i + 10;
            push = 1;
        end
        @(posedge clk_w);
        push = 0;
        
        // Wait for data to propagate
        repeat(5) @(posedge clk_r);
        
        // Read data back
        for (i = 0; i < 8; i = i + 1) begin
            expected_data = i + 10;
            @(posedge clk_r);
            pop = 1;
            #1;
            if (rdata !== expected_data) begin
                $display("  ERROR: Expected %0d, got %0d", expected_data, rdata);
                error_count = error_count + 1;
            end
        end
        @(posedge clk_r);
        pop = 0;
        @(posedge clk_r);
        $display("  Test %0d completed\n", test_num);
    end
endtask

// Task: Fill FIFO completely
task test_fill_fifo;
    integer i;
    begin
        test_num = test_num + 1;
        $display("Test %0d: Fill FIFO Completely", test_num);
        
        // Fill FIFO
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk_w);
            if (wfull) begin
                $display("  ERROR: FIFO full at %0d entries (expected %0d)", i, DEPTH);
                error_count = error_count + 1;
            end
            wdata = i + 100;
            push = 1;
        end
        @(posedge clk_w);
        push = 0;
        
        // Check full flag
        repeat(5) @(posedge clk_w);
        if (!wfull) begin
            $display("  ERROR: FIFO should be full but wfull=0");
            error_count = error_count + 1;
        end else begin
            $display("  FIFO correctly shows full");
        end
        
        // Try to write when full (should be ignored)
        @(posedge clk_w);
        wdata = 8'hFF;
        push = 1;
        @(posedge clk_w);
        push = 0;
        
        $display("  Test %0d completed\n", test_num);
    end
endtask

// Task: Empty FIFO completely
task test_empty_fifo;
    integer i;
    reg [WIDTH-1:0] expected_data;
    begin
        test_num = test_num + 1;
        $display("Test %0d: Empty FIFO Completely", test_num);
        
        // Wait for synchronization
        repeat(5) @(posedge clk_r);
        
        // Empty FIFO
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(posedge clk_r);
            if (rempty) begin
                $display("  ERROR: FIFO empty at %0d reads (expected %0d)", i, DEPTH);
                error_count = error_count + 1;
            end
            expected_data = i + 100;
            pop = 1;
            #1;
            if (rdata !== expected_data) begin
                $display("  ERROR: Expected %0d, got %0d at position %0d", expected_data, rdata, i);
                error_count = error_count + 1;
            end
        end
        @(posedge clk_r);
        pop = 0;
        
        // Check empty flag
        repeat(5) @(posedge clk_r);
        if (!rempty) begin
            $display("  ERROR: FIFO should be empty but rempty=0");
            error_count = error_count + 1;
        end else begin
            $display("  FIFO correctly shows empty");
        end
        
        $display("  Test %0d completed\n", test_num);
    end
endtask

// Task: Simultaneous read/write
task test_simultaneous_rw;
    integer i, j;
    reg [WIDTH-1:0] expected_data;
    begin
        test_num = test_num + 1;
        $display("Test %0d: Simultaneous Read/Write", test_num);
        
        // Write a few items first
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk_w);
            wdata = i + 150;
            push = 1;
        end
        @(posedge clk_w);
        push = 0;
        
        // Wait for sync
        repeat(5) @(posedge clk_r);
        
        // Simultaneous operations
        fork
            // Write thread
            begin
                for (i = 4; i < 100; i = i + 1) begin
                    @(negedge clk_w);
                    if(wfull) begin
                        push = 0;
                        wait(!wfull);
                        @(negedge clk_w);
                    end
                    wdata = i + 150;
                    push = 1;
                end
                @(posedge clk_w);
                push = 0;
            end
            
            // Read thread
            begin
                for (j = 0; j < 100; j = j + 1) begin
                    @(negedge clk_r);
                    if(rempty) begin
                        pop = 0;
                        wait(!rempty);
                        @(negedge clk_r);
                    end
                    expected_data = j + 150;
                    pop = 1;
                    if (rdata !== expected_data) begin
                        $display("  ERROR: Expected %0d, got %0d", expected_data, rdata);
                        error_count = error_count + 1;
                    end
                    @(posedge clk_r);
                    pop = 0;
                end
                @(posedge clk_r);
                pop = 0;
            end
        join
        
        $display("  Test %0d completed\n", test_num);
    end
endtask

// Monitor for debugging
initial begin
    $monitor("Time=%0t | wfull=%b rempty=%b | push=%b pop=%b | wdata=%h rdata=%h", 
             $time, wfull, rempty, push, pop, wdata, rdata);
end

// Waveform dump
initial begin
    $dumpfile("afifo_tb.vcd");
    $dumpvars(0, AFIFO_tb);
end

endmodule