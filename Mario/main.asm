; COAL Project - Fall 2025
; Updates: Async input for smooth movement, Irvine32 + winmm

INCLUDE Irvine32.inc
INCLUDELIB winmm.lib
INCLUDELIB user32.lib

; =======================================================
; CONSTANTS & PROTOTYPES
; =======================================================
PlaySound PROTO STDCALL :PTR BYTE, :DWORD, :DWORD
GetAsyncKeyState PROTO STDCALL :DWORD

SND_SYNC     EQU 0h
SND_ASYNC    EQU 1h
SND_LOOP     EQU 8h
SND_PURGE    EQU 40h
SND_FILENAME EQU 20000h
SND_NOSTOP   EQU 10h

GRAVITY      EQU 1
JUMP_FORCE   EQU -5  
FRAME_DELAY  EQU 60
SCREEN_WIDTH EQU 120
MAX_ENEMIES  EQU 10

; Virtual Key Codes for GetAsyncKeyState
VK_LEFT      EQU 25h
VK_UP        EQU 26h
VK_RIGHT     EQU 27h
VK_SPACE     EQU 20h
VK_W         EQU 57h
VK_A         EQU 41h
VK_S         EQU 53h
VK_D         EQU 44h
VK_P         EQU 50h
VK_ESCAPE    EQU 1Bh

