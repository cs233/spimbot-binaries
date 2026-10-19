### syscall constants
PRINT_STRING                        = 4
PRINT_CHAR                          = 11
PRINT_INT                           = 1

### MMIO addresses
VELOCITY                            = 0xffff0010
ANGLE                               = 0xffff0014
ANGLE_CONTROL                       = 0xffff0018
TIMER                               = 0xffff001c

BOT_X                               = 0xffff0020
BOT_Y                               = 0xffff0024
BASE_LOCATION                       = 0xffff0044

NUM_PAINT                           = 0xffff0040
SEARCH_FIELD                        = 0xffff00dc
FIELD_MAP_BYTES                     = 0xffff00c0
TRAIL_LENGTH                        = 0xffff00c4
LAST_TRAIL_CANCEL_REASON            = 0xffff00c8
LAST_CLAIMED_TILES                  = 0xffff00cc
SCORES_REQUEST                      = 0xffff1018

MMIO_STATUS                         = 0xffff204c
PRINT_HEX                           = 0xffff0088
PRINT_FLOAT                         = 0xffff0084

### interrupt acknowledgements and masks
BONK_ACK                            = 0xffff0060
BONK_INT_MASK                       = 0x1000
TIMER_ACK                           = 0xffff006c
TIMER_INT_MASK                      = 0x8000
TRAIL_CANCELLED_ACK                 = 0xffff00e8
TRAIL_CANCELLED_INT_MASK            = 0x0400
TERRITORY_DISCONNECTED_ACK          = 0xffff00ec
TERRITORY_DISCONNECTED_INT_MASK     = 0x2000

.data
has_bonked:              .byte 0
trail_cancelled:         .byte 0
territory_disconnected:  .byte 0
.align 2

.text
main:
    li      $t4, TIMER_INT_MASK
    or      $t4, $t4, BONK_INT_MASK
    or      $t4, $t4, TRAIL_CANCELLED_INT_MASK
    or      $t4, $t4, TERRITORY_DISCONNECTED_INT_MASK
    or      $t4, $t4, 1
    mtc0    $t4, $12

    li      $t1, 0
    sw      $t1, ANGLE
    li      $t1, 1
    sw      $t1, ANGLE_CONTROL
    sw      $zero, VELOCITY

    # YOUR CODE GOES HERE

loop:
    j       loop

### interrupt handler
.kdata
chunk_ih:                .space 40
non_intrpt_str:          .asciiz "Non-interrupt exception\n"
unhandled_str:           .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
# $k1 holds the interrupted $at until return.
.set noat
    move    $k1, $at
.set at
    la      $k0, chunk_ih
    sw      $a0, 0($k0)
    sw      $v0, 4($k0)
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)

    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf
    bne     $a0, 0, non_intrpt

interrupt_dispatch:
    mfc0    $k0, $13
    beq     $k0, 0, done

    and     $a0, $k0, BONK_INT_MASK
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK
    bne     $a0, 0, timer_interrupt

    and     $a0, $k0, TRAIL_CANCELLED_INT_MASK
    bne     $a0, 0, trail_cancelled_interrupt

    and     $a0, $k0, TERRITORY_DISCONNECTED_INT_MASK
    bne     $a0, 0, territory_disconnected_interrupt

    li      $v0, PRINT_STRING
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK
    li      $t0, 1
    sb      $t0, has_bonked
    j       interrupt_dispatch

timer_interrupt:
    sw      $0, TIMER_ACK
    j       interrupt_dispatch

trail_cancelled_interrupt:
    sw      $0, TRAIL_CANCELLED_ACK
    li      $t0, 1
    sb      $t0, trail_cancelled
    j       interrupt_dispatch

territory_disconnected_interrupt:
    sw      $0, TERRITORY_DISCONNECTED_ACK
    li      $t0, 1
    sb      $t0, territory_disconnected
    j       interrupt_dispatch

non_intrpt:
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall

done:
    la      $k0, chunk_ih

    lw      $t0, 32($k0)
    mthi    $t0
    lw      $t0, 36($k0)
    mtlo    $t0

    lw      $a0, 0($k0)
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)

.set noat
    move    $at, $k1
.set at
    eret
