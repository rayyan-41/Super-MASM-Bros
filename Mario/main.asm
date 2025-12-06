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
JUMP_FORCE   EQU -3      
FRAME_DELAY  EQU 50
FRAME_DELAY_SNOW EQU 80
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
    
    ; --- Snowflakes ---
    MAX_SNOWFLAKES  EQU 30
    SnowX           BYTE 30 DUP(0)
    SnowY           BYTE 30 DUP(0)
    SnowOldX        BYTE 30 DUP(0)
    SnowOldY        BYTE 30 DUP(0)
    SnowActive      BYTE 30 DUP(0)
    SnowTimer       DWORD 0
    
    ; --- UI Strings ---
    strCoins        BYTE "COINS: ", 0
    strLives        BYTE "LIVES: ", 0
    strLevelInfo    BYTE "WORLD 1-1", 0
    strLevelInfo2   BYTE "WORLD 1-2", 0
    strWin          BYTE "LEVEL 1 COMPLETED!", 0
    strScoreSaved   BYTE "SCORE SAVED!", 0
    strGameOver     BYTE "GAME OVER!", 0
    strFooter       BYTE "A product of Rayyan's Emporium | 24I-0767", 0
    
    ; --- Menu option strings with padding for highlight ---
    strOpt0         BYTE "     BEGIN GAME      ", 0
    strOpt1         BYTE "     LEADERBOARD     ", 0
    strOpt2         BYTE "     SETTINGS        ", 0
    strOpt3         BYTE "     EXIT            ", 0

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
; LEVEL DATA (120 Cols x 25 Rows)
; =======================================================
Level1_Screen1 LABEL BYTE
BYTE "         CCC                      CC                       CCC                    CCC                                   "
BYTE "        CCCCC                    CCCC                     CCCCC                  CCCCC                                  "
BYTE "       CCCCCCC                  CCCCCC                   CCCCCCC                CCCCCCC                 CCC             "
BYTE "      CCCCCCCCC                CCCCCCCC                 CCCCCCCCC              CCCCCCCCC               CCCCC            "
BYTE "     CCCCCCCCCCC              CCCCCCCCCC               CCCCCCCCCCC            CCCCCCCCCCC             CCCCCCC           "
BYTE "                                                                                                     CCCCCCCCC          "
BYTE "                                                                                                    CCCCCCCCCCC         "
BYTE "                                                                                                                        "
BYTE "                                                                                    QQQ                                 "
BYTE "                                                                                    QQQ                                 "
BYTE "                                                                                                                        "
BYTE "                       cccc                                                                                             "
BYTE "                       PPPP                                                       ccSSSSS                               "
BYTE "                       PPPP                                      cccc   ccccc    cSSSSSSS                               "
BYTE "                cccc   PPPP                  ccccc               BBBB   BBBBB   cSSSSSSSS                               "
BYTE "                PPPP   PPPP   cccc           BBBBB               BBBB   BBBBB  ccSSSSSSSS          PPP                  "
BYTE "                PPPP   PPPP   PPPP                                            cSSSSSSSSSS          PPP                  "
BYTE "                PPPP   PPPP   PPPP                                          ccSSSSSSSSSSS          PPP   PPP            "
BYTE "                PPPP   PPPP   PPPP                                         cSSSSSSSSSSSSS          PPP   PPP            "
BYTE "                PPPP   PPPP   PPPP                                        cSSSSSSSSSSSSSS          PPP   PPP            "
BYTE "                PPPP   PPPP   PPPP        G                              cSSSSSSSSSSSSSSS     G    PPP   PPP            "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen2 LABEL BYTE
BYTE "                                                                                                               TTTT     "
BYTE "                                                                                                             TTTTTT     "
BYTE "                                                                                                            TTTTTTT     "
BYTE "                                                                                                           TTTTTTTT     "
BYTE "                                                                                                          TTTTTTTTT     "
BYTE "                                                                                                         TTTTTTTTTT     "
BYTE "                                                                                                                 FF     "
BYTE "                                                                                                                 FF     "
BYTE "                                                                                                                 FF     "
BYTE "                                                                                                                 FF     "
BYTE "                      ccc                                                                                        FF     "
BYTE "                   cccSSS                                                     cccc                               FF     "
BYTE "                  cSSSSSS    ccccc                                            PPPP                               FF     "
BYTE "                ccSSSSSSS    BBBBB                                     cccc   PPPP   cccc                        FF     "
BYTE "              ccSSSSSSSSS    BBBBB                                     PPPP   PPPP   BBBB                        FF     "
BYTE "            ccSSSSSSSSSSS           cccc                               PPPP   PPPP   BBBB                        FF     "
BYTE "           cSSSSSSSSSSSSS           BBBB         QQQQ    QQQQ          PPPP   PPPP          cccc               FFFFF    "
BYTE "         ccSSSSSSSSSSSSSS           BBBB         QQQQ    QQQQ          PPPP   PPPP          BBBB              FFFFFFF   "
BYTE "        cSSSSSSSSSSSSSSSS                                              PPPP   PPPP          BBBB             FFFFFFFFF  "
BYTE "      ccSSSSSSSSSSSSSSSSS                                              PPPP   PPPP                          FFFFFFFFFFF "
BYTE "      SSSSSSSSSSSSSSSSSSS        G                                     PPPP   PPPP     G                   FFFFFFFFFFFFF"
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
    mov MenuSelection, 3
    jmp RedrawOptions

