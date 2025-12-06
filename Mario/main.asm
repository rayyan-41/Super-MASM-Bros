TITLE Super Masm Bros - Main Menu V8
; COAL Project - Fall 2025
; Updates: Menu Music, Select Sounds, Start Transition (Sync), Back Navigation

INCLUDE Irvine32.inc
INCLUDELIB winmm.lib

; =======================================================
; PROTOTYPES & CONSTANTS
; =======================================================
PlaySound PROTO STDCALL :PTR BYTE, :DWORD, :DWORD

SND_SYNC     EQU 0h      ; Play and WAIT
SND_ASYNC    EQU 1h      ; Play in background
SND_LOOP     EQU 8h      ; Loop the sound
SND_PURGE    EQU 40h     ; Stop playback
SND_FILENAME EQU 20000h  ; <--- CRITICAL ADDITION: Tells Windows its a file!

; =======================================================
; DATA SECTION
; =======================================================
.data
    ; --- Window Setup ---
    hStdOut         DWORD ?
    windowRect      SMALL_RECT <0, 0, 79, 24>
    consoleInfo     CONSOLE_SCREEN_BUFFER_INFO <>
    cursorInfo      CONSOLE_CURSOR_INFO <>
    
    ; --- Audio Files ---
    fileMenu        BYTE "menu.wav", 0
    fileSelect      BYTE "coin.wav", 0    ; The "Ting"
    fileStart       BYTE "start.wav", 0     ; 4-second transition
    isMusicOn       BYTE 1                  ; 1 = ON, 0 = OFF
    
    ; --- UI Text ---
    strOpt1         BYTE "1. BEGIN GAME", 0
    strOpt2         BYTE "2. LEADERBOARD", 0
    strOpt3         BYTE "3. SETTINGS", 0
    strOpt4         BYTE "4. EXIT", 0
    strFooter       BYTE "A product of Rayyan's Emporium | 24I-0767", 0
    
    ; --- Sub-Menu Text ---
    strBack         BYTE "[ PRESS BACKSPACE TO RETURN ]", 0
    strLeaderTitle  BYTE "--- HIGH SCORES ---", 0
    strLead1        BYTE "1. RAYYAN ..... 999999", 0
    strLead2        BYTE "2. MARIO ...... 050000", 0
    
    strSetTitle     BYTE "--- SETTINGS ---", 0
    strSetMusicOn   BYTE "1. MUSIC: [ ON  ]", 0
    strSetMusicOff  BYTE "1. MUSIC: [ OFF ]", 0
    
    ; --- Color Cycling ---
    MasmColors      DWORD yellow, lightRed, lightBlue, lightGreen, lightMagenta, cyan
    MasmColorCount  = 6                 
    CurrentColorIdx DWORD 0             
    LastTimer       DWORD 0             
    
    ; --- Bitmaps (Truncated for brevity, same as before) ---
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
; CODE SECTION
; =======================================================
.code
main PROC
    call SetupScreen
    
    ; Start Background Music
    call StartMenuMusic

    ; Init Timer
    call GetMseconds
    mov LastTimer, eax

    call DrawFullMenu
    
MenuLoop:
    call ReadKey            
    jz   CheckTimer         
    
    ; --- Input Handling ---
    
    cmp al, '1'
    je StartGameSequence    ; Special transition
    
    cmp al, '2'
    je GoToLeaderboard
    
    cmp al, '3'
    je GoToSettings
    
    cmp al, '4'
    je ExitGame
    
    jmp CheckTimer

CheckTimer:
    call GetMseconds        
    sub  eax, LastTimer     
    cmp  eax, 200           
    jb   MenuLoop           
    
    call UpdateMasmColor    
    call GetMseconds
    mov LastTimer, eax
    
    mov dl, 17      
    mov dh, 7       
    call DrawTitleMasm
    
    mov dl, 0
    mov dh, 0
    call Gotoxy
    
    jmp MenuLoop

; =======================================================
; STATE TRANSITIONS
; =======================================================

StartGameSequence:
    ; 1. Stop Background Music
    INVOKE PlaySound, NULL, 0, SND_PURGE
    
    ; 2. Play Start Sound (SYNC - Waits for 4 seconds)
    ; This acts as the "Loading" phase
    INVOKE PlaySound, OFFSET fileStart, NULL, SND_FILENAME OR SND_SYNC    

    ; 3. Jump to Game (Placeholder for now)
    call Clrscr
    mov dl, 30
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strOpt1 ; "Begin Game"
    call WriteString
    call WaitMsg
    
    ; 4. Return to Menu (For testing)
    call StartMenuMusic
    call DrawFullMenu
    jmp MenuLoop

GoToLeaderboard:
    call PlaySelectSound    
    call LeaderboardScreen  
    call StartMenuMusic     
    
    call DrawFullMenu       
    jmp MenuLoop

GoToSettings:
    call PlaySelectSound    
    call SettingsScreen     
    call StartMenuMusic     
    
    call DrawFullMenu       
    jmp MenuLoop

ExitGame:
    exit
main ENDP

; =======================================================
; SUB-SCREENS
; =======================================================

