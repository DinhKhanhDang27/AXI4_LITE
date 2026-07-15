# Vá»›i RTL hiá»‡n táº¡i, Ä‘á»ƒ hÆ°á»›ng tá»›i **100% functional coverage** thÃ¬ nÃªn chia testcase theo 5 block: `alu_core`, `axi_register_bank`, `axi4lite_slave`, `avalon_axi4lite_bridge`, vÃ  top `avalon_axi4lite_alu`.

â€œ100%â€ á»Ÿ Ä‘Ã¢y nÃªn hiá»ƒu lÃ  100% coverage theo coverpoint/cross mÃ¬nh Ä‘á»‹nh nghÄ©a; code coverage 100% cÃ²n phá»¥ thuá»™c tool vÃ  cÃ³ vÃ i nhÃ¡nh default/reset/protocol cáº§n kÃ­ch Ä‘Ãºng.

## 1. Directed Test

### Cho `alu_core`

- Reset test: sau reset `result=0`, `busy=0`, `done=0`, `error=0`.
- ADD normal: `A+B`, vÃ­ dá»¥ `10+5=15`.
- ADD overflow wrap: `32'hFFFF_FFFF + 1 = 0`.
- SUB normal: `10-5=5`.
- SUB underflow wrap: `0-1 = 32'hFFFF_FFFF`.
- MUL normal: `3*7=21`.
- MUL overflow/truncate: giÃ¡ trá»‹ lá»›n Ä‘á»ƒ check láº¥y 32 bit tháº¥p.
- DIV normal: `20/4=5`.
- DIV remainder truncate: `7/2=3`.
- DIV by zero: `B=0`, expect `result=0`, `error=1`.
- Invalid opcode: opcode `4..15`, expect `result=0`, `error=1`.
- Start while busy: pulse `start` liÃªn tiáº¿p, operation thá»© hai khÃ´ng Ä‘Æ°á»£c nháº­n khi `busy=1`.
- Timing: sau `start`, `busy=1`; cycle sau `busy=0`, `done=1`; cycle tiáº¿p `done=0`.

### Cho `axi_register_bank`

- Reset register: `A/B/opcode/result/status/start_pulse` vá» 0.
- Write/read `ADDR_A = 0x08`.
- Write/read `ADDR_B = 0x0C`.
- Write/read `ADDR_OPCODE = 0x10`, chá»‰ láº¥y 4 bit tháº¥p.
- Write `CTRL = 0x1` khi idle: táº¡o `start_pulse` Ä‘Ãºng 1 cycle, status busy bit = 1.
- Write `CTRL = 0x0`: khÃ´ng start.
- Write `CTRL = 0x1` khi status busy: khÃ´ng táº¡o start má»›i.
- Core done khÃ´ng error: `status = 3'b010`, result Ä‘Æ°á»£c latch.
- Core done cÃ³ error: `status = 3'b110`.
- Read `STATUS = 0x04`, `RESULT = 0x14`.
- Read invalid address: tráº£ 0.
- Write invalid address: khÃ´ng Ä‘á»•i register.
- Byte enable tá»«ng byte cho `A`, `B`.
- Byte enable partial cho `OPCODE`, Ä‘áº·c biá»‡t `wr_strb[0]=0` thÃ¬ opcode tháº¥p khÃ´ng Ä‘á»•i.

### Cho `axi4lite_slave`

- Reset all AXI outputs/internal flags.
- Write AW trÆ°á»›c W.
- Write W trÆ°á»›c AW.
- Write AW vÃ  W cÃ¹ng cycle.
- Hold `BVALID` khi `BREADY=0`, clear khi `BREADY=1`.
- Äáº£m báº£o `wr_en` chá»‰ pulse 1 cycle.
- Read transaction bÃ¬nh thÆ°á»ng: AR handshake, sau Ä‘Ã³ RVALID/RDATA.
- Hold `RVALID` khi `RREADY=0`, clear khi `RREADY=1`.
- Back-to-back write.
- Back-to-back read.
- Read/write interleaved náº¿u testbench cho phÃ©p.
- Check `BRESP=OKAY`, `RRESP=OKAY`.

### Cho `avalon_axi4lite_bridge`

- Reset: state idle, no valid, no readdatavalid.
- Avalon write khi idle.
- Avalon read khi idle.
- Náº¿u `avs_write` vÃ  `avs_read` cÃ¹ng lÃºc: write Ä‘Æ°á»£c Æ°u tiÃªn vÃ¬ RTL check write trÆ°á»›c.
- `avs_waitrequest=1` khi bridge busy.
- Write vá»›i AWREADY/WREADY cÃ¹ng cycle.
- Write vá»›i AWREADY trÆ°á»›c WREADY.
- Write vá»›i WREADY trÆ°á»›c AWREADY.
- BVALID delay nhiá»u cycle.
- Read vá»›i ARREADY delay.
- Read vá»›i RVALID delay.
- `avs_readdatavalid` chá»‰ pulse 1 cycle khi nháº­n RDATA.
- Check latch address/writedata/byteenable á»•n Ä‘á»‹nh trong transaction.
- ÄÆ°a `m_axi_bresp/rresp` khÃ¡c OKAY Ä‘á»ƒ toggle `unused_resp`, dÃ¹ hiá»‡n táº¡i bridge khÃ´ng xá»­ lÃ½ lá»—i.

