#include <stdio.h>
#include "io.h"
#include "system.h"

#define ALU_REG_CTRL      0x00u
#define ALU_REG_STATUS    0x04u
#define ALU_REG_A         0x08u
#define ALU_REG_B         0x0Cu
#define ALU_REG_OPCODE    0x10u
#define ALU_REG_RESULT    0x14u

#define ALU_CTRL_START    0x1u

#define ALU_STATUS_BUSY   0x1u
#define ALU_STATUS_DONE   0x2u
#define ALU_STATUS_ERROR  0x4u

#define ALU_OP_ADD        0u
#define ALU_OP_SUB        1u
#define ALU_OP_MUL        2u
#define ALU_OP_DIV        3u

#define ALU_TIMEOUT       1000000u

static void alu_write(unsigned int offset, unsigned int value)
{
    IOWR_32DIRECT(ALU_AXI4_LITE_0_BASE, offset, value);
}

static unsigned int alu_read(unsigned int offset)
{
    return IORD_32DIRECT(ALU_AXI4_LITE_0_BASE, offset);
}

static int alu_run(unsigned int a,
                   unsigned int b,
                   unsigned int opcode,
                   unsigned int *result,
                   unsigned int *status)
{
    unsigned int timeout = ALU_TIMEOUT;

    alu_write(ALU_REG_A, a);
    alu_write(ALU_REG_B, b);
    alu_write(ALU_REG_OPCODE, opcode);
    alu_write(ALU_REG_CTRL, ALU_CTRL_START);

    do {
        *status = alu_read(ALU_REG_STATUS);
        if ((*status & ALU_STATUS_DONE) != 0u) {
            *result = alu_read(ALU_REG_RESULT);
            return ((*status & ALU_STATUS_ERROR) == 0u) ? 0 : -1;
        }
    } while (--timeout != 0u);

    *result = alu_read(ALU_REG_RESULT);
    *status = alu_read(ALU_REG_STATUS);
    return -2;
}

static void test_case(const char *name,
                      unsigned int a,
                      unsigned int b,
                      unsigned int opcode,
                      unsigned int expected,
                      int expect_error)
{
    unsigned int result = 0u;
    unsigned int status = 0u;
    int rc;
    int pass;

    rc = alu_run(a, b, opcode, &result, &status);
    pass = 0;

    if (expect_error) {
        pass = (rc == -1) && ((status & ALU_STATUS_ERROR) != 0u);
    } else {
        pass = (rc == 0) && (result == expected);
    }

    printf("%s: A=%u B=%u result=%u expected=%u status=0x%08x %s\n",
           name,
           a,
           b,
           result,
           expected,
           status,
           pass ? "PASS" : "FAIL");
}

int main(void)
{
    printf("AXI4-Lite ALU software test\n");
    printf("ALU base = 0x%08x\n", (unsigned int)ALU_AXI4_LITE_0_BASE);

    test_case("ADD", 20u, 7u, ALU_OP_ADD, 27u, 0);
    test_case("SUB", 20u, 7u, ALU_OP_SUB, 13u, 0);
    test_case("MUL", 20u, 7u, ALU_OP_MUL, 140u, 0);
    test_case("DIV", 20u, 5u, ALU_OP_DIV, 4u, 0);
    test_case("DIV_BY_ZERO", 20u, 0u, ALU_OP_DIV, 0u, 1);

    printf("Done\n");

    while (1) {
    }

    return 0;
}