CursorDown:
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
    mov dl, 41
    mov dh, 9
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
    
    ; Ask for player name
    call Clrscr
    mov dl, 45
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strEnterName
    call WriteString
    
    ; Read player name
    mov edx, OFFSET PlayerName
    mov ecx, 15
    call ReadString
    
    ; Play mario.wav when level starts
    INVOKE PlaySound, OFFSET fileMario, NULL, SND_FILENAME OR SND_SYNC
    
    mov CurrentScreen, 0
    mov MarioX, 5
    mov MarioY, 17
    mov MarioVelY, 0
    mov CoinsCollected, 0
    mov PlayerLives, 3
    mov IsGameActive, 1
    mov IsJumping, 0
    mov FireballActive, 0
    
    call InitEnemies
    call InitSnowflakes
    call RenderLevelFromMap
    call DrawMarioChar
    call StartLevelMusic
    
    call GetMseconds
    mov PhysicsTimer, eax

GameLoop:
    ; Frame timing - slower on snow level (Screen 2)
    call GetMseconds
    sub  eax, PhysicsTimer
    cmp CurrentScreen, 1
    je CheckSnowDelay
    cmp  eax, FRAME_DELAY
    jb   GameLoop
    jmp FrameReady
CheckSnowDelay:
    cmp  eax, FRAME_DELAY_SNOW
    jb   GameLoop
FrameReady:
    call GetMseconds
    mov PhysicsTimer, eax
    
    ; --- ASYNC INPUT (simultaneous key detection) ---
    
    ; Check ESC
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test eax, 8000h
    jnz ReturnToMenu
    
    ; Check Left (A or Left Arrow)
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
    ; Check Right (D or Right Arrow)
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
    jne CheckJumpKey
    mov CurrentScreen, 1
    mov MarioX, 2
    call InitEnemies
    call InitSnowflakes
    call RenderLevelFromMap
    call DrawMarioChar

CheckJumpKey:
    ; Check Jump (W or Up or Space)
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
    ; Check Shoot (S)
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
    ; Check P for funny sound
    INVOKE GetAsyncKeyState, VK_P
    test eax, 8000h
    jnz PlayFunny
    jmp PhysicsUpdate

PlayFunny:
    ; Play funny sound synchronously, then resume background music
    INVOKE PlaySound, OFFSET fileFunny, NULL, SND_FILENAME OR SND_SYNC
    call StartLevelMusic

PhysicsUpdate:
    ; Drain keyboard buffer
    call ReadKey
    
    call ApplyGravityIterative
    call UpdateEnemies
    call UpdateFireball
    call UpdateSnowflakes
    call CheckCollisions
    call DrawMarioChar
    call DrawEnemies
    call DrawFireball
    call DrawSnowflakes
    
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
; ENEMY SYSTEM
; =======================================================
InitEnemies PROC USES eax ecx esi edi ebx edx
    ; Clear all enemies
    mov ecx, MAX_ENEMIES
    mov edi, 0
ClearLoop:
    mov EnemyActive[edi], 0
    inc edi
    loop ClearLoop
    
    ; Scan level for 'G' characters
    cmp CurrentScreen, 0
    je InitMap1
    mov esi, OFFSET Level1_Screen2
    jmp ScanLevel
InitMap1:
    mov esi, OFFSET Level1_Screen1

ScanLevel:
    mov dh, 0           ; Row
    mov bl, 0           ; Enemy count
ScanRow:
    mov dl, 0           ; Column
