# AXI-Lite ALU Verification Notes

README này mô tả đúng bộ testbench hiện có trong thư mục `tb/`. Hiện tại project có 3 directed/protocol testbench:

- `tb_axi_register_bank.sv`
- `tb_axi4lite_slave.sv`
- `tb_avalon_axi4lite_bridge.sv`

Chưa có testbench riêng cho `alu_core` và top `avalon_axi4lite_alu`, nên các mục đó được ghi ở phần "cần bổ sung" thay vì xem như đã được cover.

## 1. Directed Test Đang Có

### `tb_axi_register_bank`

Các case hiện đã khớp với testbench:

- Reset register/output: `operand_a`, `operand_b`, `opcode`, `start_pulse`, `STATUS`, `RESULT` về 0.
- Write/read `ADDR_A = 0x08`.
- Partial byte enable cho `ADDR_A`, ví dụ `wr_strb = 4'b0101`.
- Write/read `ADDR_B = 0x0C`.
- Write/read `ADDR_OPCODE = 0x10`, chỉ giữ 4 bit thấp.
- Write opcode với `wr_strb[0] = 0`, opcode không đổi.

- Write `CTRL = 0x1` khi idle, tạo `start_pulse` đúng 1 cycle và set status busy.
- Write `CTRL = 0x1` khi busy, không tạo start mới.

- Core done không error: status đọc ra `0x2`, result được latch.
- Write `CTRL = 0x0`, không tạo start.
- Start lại sau done được chấp nhận.
- Core done có error: status đọc ra `0x6`, result error được latch.
- Invalid read trả 0.
- Invalid write không làm hỏng register hợp lệ đã ghi trước đó.

Các case chưa có nếu muốn mở rộng:

- Byte enable từng byte cho `ADDR_B`.
- Nhiều biến thể byte enable cho `ADDR_OPCODE`.
- Check trực tiếp write invalid không đổi `B`/`opcode`, hiện mới check không corrupt `A`.

### `tb_axi4lite_slave`

Các case hiện đã khớp với testbench:

- Reset AXI output: không có `BVALID`, không có `RVALID`, không có `wr_en`, các ready ở trạng thái sẵn sàng.
- AXI write với AW trước W.
- AXI write với W trước AW.
- AXI write với AW và W cùng cycle.
- Check `wr_en` sinh đúng 1 cycle sau mỗi cặp AW/W.
- Check `wr_addr`, `wr_data`, `wr_strb` đúng với transaction.
- Hold `BVALID` khi `BREADY = 0`, clear sau khi `BREADY = 1`.
- Check `BRESP = OKAY`.
- AXI read: AR handshake, `rd_addr` đúng, `RDATA/RRESP` đúng.
- Hold `RVALID` khi `RREADY = 0`, clear sau khi `RREADY = 1`.
- Có nhiều write liên tiếp và hai read liên tiếp, bao gồm read thứ hai đóng vai trò back-to-back read đơn giản.

Các case chưa có nếu muốn mở rộng:

- Read/write interleaved thực sự.
- Back-to-back write/read không có khoảng hở giữa response và request kế tiếp.
- Assertion độc lập cho stable `AWADDR`, `WDATA/WSTRB`, `ARADDR`, `RDATA/RRESP`.
- Negative protocol case: thiếu AW hoặc thiếu W thì không sinh response/write pulse.

### `tb_avalon_axi4lite_bridge`

Các case hiện đã khớp với testbench:

- Reset output: không `waitrequest`, không `readdatavalid`, không AXI valid.
- Avalon write khi idle.
- `avs_waitrequest = 1` trong lúc bridge bận.
- Write với AWREADY/WREADY cùng cycle.
- Write với AWREADY trước WREADY.
- Write với WREADY trước AWREADY.
- Delay BVALID nhiều cycle.
- Check `AWADDR`, `WDATA`, `WSTRB` giữ đúng trong lúc chờ ready.
- Avalon read khi idle.
- Delay ARREADY và RVALID.
- Check `ARADDR` giữ đúng trong lúc chờ ready.
- Check `RREADY` được giữ khi chờ response.
- `avs_readdatavalid` pulse đúng 1 cycle và `avs_readdata` đúng.
- Avalon read/write cùng lúc ưu tiên write, vì RTL hiện check write trước read.
- Có kích `m_axi_bresp = 2'b10` để toggle đường response không dùng trong RTL.

