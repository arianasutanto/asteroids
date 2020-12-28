.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Rocks
# =================================================================================================

.globl rocks_count
rocks_count:
enter
	la t0, objects
	li t1, 0
	li v0, 0

	_rocks_count_loop:
		lw t2, Object_type(t0)
		beq t2, TYPE_ROCK_L, _rocks_count_yes
		beq t2, TYPE_ROCK_M, _rocks_count_yes
		bne t2, TYPE_ROCK_S, _rocks_count_continue
		_rocks_count_yes:
			inc v0
	_rocks_count_continue:
	add t0, t0, Object_sizeof
	inc t1
	blt t1, MAX_OBJECTS, _rocks_count_loop
leave

# ------------------------------------------------------------------------------

# void rocks_init(int num_rocks)
.globl rocks_init
rocks_init:
enter s0 s1
move s0, a0
li  s1, 0
_rocks_loop:
	bge s1, s0, _exit_rocks_init
	#x coordinate
	li a0, 0x2000
	jal random
	add v0, v0, 0x3000
	rem t1, v0, 0x4000

	#y coordinate
	li a0, 0x5000
	jal random
	add v0, v0, 0x4000
	rem t2, v0, 0x3000


	move a0, t1
	move a1, t2
	li a2, TYPE_ROCK_L
	jal rock_new

	add s1, s1, 1
	j  _rocks_loop
_exit_rocks_init:

leave s0 s1

# ------------------------------------------------------------------------------

# void rock_new(x, y, type)
rock_new:
enter s0 s1 s2 s4

move s0, a0
move s1, a1
move s2, a2

move a0, a2
jal Object_new

beq v0, 0, _exit_rock_new

move s4, v0

sw s0, Object_x(s4)
sw s1, Object_y(s4)

li t2, TYPE_ROCK_L
li t3, TYPE_ROCK_M
li t4, TYPE_ROCK_S

bne a2, t2, _check_rock_m #branch if the type is not rock l

	li t0, ROCK_L_HW
	li t1, ROCK_L_HH

	sw t0, Object_hw(s4)
	sw t1, Object_hh(s4)

	li a0, 360
	jal random

	li a0, ROCK_VEL
	move a1, v0
	jal to_cartesian

	sw v0, Object_vx(s4)
	sw v1, Object_vy(s4)

	j _exit_rock_new

_check_rock_m:
bne a2, t3, _check_rock_s
	li t0, ROCK_M_HW
	li t1, ROCK_M_HH

	sw t0, Object_hw(s4)
	sw t1, Object_hh(s4)

	li a0, 360
	jal random

	li t5, ROCK_VEL
	mul t6, t5, 4

	move a0, t6
	move a1, v0
	jal to_cartesian

	sw v0 , Object_vx(s4)
	sw v1, Object_vy(s4)

	j _exit_rock_new

_check_rock_s:
bne a2, t4, _exit_rock_new
	li t0, ROCK_S_HH
	li t1, ROCK_S_HW

	sw t0, Object_hw(s4)
	sw t1, Object_hh(s4)

	li a0, 360
	jal random

	li t7, ROCK_VEL
	mul t8, t7, 12

	move a0, t8
	move a1, v0
	jal to_cartesian

	sw v0 , Object_vx(s4)
	sw v1, Object_vy(s4)


_exit_rock_new:
leave s0 s1 s2 s4


# ------------------------------------------------------------------------------

.globl rock_update
rock_update:
enter

jal Object_accumulate_velocity
jal Object_wrap_position
jal rock_collide_with_bullets


leave

# ------------------------------------------------------------------------------

rock_collide_with_bullets:
enter s0, s1, s2
	la s0, objects
	li s1, 0
  li t1, TYPE_BULLET
	move s2, a0


	_rock_collide_with_bullets_loop:
		lw t0, Object_type(s0)
		bne t0, t1, _rock_collide_incr
		move a0, s2
		lw  a1, Object_x(s0)
		lw  a2, Object_y(s0)
		jal Object_contains_point
		beq v0, 0, _rock_collide_incr
		move a0, s2
		jal rock_get_hit
		move a0, s0
		jal Object_delete
		j _exit_rock_collide_bullets


		_rock_collide_incr:
		add s0, s0, Object_sizeof
		inc s1
		blt s1, MAX_OBJECTS, _rock_collide_with_bullets_loop

_exit_rock_collide_bullets:
leave s0 s1 s2

# ------------------------------------------------------------------------------

rock_get_hit:
enter s0
move s0, a0 #rock
lw t0, Object_type(s0)
beq t0, TYPE_ROCK_L, _case_large_rock
beq t0, TYPE_ROCK_M, _case_medium_rock
beq t0, TYPE_ROCK_S, _case_small_rock
j _delete_rock

_case_large_rock:
lw a0, Object_x(s0)
lw a1, Object_y(s0)
li a2, TYPE_ROCK_M
jal rock_new
lw a0, Object_x(s0)
lw a1, Object_y(s0)
li a2, TYPE_ROCK_M
jal rock_new

j _delete_rock

_case_medium_rock:
lw a0, Object_x(s0)
lw a1, Object_y(s0)
li a2, TYPE_ROCK_S
jal rock_new
lw a0, Object_x(s0)
lw a1, Object_y(s0)
li a2, TYPE_ROCK_S
jal rock_new


j _delete_rock

_case_small_rock:


_delete_rock:

lw a0, Object_x(s0)
lw a1, Object_y(s0)
jal explosion_new

move a0, s0
jal Object_delete
leave s0


# ------------------------------------------------------------------------------

.globl rock_collide_l
rock_collide_l:
enter
jal rock_get_hit
li a0, 3
jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_m
rock_collide_m:
enter
jal rock_get_hit
li a0, 2
jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_s
rock_collide_s:
enter
jal rock_get_hit
li a0, 1
jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_draw_l
rock_draw_l:
enter

la a1, spr_rock_l

jal Object_blit_5x5_trans

leave

# ------------------------------------------------------------------------------

.globl rock_draw_m
rock_draw_m:
enter

la a1, spr_rock_m

jal Object_blit_5x5_trans

leave

# ------------------------------------------------------------------------------

.globl rock_draw_s
rock_draw_s:
enter

la a1, spr_rock_s

jal Object_blit_5x5_trans

leave
