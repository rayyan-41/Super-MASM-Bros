TITLE Super Masm Bros - V21 Immersion Update
; COAL Project - Fall 2025
; Updates: Removed In-Game Border/Footer, Added Coin Sound

INCLUDE Irvine32.inc
INCLUDELIB winmm.lib

; =======================================================
; CONSTANTS
; =======================================================
PlaySound PROTO STDCALL :PTR BYTE, :DWORD, :DWORD

SND_SYNC     EQU 0h
SND_ASYNC    EQU 1h
SND_LOOP     EQU 8h
SND_PURGE    EQU 40h
SND_FILENAME EQU 20000h

GRAVITY      EQU 1
JUMP_FORCE   EQU -4      ; Strong Jump
FRAME_DELAY  EQU 20      ; 50 FPS
SCREEN_WIDTH EQU 120

; Key Codes
KEY_UP       EQU 72
KEY_DOWN     EQU 80
KEY_ENTER    EQU 13

; =======================================================
; DATA SECTION
; =======================================================
.data
    hStdOut         DWORD ?
    windowRect      SMALL_RECT <0, 0, 119, 24>
    cursorInfo      CONSOLE_CURSOR_INFO <>
    
    fileMenu        BYTE "menu.wav", 0
    fileSelect      BYTE "select.wav", 0
    fileStart       BYTE "start.wav", 0
    isMusicOn       BYTE 1
    
    CurrentScreen   BYTE 0      
    IsGameActive    BYTE 0
    CoinsCollected  DWORD 0
    MenuSelection   BYTE 0
    
    MarioX          BYTE 5      
    MarioY          BYTE 15     
    MarioVelY       SBYTE 0     
    IsJumping       BYTE 0      
    
    OldMarioX       BYTE 5      
    OldMarioY       BYTE 15
    
    strCoins        BYTE "COINS: ", 0
    strLives        BYTE "LIVES: 3", 0
    strLevelInfo    BYTE "WORLD 1-1", 0
    strLevelInfo2   BYTE "WORLD 1-2", 0
    strWin          BYTE "COURSE CLEAR!", 0
    strFooter       BYTE "A product of Rayyan's Emporium | 24I-0767", 0
    
    ; Menu
    strOpt0         BYTE "BEGIN GAME", 0
    strOpt1         BYTE "LEADERBOARD", 0
    strOpt2         BYTE "SETTINGS", 0
    strOpt3         BYTE "EXIT", 0
    
    strSetTitle     BYTE "--- SETTINGS ---", 0
    strSetMusicOn   BYTE "MUSIC: [ ON  ]", 0
    strSetMusicOff  BYTE "MUSIC: [ OFF ]", 0
    strBack         BYTE "[ PRESS BACKSPACE TO RETURN ]", 0
    strLeaderTitle  BYTE "--- HIGH SCORES ---", 0
    strLead1        BYTE "1. RAYYAN ..... 999999", 0
    strLead2        BYTE "2. MARIO ...... 050000", 0

    MasmColors      DWORD yellow, lightRed, lightBlue, lightGreen, lightMagenta, cyan
    MasmColorCount  = 6
    CurrentColorIdx DWORD 0
    LastTimer       DWORD 0
    PhysicsTimer    DWORD 0
    
    ; --- Bitmaps ---
    MapS    BYTE 1,1,1,1,1, 1,0,0,0,0, 1,1,1,1,1, 0,0,0,0,1, 1,1,1,1,1
    MapU    BYTE 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 1,1,1,1,1
    MapP    BYTE 1,1,1,1,1, 1,0,0,0,1, 1,1,1,1,1, 1,0,0,0,0, 1,0,0,0,0
    MapE    BYTE 1,1,1,1,1, 1,0,0,0,0, 1,1,1,1,1, 1,0,0,0,0, 1,1,1,1,1
    MapR    BYTE 1,1,1,1,0, 1,0,0,0,1, 1,1,1,1,0, 1,0,0,0,1, 1,0,0,0,1
    MapM    BYTE 1,0,0,0,1, 1,1,0,1,1, 1,0,1,0,1, 1,0,0,0,1, 1,0,0,0,1
    MapA    BYTE 0,1,1,1,0, 1,0,0,0,1, 1,1,1,1,1, 1,0,0,0,1, 1,0,0,0,1
    MapB    BYTE 1,1,1,1,0, 1,0,0,0,1, 1,1,1,1,0, 1,0,0,0,1, 1,1,1,1,0
    MapO    BYTE 0,1,1,1,0, 1,0,0,0,1, 1,0,0,0,1, 1,0,0,0,1, 0,1,1,1,0

