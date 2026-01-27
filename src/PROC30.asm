* --- Register definitions ---
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
         IFASMFR (30)   * SMF Records structs
PROC_30  CSECT
         BAKR  R14,0         
         LR    R12,R15        
         USING PROC_30,R12

* --- R1 = adress to PARMLIST
         L     R2,0(,R1)       * get ADDR_SMF

         OPEN  (SNAPDCB,OUTPUT)   


         WTO   'ROUTINE PROC_30 !'

         LLGH  R3,0(,R2)       * R3=(R1) en 16bits no signed
         AR    R3,R2           * R3 = Adresse de fin
         SNAP  DCB=SNAPDCB,ID=50,PDATA=REGS,STORAGE=((R2),(R3))    

         CLOSE (SNAPDCB)

         PR

         DS    0F       --Aligne
* Warning : comma to cols number 72 
SNAPDCB  DCB   DSORG=PS,MACRF=(W),DDNAME=SNAP,RECFM=VBA,               X
               LRECL=125,BLKSIZE=882         
         END
         