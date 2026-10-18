### syscall constants
PRINT_STRING                        = 4
PRINT_CHAR                          = 11
PRINT_INT_SYSCALL                   = 1

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

REQUEST_PUZZLE                      = 0xffff00d0
AVAIL_PUZZLES                       = 0xffff00b4
CURRENT_PUZZLE                      = 0xffff00b8
SUBMIT_SOLUTION                     = 0xffff00d4

MMIO_STATUS                         = 0xffff204c
PRINT_INT                           = 0xffff0080
PRINT_HEX                           = 0xffff0088
PRINT_FLOAT                         = 0xffff0084

### interrupt acknowledgements and masks
BONK_ACK                            = 0xffff0060
BONK_INT_MASK                       = 0x1000
TIMER_ACK                           = 0xffff006c
TIMER_INT_MASK                      = 0x8000
REQUEST_PUZZLE_ACK                  = 0xffff00e4
REQUEST_PUZZLE_INT_MASK             = 0x0800
TRAIL_CANCELLED_ACK                 = 0xffff00e8
TRAIL_CANCELLED_INT_MASK            = 0x0400
TERRITORY_DISCONNECTED_ACK          = 0xffff00ec
TERRITORY_DISCONNECTED_INT_MASK     = 0x2000

.data
has_bonked:              .byte 0
trail_cancelled:         .byte 0
territory_disconnected:  .byte 0
.align 2
puzzle:                  .space 268
solution:                .space 256
puzzle_received:         .byte 0
.align 2
num_puzzles_requested:   .word 0

.text
main:
    li      $t4, TIMER_INT_MASK
    or      $t4, $t4, BONK_INT_MASK
    or      $t4, $t4, REQUEST_PUZZLE_INT_MASK
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

    and     $a0, $k0, REQUEST_PUZZLE_INT_MASK
    bne     $a0, 0, request_puzzle_interrupt

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

request_puzzle_interrupt:
    sw      $0, REQUEST_PUZZLE_ACK
    li      $t0, 1
    sb      $t0, puzzle_received
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

### puzzle solver
.text

# zero_board($a0 rows, $a1 columns, $a2 solution).
zero_board:
    li      $t0, 0

row_loop:
    bge     $t0, $a0, zero_done
    li      $t1, 0

col_loop:
    bge     $t1, $a1, next_row_zero

    mul     $t2, $t0, $a1
    add     $t2, $t2, $t1
    add     $t3, $a2, $t2
    sb      $zero, 0($t3)

    addi    $t1, $t1, 1
    j       col_loop

next_row_zero:
    addi    $t0, $t0, 1
    j       row_loop

zero_done:
    jr      $ra

# board_done($a0 rows, $a1 columns, $a2 board): $v0 = all zero.
board_done:
    li      $t0, 0

row_loop_board_done:
    bge     $t0, $a0, all_zero
    li      $t1, 0

col_loop_board_done:
    bge     $t1, $a1, next_row

    mul     $t2, $t0, $a1
    add     $t2, $t2, $t1
    add     $t3, $a2, $t2

    lbu     $t4, 0($t3)
    bne     $t4, $0, found_nonzero

    addi    $t1, $t1, 1
    j       col_loop_board_done

next_row:
    addi    $t0, $t0, 1
    j       row_loop_board_done

found_nonzero:
    li      $v0, 0
    jr      $ra

all_zero:
    li      $v0, 1
    jr      $ra

# toggle_light($a0 row, $a1 column, $a2 puzzle, $a3 actions).
toggle_light:
    lw      $t0, 0($a2)
    lw      $t1, 4($a2)
    lw      $t2, 8($a2)

    addi    $t3, $a2, 12

    mul     $t4, $a0, $t1
    add     $t4, $t4, $a1
    add     $t5, $t3, $t4

    lbu     $t6, 0($t5)
    add     $t6, $t6, $a3
    rem     $t6, $t6, $t2
    sb      $t6, 0($t5)

    slt     $t8, $zero, $a0
    beq     $t8, $zero, skip_up

    addi    $t9, $a0, -1
    mul     $t4, $t9, $t1
    add     $t4, $t4, $a1
    add     $t5, $t3, $t4

    lbu     $t6, 0($t5)
    add     $t6, $t6, $a3
    rem     $t6, $t6, $t2
    sb      $t6, 0($t5)

skip_up:
    slt     $t8, $zero, $a1
    beq     $t8, $zero, skip_left

    addi    $t9, $a1, -1
    mul     $t4, $a0, $t1
    add     $t4, $t4, $t9
    add     $t5, $t3, $t4

    lbu     $t6, 0($t5)
    add     $t6, $t6, $a3
    rem     $t6, $t6, $t2
    sb      $t6, 0($t5)
