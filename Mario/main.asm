; COAL Project - Fall 2025
; Features: Hell Mode (I), Turbo (T), Pause (P), Funny (F), Append Scores
; Update: Ground color changed to solid dark green for better contrast.
; Library: Irvine32 + Winmm for Sound, Win32 for File Append

INCLUDE Irvine32.inc
INCLUDELIB winmm.lib
INCLUDELIB user32.lib
INCLUDELIB kernel32.lib

; =======================================================
; CONSTANTS & PROTOTYPES
; =======================================================
PlaySound PROTO STDCALL :PTR BYTE, :DWORD, :DWORD
GetAsyncKeyState PROTO STDCALL :DWORD

; --- Win32 API Constants for Appending ---
GENERIC_WRITE         EQU 40000000h
OPEN_ALWAYS           EQU 4
FILE_ATTRIBUTE_NORMAL EQU 80h
FILE_END              EQU 2

CreateFileA PROTO STDCALL :PTR BYTE, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CloseHandle PROTO STDCALL :DWORD

; --- Sound Constants ---
SND_SYNC      EQU 0h
SND_ASYNC     EQU 1h
SND_NODEFAULT EQU 2h      
; THIS CONSTANT MAKES THE MUSIC REPEAT:
SND_LOOP      EQU 8h
SND_PURGE     EQU 40h
SND_FILENAME  EQU 20000h

; --- Game Constants ---
GRAVITY       EQU 1
JUMP_FORCE    EQU -3      
SCREEN_WIDTH  EQU 120
MAX_ENEMIES   EQU 10

; --- Keys ---
VK_LEFT       EQU 25h
VK_UP         EQU 26h
VK_RIGHT      EQU 27h
VK_SPACE      EQU 20h
VK_W          EQU 57h
VK_A          EQU 41h
VK_S          EQU 53h
VK_D          EQU 44h
VK_P          EQU 50h  ; Pause
VK_F          EQU 46h  ; Funny
VK_I          EQU 49h  ; Hell Mode
VK_T          EQU 54h  ; Turbo
VK_ESCAPE     EQU 1Bh

