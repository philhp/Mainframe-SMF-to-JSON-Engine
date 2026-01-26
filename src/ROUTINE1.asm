* --- Définition des registres ---
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15

ROUTINE1 CSECT               
         BAKR  R14,0         
         LR    R12,R15        
         USING ROUTINE1,R12

         WTO   'STRATING...' Write To Operator

         L     R3,16(0,0)  
         L     R3,196(0,R3)         deplacement(index,base) 
         MVC   SYSNM(4),16(R3)      Move: Destination(Longueur), Source

         WTO   'ID (SMCA) :' Write To Operator
         LA    R1,WTOLIST             Load Address
         SVC   35

         PR


         DS    0F       --Aligne
WTOLIST  DC    AL2(8)
         DC    XL2'0000'
SYSNM    DC    CL4' '

         END