; =======================================================
; DATA SECTION
; =======================================================
.data
    fileMenu        BYTE "menu.wav", 0
    fileSelect      BYTE "select.wav", 0
    fileStart       BYTE "start.wav", 0
    fileLvl1        BYTE "lvl1.wav", 0
    fileCoin        BYTE "coin.wav", 0
    fileMario       BYTE "mario.wav", 0
    fileFunny       BYTE "funny.wav", 0
    isMusicOn       BYTE 1
    
    CurrentScreen   BYTE 0      
    IsGameActive    BYTE 0
    GameWon         BYTE 0
    CoinsCollected  DWORD 0
    MenuSelection   BYTE 0
    PlayerLives     BYTE 3
    
    ; --- Player Name & High Score ---
    PlayerName      BYTE 16 DUP(0)
    strEnterName    BYTE "Enter your name: ", 0
    strHighScore    BYTE "highscore.txt", 0
    fileHandle      DWORD ?
    scoreBuffer     BYTE 64 DUP(0)

    MarioX          BYTE 5      
    MarioY          BYTE 17     
    MarioVelY       SBYTE 0     
    IsJumping       BYTE 0      
    
    OldMarioX       BYTE 5      
    OldMarioY       BYTE 17
    
    ; --- Physics Helpers ---
    StepDir         SBYTE 0
    StepCount       BYTE 0
    
    ; --- Enemies ---
    EnemyPosX       BYTE MAX_ENEMIES DUP(0)
    EnemyPosY       BYTE MAX_ENEMIES DUP(0)
    EnemyDirX       SBYTE MAX_ENEMIES DUP(1)
    EnemyActive     BYTE MAX_ENEMIES DUP(0)
    EnemyOldX       BYTE MAX_ENEMIES DUP(0)
    EnemyOldY       BYTE MAX_ENEMIES DUP(0)
    
    ; --- Fireball ---
    FireballPosX    BYTE 0
    FireballPosY    BYTE 0
    FireballActive  BYTE 0
    FireballOldX    BYTE 0
    FireballOldY    BYTE 0
    
    ; --- UI Strings ---
    strCoins        BYTE "COINS: ", 0
    strLives        BYTE "LIVES: ", 0
    strLevelInfo    BYTE "WORLD 1-1", 0
    strLevelInfo2   BYTE "WORLD 1-2", 0
    strLevelInfo3   BYTE "WORLD 1-3", 0
    strWin          BYTE "LEVEL 1 COMPLETED!", 0
    strScoreSaved   BYTE "SCORE SAVED!", 0
    strPressAnyKey  BYTE "Press any key to continue...", 0
    strGameOver     BYTE "GAME OVER!", 0
    strFooter       BYTE "A product of Rayyan's Emporium | 24I-0767", 0
    
    ; --- Menu option strings with padding for highlight ---
    strOpt0         BYTE "     BEGIN GAME      ", 0
    strOpt1         BYTE "     LEADERBOARD     ", 0
    strOpt2         BYTE "     SETTINGS        ", 0
    strOpt3         BYTE "     INSTRUCTIONS    ", 0
    strOpt4         BYTE "     EXIT            ", 0

    strSetTitle     BYTE "--- SETTINGS ---", 0
    strSetMusicOn   BYTE "MUSIC: [ ON  ]", 0
    strSetMusicOff  BYTE "MUSIC: [ OFF ]", 0
    strBack         BYTE "[ PRESS BACKSPACE TO RETURN ]", 0
    strLeaderTitle  BYTE "--- HIGH SCORES ---", 0
    strLead1        BYTE "1. RAYYAN ..... 999999", 0
    strLead2        BYTE "2. MARIO ...... 050000", 0

    ; --- Instructions strings ---
    strInstTitle    BYTE "--- INSTRUCTIONS ---", 0
    strInst1        BYTE "MOVE LEFT:  A or LEFT ARROW", 0
    strInst2        BYTE "MOVE RIGHT: D or RIGHT ARROW", 0
    strInst3        BYTE "JUMP:       W, UP ARROW, or SPACE", 0
    strInst4        BYTE "SHOOT:      S", 0
    strInst5        BYTE "PAUSE/MENU: ESC", 0
    strInst6        BYTE "COLLECT COINS (O) TO SCORE!", 0
    strInst7        BYTE "AVOID GOOMBAS (G) OR JUMP ON THEM!", 0
    strInst8        BYTE "REACH THE FLAG (F) TO WIN!", 0

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
; LEVEL DATA (120 Cols Wide) - 3 SCREENS
; =======================================================
Level1_Screen1 LABEL BYTE
BYTE "                    CC                                               CCC                                                "
BYTE "                   CCCC         CCC                                 CCCCC                                               "
BYTE "        CC        CCCCCC       CCCCC              C                CCCCCCC                             CCC              "
BYTE "       CCCC                                      CCC              CCCCCCCCC                           CCCCC             "
BYTE "      CCCCCC                                    CCCCC            CCCCCCCCCCC                         CCCCCCCC           "
BYTE "                                               CCCCCCC          CCCCCCCCCCCCC                       CCCCCCCCCC          "
BYTE "                                                                                                   CCCCCCCCCCCC         "
BYTE "                                                                                                  CCCCCCCCCCCCCC        "
BYTE "                                                                                                 CCCCCCCCCCCCCCCC       "
BYTE "                        cccc                                                                    CCCCCCCCCCCCCCCCCC      "
BYTE "                        PPPP                                                                                            "
BYTE "                        PPPP      cccc                                                                                  "
BYTE "                 cccc   PPPP      BBBB                                                     cccc                         "
BYTE "                 PPPP   PPPP      BBBB                                                     BBBB                         "
BYTE "                 PPPP   PPPP             cccc                                              BBBB                         "
BYTE "          cccc   PPPP   PPPP             BBBB                 QQQQ        QQQQQ    cccc                                 "
BYTE "          PPPP   PPPP   PPPP             BBBB          PPPP   QQQQ        QQQQQ    BBBB                                 "
BYTE "          PPPP   PPPP   PPPP                           PPPP                        BBBB                                 "
BYTE "          PPPP   PPPP   PPPP                           PPPP                                                             "
BYTE "          PPPP   PPPP   PPPP                           PPPP                                                             "
BYTE "          PPPP   PPPP   PPPP   cccccc         ccccccc  PPPP                                                             "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen2 LABEL BYTE
BYTE "                   CC                                 CCC                                    CCCCC                      "
BYTE "                 CCCCC                              CCCCCCC                               CCCCCCCCCCC                   "
BYTE "                CCCCCCC                           CCCCCCCCCC                             CCCCCCCCCCCCC                  "
BYTE "              CCCCCCCCCC                         CCCCCCCCCCCC                          CCCCCCCCCCCCCCCC                 "
BYTE "           CCCCCCCCCCCCCC                                                             CCCCCCCCCCCCCCCCCCCC              "
BYTE "                                                                                     CCCCCCCCCCCCCCCCCCCCCC             "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                                                                                  cccc                                  "
BYTE "        ccccccc                                cSSSSSSSSSSSSSSSc                  PPPP                                  "
BYTE "        ccccccc          ccccccc              cSSSSSSSSSSSSSSSSSc                 PPPP                                  "
BYTE "        BBBBBBB          BBBBBBB             cSSSSSSSSSSSSSSSSSSSc                PPPP                                  "
BYTE "        BBBBBBB   QQQQ   BBBBBBB            cSSSSSSSSSSSSSSSSSSSSSc         cccc  PPPP                                  "
BYTE "        BBBBBBB   QQQQ   BBBBBBB           cSSSSSSSSSSSSSSSSSSSSSSSc        PPPP  PPPP   cccc                           "
BYTE "                                          cSSSSSSSSSSSSSSSSSSSSSSSSSc       PPPP  PPPP   PPPP                           "
BYTE "                                         cSSSSSSSSSSSSSSSSSSSSSSSSSSSc      PPPP  PPPP   PPPP                           "
BYTE "                                        cSSSSSSSSSSSSSSSSSSSSSSSSSSSSSc     PPPP  PPPP   PPPP                           "
BYTE "                                       cSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSc    PPPP  PPPP   PPPP                           "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen3 LABEL BYTE
BYTE "                                                                                                                   TTT  "
BYTE "                          CCC                                                                                     TTTT  "
BYTE "                         CCCCC                                    CCC                                            TTTTT  "
BYTE "                        CCCCCCC                                  CCCCC                                          TTTTTT  "
BYTE "       CCC             CCCCCCCCC                                CCCCCCC                                BBBB    TTTTTTT  "
BYTE "      CCCCC                                    cccccc       QQQQ              QQQQ                     BBBB   TTTTTTTT  "
BYTE "     CCCCCCC                                   BBBBBB       QQQQ              QQQQ           BBBBB            TTTTTTTT  "
BYTE "                                               BBBBBB                                        BBBBB                 FF   "
BYTE "                                               BBBBBB                                                              FF   "
BYTE "                                                                       QQQQ          cccc                          FF   "
BYTE "                                    ccccccc                            QQQQ          PPPP                          FF   "
BYTE "                                    BBBBBBB                                          PPPP                          FF   "
BYTE "                   ccccc            BBBBBBB                cccccc             cccc   PPPP                          FF   "
BYTE "                   BBBBB            BBBBBBB                BBBBBB             PPPP   PPPP                          FF   "
BYTE "                   BBBBB                                   BBBBBB             PPPP   PPPP                          FF   "
BYTE "                                                ccccc      BBBBBB      cccc   PPPP   PPPP                          FF   "
BYTE "                          cccccc                BBBBB                  PPPP   PPPP   PPPP                          FF   "
BYTE "                          BBBBBB                BBBBB                  PPPP   PPPP   PPPP                          FF   "
BYTE "                          BBBBBB                BBBBB                  PPPP   PPPP   PPPP                        FFFFFF "
BYTE "                                                                       PPPP   PPPP   PPPP                       FFFFFFFF"
BYTE "                  cccc                                                 PPPP   PPPP   PPPP                      FFFFFFFFF"
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
    cmp al, 13
    je HandleSelection
    jmp CheckMenuTimer