; =======================================================
; DATA SECTION
; =======================================================
.data
    fileMenu      BYTE "menu.wav", 0
    fileStart     BYTE "start.wav", 0
    fileLvl1      BYTE "lvl1.wav", 0
    fileCoin      BYTE "coin.wav", 0
    fileMario     BYTE "mario.wav", 0
    fileFunny     BYTE "funny.wav", 0
    isMusicOn     BYTE 1
    
    CurrentScreen     BYTE 0       
    IsGameActive      BYTE 0
    IsPaused          BYTE 0
    GameWon           BYTE 0
    CoinsCollected    DWORD 0
    MenuSelection     BYTE 0
    PlayerLives       BYTE 3
    
    ; --- Dynamic Palette (Hell Mode) ---
    IsInvert          BYTE 0
    Color_Sky         DWORD 0
    Color_Ground      DWORD 0
    Color_Mario       DWORD 0
    Color_Goomba      DWORD 0
    Color_Coin        DWORD 0
    Color_Brick       DWORD 0
    Color_Pipe        DWORD 0
    
    ; --- Turbo Mode ---
    IsTurbo           BYTE 0
    CurrentFrameDelay DWORD 60
    
    ; --- Player Name & Scores ---
    PlayerName        BYTE 16 DUP(0)
    strEnterName      BYTE "Enter your name: ", 0
    strHighScore      BYTE "highscore.txt", 0
    fileHandle        DWORD ?
    scoreBuffer       BYTE 64 DUP(0)
    bytesWritten      DWORD 0

    MarioX            BYTE 5       
    MarioY            BYTE 17      
    MarioVelY         SBYTE 0      
    IsJumping         BYTE 0       
    
    OldMarioX         BYTE 5       
    OldMarioY         BYTE 17
    
    ; --- Physics Helpers ---
    StepDir           SBYTE 0
    StepCount         BYTE 0
    
    ; --- Enemies ---
    EnemyPosX         BYTE MAX_ENEMIES DUP(0)
    EnemyPosY         BYTE MAX_ENEMIES DUP(0)
    EnemyDirX         SBYTE MAX_ENEMIES DUP(1)
    EnemyActive       BYTE MAX_ENEMIES DUP(0)
    EnemyOldX         BYTE MAX_ENEMIES DUP(0)
    EnemyOldY         BYTE MAX_ENEMIES DUP(0)
    
    ; --- Fireball ---
    FireballPosX      BYTE 0
    FireballPosY      BYTE 0
    FireballActive    BYTE 0
    FireballOldX      BYTE 0
    FireballOldY      BYTE 0
    
    ; --- UI Strings ---
    strCoins          BYTE "COINS: ", 0
    strLives          BYTE "LIVES: ", 0
    strTime           BYTE "TIME: ", 0
    strLevelInfo      BYTE "WORLD 1-1", 0
    strLevelInfo2     BYTE "WORLD 1-2", 0
    strLevelInfo3     BYTE "WORLD 1-3 (SNOW)", 0
    strWin            BYTE "LEVEL 1 COMPLETED!", 0
    strScoreSaved     BYTE "SCORE SAVED!", 0
    strPressAnyKey    BYTE "Press any key to continue...", 0
    strGameOver       BYTE "GAME OVER!", 0
    strPaused         BYTE "   PAUSED   ", 0
    strFooter         BYTE "Controls: [I] Hell Mode | [T] Turbo | [P] Pause | [F] Funny Sound", 0
    
    ; --- Menu Strings ---
    strOpt0           BYTE "     BEGIN GAME      ", 0
    strOpt1           BYTE "     LEADERBOARD     ", 0
    strOpt2           BYTE "     SETTINGS        ", 0
    strOpt3           BYTE "     INSTRUCTIONS    ", 0
    strOpt4           BYTE "     EXIT            ", 0

    strSetTitle       BYTE "--- SETTINGS ---", 0
    strSetMusicOn     BYTE "MUSIC: [ ON  ]", 0
    strSetMusicOff    BYTE "MUSIC: [ OFF ]", 0
    strBack           BYTE "[ PRESS BACKSPACE TO RETURN ]", 0
    strLeaderTitle    BYTE "--- HIGH SCORES ---", 0
    strNoScores       BYTE "No scores yet!", 0
    highScoreBuffer   BYTE 5000 DUP(0) ; Large buffer for reading
    bytesRead         DWORD 0

    ; --- Instructions ---
    strInstTitle      BYTE "--- INSTRUCTIONS ---", 0
    strInst1          BYTE "MOVE LEFT:  A or LEFT ARROW", 0
    strInst2          BYTE "MOVE RIGHT: D or RIGHT ARROW", 0
    strInst3          BYTE "JUMP:       W, UP ARROW, or SPACE", 0
    strInst4          BYTE "SHOOT:      S", 0
    strInst5          BYTE "PAUSE: P | FUNNY: F | TURBO: T | HELL: I", 0
    strInst6          BYTE "COLLECT COINS (O) TO SCORE!", 0
    strInst7          BYTE "AVOID GOOMBAS (G) OR JUMP ON THEM!", 0
    strInst8          BYTE "REACH THE FLAG (F) TO WIN!", 0

    MasmColors        DWORD yellow, white, lightBlue, lightGreen, lightMagenta, cyan
    MasmColorCount    = 6
    CurrentColorIdx   DWORD 0
    LastTimer         DWORD 0
    PhysicsTimer      DWORD 0
    GameStartTime     DWORD 0
    ElapsedSeconds    DWORD 0
    LastSecondTime    DWORD 0
    
    ; --- Snow System ---
    MAX_SNOWFLAKES    EQU 20
    SnowX             BYTE 20 DUP(0)
    SnowY             BYTE 20 DUP(0)
    SnowOldX          BYTE 20 DUP(0)
    SnowOldY          BYTE 20 DUP(0)
    SnowActive        BYTE 20 DUP(0)
    SnowTimer         DWORD 0
    SlowdownCounter   BYTE 0
    MarioSlowdown     BYTE 0
    
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
BYTE "          CCCC                                                                                                          "
BYTE "        CCCCCCCC                                  CCCCC                                                   CCCCC         "
BYTE "       CCCCCCCCCC                               CCCCCCC                      CCCCC                      CCCCCCCCC       "
BYTE "      CCCCCCCCCCCC                           CCCCCCCCCCC                  CCCCCCCCC                    CCCCCCCCCCC      "
BYTE "                                            CCCCCCCCCCCCCC              CCCCCCCCCCCCC                CCCCCCCCCCCCCCC    "
BYTE "                                           CCCCCCCCCCCCCCCC            CCCCCCCCCCCCCCCCC               CCCCCCCCCCC      "
BYTE "                                         CCCCCCCCCCCCCCCCCCC         CCCCCCCCCCCCCCCCCCCC              CCCCCCCCCCC      "
BYTE "                                                                                                         CCCCCCC        "
BYTE "                                                                                                                        "
BYTE "                                                                                                                        "
BYTE "                              cccccccc                                                                                  "
BYTE "                              PPPPPPPP                       ccccccc                                                    "
BYTE "                 ccccccccc    PPPPPPPP                       BBBBBBB                      QQQQQQQQQQQQQ        QQQQQQQ  "
BYTE "                 PPPPPPPPP    PPPPPPPP                       BBBBBBB   ccccc              QQQQQQQQQQQQQ        QQQQQQQ  "
BYTE "                 PPPPPPPPP    PPPPPPPP                       BBBBBBB   BBBBB              QQQQQQQQQQQQQ        QQQQQQQ  "
BYTE "                 PPPPPPPPP    PPPPPPPP                   c             BBBBB SSSSSSS                                    "
BYTE "                 PPPPPPPPP    PPPPPPPP                  SS             BBBBB SSSSSSSSS                                  "
BYTE "                 PPPPPPPPP    PPPPPPPP               cSSSS                   SSSSSSSSSS                                 "
BYTE "                 PPPPPPPPP    PPPPPPPP              SSSSSS                   SSSSSSSSSSSS                               "
BYTE "      ccccc      PPPPPPPPP    PPPPPPPP      G      SSSSSSS                   SSSSSSSSSSSSS        G                     "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHGHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen2 LABEL BYTE
BYTE "                                                  CCCCCCCCCCC                                                           "
BYTE "                                             CCCCCCCCCCCCCCCCCCCC                                         CCCCCCCC      "
BYTE "                                            CCCCCCCCCCCCCCCCCCCCC                                        CCCCCCCCCC     "
BYTE "                                                CCCCCCCCCCCCCCCC                                      CCCCCCCCCCCCCCCCCC"
BYTE "                                                CCCCCCCCCCCCC                                    CCCCCCCCCCCCCCCCCCCCCCC"
BYTE "                                                      CCCCCCC                                CCCCCCCCCCCCCCCCCCCCCCCCCCC"
BYTE "                                                        CCC                                                             "
BYTE "                                                                                                                        "
BYTE "                                cccccccc                                       cccccc                                   "
BYTE "                                BBBBBBBB                                       QQQQQQ                                   "
BYTE "                         ccc    BBBBBBBB                                       QQQQQQ                                   "
BYTE "                         SSS    BBBBBBBB                             ccccc     QQQQQQ                                   "
BYTE "                    cccSSSSS                              ccccc      BBBBB                                              "
BYTE "                    SSSSSSSS                              BBBBB      BBBBB                                              "
BYTE "                   SSSSSSSSS                 cccccccc     BBBBB      BBBBB  ccccccccc                                   "
BYTE "                  SSSSSSSSSS                 PPPPPPPP     BBBBB             PPPPPPPPP                                   "
BYTE "                SSSSSSSSSSSS                 PPPPPPPP                       PPPPPPPPP                                   "
BYTE "                SSSSSSSSSSSS                 PPPPPPPP                       PPPPPPPPP                                   "
BYTE "            cccSSSSSSSSSSSSS                 PPPPPPPP                       PPPPPPPPP                                   "
BYTE "            SSSSSSSSSSSSSSSS                 PPPPPPPP                       PPPPPPPPP                                   "
BYTE "         SSSSSSSSSSSSSSSSSSS                 PPPPPPPP          G            PPPPPPPPP               cccc  cccccccc      "
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHHHHHHHHHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHHHHHHHHHHXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHHHHHHHHHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHHHHHHHHHHXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHHHHHGHHHHHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXHHGHHHHHHHHHHXXXXXXXXXXXXXXXXXXXXXX"
BYTE "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

