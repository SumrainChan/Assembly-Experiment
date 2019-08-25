; multi-segment executable file template.
;宏定义
scroll macro n,ud,ulr,ulc,lrr,lrc,att  ;清屏或上下卷
    push ax
    push bx
    push cx
    push dx
    mov ah,ud
    mov al,n
    mov ch,ulr
    mov cl,ulc
    mov dh,lrr
    mov dl,lrc
    mov bh,att
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
endm

curse macro cury,curx   ;置光标
    push ax
    push bx
    push dx
    mov ah,2
    mov dh,cury
    mov dl,curx
    mov bh,0
    int 10h
    pop dx
    pop bx
    pop ax
endm
  
print macro str,cury,curx   ;定位打印字符串
    push ax
    push bx
    push dx
    mov ah,2
    mov dh,cury
    mov dl,curx
    mov bh,0
    int 10h
    mov dx,offset str
    mov ah,09h
    int 21h
    pop dx
    pop bx
    pop ax
endm
  
data segment
    ; add your data here!
    WELCOME db "WELCOME TO THE TYPE GAME!",'$'
    DELIMITER db "=============================",'$'
    INPUT_EXIT_TIP db "(INPUT ESC TO EXIT)",'$'
    TIME_TIP db "YOUR TIME IS:",'$'
    SCORE_TIP db "YOUR SCORE IS:",'$'
    RESTART_TIP db "ANY KEY TO RESTART",'$'
    EXIT_TIP db "ESC TO EXIT",'$'
    SUM db "/100",'$'
    COMFIRM_EXIT db "COMFIRM TO EXIT",'$'
    COMFIRM_EXIT_TIP db "(DISCARD TIME&SCORE)",'$'
    COMFIRM_EXIT_YES db "[YES] (ENTER)",'$'
    COMFIRM_EXIT_NO db "[NO] (ESC)",'$'
    Q0 db "HELLOWORLD",'$'
    Q1 db "BasketBall",'$'
    Q2 db "Good Time!",'$'
    Q3 db "Beautiful!",'$'
    Q4 db "heartbreak",'$'
    Q5 db "playguitar",'$'
    Q6 db "<Birthday>",'$'
    Q7 db "SweetSmile",'$'
    Q8 db "I Love You",'$'
    Q9 db "JackRabbit",'$'
    QUIZ dw Q0,Q1,Q2,Q3,Q4,Q5,Q6,Q7,Q8,Q9
    CUR_W db 0  ;当前题目的字符
    CUR_I db 0  ;当前输入的字符
    RIGHT_NUM db 0  ;正确字符数
    ROW db 0
    X db 0  ;输入字符的横坐标
    Y db 0  ;输入字符的纵坐标
    MIN db 0 
    SEC db 0
    MSEC db 0
ends

stack segment
    dw   128  dup(0)
ends