HandleArrows:
    cmp ah, 72
    je CursorUp
    cmp ah, 80
    je CursorDown
    jmp CheckMenuTimer

CursorUp:
    cmp MenuSelection, 0
    je WrapBottom
    dec MenuSelection
    jmp RedrawOptions
WrapBottom:
    mov MenuSelection, 4
    jmp RedrawOptions

CursorDown:
    cmp MenuSelection, 4
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
    je GoToInstructions
    cmp MenuSelection, 4
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
    mov dl, 41
    mov dh, 8
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

GoToInstructions:
    call InstructionsScreen
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

; =======================================================
; GAME LOGIC
; =======================================================
StartGameSequence:
    INVOKE PlaySound, OFFSET fileStart, NULL, SND_FILENAME OR SND_ASYNC
    
    call Clrscr
    mov dl, 45
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strEnterName
    call WriteString
    
    mov edx, OFFSET PlayerName
    mov ecx, 15
    call ReadString
    
    INVOKE PlaySound, OFFSET fileMario, NULL, SND_FILENAME OR SND_ASYNC
    
    mov CurrentScreen, 0
    mov MarioX, 5
    mov MarioY, 17
    mov MarioVelY, 0
    mov CoinsCollected, 0
    mov PlayerLives, 3
    mov IsGameActive, 1
    mov IsJumping, 0
    mov FireballActive, 0
    mov GameWon, 0
    
    call InitEnemies
    call RenderLevelFromMap
    call DrawMarioChar
    call StartLevelMusic
    
    call GetMseconds
    mov PhysicsTimer, eax