Level1_Screen3 LABEL BYTE
BYTE "                                                               CCC                                        TT            "
BYTE "                                                              CCCCCCC                                   TTTT            "
BYTE "                                                         CCCCCCCCCCCCCCCC                              TTTTT            "
BYTE "                                                        CCCCCCCCCCCCCCCCCCCCC                        TTTTTTT            "
BYTE "                                                   CCCCCCCCCCCCCCCCCCCCCCCCCC                      TTTTTTTTT            "
BYTE "                                                      CCCCCCCCCCCCCCCCCCC                        TTTTTTTTTTT            "
BYTE "                                                       CCCCCCCCCCCCCCCC                        TTTTTTTTTTTTT            "
BYTE "                                                                                                         CCC            "
BYTE "              cccccccc                                                                                   CCC            "
BYTE "              PPPPPPPP                                                                                   CCC            "
BYTE "              PPPPPPPP                                                                                   CCC            "
BYTE "              PPPPPPPP                                                                                   CCC            "
BYTE "              PPPPPPPP                              cc                                                   CCC            "
BYTE "              PPPPPPPP                              SS                                                   CCC            "
BYTE "    ccccccc   PPPPPPPP                             SSSS                                                  CCC            "
BYTE "    PPPPPPP   PPPPPPPP                            SSSSSS                                                 CCC            "
BYTE "    PPPPPPP   PPPPPPPP                          cSSSSSSSSc                                               CCC            "
BYTE "    PPPPPPP   PPPPPPPP                        cSSSSSSSSSSS                                         CCCCCCCCCCCCCCC      "
BYTE "    PPPPPPP   PPPPPPPP                      cSSSSSSSSSSSSSSSccc                                  CCCCCCCCCCCCCCCCCCC    "
BYTE "    PPPPPPP   PPPPPPPP                   cccSSSSSSSSSSSSSSSSSSScc                              CCCCCCCCCCCCCCCCCCCCCCC  "
BYTE "    PPPPPPP   PPPPPPPP        G          SSSSSSSSSSSSSSSSSSSSSSSS          G                FFFFFFFFFFFFFFFFFFFFFFFFFFFF"
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
    
    call DrawStaticMenuBackground
    call DrawMenuOptions
    
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
    jmp RedrawSelectionOnly