LeaderboardScreen PROC
    call Clrscr
    
    ; Header
    mov dl, 30
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET strLeaderTitle
    call WriteString
    
    ; Scores
    mov dl, 30
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET strLead1
    call WriteString
    
    mov dl, 30
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strLead2
    call WriteString
    
    ; Back Instruction
    mov dl, 25
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString

LB_WaitLoop:
    call ReadChar       ; Blocking wait
    cmp al, 8           ; Backspace
    je LB_Return
    cmp al, 27          ; Escape
    je LB_Return
    jmp LB_WaitLoop     ; Ignore other keys

LB_Return:
    call PlaySelectSound ; Feedback for going back
    ret
LeaderboardScreen ENDP

SettingsScreen PROC
SettingsLoop:
    call Clrscr
    
    ; Header
    mov dl, 32
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET strSetTitle
    call WriteString
    
    ; Option 1: Music Toggle
    mov dl, 30
    mov dh, 8
    call Gotoxy
    cmp isMusicOn, 1
    jne DrawOff
    mov edx, OFFSET strSetMusicOn
    jmp PrintOpt
DrawOff:
    mov edx, OFFSET strSetMusicOff
PrintOpt:
    call WriteString
    
    ; Back Instruction
    mov dl, 25
    mov dh, 20
    call Gotoxy
    mov edx, OFFSET strBack
    call WriteString

    ; Input
    call ReadChar
    
    cmp al, '1'
    je ToggleMusic
    
    cmp al, 8           ; Backspace
    je Set_Return
    cmp al, 27          ; Escape
    je Set_Return
    
    jmp SettingsLoop

ToggleMusic:
    call PlaySelectSound
    xor isMusicOn, 1    ; Toggle 0/1
    
    cmp isMusicOn, 1
    je TurnOn
    
    ; Turn Off
    INVOKE PlaySound, NULL, 0, SND_PURGE
    jmp SettingsLoop
    
TurnOn:
    call StartMenuMusic
    jmp SettingsLoop

Set_Return:
    call PlaySelectSound
    ret
SettingsScreen ENDP

; =======================================================
; AUDIO HELPERS
; =======================================================

StartMenuMusic PROC
    cmp isMusicOn, 1
    jne SkipMusic
    ; FILENAME + ASYNC + LOOP
    INVOKE PlaySound, OFFSET fileMenu, NULL, SND_FILENAME OR SND_ASYNC OR SND_LOOP
SkipMusic:
    ret
StartMenuMusic ENDP

PlaySelectSound PROC
    cmp isMusicOn, 1
    jne SkipSelect
    ; FILENAME + ASYNC
    INVOKE PlaySound, OFFSET fileSelect, NULL, SND_FILENAME OR SND_ASYNC
SkipSelect:
    ret
PlaySelectSound ENDP

; =======================================================
; GRAPHICS HELPERS (Same as V7)
; =======================================================

SetupScreen PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdOut, eax
    INVOKE SetConsoleWindowInfo, hStdOut, TRUE, ADDR windowRect
    INVOKE GetConsoleCursorInfo, hStdOut, ADDR cursorInfo
    mov cursorInfo.bVisible, 0
    INVOKE SetConsoleCursorInfo, hStdOut, ADDR cursorInfo
    ret
SetupScreen ENDP

DrawFullMenu PROC
    call Clrscr
    mov dl, 11      
    mov dh, 1       
    call DrawTitleSuper
    mov dl, 17      
    mov dh, 7       
    call DrawTitleMasm
    mov dl, 17      
    mov dh, 13      
    call DrawTitleBros
    call DrawMenuText
    call DrawFooter
    ret
DrawFullMenu ENDP

DrawMenuText PROC
    mov eax, white + (black * 16)
    call SetTextColor
    
    mov dl, 2       
    mov dh, 19      
    call Gotoxy
    mov edx, OFFSET strOpt1
    call WriteString
    
    mov dl, 2       
    mov dh, 20      
    call Gotoxy
    mov edx, OFFSET strOpt2
    call WriteString
    
    mov dl, 2       
    mov dh, 21      
    call Gotoxy
    mov edx, OFFSET strOpt3
    call WriteString

    mov dl, 2       
    mov dh, 22      
    call Gotoxy
    mov edx, OFFSET strOpt4
    call WriteString
    ret
DrawMenuText ENDP

DrawFooter PROC
    mov eax, gray + (black * 16) 
    call SetTextColor
    mov dl, 19
    mov dh, 24      
    call Gotoxy
    mov edx, OFFSET strFooter
    call WriteString
    ret
DrawFooter ENDP

UpdateMasmColor PROC
    inc CurrentColorIdx
    cmp CurrentColorIdx, MasmColorCount
    jl  SkipReset
    mov CurrentColorIdx, 0
SkipReset:
    ret
UpdateMasmColor ENDP

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
RowLoop:
    push ecx            
    push edx            
    mov ecx, 5          
ColLoop:
    mov al, [esi]       
    cmp al, 1
    jne SkipBlock
    call Gotoxy         
    mov al, 219         
    call WriteChar
    call WriteChar      
    jmp NextCol
SkipBlock:
    ; Space
NextCol:
    add dl, 2           
    inc esi             
    loop ColLoop        
    pop edx             
    inc dh              
    pop ecx             
    loop RowLoop        
    mov dh, bl          
    add dl, 12          
    ret
DrawLetter ENDP

END main