GameLoop:
    call GetMseconds
    sub  eax, PhysicsTimer
    cmp  eax, FRAME_DELAY
    jb   GameLoop
    
    call GetMseconds
    mov PhysicsTimer, eax
    
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test eax, 8000h
    jnz ReturnToMenu
    
    INVOKE GetAsyncKeyState, VK_A
    test eax, 8000h
    jnz DoMoveLeft
    INVOKE GetAsyncKeyState, VK_LEFT
    test eax, 8000h
    jnz DoMoveLeft
    jmp CheckRight

DoMoveLeft:
    cmp MarioX, 1
    jbe CheckRight
    mov al, MarioX
    dec al
    mov ah, MarioY
    call IsSolidTile
    cmp al, 1
    je CheckRight
    call EraseMario
    dec MarioX

CheckRight:
    INVOKE GetAsyncKeyState, VK_D
    test eax, 8000h
    jnz DoMoveRight
    INVOKE GetAsyncKeyState, VK_RIGHT
    test eax, 8000h
    jnz DoMoveRight
    jmp CheckJumpKey

DoMoveRight:
    cmp MarioX, 118
    jae CheckTransition
    mov al, MarioX
    inc al
    mov ah, MarioY
    call IsSolidTile
    cmp al, 1
    je CheckJumpKey
    call EraseMario
    inc MarioX
    jmp CheckJumpKey

CheckTransition:
    cmp CurrentScreen, 0
    je TransitionTo1
    cmp CurrentScreen, 1
    je TransitionTo2
    jmp CheckJumpKey

TransitionTo1:
    mov CurrentScreen, 1
    mov MarioX, 2
    call InitEnemies
    call RenderLevelFromMap
    call DrawMarioChar
    jmp CheckJumpKey

TransitionTo2:
    mov CurrentScreen, 2
    mov MarioX, 2
    call InitEnemies
    call RenderLevelFromMap
    call DrawMarioChar
    jmp CheckJumpKey

CheckJumpKey:
    INVOKE GetAsyncKeyState, VK_W
    test eax, 8000h
    jnz DoJump
    INVOKE GetAsyncKeyState, VK_UP
    test eax, 8000h
    jnz DoJump
    INVOKE GetAsyncKeyState, VK_SPACE
    test eax, 8000h
    jnz DoJump
    jmp CheckShootKey

DoJump:
    cmp IsJumping, 1
    je CheckShootKey
    mov al, MarioX
    mov ah, MarioY
    inc ah
    call IsSolidTile
    cmp al, 0
    je CheckShootKey
    mov MarioVelY, JUMP_FORCE
    mov IsJumping, 1

CheckShootKey:
    INVOKE GetAsyncKeyState, VK_S
    test eax, 8000h
    jnz DoShoot
    jmp CheckFunnyKey

DoShoot:
    cmp FireballActive, 0
    jne CheckFunnyKey
    mov al, MarioX
    inc al
    mov FireballPosX, al
    mov al, MarioY
    mov FireballPosY, al
    mov FireballActive, 1
    mov al, FireballPosX
    mov FireballOldX, al
    mov al, FireballPosY
    mov FireballOldY, al

CheckFunnyKey:
    INVOKE GetAsyncKeyState, VK_P
    test eax, 8000h
    jnz PlayFunny
    jmp PhysicsUpdate

PlayFunny:
    INVOKE PlaySound, OFFSET fileFunny, NULL, SND_FILENAME OR SND_SYNC
    call StartLevelMusic

PhysicsUpdate:
    call ReadKey
    
    call ApplyGravityIterative
    call UpdateEnemies
    call UpdateFireball
    call CheckCollisions
    call DrawMarioChar
    call DrawEnemies
    call DrawFireball
    
    ; Check if player won
    cmp GameWon, 1
    je ShowWinScreen
    
    jmp GameLoop

ShowWinScreen:
    mov GameWon, 0
    call SaveHighScore
    INVOKE PlaySound, NULL, 0, SND_PURGE
    call Clrscr
    
    ; Set black background
    mov eax, white + (black * 16)
    call SetTextColor
    
    mov dl, 50
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strWin
    call WriteString
    
    mov dl, 53
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strScoreSaved
    call WriteString
    
    ; Show coins collected
    mov dl, 52
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    
    mov dl, 45
    mov dh, 18
    call Gotoxy
    mov edx, OFFSET strPressAnyKey
    call WriteString
    
    ; Wait for any key
    call ReadChar
    
    ; Return to menu
    jmp ReturnToMenu

ReturnToMenu:
    mov IsGameActive, 0
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

ExitGame:
    exit
main ENDP