Các case chưa có nếu muốn mở rộng:

- Kích `m_axi_rresp` khác OKAY, hiện mới có `bresp` khác OKAY.
- Check write không tạo `avs_readdatavalid`.
- Check bridge không nhận command mới khi busy bằng một request thứ hai cụ thể.
- Assertion Avalon master giữ stable request/data/address khi `avs_waitrequest = 1`.

## 2. Protocol Test / Assertion Nên Bổ Sung

Hiện testbench chủ yếu là directed self-checking bằng task `check`, chưa có SVA/protocol checker riêng. Nên bổ sung assertion cho:

- AXI-Lite write:
  - `AWVALID` giữ stable `AWADDR` tới khi `AWREADY`.
  - `WVALID` giữ stable `WDATA/WSTRB` tới khi `WREADY`.
  - `BVALID` giữ stable `BRESP` tới khi `BREADY`.
  - Mỗi cặp AW/W sinh đúng một `wr_en`.
  - Không sinh write response nếu thiếu AW hoặc thiếu W.

- AXI-Lite read:
  - `ARVALID` giữ stable `ARADDR` tới khi `ARREADY`.
  - `RVALID` giữ stable `RDATA/RRESP` tới khi `RREADY`.
  - Mỗi AR sinh đúng một R response.
  - Không accept AR mới khi read transaction trước chưa hoàn tất, nếu RTL yêu cầu như vậy.

- Avalon side:
  - Khi `avs_waitrequest = 1`, master giữ stable request/address/writedata/byteenable theo Avalon-MM protocol.
  - `avs_readdatavalid` chỉ xuất hiện cho read.
  - Write không tạo `avs_readdatavalid`.
  - Bridge không nhận command mới khi đang busy.
  - Read/write cùng lúc ưu tiên write theo RTL hiện tại.

## 3. Testbench Cần Bổ Sung

### `alu_core`

- Reset: `result = 0`, `busy = 0`, `done = 0`, `error = 0`.
- ADD normal và overflow wrap.
- SUB normal và underflow wrap.
- MUL normal và overflow/truncate 32 bit thấp.
- DIV normal và remainder truncate.
- DIV by zero: `result = 0`, `error = 1`.
- Invalid opcode `4..15`: `result = 0`, `error = 1`.
- Start while busy: operation thứ hai không được nhận khi `busy = 1`.
- Timing: sau `start` có `busy`, sau đó `done` pulse 1 cycle.

### Top `avalon_axi4lite_alu`

- Full software flow: write A, write B, write opcode, write CTRL start, poll STATUS, read RESULT.
- Lặp flow cho ADD/SUB/MUL/DIV.
- DIV by zero qua bus, check status error và result 0.
- Invalid opcode qua bus, check status error.
- Partial byte write qua Avalon byteenable.
- Invalid address read/write qua Avalon.
- Back-to-back ALU operation sau khi done.
- Attempt start while busy qua Avalon, expect không nhận start mới.

## 4. Coverage Nên Định Nghĩa

Để hướng tới 100% functional coverage, nên định nghĩa coverpoint/cross trước rồi map test vào từng mục:

- Opcode: ADD, SUB, MUL, DIV, invalid.
- Operand class A/B: zero, one, max, `0x8000_0000`, random.
- DIV class: divisor zero, divisor nonzero.
- Error: no error, divide-by-zero, invalid opcode.
- ALU status: idle, busy, done.
- Register address: ctrl, status, A, B, opcode, result, invalid.
- Byteenable: `0000`, từng byte `0001/0010/0100/1000`, full `1111`, mixed.
- AXI write order: AW first, W first, same cycle.
- AXI stalls: no stall, AW stall, W stall, B stall, AR stall, R stall.
- Avalon operation: read, write, simultaneous read/write.
- Cross quan trọng: opcode x error, opcode x operand corner, register address x byteenable, write order x stall type, operation type x waitrequest, start_when x status_busy.

## Kết Luận

README cũ liệt kê nhiều testcase mục tiêu nhưng chưa khớp hoàn toàn với testbench hiện có. README này đã được chỉnh lại để phản ánh đúng directed/protocol test đang có trong `tb/`, đồng thời tách riêng các case nên bổ sung cho coverage đầy đủ hơn.
