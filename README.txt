Ngày 1:
- Đọc protocol
- Vẽ 5 channels
- Vẽ timing write/read
- Làm slide 2–5

Ngày 2:
- Code AXI-Lite slave
- Tạo register map
- Write/read LED_REG chạy được

Ngày 3:
- Code testbench
- Viết task axi_write, axi_read
- Chạy directed test

Ngày 4:
- Thêm assertion
- Test payload stable, reset, response
- Cố tình tạo bug rồi chứng minh assertion bắt được

Ngày 5:
- Random delay VALID/READY
- Test AW trước W, W trước AW
- Thêm WSTRB, invalid address, coverage

Ngày 6:
- Làm top module cho DE0-Nano
- Map switch/button/LED
- Compile Quartus
- Quay demo hoặc chụp waveform/demo board

Ngày 7:
- Hoàn thiện slide
- Chuẩn bị Q&A
- Tập nói 7–10 phút
- Chuẩn bị backup: nếu FPGA lỗi thì trình bày simulation waveform