; =======================================================
; ENEMY SYSTEM
; =======================================================
InitEnemies PROC USES eax ecx esi edi ebx edx
    mov ecx, MAX_ENEMIES
    mov edi, 0
ClearLoop:
    mov EnemyActive[edi], 0
    inc edi
    loop ClearLoop
    
    cmp CurrentScreen, 0
    je InitMap1
    cmp CurrentScreen, 1
    je InitMap2
    mov esi, OFFSET Level1_Screen3
    jmp ScanLevel
InitMap2:
    mov esi, OFFSET Level1_Screen2
    jmp ScanLevel
InitMap1:
    mov esi, OFFSET Level1_Screen1

ScanLevel:
    mov dh, 0
    mov bl, 0
ScanRow:
    mov dl, 0
ScanCol:
    mov al, [esi]
    cmp al, 'G'
    jne NextCell
    cmp bl, MAX_ENEMIES
    jae NextCell
    movzx edi, bl
    mov EnemyPosX[edi], dl
    mov EnemyPosY[edi], dh
    mov EnemyDirX[edi], 1
    mov EnemyActive[edi], 1
    mov EnemyOldX[edi], dl
    mov EnemyOldY[edi], dh
    mov byte ptr [esi], ' '
    inc bl
NextCell:
    inc esi
    inc dl
    cmp dl, 120
    jl ScanCol
    inc dh
    cmp dh, 25
    jl ScanRow
    ret
InitEnemies ENDP

UpdateEnemies PROC USES eax ebx ecx edx esi edi
    mov ecx, MAX_ENEMIES
    mov edi, 0
UpdateLoop:
    cmp EnemyActive[edi], 0
    je NextEnemy
    push ecx
    push edi
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    mov dl, EnemyOldX[edi]
    mov dh, EnemyOldY[edi]
    call Gotoxy
    mov al, ' '
    call WriteChar
    pop edi
    pop ecx
    mov al, EnemyPosX[edi]
    mov ah, EnemyDirX[edi]
    add al, ah
    cmp al, 1
    jbe ReverseDir
    cmp al, 118
    jae ReverseDir
    push ecx
    push edi
    mov ah, EnemyPosY[edi]
    call IsSolidTile
    pop edi
    pop ecx
    cmp al, 1
    je ReverseDir
    push ecx
    push edi
    mov al, EnemyPosX[edi]
    mov ah, EnemyDirX[edi]
    add al, ah
    mov ah, EnemyPosY[edi]
    inc ah
    call IsSolidTile
    pop edi
    pop ecx
    cmp al, 0
    je ReverseDir
    mov al, EnemyPosX[edi]
    mov EnemyOldX[edi], al
    mov al, EnemyPosY[edi]
    mov EnemyOldY[edi], al
    mov al, EnemyDirX[edi]
    add EnemyPosX[edi], al
    jmp NextEnemy
ReverseDir:
    neg EnemyDirX[edi]
NextEnemy:
    inc edi
    dec ecx
    jnz UpdateLoop
    ret
UpdateEnemies ENDP

DrawEnemies PROC USES eax ecx edx edi
    mov ecx, MAX_ENEMIES
    mov edi, 0
DrawLoop:
    cmp EnemyActive[edi], 0
    je SkipDraw
    mov eax, brown + (lightBlue * 16)
    call SetTextColor
    mov dl, EnemyPosX[edi]
    mov dh, EnemyPosY[edi]
    call Gotoxy
    mov al, 'G'
    call WriteChar
SkipDraw:
    inc edi
    loop DrawLoop
    ret
DrawEnemies ENDP

UpdateFireball PROC USES eax ebx esi edx
    cmp FireballActive, 0
    je FBDone
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    mov dl, FireballOldX
    mov dh, FireballOldY
    call Gotoxy
    mov al, ' '
    call WriteChar
    mov al, FireballPosX
    mov FireballOldX, al
    mov al, FireballPosY
    mov FireballOldY, al
    inc FireballPosX
    cmp FireballPosX, 119
    jae DeactivateFB
    mov al, FireballPosX
    mov ah, FireballPosY
    call IsSolidTile
    cmp al, 1
    je HitBlock
    jmp FBDone
HitBlock:
    movzx ebx, FireballPosY
    imul ebx, 120
    movzx eax, FireballPosX
    add ebx, eax
    cmp CurrentScreen, 0
    je DestroyM1
    cmp CurrentScreen, 1
    je DestroyM2
    mov esi, OFFSET Level1_Screen3
    jmp ChkBlk