ScanCol:
    mov al, [esi]
    cmp al, 'G'
    jne NextCell
    
    ; Found enemy, initialize it
    cmp bl, MAX_ENEMIES
    jae NextCell
    
    movzx edi, bl
    mov EnemyPosX[edi], dl
    mov EnemyPosY[edi], dh
    mov EnemyDirX[edi], 1
    mov EnemyActive[edi], 1
    mov EnemyOldX[edi], dl
    mov EnemyOldY[edi], dh
    
    ; Remove 'G' from map
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
    
    ; Erase old position
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
    
    ; Calculate new position
    mov al, EnemyPosX[edi]
    mov ah, EnemyDirX[edi]
    add al, ah
    
    ; Check bounds
    cmp al, 1
    jbe ReverseDir
    cmp al, 118
    jae ReverseDir
    
    ; Check collision with block
    push ecx
    push edi
    mov ah, EnemyPosY[edi]
    call IsSolidTile
    pop edi
    pop ecx
    cmp al, 1
    je ReverseDir
    
    ; Check if ground ahead
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
    
    ; Move enemy
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

; =======================================================
; FIREBALL SYSTEM
; =======================================================
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

; =======================================================
; SNOW SYSTEM
; =======================================================
InitSnowflakes PROC USES eax ecx edi
    ; Only initialize if on Screen 2
    cmp CurrentScreen, 1
    jne SkipSnowInit
    
    mov ecx, 30
    mov edi, 0
InitSnowLoop:
    ; Random X position (1-118)
    mov eax, 117
    call RandomRange
    add al, 1
    mov SnowX[edi], al
    ; Random Y position (start at top area)
    mov eax, 15
    call RandomRange
    add al, 3
    mov SnowY[edi], al
    mov SnowOldX[edi], 0
    mov SnowOldY[edi], 0
    mov SnowActive[edi], 1
    inc edi
    loop InitSnowLoop
SkipSnowInit:
    ret
InitSnowflakes ENDP

UpdateSnowflakes PROC USES eax ebx ecx edx edi esi
    ; Only update snow on Screen 2
    cmp CurrentScreen, 1
    jne SkipSnowUpdate
    
    mov ecx, 30
    mov edi, 0
UpdateSnowLoop:
    cmp SnowActive[edi], 0
    je NextSnowflake
    
    ; Erase old position
    push ecx
    push edi
    mov dl, SnowOldX[edi]
    mov dh, SnowOldY[edi]
    cmp dh, 2
    jl SkipErase
    cmp dh, 21
    jg SkipErase
    mov eax, lightBlue + (lightBlue * 16)
    call SetTextColor
    call Gotoxy
    mov al, ' '
    call WriteChar
SkipErase:
    pop edi
    pop ecx
    
    ; Save current as old
    mov al, SnowX[edi]
    mov SnowOldX[edi], al
    mov al, SnowY[edi]
    mov SnowOldY[edi], al
    
    ; Calculate next Y position
    mov al, SnowY[edi]
    inc al
    
    ; Check if next position would hit something
    push ecx
    push edi
    mov ah, al              ; ah = new Y
    mov al, SnowX[edi]      ; al = current X
    call IsSnowBlocked
    pop edi
    pop ecx
    cmp al, 1
    je ResetSnowflake
    
    ; Move snowflake down
    inc SnowY[edi]
    
    ; Random horizontal drift
    mov eax, 3
    call RandomRange
    cmp al, 0
    je DriftLeft
    cmp al, 1
    je DriftRight
    jmp CheckSnowBounds
DriftLeft:
    cmp SnowX[edi], 2
    jbe CheckSnowBounds
    ; Check if left position is blocked
    push ecx
    push edi
    mov al, SnowX[edi]
    dec al
    mov ah, SnowY[edi]
    call IsSnowBlocked
    pop edi
    pop ecx
    cmp al, 1
    je CheckSnowBounds
    dec SnowX[edi]
    jmp CheckSnowBounds
DriftRight:
    cmp SnowX[edi], 117
    jae CheckSnowBounds
    ; Check if right position is blocked
    push ecx
    push edi
    mov al, SnowX[edi]
    inc al
    mov ah, SnowY[edi]
    call IsSnowBlocked
    pop edi
    pop ecx
    cmp al, 1
    je CheckSnowBounds
    inc SnowX[edi]
    
CheckSnowBounds:
    ; Reset if reached ground level
    cmp SnowY[edi], 21
    jb NextSnowflake
    
ResetSnowflake:
    ; Reset to top with new random X
    mov eax, 116
    call RandomRange
    add al, 2
    mov SnowX[edi], al
    mov SnowY[edi], 3

