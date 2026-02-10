### syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

### MMIO addrs
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018
VELOCITY                = 0xffff0010

REQUEST_PUZZLE          = 0xffff00d0
AVAIL_PUZZLES           = 0xffff00b4
CURRENT_PUZZLE          = 0xffff00b8
PUZZLE_FEEDBACK         = 0xffff00e0
SUBMIT_SOLUTION         = 0xffff00d4

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

NUM_CARROTS             = 0xffff0040
NUM_BUNNIES_CARRIED     = 0xffff0050

SEARCH_BUNNIES          = 0xffff0054
CATCH_BUNNY             = 0xffff0058
PUT_BUNNIES_IN_PLAYPEN  = 0xffff005c

PLAYPEN_LOCATION        = 0xffff0044

SCORES_REQUEST          = 0xffff1018

TIMER                   = 0xffff001c

BONK_INT_MASK           = 0x1000      ## Bonk
BONK_ACK                = 0xffff0060  ## Bonk
TIMER_INT_MASK          = 0x8000      ## Timer
TIMER_ACK               = 0xffff006c  ## Timer
FEEDBACK_INT_MASK       = 0x800       ## Feedback
FEEDBACK_ACK            = 0xffff00e4  ## Feedback
BUNNY_MOVE_INT_MASK     = 0x400       ## Bunny Move
BUNNY_MOVE_ACK          = 0xffff00e8  ## Bunny Move
EX_CARRY_LIMIT_INT_MASK = 0x4000      ## Exceeding Carry Limit
EX_CARRY_LIMIT_ACK      = 0xffff002c  ## Exceeding Carry Limit

MMIO_STATUS             = 0xffff204c

.data

# If you want, you can use the following to detect if a bonk has happened.
has_bonked: .byte 0

.text
main:
        # enable interrupts
        li      $t4     1
        or      $t4     $t4     TIMER_INT_MASK
        or      $t4,    $t4,    BONK_INT_MASK             # enable bonk interrupt
        or      $t4,    $t4,    1 # global enable
        mtc0    $t4     $12

        li $t1, 0
        sw $t1, ANGLE
        li $t1, 1
        sw $t1, ANGLE_CONTROL
        li $t2, 0
        sw $t2, VELOCITY

        # YOUR CODE GOES HERE!!!!!!



    	# END YOUR CODE SECTION 

# Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed

loop:
        j       loop

# ======================== kernel code ================================
.kdata
chunkIH:    .space 40
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at        # Save $at
                            # NOTE: Don't touch $k1 or else you destroy $at!
.set at
    la      $k0, chunkIH
    sw      $a0, 0($k0)        # Get some free registers
    sw      $v0, 4($k0)        # by storing them to a global variable
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)

    # Save coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13                # Get Cause register
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf           # ExcCode field
    bne     $a0, 0, non_intrpt


interrupt_dispatch:                 # Interrupt:
    mfc0    $k0, $13                # Get Cause register, again
    beq     $k0, 0, done            # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK     # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

    li      $v0, PRINT_STRING       # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK
    #Fill in your bonk handler code here
    j       interrupt_dispatch      # see if other interrupts are waiting

timer_interrupt:
    sw      $0, TIMER_ACK
    #Fill in your timer interrupt code here
    j       interrupt_dispatch      # see if other interrupts are waiting

non_intrpt:                         # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                         # print out an error message
    # fall through to done

done:
    la      $k0, chunkIH

    # Restore coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    lw      $t0, 32($k0)
    mthi    $t0
    lw      $t0, 36($k0)
    mtlo    $t0

    lw      $a0, 0($k0)             # Restore saved registers
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)

.set noat
    move    $at, $k1        # Restore $at
.set at
    eret

## Provided code from Labs 6 and 7  + is_solved
.text	

is_solved:
	li	$t0, 0			# i = 0
is_loop:
	add	$t1, $a0, $t0		# &feedback->feedback[i] - 5
	lb	$t2, 5($t1)		# feedback->feedback[i]
	bne	$t2, 2, is_false	# return false if not MATCH
	add	$t0, $t0, 1		# i ++ 
	blt	$t0, 5, is_loop		# loop while i < 5
	
is_true:
	li	$v0, 1			# return TRUE
	jr	$ra

is_false:
	li	$v0, 0			# return FALSE
	jr	$ra

#########################################	
	
init_state:
	li	$t0, 0x03ffffff
	sw	$t0, 0($a0)
	sw	$t0, 4($a0)
	sw	$t0, 8($a0)
	sw	$t0, 12($a0)
	sw	$t0, 16($a0)

	sw	$0, 20($a0)
	sw	$0, 24($a0)
	sh	$0, 28($a0)

	jr	$ra

#########################################	

letters_allowed:	
	li	$t0, 0		# i = 0 
la_loop:
	bge	$t0, 5, la_done_true
	
	add	$t1, $a1, $t0	# &candidate[i]
	lb	$t1, 0($t1)	# candidate[i]
	sub	$t1, $t1, 97

	sll	$t2, $t0, 2	# 4*i
	add	$t2, $t2, $a0	# &state->letter_flags[i]
	lw	$t2, 0($t2)	# state->letter_flags[i]
	li	$t3, 1
	sll	$t3, $t3, $t1	# (1 << letter_index)
	and	$t3, $t3, $t2	# (state->letter_flags[i] & (1 << letter_index))
	beq	$t3, $0, la_done_false

	add	$t0, $t0, 1	# i ++
	j	la_loop