DestroyM2:
    mov esi, OFFSET Level1_Screen2
    jmp ChkBlk
DestroyM1:
    mov esi, OFFSET Level1_Screen1
ChkBlk:
    add esi, ebx
    mov al, [esi]
    cmp al, 'B'
    jne DeactivateFB
    mov byte ptr [esi], ' '
    mov dl, FireballPosX
    mov dh, FireballPosY
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    call Gotoxy
    mov al, ' '
    call WriteChar
DeactivateFB:
    mov FireballActive, 0
FBDone:
    ret
UpdateFireball ENDP

DrawFireball PROC
    cmp FireballActive, 0
    je SkipFB
    mov eax, yellow + (lightBlue * 16)
    call SetTextColor
    mov dl, FireballPosX
    mov dh, FireballPosY
    call Gotoxy
    mov al, '*'
    call WriteChar
SkipFB:
    ret
DrawFireball ENDP

CheckCollisions PROC USES eax ecx edi edx
    mov ecx, MAX_ENEMIES
    mov edi, 0
ChkLoop:
    cmp EnemyActive[edi], 0
    je NxtChk
    mov al, MarioX
    cmp al, EnemyPosX[edi]
    jne ChkFB
    mov al, MarioY
    cmp al, EnemyPosY[edi]
    jne ChkJmpKill
    call MarioDied
    jmp NxtChk
ChkJmpKill:
    mov al, MarioY
    inc al
    cmp al, EnemyPosY[edi]
    jne ChkFB
    mov EnemyActive[edi], 0
    push edi
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    mov dl, EnemyPosX[edi]
    mov dh, EnemyPosY[edi]
    call Gotoxy
    mov al, ' '
    call WriteChar
    pop edi
    jmp NxtChk
ChkFB:
    cmp FireballActive, 0
    je NxtChk
    mov al, FireballPosX
    cmp al, EnemyPosX[edi]
    jne NxtChk
    mov al, FireballPosY
    cmp al, EnemyPosY[edi]
    jne NxtChk
    mov EnemyActive[edi], 0
    mov FireballActive, 0
NxtChk:
    inc edi
    dec ecx
    jnz ChkLoop
    ret
CheckCollisions ENDP

MarioDied PROC
    dec PlayerLives
    cmp PlayerLives, 0
    je GameOver
    mov MarioX, 5
    mov MarioY, 17
    mov MarioVelY, 0
    mov IsJumping, 0
    call RenderLevelFromMap
    ret
GameOver:
    call SaveHighScore
    call Clrscr
    mov eax, white + (black * 16)
    call SetTextColor
    mov dl, 52
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strGameOver
    call WriteString
    mov dl, 52
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    mov dl, 45
    mov dh, 18
    call Gotoxy
    mov edx, OFFSET strPressAnyKey
    call WriteString
    call ReadChar
    exit
MarioDied ENDP

SaveHighScore PROC USES eax ebx ecx edx esi edi
    mov edx, OFFSET strHighScore
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je SaveDone
    mov fileHandle, eax
    mov edi, OFFSET scoreBuffer
    mov esi, OFFSET PlayerName
CopyName:
    mov al, [esi]
    cmp al, 0
    je AddSep
    mov [edi], al
    inc esi
    inc edi
    jmp CopyName
AddSep:
    mov byte ptr [edi], ' '
    inc edi
    mov byte ptr [edi], '-'
    inc edi
    mov byte ptr [edi], ' '
    inc edi
    mov eax, CoinsCollected
    mov ebx, 10
    mov ecx, 0
ConvLoop:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    cmp eax, 0
    jne ConvLoop
WriteDigits:
    pop edx
    add dl, '0'
    mov [edi], dl
    inc edi
    loop WriteDigits
    mov byte ptr [edi], 13
    inc edi
    mov byte ptr [edi], 10
    inc edi
    mov byte ptr [edi], 0
    mov esi, OFFSET scoreBuffer
    mov ecx, 0
CntLen:
    cmp byte ptr [esi], 0
    je DoWrite
    inc ecx
    inc esi
    jmp CntLen
DoWrite:
    mov eax, fileHandle
    mov edx, OFFSET scoreBuffer
    call WriteToFile
    mov eax, fileHandle
    call CloseFile
SaveDone:
    ret
SaveHighScore ENDP

StartMenuMusic PROC
    cmp isMusicOn, 1
    jne SkM
    INVOKE PlaySound, OFFSET fileMenu, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP
SkM: ret
StartMenuMusic ENDP

StartLevelMusic PROC
    cmp isMusicOn, 1
    jne SkLM
    INVOKE PlaySound, OFFSET fileLvl1, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP
SkLM: ret
StartLevelMusic ENDP

PlaySelectSound PROC
    cmp isMusicOn, 1
    jne SkS
    INVOKE PlaySound, OFFSET fileSelect, NULL, SND_FILENAME OR SND_ASYNC
SkS: ret
PlaySelectSound ENDP

ApplyGravityIterative PROC
    call EraseMario
    cmp MarioVelY, 0
    je ApplyGravForce
    mov al, MarioVelY
    cmp al, 0
    jg  SetDown
    neg al
    mov StepCount, al
    mov StepDir, -1
    jmp LpMove
SetDown:
    mov StepCount, al
    mov StepDir, 1
LpMove:
    mov ah, MarioY
    add ah, StepDir
    cmp ah, 3
    jl StopMv
    cmp ah, 23
    jg StopMv
    push eax
    mov al, MarioX
    call IsSolidTile
    cmp al, 1
    pop eax
    je StopMv
    mov MarioY, ah
    dec StepCount
    jnz LpMove
    jmp ApplyGravForce
StopMv:
    cmp StepDir, 1
    jne BonkHd
    mov MarioVelY, 0
    mov IsJumping, 0
    jmp DoneGrav
BonkHd:
    mov MarioVelY, 0
ApplyGravForce:
    mov al, MarioX
    mov ah, MarioY
    inc ah
    call IsSolidTile
    cmp al, 1
    je ResetSt
    cmp MarioVelY, 2
    jge DoneGrav
    inc MarioVelY
    jmp DoneGrav
ResetSt:
    mov MarioVelY, 0
    mov IsJumping, 0
DoneGrav:
    ret
ApplyGravityIterative ENDP

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
    cmp CurrentScreen, 1
    je Map2
    mov esi, OFFSET Level1_Screen3
    jmp LoadTile
Map2:
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
    push eax
    push edx
    mov eax, white + (black * 16)
    call SetTextColor
    mov dl, 9
    mov dh, 0
    call Gotoxy
    mov eax, CoinsCollected
    call WriteDec
    pop edx
    pop eax
    mov al, 0
    ret
TriggerWin:
    mov GameWon, 1
    mov al, 0
    ret
IsSolidTile ENDP

RenderLevelFromMap PROC USES eax ecx edx esi edi
    call Clrscr
    mov eax, white + (black * 16)
    call SetTextColor
    mov dh, 0
    mov ecx, 2
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
    mov dl, 2
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    mov dl, 50
    mov dh, 0
    call Gotoxy
    cmp CurrentScreen, 0
    je ShowL1
    cmp CurrentScreen, 1
    je ShowL2
    mov edx, OFFSET strLevelInfo3
    jmp PrintLvl
ShowL2:
    mov edx, OFFSET strLevelInfo2
    jmp PrintLvl
ShowL1:
    mov edx, OFFSET strLevelInfo
PrintLvl:
    call WriteString
    mov dl, 95
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET strLives
    call WriteString
    movzx eax, PlayerLives
    call WriteDec
    cmp CurrentScreen, 0
    je LoadM1
    cmp CurrentScreen, 1
    je LoadM2
    mov esi, OFFSET Level1_Screen3
    jmp StartP
