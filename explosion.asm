.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Explosions
# =================================================================================================

# void explosion_new(x, y)
.globl explosion_new
explosion_new:
enter s0 s1 s2

move s0, a0
move s1, a1

li a0, TYPE_EXPLOSION
jal Object_new

move s2, v0 # object is in s0

sw s0, Object_x(s2)
sw s1, Object_y(s2)

li t0, EXPLOSION_HH
li t1, EXPLOSION_HW

sw t0, Object_hh(s2)
sw t1, Object_hw(s2)

li t3, EXPLOSION_ANIM_DELAY
sw t3, Explosion_timer(s2)

li t5, 0
sw t5, Explosion_frame(s2)

_leave1:
leave s0 s1 s2

# ------------------------------------------------------------------------------

.globl explosion_update
explosion_update:
enter s0

move s0, a0

lw t0, Explosion_timer(s0)
lw t2, Explosion_frame(s0)

sub t0, t0, 1
sw t0, Explosion_timer(s0)

bne t0, 0, _incr_explo_frame
  li t1, EXPLOSION_ANIM_DELAY
  sw t1, Explosion_timer(s0)

_incr_explo_frame:
add t2, t2, 1
sw t2, Explosion_frame(s0)

blt t2, 6, _exit_explosion_update
jal Object_delete

_exit_explosion_update:
leave s0
# ------------------------------------------------------------------------------


.globl explosion_draw
explosion_draw:
enter s0

move s0, a0

la t0, spr_explosion_frames
lw t1, Explosion_frame(s0)
mul t2, t1, 4  #t1 now has Bi
add t0, t0, t2
lw a1, (t0)

jal Object_blit_5x5_trans


leave s0