la_done_true:
	li	$v0, 1
	jr	$ra

la_done_false:
	li	$v0, 0
	jr	$ra

#########################################	

letters_required:
	li	$t0, 0
lr_loop:
	sll	$t1, $t0, 1	# 2*i
	add	$t1, $a0, $t1
	lb	$t2, 21($t1)	# state->letters[i].count
	beq	$t2, 0, lr_done_true

	lb	$t1, 20($t1)	# letter_index = state->letters[i].letter_index
	li	$t3, 0		# count
	li	$t4, 0		# j

lr_loop2:
	add	$t5, $a1, $t4	# &candidate[j]
	lb	$t5, 0($t5)	# candidate[j]
	sub	$t5, $t5, 97	# candidate[j] - 'a'
	bne	$t1, $t5, lr_skip
	
	add	$t3, $t3, 1	# count ++
lr_skip:	
	add	$t4, $t4, 1	# j ++
	blt	$t4, 5, lr_loop2
	
	and	$t6, $t2, 0x40	# desired_count & EXACTLY
	beq	$t6, $0, lr_skip2

	li	$t7, 0x40	# EXACTLY
	not	$t7, $t7	# ~EXACTLY
	and	$t2, $t2, $t7	# desired_count &= ~EXACTLY
	bne	$t2, $t3, lr_done_false
	j	lr_skip3

lr_skip2:
	blt	$t3, $t2, lr_done_false
	
lr_skip3:	
	add	$t0, $t0, 1	# i ++
	blt	$t0, 5, lr_loop # continue if i < 5
lr_done_true:
	li	$v0, 1
	jr	$ra

lr_done_false:
	li	$v0, 0
	jr	$ra

#########################################	
	
find_matching_word:	
    sub     $sp     $sp     24
    sw      $s0     0($sp)
    sw      $s1     4($sp)
    sw      $s2     8($sp)
    sw      $s3     12($sp)         
    sw      $s4     16($sp)         
    sw      $ra     20($sp)
    
    move    $s0     $a0             # state
    move    $s1     $a1             # words
    li      $s2     0               # i = 0

    la      $s3     g_num_words
    lw      $s3     0($s3)          # g_num_words
    
_loop:
    bge     $s2     $s3     _ret_null
    
    move    $a0     $s0             # state
    move    $a1     $s1             # &words[i * 6]
    jal     letters_allowed
    move    $s4     $v0             # letters_allowed
    
    move    $a0     $s0             # state
    move    $a1     $s1             # &words[i * 6]
    jal     letters_required        
    and     $s4     $s4     $v0     # letters_allowed & letters_required
    
    move    $v0     $s1
    bne     $s4     $zero   _return # return candidate
    
    add     $s2     $s2     1       # ++i
    add     $s1     $s1     6       # ++words
    j       _loop

_ret_null:
    li      $v0     0
    
_return:
    lw      $s0     0($sp)
    lw      $s1     4($sp)
    lw      $s2     8($sp)
    lw      $s3     12($sp)
    lw      $s4     16($sp)
    lw      $ra     20($sp)
    add     $sp     $sp     24
    jr      $ra

#########################################	

count_instances_of_letter:
	li	$v0, 0		# count = 0

ciol_loop:
	add	$t1, $a0, $a1	# &feedback->word[i]
	lb	$t2, 0($t1)	# feedback->word[i]
	sub	$t2, $t2, 97	# i_letter_index = feedback->word[i] - 'a'

	bne	$t2, $a2, ciol_loop_end		# if (i_letter_index == letter_index) {
	lb	$t3, 5($t1)	# i_fback = feedback->feedback[i]

	bne	$t3, 0, ciol_else		# if (i_fback == NOMATCH) {
	or	$v0, $v0, 0x40	# count |= EXACTLY
	j	ciol_endif
	
ciol_else:
	add	$v0, $v0, 1	# count ++
	
ciol_endif:
	lw	$t4, 0($a3)	# *already_visited
	li	$t5, 1
	sll	$t5, $t5, $a1	# (1 << i)
	or	$t4, $t4, $t5
	sw	$t4, 0($a3)	# *already_visited != (1 << i)

ciol_loop_end:	
	add	$a1, $a1, 1	# i++
	blt	$a1, 5, ciol_loop
	
	jr	$ra

#########################################	

update_state:
	move	$v0, $a3
	
	li	$t0, 0x40	# EXACTLY
	bne	$a1, $t0, us_else

	li	$t1, 0		# i
	li	$t2, 1
	sll	$t2, $t2, $a2	# (1 << letter_index)
	nor	$t2, $t2, $0	# ~(1 << letter_index)
us_loop:
	mul	$t3, $t1, 4	# i * 4
	add	$t3, $t3, $a0	# &state->letter_flags[i]
	lw	$t4, 0($t3)
	and	$t4, $t4, $t2	# state->letter_flags[i] & ~(1 << letter_index)
	sw	$t4, 0($t3)

	add	$t1, $t1, 1	# i ++
	blt	$t1, 5, us_loop
	
	jr	$ra
	