LoadM2:
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
    cmp dh, 2
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
D_Brk:  mov eax, white + (red*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Que:  mov eax, white + (yellow*16)
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
D_Str:  mov eax, brown + (brown*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Pol:  mov eax, gray + (gray*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Top:  mov eax, red + (red*16)
        call SetTextColor
        call Gotoxy
        mov al, 219
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
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 0
    mov dh, 25
    call Gotoxy
    mov ecx, 120
FooterBG:
    mov al, ' '
    call WriteChar
    loop FooterBG
    mov dl, 38
    mov dh, 25
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
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
    mov dl, 35
    mov dh, 2
    call DrawTitleSuper
    mov dl, 41
    mov dh, 8
    call DrawTitleMasm
    mov dl, 41
    mov dh, 14
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
    mov dh, 27
    call Gotoxy
L2: mov al, 219
    call WriteChar
    loop L2
    mov ecx, 26
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
    mov dl, 49
    mov dh, 21
    call Gotoxy
    cmp MenuSelection, 0
    je Hl0
    mov eax, gray + (black * 16)
    call SetTextColor
    mov edx, OFFSET strOpt0
    call WriteString
    jmp Draw1
Hl0:
    mov eax, white + (red * 16)
    call SetTextColor
    mov edx, OFFSET strOpt0
    call WriteString
Draw1:
    mov dl, 49
    mov dh, 22
    call Gotoxy
    cmp MenuSelection, 1
    je Hl1
    mov eax, gray + (black * 16)
    call SetTextColor
    mov edx, OFFSET strOpt1
    call WriteString
    jmp Draw2
Hl1:
    mov eax, white + (red * 16)
    call SetTextColor
    mov edx, OFFSET strOpt1
    call WriteString
Draw2:
    mov dl, 49
    mov dh, 23
    call Gotoxy
    cmp MenuSelection, 2
    je Hl2
    mov eax, gray + (black * 16)
    call SetTextColor
    mov edx, OFFSET strOpt2
    call WriteString
    jmp Draw3
Hl2:
    mov eax, white + (red * 16)
    call SetTextColor
    mov edx, OFFSET strOpt2
    call WriteString
Draw3:
    mov dl, 49
    mov dh, 24
    call Gotoxy
    cmp MenuSelection, 3
    je Hl3
    mov eax, gray + (black * 16)
    call SetTextColor
    mov edx, OFFSET strOpt3
    call WriteString
    jmp DnMenu
Hl3:
    mov eax, white + (red * 16)
    call SetTextColor
    mov edx, OFFSET strOpt3
    call WriteString
DnMenu:
    mov dl, 49
    mov dh, 25
    call Gotoxy
    cmp MenuSelection, 4
    je Hl4
    mov eax, gray + (black * 16)
    call SetTextColor
    mov edx, OFFSET strOpt4
    call WriteString
    jmp MenuEnd
Hl4:
    mov eax, white + (red * 16)
    call SetTextColor
    mov edx, OFFSET strOpt4
    call WriteString
MenuEnd:
    ret
DrawMenuText ENDP

DrawFooter PROC
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 38
    mov dh, 26
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
    ret
DrawFooter ENDP

SetupScreen PROC
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
S_Lp:
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
    jne S_Of
    mov edx, OFFSET strSetMusicOn
    jmp S_Pr
S_Of: mov edx, OFFSET strSetMusicOff
S_Pr: call WriteString
    mov dl, 45
    mov dh, 26
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString
    call ReadChar
    cmp al, '1'
    je S_Tg
    cmp al, 8
    je S_Rt
    cmp al, 27
    je S_Rt
    jmp S_Lp
S_Tg:
    call PlaySelectSound
    xor isMusicOn, 1
    cmp isMusicOn, 1
    je S_On
    INVOKE PlaySound, NULL, 0, SND_PURGE
    jmp S_Lp
S_On:
    call StartMenuMusic
    jmp S_Lp
S_Rt:
    call PlaySelectSound
    ret
SettingsScreen ENDP

InstructionsScreen PROC
    call Clrscr
    mov dl, 50
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET strInstTitle
    call WriteString
    mov dl, 45
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET strInst1
    call WriteString
    mov dl, 45
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET strInst2
    call WriteString
    mov dl, 45
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strInst3
    call WriteString
    mov dl, 45
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strInst4
    call WriteString
    mov dl, 45
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strInst5
    call WriteString
    mov dl, 45
    mov dh, 17
    call Gotoxy
    mov edx, OFFSET strInst6
    call WriteString
    mov dl, 45
    mov dh, 19
    call Gotoxy
    mov edx, OFFSET strInst7
    call WriteString
    mov dl, 45
    mov dh, 21
    call Gotoxy
    mov edx, OFFSET strInst8
    call WriteString
    mov dl, 45
    mov dh, 24
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString
Inst_W:
    call ReadChar
    cmp al, 8
    je Inst_R
    cmp al, 27
    je Inst_R
    jmp Inst_W
Inst_R:
    call PlaySelectSound
    ret
InstructionsScreen ENDP

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
RwL:
    push ecx
    push edx
    mov ecx, 5
ClL:
    mov al, [esi]
    cmp al, 1
    jne SkB
    call Gotoxy
    mov al, 219
    call WriteChar
    call WriteChar
    jmp Nx
SkB:
Nx:
    add dl, 2
    inc esi
    loop ClL
    pop edx
    inc dh
    pop ecx
    loop RwL
    mov dh, bl
    add dl, 12
    ret
DrawLetter ENDP

END main