; =======================================================
; LEVEL DATA (120 Cols)
; =======================================================
Level1_Screen1 LABEL BYTE
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "       CCC                     CCCC                                                                                     "
BYTE "      CCCCC                   CCCCCC                                                                                    "
BYTE "     CCCCCCC                 CCCCCCCC                                                                                   "
BYTE "    CCCCCCCCC               CCCCCCCCCC                      CCC                                                         "
BYTE "                                                           CCCCC                                                        "
BYTE "                                                          CCCCCCC                                                       "
BYTE "                                                         CCCCCCCCC                                                      "
BYTE "                        QQQ                                                                                             "
BYTE "                        QQQ                                                                                             "
BYTE "                                                                                                                        "
BYTE "                                                 TTTCTTTT                                                               "
BYTE "                   cc                            TTTTTTTT                cccc                                           "
BYTE "                  PPPP                           TCTTTCTT                BBBB                                           "
BYTE "                  PPPP                           TTCTTTTT                BBBB                                           "
BYTE "                  PPPP                           TTTTTTTT                       cccc                                    "
BYTE "           cccc   PPPP     cccc                   CC                            QQQQ                                    "
BYTE "           PPPP   PPPP     PPPP                   CC               BBBB         QQQQ                                    "
BYTE "           PPPP   PPPP     PPPP                   CC               BBBB                                                 "
BYTE "           PPPP   PPPP     PPPP                   CC                                                                    "
BYTE "           PPPP   PPPP     PPPP    cccc   CC   ccc   ccccc         ccccc                                                "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen2 LABEL BYTE
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "       CC                           CC                                                                                  "
BYTE "      CCCC                         CCCC                                                                                 "
BYTE "     CCCCCC                      CCCCCCC       T                                                                        "
BYTE "    CCCCCCCC                    CCCCCCCCC      TT                                                                       "
BYTE "                                              TTT                                                                       "
BYTE "                                             TTTT                                                                       "
BYTE "                                            TTTTT                                                                       "
BYTE "                                            TTTTT                                                                       "
BYTE "                                               FF                                                                       "
BYTE "                                               FF                                                                       "
BYTE "                                               FF                                                                       "
BYTE "                    cc        ccccc            FF                                                                       "
BYTE "                   SS        BBBBB             FF                                                                       "
BYTE "                ccSSS        BBBBB             FF                                                                       "
BYTE "               cSSSSS                          FF                                                                       "
BYTE "             cSSSSSSS                          FF                                                                       "
BYTE "         c SSSSSSSSS                           FF                                                                       "
BYTE "         SSSSSSSSSSS                         FFFFFF                                                                     "
BYTE "       SSSSSSSSSSSSS                        FFFFFFFF                                                                    "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

; =======================================================
; CODE SECTION
; =======================================================
.code
main PROC
    call SetupScreen
    
    call StartMenuMusic
    call GetMseconds
    mov LastTimer, eax
    mov PhysicsTimer, eax
    
    call DrawFullMenu
    
MenuLoop:
    call ReadKey
    jz   CheckMenuTimer
    
    cmp al, 0
    je HandleArrows
    cmp al, KEY_ENTER
    je HandleSelection
    jmp CheckMenuTimer

HandleArrows:
    cmp ah, KEY_UP
    je CursorUp
    cmp ah, KEY_DOWN
    je CursorDown
    jmp CheckMenuTimer

CursorUp:
    call PlaySelectSound
    cmp MenuSelection, 0
    je WrapBottom
    dec MenuSelection
    jmp RedrawOptions
WrapBottom:
    mov MenuSelection, 3
    jmp RedrawOptions

CursorDown:
    call PlaySelectSound
    cmp MenuSelection, 3
    je WrapTop
    inc MenuSelection
    jmp RedrawOptions
WrapTop:
    mov MenuSelection, 0
    jmp RedrawOptions

RedrawOptions:
    call DrawMenuText
    jmp CheckMenuTimer