### Cho top `avalon_axi4lite_alu`

- Full software flow:
  - write A
  - write B
  - write opcode
  - write CTRL start
  - poll STATUS
  - read RESULT
- Láº·p flow cho ADD/SUB/MUL/DIV.
- DIV by zero qua bus, check status error vÃ  result 0.
- Invalid opcode qua bus, check status error.
- Partial byte write qua Avalon byteenable.
- Invalid address read/write qua Avalon.
- Back-to-back ALU operations sau khi done.
- Attempt start while busy qua Avalon, expect khÃ´ng nháº­n start má»›i.

## 2. Random Test

NÃªn cÃ³ constrained random á»Ÿ 3 táº§ng:

- ALU random:
  - random `operand_a`, `operand_b`, `opcode`.
  - opcode distribution: `0..3` nhiá»u hÆ¡n, `4..15` váº«n pháº£i cover.
  - Ã©p corner value: `0`, `1`, `32'hFFFF_FFFF`, `32'h8000_0000`, `32'h7FFF_FFFF`.
  - vá»›i DIV, random cáº£ `B=0` vÃ  `B!=0`.
  - scoreboard tÃ­nh expected báº±ng SystemVerilog model.

- Register/bus random:
  - random address trong `{0x00,0x04,0x08,0x0C,0x10,0x14}` vÃ  invalid.
  - random write/read sequence.
  - random byteenable `0000..1111`.
  - random start timing: start khi idle, start khi busy, start sau done.
  - random read status/result trong lÃºc operation Ä‘ang cháº¡y.

- Protocol random:
  - random delay cho `AWREADY`, `WREADY`, `BVALID`, `ARREADY`, `RVALID`.
  - random `BREADY/RREADY` stall.
  - random order AW/W.
  - random Avalon read/write spacing.
  - random backpressure Ä‘á»ƒ cover má»i state transition cá»§a bridge.

## 3. Protocol Test / Assertion Test

NÃªn cÃ³ assertion hoáº·c protocol checker cho:

- AXI-Lite write:
  - `AWVALID` giá»¯ stable `AWADDR` tá»›i khi `AWREADY`.
  - `WVALID` giá»¯ stable `WDATA/WSTRB` tá»›i khi `WREADY`.
  - `BVALID` giá»¯ tá»›i khi `BREADY`.
  - má»—i cáº·p AW/W sinh Ä‘Ãºng má»™t `wr_en`.
  - khÃ´ng sinh write response náº¿u thiáº¿u AW hoáº·c W.

- AXI-Lite read:
  - `ARVALID` giá»¯ stable `ARADDR` tá»›i khi `ARREADY`.
  - `RVALID` giá»¯ stable `RDATA/RRESP` tá»›i khi `RREADY`.
  - má»—i AR sinh Ä‘Ãºng má»™t R response.
  - khÃ´ng accept AR má»›i khi `read_pending` hoáº·c `rvalid_q`.

- Avalon side:
  - khi `avs_waitrequest=1`, master khÃ´ng nÃªn Ä‘á»•i request/data/address náº¿u theo protocol Avalon-MM.
  - `avs_readdatavalid` chá»‰ xuáº¥t hiá»‡n cho read.
  - write khÃ´ng táº¡o `avs_readdatavalid`.
  - bridge khÃ´ng nháº­n command má»›i khi busy.
  - write Ä‘Æ°á»£c Æ°u tiÃªn náº¿u read/write cÃ¹ng lÃºc, vÃ¬ RTL hiá»‡n táº¡i nhÆ° váº­y.

## 4. Coverage NÃªn Äá»‹nh NghÄ©a

Coverpoint tá»‘i thiá»ƒu:

- Opcode: ADD, SUB, MUL, DIV, invalid.
- Operand class A/B: zero, one, max, min signed-ish `0x8000_0000`, random.
- DIV class: divisor zero, divisor nonzero.
- Error: no error, divide-by-zero, invalid opcode.
- ALU status: idle, busy, done.
- Register address: ctrl, status, A, B, opcode, result, invalid.
- Byteenable: `0000`, tá»«ng byte `0001/0010/0100/1000`, full `1111`, random mixed.
- AXI write order: AW first, W first, same cycle.
- AXI stalls: no stall, AW stall, W stall, B stall, AR stall, R stall.
- Avalon operation: read, write, simultaneous read/write.
- Cross quan trá»ng:
  - opcode x error
  - opcode x operand corner
  - register address x byteenable
  - write order x stall type
  - operation type x waitrequest
  - start_when x status_busy

**Káº¿t luáº­n ngáº¯n:** directed test dÃ¹ng Ä‘á»ƒ Ä‘Ã³ng háº¿t corner rÃµ rÃ ng; random test dÃ¹ng Ä‘á»ƒ quÃ©t tá»• há»£p operand/address/byteenable/stall; protocol test/assertion dÃ¹ng Ä‘á»ƒ báº¯t AXI-Lite vÃ  Avalon timing. Náº¿u báº¡n muá»‘n coverage tháº­t sá»± 100%, nÃªn viáº¿t coverage model trÆ°á»›c, rá»“i map tá»«ng testcase vÃ o coverpoint/cross á»Ÿ trÃªn.
