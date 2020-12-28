.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Player
# =================================================================================================

.globl player_init
player_init:
enter
	# NOTE: this is unique to the player object. All other objects are made using
	# Object_new. it's just a special object.

	la t0, player
	# player.type = TYPE_PLAYER
	li t1, TYPE_PLAYER
	sw t1, Object_type(t0)

	# player.hw = PLAYER_HW, player.hh = PLAYER_HH
	li t1, PLAYER_HW
	sw t1, Object_hw(t0)
	li t1, PLAYER_HH
	sw t1, Object_hh(t0)

	# reset lives
	li t1, PLAYER_INIT_LIVES
	sw t1, player_lives

	# reset the rest
	jal player_respawn
leave

# ------------------------------------------------------------------------------
player_respawn:
enter
	la t0, player

	# player.x = player.y = 32.0
	li t1, 0x2000
	sw t1, Object_x(t0)
	sw t1, Object_y(t0)

	# player.vx = player.vy = 0
	sw zero, Object_vx(t0)
	sw zero, Object_vy(t0)

	# reset the other variables
	sw zero, player_iframes
	sw zero, player_fire_time
	sw zero, player_deadframes
	sw zero, player_angle
	sw zero, player_accel
	li t1, PLAYER_MAX_HEALTH
	sw t1, player_health
leave

# ------------------------------------------------------------------------------
.globl player_update
player_update:
enter


lw t0, player_fire_time
lw t1, player_iframes
lw t2, player_deadframes
lw t3, player_lives

ble t0, 0, _check_frame_timer
	sub t0, t0, 1
	sw t0, player_fire_time

_check_frame_timer:

ble t1, 0, _check_dead_frames
	sub t1, t1, 1
	sw t1, player_iframes
	j _continue_update

_check_dead_frames:
beq t2, 0, _continue_update
	sub t2, t2, 1
	sw t2, player_deadframes

bne t2, 0, _exit_player_update

ble t3, 0 , _lose_game
jal player_respawn
li t4, PLAYER_RESPAWN_IFRAMES
sw t4, player_iframes
j _continue_update

_lose_game:
jal lose_game
j _exit_player_update


_continue_update:
jal player_check_input

jal player_update_thrust

la a0, player
li a1, PLAYER_DRAG
jal Object_damp_velocity

la a0, player
jal Object_accumulate_velocity

la a0, player
jal Object_wrap_position


_exit_player_update:

leave

# ------------------------------------------------------------------------------
.globl player_draw
player_draw:
enter
	# don't draw the player if they're dead.
	lw   t0, player_deadframes
	bnez t0, _player_draw_return

	# if they're invulnerable, draw them 4 frames on, 4 frames off.
	lw   t0, player_iframes
	beqz t0, _player_draw_doit
	lw   t0, frame_counter
	and  t0, t0, 4
	beqz t0, _player_draw_return

	_player_draw_doit:
		# there are 16 different directions in the rotation animation.
		# this chooses which frame to use based on the player's angle (0 = up, 90 = right)
		# a1 = spr_player[((player_angle + 11) % 360) / 23]
		lw  t0, player_angle
		add t0, t0, 11
		blt t0, 360, _player_draw_a_nowrap
			sub t0, t0, 360
		_player_draw_a_nowrap:
		div t0, t0, 23
		sll t0, t0, 2
		la  a1, spr_player
		add a1, a1, t0
		lw  a1, (a1)
		jal Object_blit_5x5_trans

	_player_draw_return:
leave

# ------------------------------------------------------------------------------
.globl player_check_input
player_check_input:
enter

jal input_get_keys

and t1, v0, KEY_L
and t2, v0, KEY_R
and t3, v0, KEY_U
and t6, v0, KEY_B

# rotate left counterclockwise
beq	t1, 0, _clockwise 	# if  KEY_L= 0 then branch to _clockwise

lw t0, player_angle
sub t0 , t0, PLAYER_ANG_VEL
sw t0, player_angle

