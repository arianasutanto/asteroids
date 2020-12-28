.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Bullet
# =================================================================================================

# void bullet_new(x: a0, y: a1, angle: a2)
.globl bullet_new
bullet_new:
enter s0 s1 s2 s4

move s0, a0
move s1, a1
move s2, a2



li a0, TYPE_BULLET
jal Object_new

move s4, v0

li t0, BULLET_LIFE
sw t0, Bullet_frame(s4)

beq v0, 0,  _exit_bullet_new

sw s0, Object_x(v0) #obj.y=y
sw s1, Object_y(v0) #obj.x = x

li a0, BULLET_THRUST
move a1, s2
jal to_cartesian

sw v0 , Object_vx(s4)
sw v1, Object_vy(s4)


_exit_bullet_new:
leave s0 s1 s2 s4


# -----------------------------------------------------------------------------

.globl bullet_update
bullet_update:
enter

lw t0, Bullet_frame(a0)
sub t0, t0, 1
sw t0, Bullet_frame(a0)


bne t0, 0, _not_zero
  jal Object_delete
  j _exit_bullet_update

_not_zero:
jal Object_accumulate_velocity

jal Object_wrap_position


_exit_bullet_update:
leave

# ------------------------------------------------------------------------------

.globl bullet_draw
bullet_draw:
enter



lw t1, Object_x(a0)
lw t2, Object_y(a0)

sra t3, t1, 8
sra t4, t2, 8

move a0, t3
move a1, t4
li a2, COLOR_RED

jal display_set_pixel

leave