WrapBottom:
    mov MenuSelection, 4
    jmp RedrawSelectionOnly

CursorDown:
    cmp MenuSelection, 4
    je WrapTop
    inc MenuSelection
    jmp RedrawSelectionOnly
WrapTop:
    mov MenuSelection, 0
    jmp RedrawSelectionOnly

RedrawSelectionOnly:
    call DrawMenuOptions
    jmp CheckMenuTimer

HandleSelection:
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
    call DrawStaticMenuBackground
    call DrawMenuOptions
    jmp MenuLoop

GoToSettings:
    call SettingsScreen
    call StartMenuMusic
    call DrawStaticMenuBackground
    call DrawMenuOptions
    jmp MenuLoop

GoToInstructions:
    call InstructionsScreen
    call StartMenuMusic
    call DrawStaticMenuBackground
    call DrawMenuOptions
    jmp MenuLoop

; =======================================================
; GAME LOGIC
; =======================================================
StartGameSequence:
    INVOKE PlaySound, OFFSET fileStart, NULL, SND_FILENAME OR SND_SYNC OR SND_NODEFAULT
    
    call Clrscr
    mov dl, 45
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strEnterName
    call WriteString
    
    mov edx, OFFSET PlayerName
    mov ecx, 15
    call ReadString
    
    INVOKE PlaySound, OFFSET fileMario, NULL, SND_FILENAME OR SND_SYNC OR SND_NODEFAULT
    
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
    mov IsPaused, 0
    
    ; Reset Mods
    mov IsInvert, 0
    mov IsTurbo, 0
    mov CurrentFrameDelay, 60
    call UpdatePalette ; Set initial normal colors
    
    call InitEnemies
    call RenderLevelFromMap
    call DrawMarioChar
    
    call GetMseconds
    mov GameStartTime, eax
    mov LastSecondTime, eax
    mov ElapsedSeconds, 0
    
    call InitSnow
    call StartLevelMusic
    call GetMseconds
    mov PhysicsTimer, eax

GameLoop:
    call GetMseconds
    sub  eax, PhysicsTimer
    cmp  eax, CurrentFrameDelay ; Variable delay for Turbo
    jb   GameLoop
    
    call GetMseconds
    mov PhysicsTimer, eax
    
    ; --- Global Hotkeys ---
    INVOKE GetAsyncKeyState, VK_P
    test eax, 8000h
    jnz TogglePause
    
    INVOKE GetAsyncKeyState, VK_ESCAPE
    test eax, 8000h
    jnz ReturnToMenu
    
    INVOKE GetAsyncKeyState, VK_I
    test eax, 8000h
    jnz ToggleHellMode
    
    INVOKE GetAsyncKeyState, VK_T
    test eax, 8000h
    jnz ToggleTurboMode
    
    cmp IsPaused, 1
    je DrawPausedState
    
    ; --- Player Movement ---
    INVOKE GetAsyncKeyState, VK_A
    test eax, 8000h
    jnz DoMoveLeft
    INVOKE GetAsyncKeyState, VK_LEFT
    test eax, 8000h
    jnz DoMoveLeft
    jmp CheckRight

DrawPausedState:
    mov eax, white + (red * 16)
    call SetTextColor
    mov dl, 53
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strPaused
    call WriteString
    jmp GameLoop

TogglePause:
    xor IsPaused, 1
    cmp IsPaused, 1
    je HandlePauseStart
    call StartLevelMusic
    call RenderLevelFromMap
    call DrawMarioChar
    call DrawEnemies
    jmp GameLoopWait
HandlePauseStart:
    INVOKE PlaySound, NULL, 0, SND_PURGE
    jmp GameLoopWait

ToggleHellMode:
    xor IsInvert, 1
    call UpdatePalette
    call RenderLevelFromMap
    call DrawMarioChar
    call DrawEnemies
    jmp GameLoopWait

ToggleTurboMode:
    xor IsTurbo, 1
    cmp IsTurbo, 1
    je SetFast
    mov CurrentFrameDelay, 60
    jmp GameLoopWait
SetFast:
    mov CurrentFrameDelay, 25 ; Super fast
    jmp GameLoopWait