NextSnowflake:
    inc edi
    dec ecx
    jnz UpdateSnowLoop
SkipSnowUpdate:
    ret
UpdateSnowflakes ENDP

; Check if snow position is blocked by Mario, structures, etc.
; Input: AL = X, AH = Y
; Output: AL = 1 if blocked, 0 if clear
IsSnowBlocked PROC USES ebx esi edi
    ; Check bounds
    cmp ah, 21
    jge SnowBlocked
    cmp ah, 2
    jl SnowBlocked
    
    ; Check if hitting Mario
    cmp al, MarioX
    jne NotMario
    cmp ah, MarioY
    je SnowBlocked
NotMario:
    
    ; Check map tile
    movzx ebx, ah
    imul ebx, 120
    movzx edi, al
    add ebx, edi
    mov esi, OFFSET Level1_Screen2
    add esi, ebx
    mov al, [esi]
    
    ; Check for blocking tiles
    cmp al, ' '
    je SnowClear
    cmp al, 'G'
    je SnowClear
    ; Everything else blocks snow
    jmp SnowBlocked
    
SnowClear:
    mov al, 0
    ret
SnowBlocked:
    mov al, 1
    ret
IsSnowBlocked ENDP

DrawSnowflakes PROC USES eax ecx edx edi
    ; Only draw snow on Screen 2
    cmp CurrentScreen, 1
    jne SkipSnowDrawAll
    
    mov ecx, 30
    mov edi, 0
DrawSnowLoop:
    cmp SnowActive[edi], 0
    je SkipSnowDraw
    
    mov dh, SnowY[edi]
    cmp dh, 3
    jl SkipSnowDraw
    cmp dh, 21
    jge SkipSnowDraw
    
    ; Don't draw if position is blocked
    push ecx
    push edi
    mov al, SnowX[edi]
    mov ah, SnowY[edi]
    call IsSnowBlocked
    pop edi
    pop ecx
    cmp al, 1
    je SkipSnowDraw
    
    mov eax, white + (lightBlue * 16)
    call SetTextColor
    mov dl, SnowX[edi]
    mov dh, SnowY[edi]
    call Gotoxy
    mov al, '*'
    call WriteChar

SkipSnowDraw:
    inc edi
    loop DrawSnowLoop
SkipSnowDrawAll:
    ret
DrawSnowflakes ENDP

; =======================================================
; COLLISION DETECTION
; =======================================================
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
    mov dl, 52
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strGameOver
    call WriteString
    mov dl, 48
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    call WaitMsg
    exit
MarioDied ENDP

; =======================================================
; HIGH SCORE SYSTEM
; =======================================================
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

; =======================================================
; AUDIO
; =======================================================
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

; =======================================================
; PHYSICS
; =======================================================
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
    ; Play coin sound asynchronously (non-blocking)
    INVOKE PlaySound, OFFSET fileCoin, NULL, SND_FILENAME OR SND_ASYNC
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
    call SaveHighScore
    INVOKE PlaySound, NULL, 0, SND_PURGE
    call Clrscr
    mov dl, 50
    mov dh, 11
    call Gotoxy
    mov edx, OFFSET strWin
    call WriteString
    mov dl, 53
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET strScoreSaved
    call WriteString
    call WaitMsg
    ; Exit - user will restart game to play again
    exit

IsSolidTile ENDP

; =======================================================
; RENDERING
; =======================================================
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
D_Gnd:  ; Ground - white on Screen 2 (snow), green on Screen 1
        cmp CurrentScreen, 1
        je D_GndSnow
        mov eax, white + (green*16)
        jmp D_GndDraw
D_GndSnow:
        mov eax, white + (white*16)
D_GndDraw:
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
D_Pol:  mov eax, lightRed + (lightBlue*16)
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
    mov dh, 3
    call DrawTitleSuper
    mov dl, 41
    mov dh, 9
    call DrawTitleMasm
    mov dl, 41
    mov dh, 15
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
    ; Option 0 - BEGIN GAME
    mov dl, 49
    mov dh, 19
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
    ; Option 1 - LEADERBOARD
    mov dl, 49
    mov dh, 20
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
    ; Option 2 - SETTINGS
    mov dl, 49
    mov dh, 21
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
    ; Option 3 - EXIT
    mov dl, 49
    mov dh, 22
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
    ret
DrawMenuText ENDP

DrawFooter PROC
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 38
    mov dh, 23
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
    ret
DrawFooter ENDP

SetupScreen PROC
    ; Using Irvine32 only - no Windows API calls
    ; Console will use default settings
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
    mov dh, 20
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