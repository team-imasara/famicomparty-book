NUM_ENEMIES = 5

.importzp enemy_x_pos, enemy_y_pos
.importzp enemy_x_vels, enemy_y_vels
.importzp enemy_flags, current_enemy, current_enemy_type
.importzp enemy_timer

.export update_enemy
.proc update_enemy
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Check if this enemy is active.
  LDX current_enemy
  LDA enemy_flags,X
  AND #%10000000
  BEQ done

  ; Update Y position.
  LDA enemy_y_pos,X
  CLC
  ADC enemy_y_vels,X
  STA enemy_y_pos,X

  ; Set inactive if Y >= 239
  CMP #239
  BCC done
  LDA enemy_flags,X
  EOR #%10000000
  STA enemy_flags,X

done:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.export process_enemies
.proc process_enemies
  ; Push registers onto the stack
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Start with enemy zero.
  LDX #$00

enemy:
	STX current_enemy
  LDA enemy_flags,X
  ; Check if active (bit 7 set)
  AND #%10000000
  BEQ spawn_or_timer
  ; If we get here, the enemy is active,
  ; so call update_enemy
  JSR update_enemy
  ; Then, get ready for the next loop.
  JMP prep_next_loop
spawn_or_timer:
  ; Start a timer if it is not already running.
  LDA enemy_timer
  BEQ spawn_enemy ; If zero, time to spawn
  CMP #20 ; Otherwise, see if it's running
  ; If carry is set, enemy_timer > 20
  BCC prep_next_loop

  LDA #20
  STA enemy_timer
	JMP prep_next_loop
spawn_enemy:
  ; Set this slot as active
  ; (set bit 7 to "1")
  LDA enemy_flags,X
  ORA #%10000000
  STA enemy_flags,X
  ; Set y position to zero
  LDA #$00
  STA enemy_y_pos,X
  ; IMPORTANT: reset the timer!
  LDA #$ff
  STA enemy_timer

prep_next_loop:
  INX
  CPX #NUM_ENEMIES
  BNE enemy

  ; Done with all enemies. Decrement
  ; enemy spawn timer if 20 or less
  ; (and not zero)
  LDA enemy_timer
  BEQ done
  CMP #20
	BEQ decrement
  BCS done
decrement:
  DEC enemy_timer

done:
  ; Restore registers, then return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP

  RTS
.endproc

.export draw_enemy
.proc draw_enemy
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; First, check if the enemy is active.
	LDX current_enemy
	LDA enemy_flags,X
  AND #%10000000
	BNE continue
	JMP done

continue:
  ; Find the appropriate OAM address offset
  ; by starting at $0210 (after the player
  ; sprites) and adding $10 for each enemy
  ; until we hit the current index.
  LDA #$10
  LDX current_enemy
  BEQ oam_address_found
find_address:
  CLC
  ADC #$10
  DEX
  BNE find_address

oam_address_found:
  LDX current_enemy
  TAY ; use Y to hold OAM address offset

  ; Find the current enemy's type and
  ; store it for later use. The enemy type
  ; is in bits 0-2 of enemy_flags.
  LDA enemy_flags,X
  AND #%00000111
  STA current_enemy_type

  ; enemy top-left
  LDA enemy_y_pos,X
  STA $0200,Y
  INY
  LDX current_enemy_type
  LDA enemy_top_lefts,X
  STA $0200,Y
  INY
  LDA enemy_palettes,X
  STA $0200,Y
  INY
  LDX current_enemy
  LDA enemy_x_pos,X
  STA $0200,Y
  INY

  ; enemy top-right
  LDA enemy_y_pos,X
  STA $0200,Y
  INY
  LDX current_enemy_type
  LDA enemy_top_rights,X
  STA $0200,Y
  INY
  LDA enemy_palettes,X
  STA $0200,Y
  INY
  LDX current_enemy
  LDA enemy_x_pos,X
  CLC
  ADC #$08
  STA $0200,Y
  INY

  ; enemy bottom-left
  LDA enemy_y_pos,X
  CLC
  ADC #$08
  STA $0200,Y
  INY
  LDX current_enemy_type
  LDA enemy_bottom_lefts,X
  STA $0200,Y
  INY
  LDA enemy_palettes,X
  STA $0200,Y
  INY
  LDX current_enemy
  LDA enemy_x_pos,X
  STA $0200,Y
  INY

  ; enemy bottom-right
  LDA enemy_y_pos,X
  CLC
  ADC #$08
  STA $0200,Y
  INY
  LDX current_enemy_type
  LDA enemy_bottom_rights,X
  STA $0200,Y
  INY
  LDA enemy_palettes,X
  STA $0200,Y
  INY
  LDX current_enemy
  LDA enemy_x_pos,X
  CLC
  ADC #$08
  STA $0200,Y

done:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "RODATA"
enemy_top_lefts:
.byte $09, $0d
enemy_top_rights:
.byte $0b, $0e
enemy_bottom_lefts:
.byte $0a, $0f
enemy_bottom_rights:
.byte $0c, $10

enemy_palettes:
.byte $01, $02