GameLoopWait:
    mov ecx, 15000000 ; Debounce delay
    LpWait: loop LpWait
    jmp GameLoop

DoMoveLeft:
    cmp CurrentScreen, 2
    jne DoLeftNow
    inc MarioSlowdown
    test MarioSlowdown, 1
    jnz CheckRight
DoLeftNow:
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
    cmp CurrentScreen, 2
    jne DoRightNow
    inc MarioSlowdown
    test MarioSlowdown, 1
    jnz CheckJumpKey
DoRightNow:
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
    call InitSnow
    call RenderLevelFromMap
    call DrawMarioChar
    jmp CheckJumpKey

TransitionTo2:
    mov CurrentScreen, 2
    mov MarioX, 2
    call InitEnemies
    call InitSnow
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
    INVOKE GetAsyncKeyState, VK_F
    test eax, 8000h
    jnz PlayFunny
    jmp PhysicsUpdate

PlayFunny:
    INVOKE PlaySound, OFFSET fileFunny, NULL, SND_FILENAME OR SND_SYNC OR SND_NODEFAULT
    call StartLevelMusic

PhysicsUpdate:
    call ReadKey
    call UpdateTimer
    call ApplyGravityIterative
    call UpdateEnemies
    call UpdateFireball
    call UpdateSnow
    call CheckCollisions
    call CheckPitDeath
    
    cmp GameWon, 2
    je ReturnToMenu
    
    call DrawMarioChar
    call DrawEnemies
    call DrawFireball
    call DrawSnow
    
    cmp GameWon, 1
    je ShowWinScreen
    
    jmp GameLoop

ShowWinScreen:
    mov GameWon, 0
    call SaveHighScore
    INVOKE PlaySound, NULL, 0, SND_PURGE
    
    call Clrscr
    mov eax, black + (black * 16)
    call SetTextColor
    
    mov dh, 0
WinBlackRows:
    mov dl, 0
    call Gotoxy
    mov ecx, 120
WinBlackBG:
    mov al, ' '
    call WriteChar
    loop WinBlackBG
    inc dh
    cmp dh, 30
    jl WinBlackRows
    
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
    
    mov dl, 50
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    
    mov dl, 50
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET PlayerName
    call WriteString
    
    mov dl, 45
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strPressAnyKey
    call WriteString
    
    call ReadChar
    jmp ReturnToMenu

ReturnToMenu:
    mov IsGameActive, 0
    call StartMenuMusic
    call DrawStaticMenuBackground
    call DrawMenuOptions
    jmp MenuLoop

ExitGame:
    exit
main ENDP

; =======================================================
; DYNAMIC PALETTE SYSTEM (HELL MODE)
; =======================================================
UpdatePalette PROC
    cmp IsInvert, 1
    je SetHellMode
    
    ; Normal Colors
    mov eax, white
    add eax, (lightBlue * 16)
    mov Color_Sky, eax
    
    ; FIX: Use GREEN text on GREEN background for solid dark green ground
    mov eax, green
    add eax, (green * 16)
    mov Color_Ground, eax
    
    mov eax, red
    add eax, (lightBlue * 16)
    mov Color_Mario, eax
    
    mov eax, brown
    add eax, (lightBlue * 16)
    mov Color_Goomba, eax
    
    mov eax, yellow
    add eax, (lightBlue * 16)
    mov Color_Coin, eax
    
    mov eax, black
    add eax, (lightRed * 16)
    mov Color_Brick, eax
    
    mov eax, green
    add eax, (black * 16)
    mov Color_Pipe, eax
    
    ret
    
SetHellMode:
    ; Hell Mode Colors (Black Sky, Red Ground)
    mov eax, red
    add eax, (black * 16) 
    mov Color_Sky, eax
    
    mov eax, yellow
    add eax, (red * 16)   
    mov Color_Ground, eax
    
    mov eax, cyan
    add eax, (black * 16) 
    mov Color_Mario, eax
    
    mov eax, white
    add eax, (black * 16) 
    mov Color_Goomba, eax
    
    mov eax, lightRed
    add eax, (black * 16) 
    mov Color_Coin, eax
    
    mov eax, white
    add eax, (gray * 16)  
    mov Color_Brick, eax
    
    mov eax, red
    add eax, (black * 16) 
    mov Color_Pipe, eax
    
    ret
UpdatePalette ENDP

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
    mov eax, Color_Sky 
    call SetTextColor
    mov dl, EnemyPosX[edi]
    mov dh, EnemyPosY[edi]
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
    mov eax, Color_Goomba 
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
    mov eax, Color_Sky 
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
    mov eax, Color_Sky 
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
    mov eax, Color_Coin 
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
    add CoinsCollected, 50
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
    push edi
    mov eax, Color_Sky 
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
    add CoinsCollected, 50
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
    
