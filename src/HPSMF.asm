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
*
* COL 1  COL10 COL 16                                          COL 72
*        |     |                                               |
START    CSECT
         IFASMFR (30)      * SMF Records structs
START    CSECT

         BAKR  R14,0        Branch And StacK Register(PUSH ALL)
         LR    R12,R15
         USING START,R12

* --- External subroutines declaration ---
         EXTRN PROC_101
         EXTRN PROC_30         

         OPEN  (SMFFILE,INPUT)

         WTO   '[ '

LOOP     GET   SMFFILE            * Open SMF File
         LR    R2,R1              * Save RDW

         USING SMF30RHD,R2

* --- Reading SMF Type : RTY (Offset +5, size 1) ---
         SR    R4,R4             * Clean R4
         IC    R4,SMF30RTY      * Use SMF30RTY macro (Offset+5)

         CLI   SMF30RTY,101        
         BE    ANALYSE
         CLI   SMF30RTY,30        
         BE    ANALYSE
         B     LOOP              *Skip all records expect 101 and 30

ANALYSE  DS    0H

* --- EBCDIC Convertion to decimal       
* --- Ex: If R4 = X'65', DOUBLE will contain X'000000000000101C
         CVD   R4,DOUBLE           * Binary (R4) -> Packed Decimal
         UNPK  RTYJSON(3),DOUBLE+6(2)
         OI    RTYJSON+2,X'F0'

* --- Date formatting and conversion ---
* Format SMF : [CC][YY][DD][DF] -> 4 bytes packés CC:Century
         UNPK  DOUBLE(7),SMF30DTE
* Résult on DOUBLE : F0 F0 FY FY FD FD FD CF ( C is the signe )
         
         MVC   DATEJSON(2),DOUBLE+2   * Store Year (YY)
         MVI   DATEJSON+2,C'.'        * Store decimal point "."
         MVC   DATEJSON+3(3),DOUBLE+4 * Store day : 3 digits

* --- Time formatting and conversion ---
         L     R5,SMF30TME         * Load time (binary)
         SR    R4,R4               * Clear R4 for R4-R5 division pair
* --- Clear Hundredths ---
         L     R9,=F'100'          * Divisor
         DR    R4,R9               * R5 = seconds, R4 = Hundredths
* --- Extract seconds ---
         SR    R4,R4               * Clear R4 for division
         L     R9,=F'60'
         DR    R4,R9               * R5 = Total minutes, R4 = seconds
         CVD   R4,DOUBLE           * Convert seconds to packed
         UNPK  TIMEJSON+6(2),DOUBLE+6(2) 
         OI    TIMEJSON+7,X'F0'
* --- Extract Minutes and Hours ---
         SR    R4,R4
         DR    R4,R9               * R5 = Hours, R4 = Minutes
         
         CVD   R4,DOUBLE           
         UNPK  TIMEJSON+3(2),DOUBLE+6(2) 
         OI    TIMEJSON+4,X'F0'
         
         CVD   R5,DOUBLE           
         UNPK  TIMEJSON(2),DOUBLE+6(2) 
         OI    TIMEJSON+1,X'F0'         

* --- Extract SID (Offset +14) ---

         MVC   SIDJSON,SMF30SID
* --- SHOW JSON ---
         LA    R1,RTYWTO      
         SVC   35               
         LA    R1,SIDWTO     
         SVC   35             
         LA    R1,DATEWTO     
         SVC   35               
         LA    R1,TIMEWTO     
         SVC   35        

* --- Dispatching to routines ---
         LR    R1,R2
         CLI   5(R1),X'65'         * Type 101 ?
         BNE   NO_101

         ST    R2,ADDR_SMF         * Store SMF record pointer
*         ST    R3,ADDR_JSN        * Store another pointer      
         LA    R1,PARMLIST         * R1 : List pointer for subroutine

         L     R15,=V(PROC_101)    * Call SUBROUTINE, R1:list pointer
         BASR  R14,R15     
         B     LOOP          

NO_101   CLI   5(R1),X'1E'         * Type 30 ?
         BNE   NO_30
         ST    R2,ADDR_SMF         * Store SMF record pointer
         LA    R1,PARMLIST         * R1 : List pointer for subroutine

         L     R15,=V(PROC_30)     * Call SUBROUTINE, R1:list pointer
         BASR  R14,R15    
         B     LOOP          

         

NO_30    WTO   '}, '

         B     LOOP
         

EOF      CLOSE (SMFFILE)


         WTO   '] '

         PR

         LTORG

PARMLIST DS    0F                  * Start of List pointer
ADDR_SMF DS    A                   * SMF pointer
ADDR_JSN DS    A                   * Another pointer

         DS    0D                  * Doubleword alignment : 64bits
DOUBLE   DS    D

         DS    0F                  * Fullword alignment : 32 bits
RTYWTO   DC    AL2(RTYEND-RTYWTO)
         DC    XL2'0000'
         DC    C'{ "record_type": "'
RTYJSON  DC    CL3'   '         
         DC    C'",'
RTYEND   EQU   *         
SIDWTO   DC    AL2(SIDEND-SIDWTO)
         DC    XL2'0000'
         DC    C'"system_id": "'
SIDJSON  DC    CL4'    '         
         DC    C'",'
SIDEND   EQU   *
DATEWTO  DC    AL2(DATEEND-DATEWTO)
         DC    XL2'0000'
         DC    C'"date": "'
DATEJSON DC    CL6'      '         
         DC    C'",'
DATEEND  EQU   *
TIMEWTO  DC    AL2(TIMEEND-TIMEWTO)
         DC    XL2'0000'
         DC    C'"time": "'
TIMEJSON DC    CL8'HH:MM:SS'         
         DC    C'",'
TIMEEND  EQU   *
      
         DS    0F                 * Fullword alignment : 32 bits

* --- Définitions des zones ---
SMFFILE  DCB   DDNAME=SMFFILE,                                         X
               DSORG=PS,                                               X
               MACRF=GL,                                               X
               EODAD=EOF


         END   START
