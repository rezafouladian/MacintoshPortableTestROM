TROMCode        EQU $55AAAA55           ; Test ROM constant
ROMBase         EQU $D00000
DebugOutput     EQU $C00000             ; Serial debug interface
BacklightType   EQU $FC0200
DebugROMVer     EQU $00

    org     $00000                      ; Start ROM at $0, translated to $D00000 by select logic

    ; A1 = return address from system ROM

ROMEntryA:
    move.b  #$00,DebugOutput            ; Message $00: "Starting from cold boot"
    bra     StartCode
ROMEntryB:
    move.b  #$01,DebugOutput            ; Message $01: "Resuming from sleep passed startup tests"
StartCode:
    move.b  #$02,DebugOutput            ; Message $02: Display greeting
    move.b  #DebugROMVer,DebugOutput    ; Greeting is immediately followed by ROM version
    ; Check which model we are on by checking the backlight value
DetectPortable:
    cmpi.b  #$A3,BacklightType          ; Check for upgraded Portable
    beq     .UpgradeFound
    cmpi.b  #$A5,BacklightType          ; Check for backlit Portable
    beq     .BacklitFound
    cmpi.b  #$AD,BacklightType          ; Check for Powerbook 100
    beq     .PB100Found
    bra.s   .RegularPortable            ; Nothing found, must be a regular Portable
.UpgradeFound:
    move.b  #$03,DebugOutput            ; Message #$03: "Found a Portable (M5120) with backlight upgrade card"
    bra.s   .Done                       
.BacklitFound:
    move.b  #$04,DebugOutput            ; Message #$04: "Found a Backlit Portable (M5126)"
    bra.s   .Done
.PB100Found:
    move.b  #$05,DebugOutput            ; Message #$05: "Found a Powerbook 100"
    bra.s   .Done
.RegularPortable:
    move.b  #$06,DebugOutput            ; Message #$06: "No backlight found, assuming Portable (M5120)"


EntryVectors:
    org     $80000                      ; Place at $80000, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80000
    dc.l    ROMEntryA                   ; Provide code to execute from
    org     $80080                      ; Place at #80080, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80080
    dc.l    ROMEntryB                   ; Provide code to execute from