NxtChk:
    inc edi
    dec ecx
    jnz ChkLoop
    ret
CheckCollisions ENDP

CheckPitDeath PROC USES eax ebx esi
    movzx ebx, MarioY
    imul ebx, 120
    movzx eax, MarioX
    add ebx, eax
    
    cmp CurrentScreen, 0
    je PitMap1
    cmp CurrentScreen, 1
    je PitMap2
    mov esi, OFFSET Level1_Screen3
    jmp CheckPitTile
PitMap2:
    mov esi, OFFSET Level1_Screen2
    jmp CheckPitTile
PitMap1:
    mov esi, OFFSET Level1_Screen1
    
CheckPitTile:
    add esi, ebx
    mov al, [esi]
    cmp al, 'H'
    jne PitCheckDone
    call MarioDied
PitCheckDone:
    ret
CheckPitDeath ENDP

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
    INVOKE PlaySound, NULL, 0, SND_PURGE
    
    call Clrscr
    mov eax, black + (black * 16)
    call SetTextColor
    
    mov dh, 0
GOBlackRows:
    mov dl, 0
    call Gotoxy
    mov ecx, 120
GOBlackBG:
    mov al, ' '
    call WriteChar
    loop GOBlackBG
    inc dh
    cmp dh, 30
    jl GOBlackRows
    
    mov eax, white + (black * 16)
    call SetTextColor
    
    mov dl, 52
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strGameOver
    call WriteString
    
    mov dl, 50
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strScoreSaved
    call WriteString
    
    mov dl, 50
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET strCoins
    call WriteString
    mov eax, CoinsCollected
    call WriteDec
    
    mov dl, 50
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET PlayerName
    call WriteString
    
    mov dl, 45
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strPressAnyKey
    call WriteString
    
    call ReadChar
    mov IsGameActive, 0
    mov PlayerLives, 3
    mov GameWon, 2 
    ret
MarioDied ENDP

; =======================================================
; HIGH SCORE APPEND (WIN32 Required for Append)
; =======================================================
SaveHighScore PROC USES eax ebx ecx edx esi edi
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
    ; Irvine32 CreateOutputFile deletes the file. We MUST use Win32 to append.
    INVOKE CreateFileA, ADDR strHighScore, GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je SaveDone
    mov fileHandle, eax
    
    INVOKE SetFilePointer, fileHandle, 0, NULL, FILE_END
    INVOKE WriteFile, fileHandle, ADDR scoreBuffer, ecx, ADDR bytesWritten, 0
    INVOKE CloseHandle, fileHandle

SaveDone:
    ret
SaveHighScore ENDP

StartMenuMusic PROC
    cmp isMusicOn, 1
    jne SkM
    INVOKE PlaySound, OFFSET fileMenu, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP OR SND_NODEFAULT
SkM: ret
StartMenuMusic ENDP

StartLevelMusic PROC
    cmp isMusicOn, 1
    jne SkLM
    INVOKE PlaySound, OFFSET fileLvl1, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP OR SND_NODEFAULT
SkLM: ret
StartLevelMusic ENDP

UpdateTimer PROC USES eax edx
    call GetMseconds
    sub eax, LastSecondTime
    cmp eax, 1000
    jb TimerDone
    
    call GetMseconds
    mov LastSecondTime, eax
    inc ElapsedSeconds
    
    mov eax, white + (black * 16)
    call SetTextColor
    mov dl, 75
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET strTime
    call WriteString
    mov eax, ElapsedSeconds
    call WriteDec
    mov al, 's'
    call WriteChar
    
TimerDone:
    ret
UpdateTimer ENDP

InitSnow PROC USES eax ecx edi
    mov ecx, 20
    mov edi, 0
ClearSnow:
    mov SnowActive[edi], 0
    inc edi
    loop ClearSnow
    
    cmp CurrentScreen, 2
    jne SnowInitDone
    
    mov ecx, 15
    mov edi, 0
InitFlakes:
    call RandomRange32
    mov SnowX[edi], al
    call RandomRange32
    and al, 1Fh
    add al, 2
    mov SnowY[edi], al
    mov al, SnowX[edi]
    mov SnowOldX[edi], al
    mov al, SnowY[edi]
    mov SnowOldY[edi], al
    mov SnowActive[edi], 1
    inc edi
    loop InitFlakes
    
SnowInitDone:
    ret
InitSnow ENDP

RandomRange32 PROC
    push edx
    call GetMseconds
    xor eax, 12345678h
    mov edx, eax
    shr edx, 16
    xor eax, edx
    and eax, 7Fh
    pop edx
    ret
RandomRange32 ENDP