skip_left:
    addi    $t9, $t0, -1
    slt     $t8, $a0, $t9
    beq     $t8, $zero, skip_down

    addi    $t9, $a0, 1
    mul     $t4, $t9, $t1
    add     $t4, $t4, $a1
    add     $t5, $t3, $t4

    lbu     $t6, 0($t5)
    add     $t6, $t6, $a3
    rem     $t6, $t6, $t2
    sb      $t6, 0($t5)
skip_down:
    addi    $t9, $t1, -1
    slt     $t8, $a1, $t9
    beq     $t8, $zero, toggle_done

    addi    $t9, $a1, 1
    mul     $t4, $a0, $t1
    add     $t4, $t4, $t9
    add     $t5, $t3, $t4

    lbu     $t6, 0($t5)
    add     $t6, $t6, $a3
    rem     $t6, $t6, $t2
    sb      $t6, 0($t5)

toggle_done:
    jr      $ra

# solve($a0 puzzle, $a1 solution, $a2 row, $a3 column): $v0 = success.
# Search the first row, chase lights below it, and undo failed branches.
solve:

    sub     $sp, $sp, 36
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)
    sw      $s4, 20($sp)
    sw      $s5, 24($sp)
    sw      $s6, 28($sp)
    sw      $s7, 32($sp)

    move    $s0, $a0
    move    $s1, $a1
    move    $s2, $a2
    move    $s3, $a3

    lw      $s4, 0($s0)
    lw      $s5, 4($s0)
    lw      $s6, 8($s0)

    sub     $t0, $s5, 1
    bne     $s3, $t0, solve_same_row
    add     $s7, $s2, 1
    j       solve_check_bounds
solve_same_row:
    move    $s7, $s2

solve_check_bounds:
    bge     $s2, $s4, solve_call_board_done
    bge     $s3, $s5, solve_call_board_done
    j       solve_check_row

solve_call_board_done:
    move    $a0, $s4
    move    $a1, $s5
    add     $a2, $s0, 12
    jal     board_done
    j       solve_return

solve_check_row:
    beq     $s2, $0, solve_first_row

    sub     $t0, $s2, 1
    mul     $t0, $t0, $s5
    add     $t0, $t0, $s3
    add     $t1, $s0, 12
    add     $t1, $t1, $t0
    lbu     $t2, 0($t1)
    sub     $t3, $s6, $t2
    rem     $t3, $t3, $s6

    sub     $sp, $sp, 4
    sw      $t3, 0($sp)

    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $t3, 0($t1)

    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t3
    jal     toggle_light

    add     $t0, $s3, 1
    rem     $t0, $t0, $s5
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s7
    move    $a3, $t0
    jal     solve

    bne     $v0, $0, solve_row_return_true

    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $0, 0($t1)

    lw      $t3, 0($sp)

    sub     $t4, $s6, $t3
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t4
    jal     toggle_light

    add     $sp, $sp, 4
    li      $v0, 0
    j       solve_return

solve_row_return_true:
    add     $sp, $sp, 4
    li      $v0, 1
    j       solve_return

solve_first_row:
    li      $t6, 0

    sub     $sp, $sp, 4

solve_loop:
    bge     $t6, $s6, solve_loop_end

    sw      $t6, 0($sp)

    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $t6, 0($t1)

    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t6
    jal     toggle_light

    add     $t0, $s3, 1
    rem     $t0, $t0, $s5
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s7
    move    $a3, $t0
    jal     solve

    bne     $v0, $0, solve_loop_return_true

    lw      $t6, 0($sp)

    sub     $t4, $s6, $t6
    move    $a0, $s2
    move    $a1, $s3
    move    $a2, $s0
    move    $a3, $t4
    jal     toggle_light

    mul     $t0, $s2, $s5
    add     $t0, $t0, $s3
    add     $t1, $s1, $t0
    sb      $0, 0($t1)

    lw      $t6, 0($sp)
    add     $t6, $t6, 1
    j       solve_loop

solve_loop_return_true:
    add     $sp, $sp, 4
    li      $v0, 1
    j       solve_return

solve_loop_end:
    add     $sp, $sp, 4
    li      $v0, 0

solve_return:
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    lw      $s4, 20($sp)
    lw      $s5, 24($sp)
    lw      $s6, 28($sp)
    lw      $s7, 32($sp)
    add     $sp, $sp, 36
    jr      $ra
