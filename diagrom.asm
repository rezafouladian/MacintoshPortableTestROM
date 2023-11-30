TROMCode        EQU $55AAAA55           ; Test ROM constant
ROMBase         EQU $D00000
DebugOutput     EQU $C00000             ; Serial debug interface
BacklightType   EQU $FC0200
DebugROMVer     EQU $00
MemFindConst    EQU $C0000000
MemFindStConst  EQU $A0000

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

    ; Basic RAM check
RAMFind:
    move.l  #MemFindStConst,A0          ; Start testing at $0A0000
    move.b  #9-1,D1                     ; Setup loop counter to test all 9MB
.LoadTestValues:
    move.l  #MemFindConst+A0,(A0)
    add.l   #$100000,A0
    dbf     D1,.LoadTestValues
.CheckValues:
    cmpi.l  #MemFindConst+MemFindStConst,MemFindStConst ; Check permanent RAM first
    bne.s   .PermRAMFail
.LoopSetup:
    move.l  #$100000+MemFindStConst,A0  ; Start afer permanent RAM
    move.b  #8-1,D1                     ; Setup loop counter to test 1MB-9MB
.CheckExpansionRAM:
    ori.b   #%00000001,D2               ; Assume good and change later
    cmpi.l  #MemFindConst+A0,(A0)
    bne.s   .RAMFail
.ContinueLoop:
    add.l   #$100000,A0
    lsr.b   D2                          ; Shift bit
    dbf     D1,.CheckExpansionRAM
    bra.s   .Done
.PermRAMFail:
    move.b  #$07,DebugOutput            ; Message #$07: "Error: Permanent RAM check test failed"
    bra.s   .LoopSetup
.RAMFail:
    andi.b  #%11111110,D2               ; Mark bit as failed to indicate MB
    bra.s   .ContinueLoop
.Done:
    move.b  #$08,DebugOutput            ; Message #$08: RAM find results
    move.b  D2,DebugOutput

EntryVectors:
    org     $80000                      ; Place at $80000, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80000
    dc.l    ROMEntryA                   ; Provide code to execute from
    org     $80080                      ; Place at #80080, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80080
    dc.l    ROMEntryB                   ; Provide code to execute from