bge	t0, 0, _clockwise	# if player_angle < 0

add t0, t0, 360
sw t0, player_angle

# rotate right clockwise
_clockwise:

beq	t2, 0, _check_KEY_U 	# if  KEY_R= 0 then exit

lw t0, player_angle
add t0 , t0, PLAYER_ANG_VEL
sw t0, player_angle

blt	t0, 360, _check_KEY_U	# if player_angle > 0

sub t0, t0, 360
sw t0, player_angle

# check if up key pressed

_check_KEY_U:
beq t3, 0, _set_to_zero #if t3 is equal to 0 exit
li t4, 1
sw t4, player_accel
j _check_KEY_B

_set_to_zero:
li t5, 0
sw t5, player_accel

_check_KEY_B:

beq t6, 0, _exit #if B is not pressed exit / if t6 is equal to 0 exit
jal player_fire

_exit:
leave

# ------------------------------------------------------------------------------
.globl player_fire
player_fire:
enter

la t0, player
lw t1, player_fire_time

bne t1, 0, _exit_player_fire
	li t2, PLAYER_FIRE_DELAY
	sw t2, player_fire_time
	lw a0, Object_x(t0)
	lw a1, Object_y(t0)
	lw a2, player_angle
	jal bullet_new

_exit_player_fire:
leave

# ------------------------------------------------------------------------------
.globl player_update_thrust
player_update_thrust:
enter

lw t1, player_angle

lw t2, player_accel
beq t2, 0, _exit_two

li a0, PLAYER_THRUST
move a1, t1
jal to_cartesian

la a0, player
move a1, v0
move a2, v1
jal Object_apply_acceleration


_exit_two:

leave

# ------------------------------------------------------------------------------
# void player_damage(int dmg)
#   can be called by other objects (like rocks) to damage the player.
#   the argument is how many points of damage to do.
.globl player_damage
player_damage:
enter


lw t0, player_iframes
bne t0, 0, _exit_player_damage

	lw t1, player_health
	sub  t1, t1, a0
	maxi t1, t1, 0
	sw t1, player_health


bne t1, 0, _player_health_not_zero
	la t2, player
	lw a0, Object_x(t2)
	lw a1, Object_y(t2)
	jal explosion_new

	lw t1, player_lives
	sub t1, t1, 1
	maxi t1, t1, 0
	sw t1, player_lives
	li t4, PLAYER_RESPAWN_TIME
	sw t4, player_deadframes

_player_health_not_zero:
	li t2, PLAYER_HURT_IFRAMES
	sw t2, player_iframes


_exit_player_damage:

leave

# ------------------------------------------------------------------------------
# player_collide_all()
# checks if the player collides with anything.
# call the appropriate player-collision function on all active objects that have one.
.globl player_collide_all
player_collide_all:
enter s0, s1, s2
	# s0 = obj
	# s1 = i
	# s2 = collision function

	# start at objects[1]
	la s0, objects
	add s0, s0, Object_sizeof
	li s1, 1
_player_collide_all_loop:
		# don't collide if the player is invulnerable or dead.
		lw   t0, player_deadframes
		bnez t0, _player_collide_all_return
		lw   t0, player_iframes
		bnez t0, _player_collide_all_return

		# s2 = player_collide_funcs[obj.type]
		lw  s2, Object_type(s0)
		sll s2, s2, 2
		la  t0, player_collide_funcs
		add s2, s2, t0
		lw  s2, (s2)

		# skip objects without a collision function
		beq s2, 0, _player_collide_all_continue

		# if Objects_overlap(obj, player)
		move a0, s0
		la   a1, player
		jal  Objects_overlap
		beq  v0, 0, _player_collide_all_continue

			# OKAY, we hit the player
			# call the function (in s2) with the object as the argument
			move a0, s0
			jalr s2

_player_collide_all_continue:
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _player_collide_all_loop

_player_collide_all_return:
leave s0, s1, s2