HandleSelection:
    call PlaySelectSound
    cmp MenuSelection, 0
    je StartGameSequence
    cmp MenuSelection, 1
    je GoToLeaderboard
    cmp MenuSelection, 2
    je GoToSettings
    cmp MenuSelection, 3
    je ExitGame
    jmp CheckMenuTimer

CheckMenuTimer:
    call GetMseconds
    sub  eax, LastTimer
    cmp  eax, 200
    jb   MenuLoop
    call UpdateMasmColor
    call GetMseconds
    mov LastTimer, eax
    mov dl, 37  ; Centered for 120 width
    mov dh, 7
    call DrawTitleMasm
    mov dl, 0
    mov dh, 0
    call Gotoxy
    jmp MenuLoop

GoToLeaderboard:
    call LeaderboardScreen
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

GoToSettings:
    call SettingsScreen
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

; =======================================================
; GAME LOGIC
; =======================================================
StartGameSequence:
    INVOKE PlaySound, NULL, 0, SND_PURGE
    INVOKE PlaySound, OFFSET fileStart, NULL, SND_FILENAME OR SND_SYNC
    
    mov CurrentScreen, 0
    mov MarioX, 5
    mov MarioY, 15
    mov MarioVelY, 0
    mov CoinsCollected, 0
    mov IsGameActive, 1
    
    call RenderLevelFromMap
    call DrawMarioChar
    
GameLoop:
    call ReadKey
    jz   PhysicsUpdate
    
    cmp al, 27
    je ReturnToMenu
    cmp al, 'a'
    je MoveLeft
    cmp al, 'A'
    je MoveLeft
    cmp al, 'd'
    je MoveRight
    cmp al, 'D'
    je MoveRight
    cmp al, 'w'
    je JumpAction
    cmp al, 'W'
    je JumpAction
    
    jmp PhysicsUpdate

MoveLeft:
    mov al, MarioX
    dec al
    mov ah, MarioY
    call IsSolidTile
    cmp al, 1
    je PhysicsUpdate 
    
    call EraseMario
    dec MarioX
    jmp PhysicsUpdate

MoveRight:
    cmp MarioX, 118
    jae CheckTransition
    
    mov al, MarioX
    inc al
    mov ah, MarioY
    call IsSolidTile
    cmp al, 1
    je PhysicsUpdate 
    
    call EraseMario
    inc MarioX
    jmp PhysicsUpdate

CheckTransition:
    cmp CurrentScreen, 0
    jne PhysicsUpdate
    mov CurrentScreen, 1
    mov MarioX, 2
    call RenderLevelFromMap
    call DrawMarioChar
    jmp PhysicsUpdate

JumpAction:
    mov al, MarioX
    mov ah, MarioY
    inc ah          
    call IsSolidTile
    cmp al, 0
    je PhysicsUpdate 
    
    mov MarioVelY, JUMP_FORCE
    mov IsJumping, 1
    jmp PhysicsUpdate

PhysicsUpdate:
    call GetMseconds
    sub  eax, PhysicsTimer
    cmp  eax, FRAME_DELAY
    jb   GameLoop
    
    call GetMseconds
    mov PhysicsTimer, eax
    
    call ApplyGravity
    call DrawMarioChar
    jmp GameLoop

ReturnToMenu:
    mov IsGameActive, 0
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

ExitGame:
    exit
main ENDP

; =======================================================
; PHYSICS & COLLISION
; =======================================================
ApplyGravity PROC
    call EraseMario
    
    movsx eax, MarioVelY
    movzx ebx, MarioY
    add ebx, eax    
    
    cmp MarioVelY, 0
    jge CheckFloor
    mov al, MarioX
    mov ah, bl      
    call IsSolidTile
    cmp al, 1
    jne MoveVert
    mov MarioVelY, 0 
    ret
    
CheckFloor:
    mov al, MarioX
    mov ah, bl
    call IsSolidTile
    cmp al, 1
    jne MoveVert
    mov MarioVelY, 0 
    ret

MoveVert:
    mov MarioY, bl  
    
    mov al, MarioX
    mov ah, MarioY
    inc ah
    call IsSolidTile
    cmp al, 1
    je Landed
    
    cmp MarioVelY, 2
    jge RetGrav
    inc MarioVelY
    jmp RetGrav
    
Landed:
    mov MarioVelY, 0
    
RetGrav:
    ret
ApplyGravity ENDP