UpdateSnow PROC USES eax ecx edx edi ebx esi
    cmp CurrentScreen, 2
    jne SnowUpdateDone
    
    inc SlowdownCounter
    cmp SlowdownCounter, 3
    jl SnowUpdateDone
    mov SlowdownCounter, 0
    
    mov ecx, 20
    mov edi, 0
    
UpdateSnowLoop:
    cmp SnowActive[edi], 0
    je NextSnowflake
    
    push ecx
    push edi
    mov dl, SnowOldX[edi]
    mov dh, SnowOldY[edi]
    cmp dh, 2
    jl SkipSnowErase
    cmp dh, 21
    jge SkipSnowErase
    
    movzx ebx, dh
    imul ebx, 120
    movzx eax, dl
    add ebx, eax
    mov esi, OFFSET Level1_Screen3
    add esi, ebx
    mov al, [esi]
    
    cmp al, ' '
    jne SkipSnowErase
    
    mov eax, Color_Sky 
    call SetTextColor
    call Gotoxy
    mov al, ' '
    call WriteChar
    
SkipSnowErase:
    pop edi
    pop ecx
    
    mov al, SnowX[edi]
    mov SnowOldX[edi], al
    mov al, SnowY[edi]
    mov SnowOldY[edi], al
    
    inc SnowY[edi]
    
    push ecx
    push edi
    call GetMseconds
    pop edi
    pop ecx
    and al, 3
    cmp al, 0
    je DriftLeft
    cmp al, 1
    je DriftRight
    jmp NoDrift
DriftLeft:
    cmp SnowX[edi], 2
    jbe NoDrift
    dec SnowX[edi]
    jmp NoDrift
DriftRight:
    cmp SnowX[edi], 117
    jae NoDrift
    inc SnowX[edi]
NoDrift:
    
    cmp SnowY[edi], 21
    jge ResetSnowflake
    
    push ecx
    push edi
    movzx ebx, SnowY[edi]
    imul ebx, 120
    movzx eax, SnowX[edi]
    add ebx, eax
    mov esi, OFFSET Level1_Screen3
    add esi, ebx
    mov al, [esi]
    pop edi
    pop ecx
    
    cmp al, ' '
    je NextSnowflake
    
ResetSnowflake:
    push ecx
    push edi
    call GetMseconds
    pop edi
    pop ecx
    and al, 7Fh
    add al, 5
    cmp al, 115
    jbe SnowXOk
    mov al, 60
SnowXOk:
    mov SnowX[edi], al
    mov SnowY[edi], 3
    
NextSnowflake:
    inc edi
    dec ecx
    jnz UpdateSnowLoop
    
SnowUpdateDone:
    ret
UpdateSnow ENDP

DrawSnow PROC USES eax ecx edx edi ebx esi
    cmp CurrentScreen, 2
    jne DrawSnowDone
    
    mov ecx, 20
    mov edi, 0
    
DrawSnowLoop:
    cmp SnowActive[edi], 0
    je SkipDrawSnow
    
    mov dh, SnowY[edi]
    cmp dh, 2
    jl SkipDrawSnow
    cmp dh, 21
    jge SkipDrawSnow
    
    movzx ebx, dh
    imul ebx, 120
    movzx eax, SnowX[edi]
    add ebx, eax
    mov esi, OFFSET Level1_Screen3
    add esi, ebx
    mov al, [esi]
    
    cmp al, ' '
    jne SkipDrawSnow
    
    mov eax, white + (lightBlue * 16)
    cmp IsInvert, 1
    jne NormalSnow
    mov eax, white + (black * 16) 
    jmp DrawSnowNow
NormalSnow:
    mov eax, white + (lightBlue * 16)
DrawSnowNow:
    call SetTextColor
    mov dl, SnowX[edi]
    call Gotoxy
    mov al, '*'
    call WriteChar
    
SkipDrawSnow:
    inc edi
    loop DrawSnowLoop
    
DrawSnowDone:
    ret
DrawSnow ENDP

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
    cmp al, 'H'
    je FallInPit
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
FallInPit:
    mov al, 0
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
    
    mov dl, 40
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
    
    mov dl, 70
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET strTime
    call WriteString
    mov eax, ElapsedSeconds
    call WriteDec
    mov al, 's'
    call WriteChar
    
    mov dl, 100
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
    cmp al, 'H'
    je D_Pit
    jmp NextT
D_Sky:  mov eax, Color_Sky 
        call SetTextColor
        call Gotoxy
        mov al, ' '
        call WriteChar
        jmp NextT
D_Gnd:  
        cmp CurrentScreen, 2
        jne NormalGround
        cmp IsInvert, 1
        jne SnowGndNormal
        mov eax, Color_Ground
        jmp DrawGround
SnowGndNormal:
        mov eax, white + (white*16)
        jmp DrawGround
NormalGround:
        mov eax, Color_Ground 
