# Với RTL hiện tại, để hướng tới **100% functional coverage** thì nên chia testcase theo 5 block: `alu_core`, `axi_register_bank`, `axi4lite_slave`, `avalon_axi4lite_bridge`, và top `avalon_axi4lite_alu`.

“100%” ở đây nên hiểu là 100% coverage theo coverpoint/cross mình định nghĩa; code coverage 100% còn phụ thuộc tool và có vài nhánh default/reset/protocol cần kích đúng.

## 1. Directed Test

### Cho `alu_core`

- Reset test: sau reset `result=0`, `busy=0`, `done=0`, `error=0`.
- ADD normal: `A+B`, ví dụ `10+5=15`.
- ADD overflow wrap: `32'hFFFF_FFFF + 1 = 0`.
- SUB normal: `10-5=5`.
- SUB underflow wrap: `0-1 = 32'hFFFF_FFFF`.
- MUL normal: `3*7=21`.
- MUL overflow/truncate: giá trị lớn để check lấy 32 bit thấp.
- DIV normal: `20/4=5`.
- DIV remainder truncate: `7/2=3`.
- DIV by zero: `B=0`, expect `result=0`, `error=1`.
- Invalid opcode: opcode `4..15`, expect `result=0`, `error=1`.
- Start while busy: pulse `start` liên tiếp, operation thứ hai không được nhận khi `busy=1`.
- Timing: sau `start`, `busy=1`; cycle sau `busy=0`, `done=1`; cycle tiếp `done=0`.

### Cho `axi_register_bank`

- Reset register: `A/B/opcode/result/status/start_pulse` về 0.
- Write/read `ADDR_A = 0x08`.
- Write/read `ADDR_B = 0x0C`.
- Write/read `ADDR_OPCODE = 0x10`, chỉ lấy 4 bit thấp.
- Write `CTRL = 0x1` khi idle: tạo `start_pulse` đúng 1 cycle, status busy bit = 1.
- Write `CTRL = 0x0`: không start.
- Write `CTRL = 0x1` khi status busy: không tạo start mới.
- Core done không error: `status = 3'b010`, result được latch.
- Core done có error: `status = 3'b110`.
- Read `STATUS = 0x04`, `RESULT = 0x14`.
- Read invalid address: trả 0.
- Write invalid address: không đổi register.
- Byte enable từng byte cho `A`, `B`.
- Byte enable partial cho `OPCODE`, đặc biệt `wr_strb[0]=0` thì opcode thấp không đổi.

### Cho `axi4lite_slave`

- Reset all AXI outputs/internal flags.
- Write AW trước W.
- Write W trước AW.
- Write AW và W cùng cycle.
- Hold `BVALID` khi `BREADY=0`, clear khi `BREADY=1`.
- Đảm bảo `wr_en` chỉ pulse 1 cycle.
- Read transaction bình thường: AR handshake, sau đó RVALID/RDATA.
- Hold `RVALID` khi `RREADY=0`, clear khi `RREADY=1`.
- Back-to-back write.
- Back-to-back read.
- Read/write interleaved nếu testbench cho phép.
- Check `BRESP=OKAY`, `RRESP=OKAY`.

### Cho `avalon_axi4lite_bridge`

- Reset: state idle, no valid, no readdatavalid.
- Avalon write khi idle.
- Avalon read khi idle.
- Nếu `avs_write` và `avs_read` cùng lúc: write được ưu tiên vì RTL check write trước.
- `avs_waitrequest=1` khi bridge busy.
- Write với AWREADY/WREADY cùng cycle.
- Write với AWREADY trước WREADY.
- Write với WREADY trước AWREADY.
- BVALID delay nhiều cycle.
- Read với ARREADY delay.
- Read với RVALID delay.
- `avs_readdatavalid` chỉ pulse 1 cycle khi nhận RDATA.
- Check latch address/writedata/byteenable ổn định trong transaction.
- Đưa `m_axi_bresp/rresp` khác OKAY để toggle `unused_resp`, dù hiện tại bridge không xử lý lỗi.

### Cho top `avalon_axi4lite_alu`