IsSolidTile PROC USES esi edi ebx
    cmp al, 119
    ja IsSolid_True
    cmp ah, 24
    ja IsSolid_True
    
    movzx ebx, ah
    imul ebx, 120
    movzx edi, al
    add ebx, edi
    
    cmp CurrentScreen, 0
    je Map1
    mov esi, OFFSET Level1_Screen2
    jmp LoadTile
Map1:
    mov esi, OFFSET Level1_Screen1

LoadTile:
    add esi, ebx
    mov al, [esi]   
    
    cmp al, 'c'
    je CollectCoin
    cmp al, 'F'
    je TriggerWin
    
    cmp al, ' '
    je IsSolid_False
    cmp al, 'C'     
    je IsSolid_False
    cmp al, 'T'     
    je IsSolid_False
    
    mov al, 1
    ret

IsSolid_False:
    mov al, 0
    ret
IsSolid_True:
    mov al, 1
    ret

CollectCoin:
    mov byte ptr [esi], ' ' 
    inc CoinsCollected
    
    ; Play Sound (Updated V21)
    INVOKE PlaySound, OFFSET fileSelect, NULL, SND_FILENAME OR SND_ASYNC
    
    ; Update HUD
    push eax
    push edx
    mov eax, white + (black * 16) 
    call SetTextColor
    mov dl, 9
    mov dh, 1 
    call Gotoxy
    mov eax, CoinsCollected
    call WriteDec
    pop edx
    pop eax
    
    mov al, 0 
    ret

TriggerWin:
    call Clrscr
    mov dl, 55 
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strWin
    call WriteString
    call WaitMsg
    exit

IsSolidTile ENDP

; =======================================================
; RENDERING & HUD
; =======================================================

RenderLevelFromMap PROC USES eax ecx edx esi edi
    call Clrscr
    
    ; 1. Draw HUD Background (Rows 0-2)
    mov eax, white + (black * 16)
    call SetTextColor
    mov dh, 0
    mov ecx, 3 
HudBG:
    push ecx
    mov dl, 0
    mov ecx, 120
    call Gotoxy
    mov al, ' '
    HudL: call WriteChar
    loop HudL
    inc dh
    pop ecx
    loop HudBG
    
    ; 2. Draw HUD Text
    mov dl, 2
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    
    mov dl, 55
    mov dh, 1
    call Gotoxy
    cmp CurrentScreen, 0
    je ShowL1
    mov edx, OFFSET strLvl2
    jmp PrintLvl
ShowL1:
    mov edx, OFFSET strLevelInfo
PrintLvl:
    call WriteString
    
    mov dl, 100
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET strLives
    call WriteString
    
    ; NOTE: Removed DrawBorder call for game immersion
    
    cmp CurrentScreen, 0
    je LoadM1
    mov esi, OFFSET Level1_Screen2
    jmp StartP
LoadM1:
    mov esi, OFFSET Level1_Screen1

StartP:
    mov dh, 0
RowLoop:
    mov dl, 0
    mov ecx, 120 
    
ColLoop:
    mov al, [esi]
    
    ; Skip HUD Area (Rows 0-2)
    cmp dh, 3
    jl NextT
    
    cmp al, ' '
    je D_Sky
    cmp al, 'X'
    je D_Gnd
    cmp al, 'B'
    je D_Brk
    cmp al, 'Q'
    je D_Que
    cmp al, 'P'
    je D_Pip
    cmp al, 'c'
    je D_Coi
    cmp al, 'C'
    je D_Cld
    cmp al, 'S'
    je D_Str
    cmp al, 'F'
    je D_Pol
    cmp al, 'T'
    je D_Top
    jmp NextT

D_Sky:  mov eax, white + (lightBlue*16)
        call SetTextColor
        call Gotoxy
        mov al, ' '
        call WriteChar
        jmp NextT
D_Gnd:  mov eax, white + (green*16)
        call SetTextColor
        call Gotoxy
        mov al, ' '
        call WriteChar
        jmp NextT
D_Brk:  mov eax, lightRed + (brown*16)
        call SetTextColor
        call Gotoxy
        mov al, 178
        call WriteChar
        jmp NextT
D_Que:  mov eax, yellow + (brown*16)
        call SetTextColor
        call Gotoxy
        mov al, '?'
        call WriteChar
        jmp NextT
