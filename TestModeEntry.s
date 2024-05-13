VIA_Base        EQU     $F70000
VIA_DDR_B       EQU     $F70400
VIA_ACR         EQU     $F71600
VIA_IER         EQU     $F71C00
VIA_T2L         EQU     $F71000
VIA_T2H         EQU     $F71200
Sound_Base      EQU     $FB0000
Video_Base      EQU     $FA8000
Error1Handler   EQU     $900EBE
QuasiPwrMgr     EQU     $901B28
ErrorBeep1      EQU     $904AA8
TMEntry1        EQU     $9012D4
TROMCode        EQU     $55AAAA55
MsgQ            EQU     16            
nosleep         EQU     18
aski            EQU     20
timer           EQU     22
test            EQU     26
beok            EQU     27

; Define options if not defined during build
        IFND SmallROM
SmallROM    EQU 0
        ENDIF
        IFND ROMDisk
ROMDisk     EQU 0
        ENDIF
        IFND ROMDisk2
ROMDisk2    EQU 0
        ENDIF

        IF ROMDisk
        incbin  'ROMDisk.bin'
        ENDIF

        IFEQ ROMDisk                    ; If ROMDisk is not enabled
        IFEQ SmallROM                   ; If the test ROM file should not have filler
        org     $F00000                 ; Dummy for proper sizing
        ENDIF
        ENDIF

        org     $F80000                 ; Cold start load location
        dc.l    TROMCode
        dc.l    ColdBoot
Setup:
        bset.l  #beok,D7                ; Allow bus errors just in case
        lea     VIA_Base,A0
        move.b  #%10111001,(VIA_DDR_B-VIA_Base,A0)
        bclr.b  #3,(A0)
        lea     Setup2,A6
        move.w  #$1001,D0
        move.l  #$F7000000,D1
        jmp     QuasiPwrMgr
        org     $F80080                 ; Warm start load location
        dc.l    TROMCode
        dc.l    WarmBoot
ColdBoot:
        move.l  #$D1A30ABC,D6
        jmp     Setup
WarmBoot:
        move.l  #$D1A30123,D6
        jmp     Setup
Setup2:
        lea     Sound_Base,A0
        lea     ErrorScreen,A6
        jmp     ErrorBeep1
ErrorScreen:
        lea     Video_Base,A2
        move.w  #$D1A3,D7
        move.w  #400,D0
        move.w  #640,D1
        move.w  #80,D2
        move.l  #32000,D3
        movea.l A2,A3
        lsr.w   #1,D0
        mulu.w  D2,D0
        adda.l  D0,A3
        lsr.w   #4,D1
        adda.w  D1,A3
        moveq   #-1,D0
        lsr.l   #2,D3
.DisplayMajor:
        move.l  D0,(A2)+
        subq.l  #1,D3
        bhi.b   .DisplayMajor
        movea.l A3,A2
        move.l  D2,D0
        mulu.w  #24,D0
        adda.l  D0,A2
        subq.w  #4,A2
        move.l  D7,D0
        moveq   #7,D4
        lea     .DisplayMinor,A6
        jmp     .FailData
.DisplayMinor:
        movea.l A3,A2
        move.l  D2,D0
        mulu.w  #36,D0
        adda.l  D0,A2
        subq.w  #4,A2
        move.l  D6,D0
        moveq   #7,D4
        lea     Setup3,A6
        jmp     .FailData   
.FailData:
        rol.l   #4,D0
        move.w  D0,D5
        andi.w  #%1111,D5
        mulu.w  #3,D5
        lea     .FailFont,A1
        moveq   #-$3D,D1
        moveq   #2,D3
.Loop:
        move.b  (A1),D5
        lsr.w   #2,D5
        or.w    D1,D5
        move.b  D5,(A2)
        adda.w  D2,A2
        move.b  (A1)+,D5
        lsl.w   #2,D5
        or.w    D1,D5
        move.b  D5,(A2)
        adda.w  D2,A2
        dbf     D3,.Loop
        move.w  D2,D2
        mulu.w  #6,D1
        suba.l  D1,A2
        addq.w  #1,A2
        dbf     D4,.FailData
        jmp     (A6)
.FailFont:
        incbin  'FailFont.bin'
Setup3:
        or.l    1<<test|1<<MsgQ|1<<timer|1<<nosleep|1<<aski,D7
        move.w  #12,D4
        swap    D4
        lea     VIA_Base,A0
        clr.b   (VIA_ACR-VIA_Base,A0)   ; Setup timer 2 for timed interrupts
        move.b  #$20,(VIA_IER-VIA_Base,A0)      ; Disable timer 2 interrupts
        move.b  #$FF,(VIA_T2L-VIA_Base,A0)      ; Low byte
        move.b  #$FF,(VIA_T2H-VIA_Base,A0)      ; High byte
        jmp     TMEntry1


        IF ROMDisk2
        org     $F90000                 ; Locate second ROM Disk at next 64k boundary
        incbin  'ROMDisk2.bin'
        ENDIF