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

PROC_30  CSECT
         BAKR  R14,0         
         LR    R12,R15        
         USING PROC_30,R12
* --- R1 = (Offset +18)
         L     R4,18(,R1)     


         WTO   'ROUTINE PROC_30 !!!!' Write To Operator

         PR
         END
         