code segment
start:
; set segment registers:
    mov ax, data
    mov ds, ax
    mov es, ax

    ; add your code here
    begin:
    ;初始化
    scroll 0,7,0,0,30,79,02  ;清屏
    scroll 25,7,1,10,26,52,0b7h  ;开外窗口
    scroll 20,7,4,12,24,50,7bh   ;开内窗口
    print DELIMITER,1,16
    print WELCOME,2,18    
    print INPUT_EXIT_TIP,3,20
    mov si,0
    mov ROW,4
    mov RIGHT_NUM,0
    
    mov ch,0
    again:       ;遍历每行
    curse ROW,25
    mov bx,QUIZ[si]
    mov dx,bx
    mov ah,09h
    int 21h   
    inc ROW
    curse ROW,25
    mov dh,ROW
    mov X,dh
    mov Y,25
    
    mov cl,0   
    input:       ;字符输入
    mov ah,0
    int 16h
    cmp al,1bh
    jne next2
    jmp inputesc   ;输入Esc,打开退出提示窗口
    next2:
    cmp X,5
    jnz next:
    cmp Y,25
    jnz next
    call starttime   ;检测到第一个字符输入时打开计时器
    next:
    mov dl,[bx]
    mov CUR_W,dl
    mov CUR_I,al
    call compare   ;校对
    inc cl
    inc bx 
    inc Y
    cmp cl,10
    jnz input
       
    add si,2
    inc ROW
    inc ch
    cmp ch,10
    jnz again
    
    end:
    call endtime
    scroll 0,7,10,20,20,42,0b7h
    scroll 10,7,10,20,20,42,0b7h
    print TIME_TIP,11,25
    curse 12,25
    call showtime
    print SCORE_TIP,14,25
    curse 15,25
    call showscore
    mov ah,9
    mov dx,offset SUM
    int 21h
    print RESTART_TIP,17,23
    print EXIT_TIP,18,26
    mov ah,0
    int 16h
    cmp al,1bh
    jne begin
    
    finish:
    mov ax, 4c00h ; exit to operating system.
    int 21h
               
    inputesc:
    scroll 10,7,10,20,20,42,0b7h
    print COMFIRM_EXIT,12,22
    print COMFIRM_EXIT_TIP,13,22
    print COMFIRM_EXIT_YES,15,23
    print COMFIRM_EXIT_NO,16,23
    curse 17,23
    mov ah,0
    int 16h
    cmp al,1bh
    jne finish
    curse X,Y
    scroll 0,7,10,20,20,42,7bh
    jmp input
   
    compare proc   ;校对输入是否正确
      push ax
      push bx
      push cx
      push dx
      push es
      push si
      push di
      mov ch,CUR_W
      mov cl,CUR_I
      cmp ch,cl
      jz right:
      jnz wrong:
      return:
      pop di
      pop si
      pop es
      pop dx
      pop cx
      pop bx
      pop ax
      ret
      right:
      mov dl,RIGHT_NUM
      inc dl
      mov RIGHT_NUM,dl
      scroll 20,7,X,Y,X,Y,7ah
      mov dl,CUR_I
      mov ah,2
      int 21h
      jmp return
      wrong:
      scroll 20,7,X,Y,X,Y,7ch
      mov dl,CUR_I
      mov ah,2
      int 21h
      jmp return
    compare endp
    
    
    starttime proc  ;打开计时器
      push ax
      push bx
      push cx
      push dx
      mov ah,2ch
      int 21h
      mov MIN,cl
      mov SEC,dh
      mov MSEC,dl
      pop dx
      pop cx
      pop bx
      pop ax
      ret
    starttime endp
    
    endtime proc   ;关闭计时器并计算用时
      push ax
      push bx
      push cx
      push dx
      mov ah,2ch
      int 21h
      cmp dl,MSEC
      jge n1
      add dl,100
      sub dh,1
      n1:
      sub dl,MSEC
      mov MSEC,dl
      cmp dh,SEC
      jge n2
      add dh,60
      sub cl,1
      n2:
      sub dh,MSEC
      mov MSEC,dh
      cmp cl,min
      jge n3
      add cl,60
      sub ch,1
      n3:
      sub cl,min
      mov min,cl
      pop dx
      pop cx
      pop bx
      pop ax
      ret
    endtime endp
    
    showtime proc     ;显示用时
      push ax
      push bx
      push cx
      push dx
      mov ah,0
      mov al,MIN
      call bin2ascii
      mov al,':'
      mov ah,0eh
      int 10h 
      mov ah,0
      mov al,SEC
      call bin2ascii
      mov al,':'
      mov ah,0eh
      int 10h  
      mov ah,0
      mov al,MSEC
      call bin2ascii
      pop dx
      pop cx
      pop bx
      pop ax
      ret
    showtime endp
    
    showscore proc   ;显示成绩
      push ax
      push bx
      push cx
      push dx      
      mov ah,0
      mov al,RIGHT_NUM
      call bin2ascii    
      pop dx
      pop cx
      pop bx
      pop ax
      ret
    showscore endp
    
    bin2ascii proc  ;将二进制转换成ASCII码输出，调用al寄存器传参
      mov cx,100
      call transform
      mov cx,10
      call transform
      mov cx,1
      call transform
      ret
    bin2ascii endp
    
    transform proc
      mov dx,0
      div cx
      add al,30h
      mov ah,0eh
      int 10h
      mov ax,dx
      ret
    transfrom proc

ends

end start ; set entry point and stop the assembler.