us_else:	
	mul	$t0, $v0, 2	# 2 * next_letter
	add	$t0, $t0, $a0	# &state->letters[next_letter] - 20
	sb	$a2, 20($t0)	# state->letters[next_letter].letter_index = letter_index;
	sb	$a1, 21($t0)	# state->letters[next_letter].count = count;
	add	$v0, $v0, 1	# next_letter ++;

	jr	$ra

#########################################	

build_state:	
	bne	$a0, $0, bs_recurse
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)
	
	move	$a0, $a1
	jal	init_state
	
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra

bs_recurse:	
	sub	$sp, $sp, 28
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$0,  24($sp)	# already_visited

	move	$s0, $a0	# feedback
	move	$s1, $a1	# state

	lw	$a0, 12($a0)	# feedback->prev
	jal	build_state
	
	li	$s3, 0		# next_letter = 0;
	li	$s2, 0		# i = 0

bs_loop:
	add	$t0, $s0, $s2	# &feedback->word[i]
	lb	$t1, 0($t0)	# feedback->word[i]
	sub	$s4, $t1, 97	# letter_index = feedback->word[i] - 'a'
	lb	$t2, 5($t0)	# fback = feedback->feedback[i]
	mul	$t3, $s2, 4	# i * 4
	add	$t3, $s1, $t3	# &state->letter_flags[i]
	li	$t0, 1
	sll	$t4, $t0, $s4	# (1 << letter_index)
	
	bne	$t2, 2, bs_else
	sw	$t4, 0($t3)	# state->letter_flags[i] = (1 << letter_index)
	j	bs_cont
bs_else:	
	nor	$t4, $t4, $0	# ~(1 << letter_index)
	lw	$t5, 0($t3)	# state->letter_flags[i]
	and	$t5, $t5, $t4	# state->letter_flags[i] & ~(1 << letter_index)
	sw	$t5, 0($t3)	# state->letter_flags[i] &= ~(1 << letter_index)
	
bs_cont:	
	li	$t0, 1
	sll	$t0, $t0, $s2	# (1 << i)
	lw	$t1,  24($sp)	# already_visited
	and	$t0, $t1, $t0	# already_visited & (1 << i)
	bne	$t0, $0, bs_end_loop

	move	$a0, $s0	# feedback
	move	$a1, $s2	# i
	move	$a2, $s4	# letter_index
	add	$a3, $sp, 24	# &already_visited
	jal	count_instances_of_letter

	move	$a0, $s1	# state
	move	$a1, $v0	# count
	move	$a2, $s4	# letter_index
	move	$a3, $s3	# next_letter
	jal	update_state
	move 	$s3, $v0	# next_letter = update_state(...)

bs_end_loop:	
	add	$s2, $s2, 1	# i ++
	blt	$s2, 5, bs_loop

	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 28
	jr	$ra


