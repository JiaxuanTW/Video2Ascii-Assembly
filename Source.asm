INCLUDE Irvine32.inc

.data
; Ū�� Console ��T�����ܼ�
consoleInfo	CONSOLE_SCREEN_BUFFER_INFO <>
consoleRowSize DWORD ?
consoleColumnSize DWORD ?

; �}�ɬ����ܼ�
imagePath BYTE "frames/image.bmp", 0
fileHandle HANDLE ?
fileType BYTE 2 DUP(? ), 0
fileSize DWORD ?
dataOffset WORD ?
imageWidth DWORD ?
imageHeight DWORD ?
imageSize DWORD ?
buffer DWORD ?
; TODO: �ʺA�t�m�A�w�q�W����
byteArray BYTE 20000 DUP(? ), 0

; �r��`��
fileError BYTE "ERROR: Failed to open the image!", 10, 0
message1 BYTE "byteArray length: ", 0
; asciiArray BYTE "@#$%?*+;:,.", 0
asciiArray BYTE ".,:;+*?%$#@", 0

.code
main PROC

; ---------------------------------------------------------------------------- -
; ���o Console ��ܵ������e
; �I�s GetConsoleScreenBufferInfo() ���o consoleInfo
; consoleRowSize = consoleInfo.srWindow.Bottom - consoleInfo.srWindow.Top
; consoleColumnSize = consoleInfo.srWindow.Right - consoleInfo.srWindow.Left
; ��ڤj�p�����٭n�A + 1 (�i�̪��p�վ�)

INVOKE GetStdHandle, STD_OUTPUT_HANDLE
; EAX �w�s�J�q�W�����O���o�� StdHandle
INVOKE GetConsoleScreenBufferInfo, eax, ADDR consoleInfo

movzx eax, consoleInfo.srWindow.Bottom
movzx ebx, consoleInfo.srWindow.Top
sub eax, ebx
inc eax
mov consoleRowSize, eax

movzx eax, consoleInfo.srWindow.Right
movzx ebx, consoleInfo.srWindow.Left
sub eax, ebx
mov consoleColumnSize, eax

; ---------------------------------------------------------------------------- -
; Ū�� BMP �ɮ�
; �ϥ� Irvine32 Library �禡�I�s

mov edx, OFFSET imagePath
; �}���ɮ�: (�Ѽ�)EDX = �Ϥ���m(�^��) EAX = FileHandle
call OpenInputFile
; �Y�L�k���\�}���ɮסA�Y�^ INVALID_HANDLE_VALUE �� EAX
cmp eax, INVALID_HANDLE_VALUE
; ����󤣬۵��ɸ���(jump - if - not- equal)
jne file_ok

; ��ܿ��~ĵ�i
file_error :
mov edx, OFFSET fileError
call WriteString
jmp quit

; ���\�}���ɮ�
file_ok :
mov fileHandle, eax

; Ū�����: (�Ѽ�)EAX = FileHandle
;                ECX = Ū���줸�ռƶq
;                EDX = �w�İ�
;         (�^��)EAX = Ū���줸�ռƶq�A���~�h�Y�^���~�N�X

; Ū���ɮ׮榡
mov eax, fileHandle
mov ecx, 2
mov edx, OFFSET fileType
call ReadFromFile

; Ū���ɮפj�p
mov eax, fileHandle
mov ecx, 4
mov edx, OFFSET fileSize
call ReadFromFile

; �W�[ 4 Bytes �����q
INVOKE SetFilePointer,
fileHandle,
4,
0,
FILE_CURRENT

; Ū����ư����줸�ռ�
mov eax, fileHandle
mov ecx, 1
mov edx, OFFSET dataOffset
call ReadFromFile

; �W�[ 7 Bytes �����q
INVOKE SetFilePointer,
fileHandle,
7,
0,
FILE_CURRENT

; Ū���Ϥ��e��
mov eax, fileHandle
mov ecx, 4
mov edx, OFFSET imageWidth
call ReadFromFile

; Ū���Ϥ�����
mov eax, fileHandle
mov ecx, 4
mov edx, OFFSET imageHeight
call ReadFromFile

; �p��Ϥ������ƶq
; imageSize = imageWidth * imageHeight
; TODO: �`�N���k�d��
mov eax, imageWidth
mov ebx, imageHeight
mul ebx
mov imageSize, eax

; �W�[{ dataOffset } Bytes �����q
INVOKE SetFilePointer,
fileHandle,
dataOffset,
0,
FILE_BEGIN

; Ū����m���
mov esi, 0
mov ecx, imageSize
lp_read_bytes :
; EDI �ΨӼȮ��x�s RGB 3 �ӭȪ��X
mov edi, 0
push ecx
mov ecx, 3
lp_read_rgb:
push ecx
; Ū�� RGB �T���
mov eax, fileHandle
mov ecx, 1
mov edx, OFFSET buffer
call ReadFromFile
; �[�`�T��ȡA�ݤ���Ƕ���
add edi, buffer
pop ecx
loop lp_read_rgb
; �i��Ƕ��ƨ��x�s�� byteArray
mov edx, 0
mov eax, edi
; �o�̦]���Ƕ��ƦӰ��H 3�A�S�]���W�ư��H 25
mov ecx, 75
div ecx

; �ഫ���r�����x�s
push esi
mov esi, eax
mov dl, [asciiArray + esi]
pop esi
mov[byteArray + esi], dl

inc esi
pop ecx

; �r��������
; ���J�����m����: (ESI - imageWidth) % (imageWidth + 1) == 0
; �A�νd�� ESI >= imageWidth
; �ˬd ESI �O�_�j�� imageWidth
cmp esi, imageWidth
; �Y ���� < �k�� �h���L
    jb continue_read
    push ecx
    mov edx, 0
    mov eax, esi
    sub eax, imageWidth
    mov ecx, imageWidth
    inc ecx
    div ecx
    pop ecx
    cmp edx, 0
    jne continue_read
    add_newline :
mov[byteArray + esi], 10
inc esi
continue_read :
loop lp_read_bytes

; �����ɮ�
mov eax, fileHandle
call CloseFile

; ---------------------------------------------------------------------------- -
; ���տ�X
; mov esi, OFFSET byteArray
; mov ebx, TYPE byteArray
; mov ecx, LENGTHOF byteArray
; call DumpMem
mov edx, OFFSET byteArray
call WriteString

mov edx, OFFSET message1
call WriteString

INVOKE Str_length, ADDR byteArray
call WriteDec
call Crlf

quit :
exit
main ENDP

END main