D_Pip:  mov eax, lightGreen + (green*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Coi:  mov eax, yellow + (lightBlue*16)
        call SetTextColor
        call Gotoxy
        mov al, 'O'
        call WriteChar
        jmp NextT
D_Cld:  mov eax, white + (lightBlue*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Str:  mov eax, white + (brown*16)
        call SetTextColor
        call Gotoxy
        mov al, 177
        call WriteChar
        jmp NextT
D_Pol:  mov eax, white + (lightBlue*16)
        call SetTextColor
        call Gotoxy
        mov al, 179
        call WriteChar
        jmp NextT
D_Top:  mov eax, lightRed + (lightBlue*16)
        call SetTextColor
        call Gotoxy
        mov al, 16
        call WriteChar
        jmp NextT

NextT:
    inc esi
    inc dl
    dec ecx
    jnz ColLoop
    
    inc dh
    cmp dh, 25
    jl RowLoop
    
    ; Note: Removed Footer drawing for immersion
    
    ret
RenderLevelFromMap ENDP

DrawMarioChar PROC
    mov eax, red + (lightBlue * 16)
    call SetTextColor
    mov dl, MarioX
    mov dh, MarioY
    call Gotoxy
    mov al, 'M'
    call WriteChar
    mov al, MarioX
    mov OldMarioX, al
    mov al, MarioY
    mov OldMarioY, al
    ret
DrawMarioChar ENDP

EraseMario PROC
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    mov dl, OldMarioX
    mov dh, OldMarioY
    call Gotoxy
    mov al, ' '
    call WriteChar
    ret
EraseMario ENDP

DrawFullMenu PROC
    call Clrscr
    call DrawBorder
    mov dl, 31 
    mov dh, 1
    call DrawTitleSuper
    mov dl, 37
    mov dh, 7
    call DrawTitleMasm
    mov dl, 37
    mov dh, 13
    call DrawTitleBros
    call DrawMenuText
    call DrawFooter
    ret
DrawFullMenu ENDP

DrawBorder PROC
    mov eax, brown + (black * 16) 
    call SetTextColor
    mov ecx, 120
    mov dl, 0
    mov dh, 0
    call Gotoxy
L1: mov al, 219
    call WriteChar
    loop L1
    mov ecx, 120
    mov dl, 0
    mov dh, 24
    call Gotoxy
L2: mov al, 219
    call WriteChar
    loop L2
    mov ecx, 23
    mov dh, 1
L3: mov dl, 0
    call Gotoxy
    mov al, 219
    call WriteChar
    mov dl, 119
    call Gotoxy
    mov al, 219
    call WriteChar
    inc dh
    loop L3
    ret
DrawBorder ENDP

DrawMenuText PROC
    ; Option 0
    mov dl, 52
    mov dh, 19
    call Gotoxy
    cmp MenuSelection, 0
    je Highlight0
    mov eax, gray + (black * 16)
    call SetTextColor
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt0
    call WriteString
    jmp Draw1
Highlight0:
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov al, '>'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt0
    call WriteString
Draw1:
    mov dl, 52
    mov dh, 20
    call Gotoxy
    cmp MenuSelection, 1
    je Highlight1
    mov eax, gray + (black * 16)
    call SetTextColor
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt1
    call WriteString
    jmp Draw2
Highlight1:
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov al, '>'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt1
    call WriteString
Draw2:
    mov dl, 52
    mov dh, 21
    call Gotoxy
    cmp MenuSelection, 2
    je Highlight2
    mov eax, gray + (black * 16)
    call SetTextColor
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt2
    call WriteString
    jmp Draw3
Highlight2:
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov al, '>'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt2
    call WriteString
Draw3:
    mov dl, 52
    mov dh, 22
    call Gotoxy
    cmp MenuSelection, 3
    je Highlight3
    mov eax, gray + (black * 16)
    call SetTextColor
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt3
    call WriteString
    jmp DoneMenu
Highlight3:
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov al, '>'
    call WriteChar
    mov al, ' '
    call WriteChar
    mov edx, OFFSET strOpt3
    call WriteString
DoneMenu:
    ret
DrawMenuText ENDP

DrawFooter PROC
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 39 
    mov dh, 23 
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
    ret
DrawFooter ENDP

StartMenuMusic PROC
    cmp isMusicOn, 1
    jne SkM
    INVOKE PlaySound, OFFSET fileMenu, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP
SkM: ret
StartMenuMusic ENDP

PlaySelectSound PROC
    cmp isMusicOn, 1
    jne SkS
    INVOKE PlaySound, OFFSET fileSelect, NULL, SND_FILENAME OR SND_ASYNC
SkS: ret
PlaySelectSound ENDP

SetupScreen PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdOut, eax
    INVOKE SetConsoleWindowInfo, hStdOut, TRUE, ADDR windowRect
    INVOKE GetConsoleCursorInfo, hStdOut, ADDR cursorInfo
    mov cursorInfo.bVisible, 0
    INVOKE SetConsoleCursorInfo, hStdOut, ADDR cursorInfo
    ret
SetupScreen ENDP

UpdateMasmColor PROC
    inc CurrentColorIdx
    cmp CurrentColorIdx, MasmColorCount
    jl  SkC
    mov CurrentColorIdx, 0
SkC: ret
UpdateMasmColor ENDP

LeaderboardScreen PROC
    call Clrscr
    mov dl, 50 
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET strLeaderTitle
    call WriteString
    mov dl, 50
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET strLead1
    call WriteString
    mov dl, 50
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strLead2
    call WriteString
    mov dl, 45
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString
LB_W:
    call ReadChar
    cmp al, 8
    je LB_R
    cmp al, 27
    je LB_R
    jmp LB_W
LB_R:
    call PlaySelectSound
    ret
LeaderboardScreen ENDP

SettingsScreen PROC
S_Loop:
    call Clrscr
    mov dl, 52
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET strSetTitle
    call WriteString
    mov dl, 50
    mov dh, 8
    call Gotoxy
    cmp isMusicOn, 1
    jne S_Off
    mov edx, OFFSET strSetMusicOn
    jmp S_Pr
S_Off: mov edx, OFFSET strSetMusicOff
S_Pr: call WriteString
    mov dl, 45
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString
    call ReadChar
    cmp al, '1'
    je S_Tog
    cmp al, 8
    je S_Ret
    cmp al, 27
    je S_Ret
    jmp S_Loop
S_Tog:
    call PlaySelectSound
    xor isMusicOn, 1
    cmp isMusicOn, 1
    je S_On
    INVOKE PlaySound, NULL, 0, SND_PURGE
    jmp S_Loop
S_On:
    call StartMenuMusic
    jmp S_Loop
S_Ret:
    call PlaySelectSound
    ret
SettingsScreen ENDP

DrawTitleSuper PROC
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov esi, OFFSET MapS
    call DrawLetter
    mov esi, OFFSET MapU
    call DrawLetter
    mov esi, OFFSET MapP
    call DrawLetter
    mov esi, OFFSET MapE
    call DrawLetter
    mov esi, OFFSET MapR
    call DrawLetter
    ret
DrawTitleSuper ENDP

DrawTitleMasm PROC
    mov esi, OFFSET MasmColors
    mov eax, CurrentColorIdx
    mov eax, [esi + eax*4]
    add eax, (black * 16)
    call SetTextColor
    mov esi, OFFSET MapM
    call DrawLetter
    mov esi, OFFSET MapA
    call DrawLetter
    mov esi, OFFSET MapS
    call DrawLetter
    mov esi, OFFSET MapM
    call DrawLetter
    ret
DrawTitleMasm ENDP

DrawTitleBros PROC
    mov eax, lightRed + (black * 16)
    call SetTextColor
    mov esi, OFFSET MapB
    call DrawLetter
    mov esi, OFFSET MapR
    call DrawLetter
    mov esi, OFFSET MapO
    call DrawLetter
    mov esi, OFFSET MapS
    call DrawLetter
    ret
DrawTitleBros ENDP

DrawLetter PROC USES eax ecx esi ebx
    mov bl, dh
    mov ecx, 5
RowL:
    push ecx
    push edx
    mov ecx, 5
ColL:
    mov al, [esi]
    cmp al, 1
    jne SkB
    call Gotoxy
    mov al, 219
    call WriteChar
    call WriteChar
    jmp Nxt
SkB:
Nxt:
    add dl, 2
    inc esi
    loop ColL
    pop edx
    inc dh
    pop ecx
    loop RowL
    mov dh, bl
    add dl, 12
    ret
DrawLetter ENDP

END main