# Kế hoạch 6 ngày: AXI4-Lite Design Verification

## Mục tiêu

Xây dựng và kiểm chứng một AXI4-Lite Slave bằng SystemVerilog, gồm:

* Register Bank.
* Custom Hardware Core như ALU hoặc Counter.
* SystemVerilog Testbench.
* Assertions và Functional Coverage.
* Tích hợp với Nios II, On-Chip Memory và JTAG UART trên DE0-Nano.

## Kiến trúc hệ thống

```text
Nios II
   |
Avalon-MM Interconnect
   |
Avalon-to-AXI Bridge
   |
AXI4-Lite Slave Register Bank
   |
ALU / Counter Core
```

## Kế hoạch thực hiện

### Ngày 1: Nghiên cứu AXI4-Lite

* Tìm hiểu 5 channel: AW, W, B, AR, R.
* Hiểu cơ chế handshake `VALID && READY`.
* Tìm hiểu backpressure, `WSTRB`, `BRESP`, `RRESP`.
* Thiết kế block diagram và register map.

### Ngày 2: Thiết kế AXI4-Lite Slave

* Viết logic read/write AXI4-Lite.
* Xử lý AW và W độc lập.
* Xây dựng address decoder.
* Tạo Register Bank gồm CTRL, STATUS, DATA và RESULT.

### Ngày 3: Thiết kế Custom Hardware Core

* Viết ALU hoặc Counter bằng SystemVerilog.
* Kết nối core với Register Bank.
* Thực hiện flow `START → BUSY → DONE → RESULT`.
* Kiểm tra chức năng cơ bản bằng simulation.

### Ngày 4: Xây dựng Verification Environment

* Tạo AXI4-Lite interface.
* Viết driver, monitor và scoreboard.
* Tạo các test đọc/ghi register.
* Kiểm tra AW-first, W-first, simultaneous và backpressure.

### Ngày 5: Assertions và Coverage

* Viết SystemVerilog Assertions kiểm tra protocol.
* Kiểm tra tín hiệu ổn định khi bị stall.
* Tạo functional coverage cho address, opcode, WSTRB và transaction order.
* Thực hiện bug injection để chứng minh testbench phát hiện lỗi.

### Ngày 6: Tích hợp và Demo

* Tích hợp Nios II, On-Chip Memory, JTAG UART và AXI4-Lite peripheral trong Platform Designer.
* Viết chương trình C để ghi input, gửi START, đọc STATUS và RESULT.
* In kết quả trên Nios II Terminal.
* Chuẩn bị waveform, test report, slide và câu hỏi Q&A.

## Kết quả mong đợi

```text
Nios II ghi dữ liệu vào Register Bank
        ↓
Custom Hardware Core xử lý
        ↓
Core cập nhật STATUS và RESULT
        ↓
Nios II đọc kết quả
        ↓
JTAG UART hiển thị kết quả
```

Project chứng minh khả năng thiết kế AXI4-Lite Slave, xây dựng môi trường verification và tích hợp hardware–software trên FPGA.