DrawGround:
        call SetTextColor
        call Gotoxy
        mov al, ' '
        call WriteChar
        jmp NextT
D_Brk:  mov eax, Color_Brick 
        call SetTextColor
        call Gotoxy
        mov al, 176
        call WriteChar
        jmp NextT
D_Que:  mov eax, brown + (yellow*16)
        cmp IsInvert, 1
        jne NormQ
        mov eax, white + (red*16)
NormQ:  call SetTextColor
        call Gotoxy
        mov al, '?'
        call WriteChar
        jmp NextT
D_Pip:  mov eax, Color_Pipe 
        call SetTextColor
        call Gotoxy
        mov al, 219
        call WriteChar
        jmp NextT
D_Coi:  mov eax, Color_Coin 
        call SetTextColor
        call Gotoxy
        mov al, 'O'
        call WriteChar
        jmp NextT
D_Cld:  mov eax, white + (lightBlue*16)
        cmp IsInvert, 1
        jne NormCld
        mov eax, white + (black*16)
NormCld:call SetTextColor
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
D_Pit:  mov eax, gray + (black*16)
        call SetTextColor
        call Gotoxy
        mov al, 178
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
    
    mov eax, black + (black * 16)
    call SetTextColor
    
    mov dh, 25
BlackRows:
    mov dl, 0
    call Gotoxy
    mov ecx, 120
BlackBG:
    mov al, ' '
    call WriteChar
    loop BlackBG
    inc dh
    cmp dh, 30
    jl BlackRows
    
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 38
    mov dh, 27
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
    
    ret
RenderLevelFromMap ENDP

DrawMarioChar PROC
    mov eax, Color_Mario 
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
    mov eax, Color_Sky 
    call SetTextColor
    mov dl, OldMarioX
    mov dh, OldMarioY
    call Gotoxy
    mov al, ' '
    call WriteChar
    ret
EraseMario ENDP

DrawStaticMenuBackground PROC
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
    call DrawFooter
    ret
DrawStaticMenuBackground ENDP

DrawMenuOptions PROC
    ; This function is called frequently - don't clear screen!
    mov dl, 49
    mov dh, 20
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
    mov dh, 21
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
    mov dh, 22
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
    mov dh, 23
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
    mov dh, 24
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
DrawMenuOptions ENDP

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
    mov dh, 29
    call Gotoxy
L2: mov al, 219
    call WriteChar
    loop L2
    
    mov ecx, 28
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

DrawFooter PROC
    mov eax, gray + (black * 16)
    call SetTextColor
    mov dl, 38
    mov dh, 27
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

; =======================================================
; LEADERBOARD: USES IRVINE32 FILE READING
; =======================================================
LeaderboardScreen PROC USES eax ebx ecx edx esi edi
    call Clrscr
    call DrawBorder  
    mov eax, white + (black * 16)
    call SetTextColor
    
    mov dl, 50
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET strLeaderTitle
    call WriteString
    
    ; --- IRVINE32 FILE READING ---
    mov edx, OFFSET strHighScore
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je NoScoresFound
    
    mov fileHandle, eax
    
    mov eax, fileHandle
    mov edx, OFFSET highScoreBuffer
    mov ecx, 5000 ; Read up to 5000 bytes
    call ReadFromFile
    mov bytesRead, eax
    
    mov eax, fileHandle
    call CloseFile
    ; -----------------------------
    
    cmp bytesRead, 0
    je NoScoresFound
    
    mov dh, 6
    mov esi, OFFSET highScoreBuffer
    mov ecx, bytesRead
    
DisplayScores:
    cmp ecx, 0
    je DoneDisplaying
    cmp dh, 18
    jge DoneDisplaying
    
    mov dl, 45
    call Gotoxy
    
PrintChar:
    cmp ecx, 0
    je DoneDisplaying
    mov al, [esi]
    cmp al, 0
    je DoneDisplaying
    cmp al, 13
    je SkipCR
    cmp al, 10
    je NextLine
    call WriteChar
SkipCR:
    inc esi
    dec ecx
    jmp PrintChar
    
NextLine:
    inc esi
    dec ecx
    add dh, 2
    jmp DisplayScores
    
NoScoresFound:
    mov dl, 50
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strNoScores
    call WriteString
    
DoneDisplaying:
    mov dl, 45
    mov dh, 22
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
    ret
LeaderboardScreen ENDP

SettingsScreen PROC
S_Lp:
    call Clrscr
    call DrawBorder
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
    xor isMusicOn, 1
    cmp isMusicOn, 1
    je S_On
    INVOKE PlaySound, NULL, 0, SND_PURGE
    jmp S_Lp
S_On:
    call StartMenuMusic
    jmp S_Lp
S_Rt:
    ret
SettingsScreen ENDP

InstructionsScreen PROC
    call Clrscr
    call DrawBorder
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