TROMCode        EQU $55AAAA55           ; Test ROM constant
ROMBase         EQU $D00000
DebugOutput     EQU $C00000             ; Serial debug interface
BacklightType   EQU $FC0200
ScreenBase      EQU $FA8000
DebugROMVer     EQU $00
MemFindConst    EQU $C0000000
MemFindStConst  EQU $A0000
IconOffset      EQU $3956

MsgCold         EQU $00                 ; Message $00: "Starting from cold boot"
MsgResume       EQU $01                 ; Message $01: "Resuming from sleep passed startup tests"
MsgGreeting     EQU $02                 ; Message $02: Display greeting


    org     $00000                      ; Start ROM at $0, translated to $D00000 by select logic

    ; A1 = return address from system ROM

ROMEntryA:
    move.b  #MsgCold,DebugOutput        ; Play cold boot message
    bra     StartCode
ROMEntryB:
    move.b  #MsgResume,DebugOutput      ; Starting from sleep
StartCode:
    move.b  #MsgGreeting,DebugOutput    ; Play greeting
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

    ; Basic RAM size check
RAMFind:
    move.l  #MemFindStConst,A0          ; Start testing at $0A0000
    move.b  #9-1,D1                     ; Setup loop counter to test all 9MB
.LoadTestValues:
    move.l  #MemFindConst+A0,(A0)
    add.l   #$100000,A0                 ; Go to the next MB of RAM
    dbf     D1,.LoadTestValues          ; Loop until finished
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
    add.l   #$100000,A0                 ; Move forward 1MB
    lsl.b   D2                          ; Shift bit
    dbf     D1,.CheckExpansionRAM       ; Loop until finished
    bra.s   .Done
.PermRAMFail:
    move.b  #$07,DebugOutput            ; Message #$07: "Error: Permanent RAM check test failed"
    bra.s   .LoopSetup
.RAMFail:
    andi.b  #%11111110,D2               ; Mark bit as failed to indicate MB
    bra.s   .ContinueLoop               ; Go back to the test loop
.Done:
    move.b  #$08,DebugOutput            ; Message #$08: RAM find results
    move.b  D2,DebugOutput              ; Output bits of detected RAM, lsb = 9MB

EarlyInit:
    move.b  #$09,DebugOutput            ; Message $09: Initial screen clearing
.ClearScreen:
    lea     .DrawInitIcon,A6
    jmp     BlackScreen
.DrawInitIcon:
    move.b  #$0A,DebugOutput            ; Message $0A: Drawing icon on screen
    lea     DiagIcon,A1                 ; Load address of the inital diag icon
    movea.l IconOffset,A0               ; Load offset to near center of screen
    lea     .PlayInitTone,A6
    jmp     DrawIcon
.PlayInitTone:
    move.b  #$0B,DebugOutput            ; Message $0B: Playing test tone




BlackScreen:
    moveq   #-1,D0                      ; We're going to fill the screen with FFFF FFFF
    move.w  #(32000/4)-1,D1             ; Setup loop for screen size
.ScreenLoop:
    move.l  D0,(A0)+                    ; Put data on the screen
    dbf     D1,.ScreenLoop              ; Loop until complete
    jmp     (A6)

; Draw a bitmap on the screen
;
; A0 = Offset where to draw the icon
; A1 = Icon to draw
DrawIcon:
    adda.l  ScreenBase,A0

    jmp     (A6)
DiagIcon:



EntryVectors:
    org     $80000                      ; Place at $80000, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80000
    dc.l    ROMEntryA                   ; Provide code to execute from
    org     $80080                      ; Place at #80080, translated to both $D80000 and $F80000,
    dc.l    TROMCode                    ; only meant to be read from $F80080
    dc.l    ROMEntryB                   ; Provide code to execute from