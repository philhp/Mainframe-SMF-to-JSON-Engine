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

PROC_102 CSECT
         IFASMFR (30)   * SMF Records structs
         DSNDQWHS       * SMF Header Standard structs
         DSNDQWHC       * SMF Header Correlation structs         
         DSNDQW01
PROC_102 CSECT
         BAKR  R14,0         
         LR    R12,R15        
         USING PROC_102,R12

* --- R1 = adress to PARMLIST
         L     R2,0(,R1)       * get ADDR_SMF

         OPEN  (SNAPDCB,OUTPUT)   

* Reading the self-defining section for variable-length data items
START102 LA    R1,28(,R2)   * ???? 1st : always Product section
         L     R3,0(,R1)    * ???? R3=OFFSET of QWHS
         ALR   R3,R2        * ???? R3=Product Section
* --- Header Correlation         
         USING QWHS,R3   

         LH    R1,QWHSIID     * Load IFCID
         CVD   R1,DOUBLE      * convert R5 to decimal packed
         UNPK  IFCIJSON(3),DOUBLE+6(2)
         OI    IFCIJSON+2,X'F0'  * Sign correction
         LA    R1,IFCIWTO           Load Address
         SVC   35


         WTO   'ROUTINE PROC_102 !'

         LR    R4,R3
         LLGH  R3,0(,R2)       * R3=(R1) en 16bits no signed
         AR    R3,R2           * R3 = Adresse de fin
         SNAP  DCB=SNAPDCB,ID=50,PDATA=REGS,STORAGE=((R2),(R3))    

         CLOSE (SNAPDCB)

         PR

* --- DATA Zone ---
         DS    0D                * 64bits align
CPUBIN   DS    D                 * Zone de 8 octets (Doubleword)         
DOUBLE   DS    D

IFCIWTO  DC    AL2(IFCIEND-IFCIWTO)
         DC    XL2'0000'
         DC    C'"db2_ifcid": "'
IFCIJSON DC    CL3'   '         
         DC    C'",'
IFCIEND  EQU   *


         DS    0F       --Aligne
* Warning : comma to cols number 72 
SNAPDCB  DCB   DSORG=PS,MACRF=(W),DDNAME=SNAP,RECFM=VBA,               X
               LRECL=125,BLKSIZE=882         
         END
         