.data
.align 2
g_num_words:	.word 2315
words:
.asciiz	"aback" "abase" "abate" "abbey" "abbot" "abhor" "abide" "abled" "abode" "abort" "about" "above" "abuse"
.asciiz	"abyss" "acorn" "acrid" "actor" "acute" "adage" "adapt" "adept" "admin" "admit" "adobe" "adopt" "adore"
.asciiz	"adorn" "adult" "affix" "afire" "afoot" "afoul" "after" "again" "agape" "agate" "agent" "agile" "aging"
.asciiz	"aglow" "agony" "agora" "agree" "ahead" "aider" "aisle" "alarm" "album" "alert" "algae" "alibi" "alien"
.asciiz "align" "alike" "alive" "allay" "alley" "allot" "allow" "alloy" "aloft" "alone" "along" "aloof" "aloud"
.asciiz	"alpha" "altar" "alter" "amass" "amaze" "amber" "amble" "amend" "amiss" "amity" "among" "ample" "amply"
.asciiz	"amuse" "angel" "anger" "angle" "angry" "angst" "anime" "ankle" "annex" "annoy" "annul" "anode" "antic"
.asciiz	"anvil" "aorta" "apart" "aphid" "aping" "apnea" "apple" "apply" "apron" "aptly" "arbor" "ardor" "arena"
.asciiz	"argue" "arise" "armor" "aroma" "arose" "array" "arrow" "arson" "artsy" "ascot" "ashen" "aside" "askew"
.asciiz	"assay" "asset" "atoll" "atone" "attic" "audio" "audit" "augur" "aunty" "avail" "avert" "avian" "avoid"
.asciiz	"await" "awake" "award" "aware" "awash" "awful" "awoke" "axial" "axiom" "axion" "azure" "bacon" "badge"
.asciiz	"badly" "bagel" "baggy" "baker" "baler" "balmy" "banal" "banjo" "barge" "baron" "basal" "basic" "basil"
.asciiz	"basin" "basis" "baste" "batch" "bathe" "baton" "batty" "bawdy" "bayou" "beach" "beady" "beard" "beast"
.asciiz	"beech" "beefy" "befit" "began" "begat" "beget" "begin" "begun" "being" "belch" "belie" "belle" "belly"
.asciiz "below" "bench" "beret" "berry" "berth" "beset" "betel" "bevel" "bezel" "bible" "bicep" "biddy" "bigot"
.asciiz	"bilge" "billy" "binge" "bingo" "biome" "birch" "birth" "bison" "bitty" "black" "blade" "blame" "bland"
.asciiz	"blank" "blare" "blast" "blaze" "bleak" "bleat" "bleed" "bleep" "blend" "bless" "blimp" "blind" "blink"
.asciiz	"bliss" "blitz" "bloat" "block" "bloke" "blond" "blood" "bloom" "blown" "bluer" "bluff" "blunt" "blurb"
.asciiz	"blurt" "blush" "board" "boast" "bobby" "boney" "bongo" "bonus" "booby" "boost" "booth" "booty" "booze"
.asciiz	"boozy" "borax" "borne" "bosom" "bossy" "botch" "bough" "boule" "bound" "bowel" "boxer" "brace" "braid"
.asciiz	"brain" "brake" "brand" "brash" "brass" "brave" "bravo" "brawl" "brawn" "bread" "break" "breed" "briar"
.asciiz "bribe" "brick" "bride" "brief" "brine" "bring" "brink" "briny" "brisk" "broad" "broil" "broke" "brood"
.asciiz	"brook" "broom" "broth" "brown" "brunt" "brush" "brute" "buddy" "budge" "buggy" "bugle" "build" "built"
.asciiz	"bulge" "bulky" "bully" "bunch" "bunny" "burly" "burnt" "burst" "bused" "bushy" "butch" "butte" "buxom"
.asciiz	"buyer" "bylaw" "cabal" "cabby" "cabin" "cable" "cacao" "cache" "cacti" "caddy" "cadet" "cagey" "cairn"
.asciiz	"camel" "cameo" "canal" "candy" "canny" "canoe" "canon" "caper" "caput" "carat" "cargo" "carol" "carry"
.asciiz	"carve" "caste" "catch" "cater" "catty" "caulk" "cause" "cavil" "cease" "cedar" "cello" "chafe" "chaff"
.asciiz	"chain" "chair" "chalk" "champ" "chant" "chaos" "chard" "charm" "chart" "chase" "chasm" "cheap" "cheat"
.asciiz	"check" "cheek" "cheer" "chess" "chest" "chick" "chide" "chief" "child" "chili" "chill" "chime" "china"
.asciiz	"chirp" "chock" "choir" "choke" "chord" "chore" "chose" "chuck" "chump" "chunk" "churn" "chute" "cider"
.asciiz	"cigar" "cinch" "circa" "civic" "civil" "clack" "claim" "clamp" "clang" "clank" "clash" "clasp" "class"
.asciiz	"clean" "clear" "cleat" "cleft" "clerk" "click" "cliff" "climb" "cling" "clink" "cloak" "clock" "clone"
.asciiz	"close" "cloth" "cloud" "clout" "clove" "clown" "cluck" "clued" "clump" "clung" "coach" "coast" "cobra"
.asciiz	"cocoa" "colon" "color" "comet" "comfy" "comic" "comma" "conch" "condo" "conic" "copse" "coral" "corer"
.asciiz	"corny" "couch" "cough" "could" "count" "coupe" "court" "coven" "cover" "covet" "covey" "cower" "coyly"
.asciiz	"crack" "craft" "cramp" "crane" "crank" "crash" "crass" "crate" "crave" "crawl" "craze" "crazy" "creak"
.asciiz	"cream" "credo" "creed" "creek" "creep" "creme" "crepe" "crept" "cress" "crest" "crick" "cried" "crier"
.asciiz	"crime" "crimp" "crisp" "croak" "crock" "crone" "crony" "crook" "cross" "croup" "crowd" "crown" "crude"
.asciiz	"cruel" "crumb" "crump" "crush" "crust" "crypt" "cubic" "cumin" "curio" "curly" "curry" "curse" "curve"
.asciiz	"curvy" "cutie" "cyber" "cycle" "cynic" "daddy" "daily" "dairy" "daisy" "dally" "dance" "dandy" "datum"
.asciiz	"daunt" "dealt" "death" "debar" "debit" "debug" "debut" "decal" "decay" "decor" "decoy" "decry" "defer"
.asciiz	"deign" "deity" "delay" "delta" "delve" "demon" "demur" "denim" "dense" "depot" "depth" "derby" "deter"
.asciiz	"detox" "deuce" "devil" "diary" "dicey" "digit" "dilly" "dimly" "diner" "dingo" "dingy" "diode" "dirge"
.asciiz	"dirty" "disco" "ditch" "ditto" "ditty" "diver" "dizzy" "dodge" "dodgy" "dogma" "doing" "dolly" "donor"
.asciiz	"donut" "dopey" "doubt" "dough" "dowdy" "dowel" "downy" "dowry" "dozen" "draft" "drain" "drake" "drama"
.asciiz	"drank" "drape" "drawl" "drawn" "dread" "dream" "dress" "dried" "drier" "drift" "drill" "drink" "drive"
.asciiz	"droit" "droll" "drone" "drool" "droop" "dross" "drove" "drown" "druid" "drunk" "dryer" "dryly" "duchy"
.asciiz	"dully" "dummy" "dumpy" "dunce" "dusky" "dusty" "dutch" "duvet" "dwarf" "dwell" "dwelt" "dying" "eager"
.asciiz	"eagle" "early" "earth" "easel" "eaten" "eater" "ebony" "eclat" "edict" "edify" "eerie" "egret" "eight"
.asciiz	"eject" "eking" "elate" "elbow" "elder" "elect" "elegy" "elfin" "elide" "elite" "elope" "elude" "email"
.asciiz	"embed" "ember" "emcee" "empty" "enact" "endow" "enema" "enemy" "enjoy" "ennui" "ensue" "enter" "entry"
.asciiz	"envoy" "epoch" "epoxy" "equal" "equip" "erase" "erect" "erode" "error" "erupt" "essay" "ester" "ether"
.asciiz	"ethic" "ethos" "etude" "evade" "event" "every" "evict" "evoke" "exact" "exalt" "excel" "exert" "exile"
.asciiz	"exist" "expel" "extol" "extra" "exult" "eying" "fable" "facet" "faint" "fairy" "faith" "false" "fancy"
.asciiz	"fanny" "farce" "fatal" "fatty" "fault" "fauna" "favor" "feast" "fecal" "feign" "fella" "felon" "femme"
.asciiz	"femur" "fence" "feral" "ferry" "fetal" "fetch" "fetid" "fetus" "fever" "fewer" "fiber" "fibre" "ficus"
.asciiz	"field" "fiend" "fiery" "fifth" "fifty" "fight" "filer" "filet" "filly" "filmy" "filth" "final" "finch"
.asciiz	"finer" "first" "fishy" "fixer" "fizzy" "fjord" "flack" "flail" "flair" "flake" "flaky" "flame" "flank"
.asciiz	"flare" "flash" "flask" "fleck" "fleet" "flesh" "flick" "flier" "fling" "flint" "flirt" "float" "flock"
.asciiz	"flood" "floor" "flora" "floss" "flour" "flout" "flown" "fluff" "fluid" "fluke" "flume" "flung" "flunk"
.asciiz	"flush" "flute" "flyer" "foamy" "focal" "focus" "foggy" "foist" "folio" "folly" "foray" "force" "forge"
.asciiz	"forgo" "forte" "forth" "forty" "forum" "found" "foyer" "frail" "frame" "frank" "fraud" "freak" "freed"
.asciiz	"freer" "fresh" "friar" "fried" "frill" "frisk" "fritz" "frock" "frond" "front" "frost" "froth" "frown"
.asciiz	"froze" "fruit" "fudge" "fugue" "fully" "fungi" "funky" "funny" "furor" "furry" "fussy" "fuzzy" "gaffe"
.asciiz	"gaily" "gamer" "gamma" "gamut" "gassy" "gaudy" "gauge" "gaunt" "gauze" "gavel" "gawky" "gayer" "gayly"
.asciiz	"gazer" "gecko" "geeky" "geese" "genie" "genre" "ghost" "ghoul" "giant" "giddy" "gipsy" "girly" "girth"
.asciiz	"given" "giver" "glade" "gland" "glare" "glass" "glaze" "gleam" "glean" "glide" "glint" "gloat" "globe"
.asciiz	"gloom" "glory" "gloss" "glove" "glyph" "gnash" "gnome" "godly" "going" "golem" "golly" "gonad" "goner"
.asciiz	"goody" "gooey" "goofy" "goose" "gorge" "gouge" "gourd" "grace" "grade" "graft" "grail" "grain" "grand"
.asciiz	"grant" "grape" "graph" "grasp" "grass" "grate" "grave" "gravy" "graze" "great" "greed" "green" "greet"
.asciiz	"grief" "grill" "grime" "grimy" "grind" "gripe" "groan" "groin" "groom" "grope" "gross" "group" "grout"
.asciiz	"grove" "growl" "grown" "gruel" "gruff" "grunt" "guard" "guava" "guess" "guest" "guide" "guild" "guile"
.asciiz	"guilt" "guise" "gulch" "gully" "gumbo" "gummy" "guppy" "gusto" "gusty" "gypsy" "habit" "hairy" "halve"
.asciiz	"handy" "happy" "hardy" "harem" "harpy" "harry" "harsh" "haste" "hasty" "hatch" "hater" "haunt" "haute"
.asciiz	"haven" "havoc" "hazel" "heady" "heard" "heart" "heath" "heave" "heavy" "hedge" "hefty" "heist" "helix"
.asciiz	"hello" "hence" "heron" "hilly" "hinge" "hippo" "hippy" "hitch" "hoard" "hobby" "hoist" "holly" "homer"
.asciiz	"honey" "honor" "horde" "horny" "horse" "hotel" "hotly" "hound" "house" "hovel" "hover" "howdy" "human"
.asciiz	"humid" "humor" "humph" "humus" "hunch" "hunky" "hurry" "husky" "hussy" "hutch" "hydro" "hyena" "hymen"
.asciiz	"hyper" "icily" "icing" "ideal" "idiom" "idiot" "idler" "idyll" "igloo" "iliac" "image" "imbue" "impel"
.asciiz	"imply" "inane" "inbox" "incur" "index" "inept" "inert" "infer" "ingot" "inlay" "inlet" "inner" "input"
.asciiz	"inter" "intro" "ionic" "irate" "irony" "islet" "issue" "itchy" "ivory" "jaunt" "jazzy" "jelly" "jerky"
.asciiz	"jetty" "jewel" "jiffy" "joint" "joist" "joker" "jolly" "joust" "judge" "juice" "juicy" "jumbo" "jumpy"
.asciiz	"junta" "junto" "juror" "kappa" "karma" "kayak" "kebab" "khaki" "kinky" "kiosk" "kitty" "knack" "knave"
.asciiz	"knead" "kneed" "kneel" "knelt" "knife" "knock" "knoll" "known" "koala" "krill" "label" "labor" "laden"
.asciiz	"ladle" "lager" "lance" "lanky" "lapel" "lapse" "large" "larva" "lasso" "latch" "later" "lathe" "latte"
.asciiz	"laugh" "layer" "leach" "leafy" "leaky" "leant" "leapt" "learn" "lease" "leash" "least" "leave" "ledge"
.asciiz	"leech" "leery" "lefty" "legal" "leggy" "lemon" "lemur" "leper" "level" "lever" "libel" "liege" "light"
.asciiz	"liken" "lilac" "limbo" "limit" "linen" "liner" "lingo" "lipid" "lithe" "liver" "livid" "llama" "loamy"
.asciiz	"loath" "lobby" "local" "locus" "lodge" "lofty" "logic" "login" "loopy" "loose" "lorry" "loser" "louse"
.asciiz	"lousy" "lover" "lower" "lowly" "loyal" "lucid" "lucky" "lumen" "lumpy" "lunar" "lunch" "lunge" "lupus"
.asciiz	"lurch" "lurid" "lusty" "lying" "lymph" "lynch" "lyric" "macaw" "macho" "macro" "madam" "madly" "mafia"
.asciiz	"magic" "magma" "maize" "major" "maker" "mambo" "mamma" "mammy" "manga" "mange" "mango" "mangy" "mania"
.asciiz	"manic" "manly" "manor" "maple" "march" "marry" "marsh" "mason" "masse" "match" "matey" "mauve" "maxim"
.asciiz	"maybe" "mayor" "mealy" "meant" "meaty" "mecca" "medal" "media" "medic" "melee" "melon" "mercy" "merge"
.asciiz	"merit" "merry" "metal" "meter" "metro" "micro" "midge" "midst" "might" "milky" "mimic" "mince" "miner"
.asciiz	"minim" "minor" "minty" "minus" "mirth" "miser" "missy" "mocha" "modal" "model" "modem" "mogul" "moist"
.asciiz	"molar" "moldy" "money" "month" "moody" "moose" "moral" "moron" "morph" "mossy" "motel" "motif" "motor"
.asciiz	"motto" "moult" "mound" "mount" "mourn" "mouse" "mouth" "mover" "movie" "mower" "mucky" "mucus" "muddy"
.asciiz	"mulch" "mummy" "munch" "mural" "murky" "mushy" "music" "musky" "musty" "myrrh" "nadir" "naive" "nanny"
.asciiz	"nasal" "nasty" "natal" "naval" "navel" "needy" "neigh" "nerdy" "nerve" "never" "newer" "newly" "nicer"
.asciiz	"niche" "niece" "night" "ninja" "ninny" "ninth" "noble" "nobly" "noise" "noisy" "nomad" "noose" "north"
.asciiz	"nosey" "notch" "novel" "nudge" "nurse" "nutty" "nylon" "nymph" "oaken" "obese" "occur" "ocean" "octal"
.asciiz	"octet" "odder" "oddly" "offal" "offer" "often" "olden" "older" "olive" "ombre" "omega" "onion" "onset"
.asciiz	"opera" "opine" "opium" "optic" "orbit" "order" "organ" "other" "otter" "ought" "ounce" "outdo" "outer"
.asciiz "outgo" "ovary" "ovate" "overt" "ovine" "ovoid" "owing" "owner" "oxide" "ozone" "paddy" "pagan" "paint"
.asciiz "paler" "palsy" "panel" "panic" "pansy" "papal" "paper" "parer" "parka" "parry" "parse" "party" "pasta"
.asciiz "paste" "pasty" "patch" "patio" "patsy" "patty" "pause" "payee" "payer" "peace" "peach" "pearl" "pecan"
.asciiz "pedal" "penal" "pence" "penne" "penny" "perch" "peril" "perky" "pesky" "pesto" "petal" "petty" "phase"
.asciiz "phone" "phony" "photo" "piano" "picky" "piece" "piety" "piggy" "pilot" "pinch" "piney" "pinky" "pinto"
.asciiz "piper" "pique" "pitch" "pithy" "pivot" "pixel" "pixie" "pizza" "place" "plaid" "plain" "plait" "plane"
.asciiz "plank" "plant" "plate" "plaza" "plead" "pleat" "plied" "plier" "pluck" "plumb" "plume" "plump" "plunk"
.asciiz "plush" "poesy" "point" "poise" "poker" "polar" "polka" "polyp" "pooch" "poppy" "porch" "poser" "posit"
.asciiz "posse" "pouch" "pound" "pouty" "power" "prank" "prawn" "preen" "press" "price" "prick" "pride" "pried"
.asciiz "prime" "primo" "print" "prior" "prism" "privy" "prize" "probe" "prone" "prong" "proof" "prose" "proud"
.asciiz "prove" "prowl" "proxy" "prude" "prune" "psalm" "pubic" "pudgy" "puffy" "pulpy" "pulse" "punch" "pupal"
.asciiz "pupil" "puppy" "puree" "purer" "purge" "purse" "pushy" "putty" "pygmy" "quack" "quail" "quake" "qualm"
.asciiz "quark" "quart" "quash" "quasi" "queen" "queer" "quell" "query" "quest" "queue" "quick" "quiet" "quill"
.asciiz "quilt" "quirk" "quite" "quota" "quote" "quoth" "rabbi" "rabid" "racer" "radar" "radii" "radio" "rainy"
.asciiz "raise" "rajah" "rally" "ralph" "ramen" "ranch" "randy" "range" "rapid" "rarer" "raspy" "ratio" "ratty"
.asciiz "raven" "rayon" "razor" "reach" "react" "ready" "realm" "rearm" "rebar" "rebel" "rebus" "rebut" "recap"
.asciiz "recur" "recut" "reedy" "refer" "refit" "regal" "rehab" "reign" "relax" "relay" "relic" "remit" "renal"
.asciiz "renew" "repay" "repel" "reply" "rerun" "reset" "resin" "retch" "retro" "retry" "reuse" "revel" "revue"
.asciiz "rhino" "rhyme" "rider" "ridge" "rifle" "right" "rigid" "rigor" "rinse" "ripen" "riper" "risen" "riser"
.asciiz "risky" "rival" "river" "rivet" "roach" "roast" "robin" "robot" "rocky" "rodeo" "roger" "rogue" "roomy"
.asciiz "roost" "rotor" "rouge" "rough" "round" "rouse" "route" "rover" "rowdy" "rower" "royal" "ruddy" "ruder"
.asciiz "rugby" "ruler" "rumba" "rumor" "rupee" "rural" "rusty" "sadly" "safer" "saint" "salad" "sally" "salon"
.asciiz "salsa" "salty" "salve" "salvo" "sandy" "saner" "sappy" "sassy" "satin" "satyr" "sauce" "saucy" "sauna"
.asciiz "saute" "savor" "savoy" "savvy" "scald" "scale" "scalp" "scaly" "scamp" "scant" "scare" "scarf" "scary"
.asciiz "scene" "scent" "scion" "scoff" "scold" "scone" "scoop" "scope" "score" "scorn" "scour" "scout" "scowl"
.asciiz "scram" "scrap" "scree" "screw" "scrub" "scrum" "scuba" "sedan" "seedy" "segue" "seize" "semen" "sense"
.asciiz "sepia" "serif" "serum" "serve" "setup" "seven" "sever" "sewer" "shack" "shade" "shady" "shaft" "shake"
.asciiz "shaky" "shale" "shall" "shalt" "shame" "shank" "shape" "shard" "share" "shark" "sharp" "shave" "shawl"
.asciiz "shear" "sheen" "sheep" "sheer" "sheet" "sheik" "shelf" "shell" "shied" "shift" "shine" "shiny" "shire"
.asciiz "shirk" "shirt" "shoal" "shock" "shone" "shook" "shoot" "shore" "shorn" "short" "shout" "shove" "shown"
.asciiz "showy" "shrew" "shrub" "shrug" "shuck" "shunt" "shush" "shyly" "siege" "sieve" "sight" "sigma" "silky"
.asciiz "silly" "since" "sinew" "singe" "siren" "sissy" "sixth" "sixty" "skate" "skier" "skiff" "skill" "skimp"
.asciiz "skirt" "skulk" "skull" "skunk" "slack" "slain" "slang" "slant" "slash" "slate" "slave" "sleek" "sleep"
.asciiz "sleet" "slept" "slice" "slick" "slide" "slime" "slimy" "sling" "slink" "sloop" "slope" "slosh" "sloth"
.asciiz "slump" "slung" "slunk" "slurp" "slush" "slyly" "smack" "small" "smart" "smash" "smear" "smell" "smelt"
.asciiz "smile" "smirk" "smite" "smith" "smock" "smoke" "smoky" "smote" "snack" "snail" "snake" "snaky" "snare"
.asciiz "snarl" "sneak" "sneer" "snide" "sniff" "snipe" "snoop" "snore" "snort" "snout" "snowy" "snuck" "snuff"
.asciiz "soapy" "sober" "soggy" "solar" "solid" "solve" "sonar" "sonic" "sooth" "sooty" "sorry" "sound" "south"
.asciiz "sower" "space" "spade" "spank" "spare" "spark" "spasm" "spawn" "speak" "spear" "speck" "speed" "spell"
.asciiz "spelt" "spend" "spent" "sperm" "spice" "spicy" "spied" "spiel" "spike" "spiky" "spill" "spilt" "spine"
.asciiz "spiny" "spire" "spite" "splat" "split" "spoil" "spoke" "spoof" "spook" "spool" "spoon" "spore" "sport"
.asciiz "spout" "spray" "spree" "sprig" "spunk" "spurn" "spurt" "squad" "squat" "squib" "stack" "staff" "stage"
.asciiz "staid" "stain" "stair" "stake" "stale" "stalk" "stall" "stamp" "stand" "stank" "stare" "stark" "start"
.asciiz "stash" "state" "stave" "stead" "steak" "steal" "steam" "steed" "steel" "steep" "steer" "stein" "stern"
.asciiz "stick" "stiff" "still" "stilt" "sting" "stink" "stint" "stock" "stoic" "stoke" "stole" "stomp" "stone"
.asciiz "stony" "stood" "stool" "stoop" "store" "stork" "storm" "story" "stout" "stove" "strap" "straw" "stray"
.asciiz "strip" "strut" "stuck" "study" "stuff" "stump" "stung" "stunk" "stunt" "style" "suave" "sugar" "suing"
.asciiz "suite" "sulky" "sully" "sumac" "sunny" "super" "surer" "surge" "surly" "sushi" "swami" "swamp" "swarm"
.asciiz "swash" "swath" "swear" "sweat" "sweep" "sweet" "swell" "swept" "swift" "swill" "swine" "swing" "swirl"
.asciiz "swish" "swoon" "swoop" "sword" "swore" "sworn" "swung" "synod" "syrup" "tabby" "table" "taboo" "tacit"
.asciiz "tacky" "taffy" "taint" "taken" "taker" "tally" "talon" "tamer" "tango" "tangy" "taper" "tapir" "tardy"
.asciiz "tarot" "taste" "tasty" "tatty" "taunt" "tawny" "teach" "teary" "tease" "teddy" "teeth" "tempo" "tenet"
.asciiz "tenor" "tense" "tenth" "tepee" "tepid" "terra" "terse" "testy" "thank" "theft" "their" "theme" "there"
.asciiz "these" "theta" "thick" "thief" "thigh" "thing" "think" "third" "thong" "thorn" "those" "three" "threw"
.asciiz "throb" "throw" "thrum" "thumb" "thump" "thyme" "tiara" "tibia" "tidal" "tiger" "tight" "tilde" "timer"
.asciiz "timid" "tipsy" "titan" "tithe" "title" "toast" "today" "toddy" "token" "tonal" "tonga" "tonic" "tooth"
.asciiz "topaz" "topic" "torch" "torso" "torus" "total" "totem" "touch" "tough" "towel" "tower" "toxic" "toxin"
.asciiz "trace" "track" "tract" "trade" "trail" "train" "trait" "tramp" "trash" "trawl" "tread" "treat" "trend"
.asciiz "triad" "trial" "tribe" "trice" "trick" "tried" "tripe" "trite" "troll" "troop" "trope" "trout" "trove"
.asciiz "truce" "truck" "truer" "truly" "trump" "trunk" "truss" "trust" "truth" "tryst" "tubal" "tuber" "tulip"
.asciiz "tulle" "tumor" "tunic" "turbo" "tutor" "twang" "tweak" "tweed" "tweet" "twice" "twine" "twirl" "twist"
.asciiz "twixt" "tying" "udder" "ulcer" "ultra" "umbra" "uncle" "uncut" "under" "undid" "undue" "unfed" "unfit"
.asciiz "unify" "union" "unite" "unity" "unlit" "unmet" "unset" "untie" "until" "unwed" "unzip" "upper" "upset"
.asciiz "urban" "urine" "usage" "usher" "using" "usual" "usurp" "utile" "utter" "vague" "valet" "valid" "valor"
.asciiz "value" "valve" "vapid" "vapor" "vault" "vaunt" "vegan" "venom" "venue" "verge" "verse" "verso" "verve"
.asciiz "vicar" "video" "vigil" "vigor" "villa" "vinyl" "viola" "viper" "viral" "virus" "visit" "visor" "vista"
.asciiz "vital" "vivid" "vixen" "vocal" "vodka" "vogue" "voice" "voila" "vomit" "voter" "vouch" "vowel" "vying"
.asciiz "wacky" "wafer" "wager" "wagon" "waist" "waive" "waltz" "warty" "waste" "watch" "water" "waver" "waxen"
.asciiz "weary" "weave" "wedge" "weedy" "weigh" "weird" "welch" "welsh" "wench" "whack" "whale" "wharf" "wheat"
.asciiz "wheel" "whelp" "where" "which" "whiff" "while" "whine" "whiny" "whirl" "whisk" "white" "whole" "whoop"
.asciiz "whose" "widen" "wider" "widow" "width" "wield" "wight" "willy" "wimpy" "wince" "winch" "windy" "wiser"
.asciiz "wispy" "witch" "witty" "woken" "woman" "women" "woody" "wooer" "wooly" "woozy" "wordy" "world" "worry"
.asciiz "worse" "worst" "worth" "would" "wound" "woven" "wrack" "wrath" "wreak" "wreck" "wrest" "wring" "wrist"
.asciiz "write" "wrong" "wrote" "wrung" "wryly" "yacht" "yearn" "yeast" "yield" "young" "youth" "zebra" "zesty" "zonal"