- Full software flow:
  - write A
  - write B
  - write opcode
  - write CTRL start
  - poll STATUS
  - read RESULT
- Lặp flow cho ADD/SUB/MUL/DIV.
- DIV by zero qua bus, check status error và result 0.
- Invalid opcode qua bus, check status error.
- Partial byte write qua Avalon byteenable.
- Invalid address read/write qua Avalon.
- Back-to-back ALU operations sau khi done.
- Attempt start while busy qua Avalon, expect không nhận start mới.

## 2. Random Test

Nên có constrained random ở 3 tầng:

- ALU random:
  - random `operand_a`, `operand_b`, `opcode`.
  - opcode distribution: `0..3` nhiều hơn, `4..15` vẫn phải cover.
  - ép corner value: `0`, `1`, `32'hFFFF_FFFF`, `32'h8000_0000`, `32'h7FFF_FFFF`.
  - với DIV, random cả `B=0` và `B!=0`.
  - scoreboard tính expected bằng SystemVerilog model.

- Register/bus random:
  - random address trong `{0x00,0x04,0x08,0x0C,0x10,0x14}` và invalid.
  - random write/read sequence.
  - random byteenable `0000..1111`.
  - random start timing: start khi idle, start khi busy, start sau done.
  - random read status/result trong lúc operation đang chạy.

- Protocol random:
  - random delay cho `AWREADY`, `WREADY`, `BVALID`, `ARREADY`, `RVALID`.
  - random `BREADY/RREADY` stall.
  - random order AW/W.
  - random Avalon read/write spacing.
  - random backpressure để cover mọi state transition của bridge.

## 3. Protocol Test / Assertion Test

Nên có assertion hoặc protocol checker cho:

- AXI-Lite write:
  - `AWVALID` giữ stable `AWADDR` tới khi `AWREADY`.
  - `WVALID` giữ stable `WDATA/WSTRB` tới khi `WREADY`.
  - `BVALID` giữ tới khi `BREADY`.
  - mỗi cặp AW/W sinh đúng một `wr_en`.
  - không sinh write response nếu thiếu AW hoặc W.

- AXI-Lite read:
  - `ARVALID` giữ stable `ARADDR` tới khi `ARREADY`.
  - `RVALID` giữ stable `RDATA/RRESP` tới khi `RREADY`.
  - mỗi AR sinh đúng một R response.
  - không accept AR mới khi `read_pending` hoặc `rvalid_q`.

- Avalon side:
  - khi `avs_waitrequest=1`, master không nên đổi request/data/address nếu theo protocol Avalon-MM.
  - `avs_readdatavalid` chỉ xuất hiện cho read.
  - write không tạo `avs_readdatavalid`.
  - bridge không nhận command mới khi busy.
  - write được ưu tiên nếu read/write cùng lúc, vì RTL hiện tại như vậy.

## 4. Coverage Nên Định Nghĩa

Coverpoint tối thiểu:

- Opcode: ADD, SUB, MUL, DIV, invalid.
- Operand class A/B: zero, one, max, min signed-ish `0x8000_0000`, random.
- DIV class: divisor zero, divisor nonzero.
- Error: no error, divide-by-zero, invalid opcode.
- ALU status: idle, busy, done.
- Register address: ctrl, status, A, B, opcode, result, invalid.
- Byteenable: `0000`, từng byte `0001/0010/0100/1000`, full `1111`, random mixed.
- AXI write order: AW first, W first, same cycle.
- AXI stalls: no stall, AW stall, W stall, B stall, AR stall, R stall.
- Avalon operation: read, write, simultaneous read/write.
- Cross quan trọng:
  - opcode x error
  - opcode x operand corner
  - register address x byteenable
  - write order x stall type
  - operation type x waitrequest
  - start_when x status_busy

**Kết luận ngắn:** directed test dùng để đóng hết corner rõ ràng; random test dùng để quét tổ hợp operand/address/byteenable/stall; protocol test/assertion dùng để bắt AXI-Lite và Avalon timing. Nếu bạn muốn coverage thật sự 100%, nên viết coverage model trước, rồi map từng testcase vào coverpoint/cross ở trên.
