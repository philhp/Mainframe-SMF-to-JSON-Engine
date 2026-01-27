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

PROC_101 CSECT   
*         IFASMFR (30)
* --- 1. MAPPING OFFICIEL DB2 ---
         IFASMFR (30)   * SMF Records structs
         DSNDQWHS       * SMF Header Standard structs
         DSNDQWHC       * SMF Header Correlation structs
         DSNDQWAC       * SMF Accounting structs
        
PROC_101 CSECT
         BAKR  R14,0         
         LR    R12,R15        
         USING PROC_101,R12


* --- R1 = adress to PARMLIST
         L     R2,0(,R1)       * get ADDR_SMF

         OPEN  (SNAPDCB,OUTPUT)

* --- 1. SELF DEFINING SECTION FOR VARIABLE LENGTH DATA ITEMS

* Reading the self-defining section for variable-length data items
STARTDB2 LA    R1,28(,R2)   * 1st : always Product section
         L     R3,0(,R1)    * R3=OFFSET of QWHS
         ALR   R3,R2        * R3=Product Section
* --- Header Correlation         
         USING QWHS,R3      

         LH    R1,QWHSIID     * Load IFCID
         CVD   R1,DOUBLE      * convert R5 to decimal packed
         UNPK  IFCIJSON(3),DOUBLE+6(2)
         OI    IFCIJSON+2,X'F0'  * Sign correction
         LA    R1,IFCIWTO           Load Address
         SVC   35


* --- Show Hexadecimal ---
         L     R1,QWHSISEQ         * Load Sequence
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5) 
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   SEQJSON(8),HEXWORK    * Copy 8 digits to WTO
         LA    R1,SEQWTO            
         SVC   35

         MVC   LOCJSON(16),QWHSLOCN * Copy 16 bytes to WTO zone
         LA    R1,LOCWTO        
         SVC   35               

         MVC   NETDJSON(8),QWHSNID     * NetworkID ex: "NETD    "
         LA    R1,NETDWTO        
         SVC   35              

         MVC   LUJSON(8),QWHSLUNM   * LU LogicalUnit ex : "DBBGLU1 "
         LA    R1,LUWTO        
         SVC   35               

         LH    R1,QWHSLEN    * Load lenght to R4
         AR    R3,R1         * Add to R3

* --- Header Correlation
         USING QWHC,R3      

         MVC   CONNJSON(8),QWHCCN  * Connexion Name
         LA    R1,CONNWTO    
         SVC   35              
         MVC   PLANJSON(8),QWHCPLAN  * Plan Name
         LA    R1,PLANWTO    
         SVC   35   

* --- Extraction of Auth ID (User) ---
         MVC   AUTHJSON(8),QWHCAID    
         LA    R1,AUTHWTO           
         SVC   35
         
* --- Extraction of Correlation ID (Job Name / TSO ID) ---
         MVC   CORRJSON(8),QWHCCV    
         LA    R1,CORRWTO           
         SVC   35
 
* --- Extraction de l'User ID Distant (16 octets) ---
         MVC   EUSRJSON(8),QWHCEUID    
         LA    R1,EUSRWTO          
         SVC   35


* --- 2. 2nd DATA SECTION OF SELF DEFINING SECTION

         LA    R1,36(,R2)   * 2nd data section : Accounting sec
         L     R3,0(,R1)    * R3=OFFSET of QWAC
         ALR   R3,R2
* --- Header Accounting         
         USING QWAC,R3      

* --- Extraction CPU time ---
         MVC   CPUBIN(8),QWACAJST     
* --- Conversion of Most Significant Bytes (MSB) ---
         L     R1,CPUBIN            
         ST    R1,TEMPVAL           
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   CPUJSON(8),HEXWORK
* --- Conversion of Less Significant Bytes (LSB) ---
         L     R1,CPUBIN+4          
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   CPUJSON2(8),HEXWORK

         LA    R1,CPUWTO
         SVC   35

* --- ELAPSED TIME Extraction ---
         MVC   CPUBIN(8),QWACASC   
* --- Conversion of Most Significant Bytes (MSB) ---
         L     R1,CPUBIN           
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   ELAPJSON(8),HEXWORK
* --- Conversion of Less Significant Bytes (LSB) ---
         L     R1,CPUBIN+4           
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   ELAJSON2(8),HEXWORK         

         LA    R1,ELAPWTO
         SVC   35

* --- LATCH TIME Extraction 
         MVC   CPUBIN(8),QWACAWLH   
* --- Conversion of Most Significant Bytes (MSB) ---
         L     R1,CPUBIN            
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   WAITJSON(8),HEXWORK   
* --- Conversion of Less Significant Bytes (LSB) ---
         L     R1,CPUBIN+4           
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   WAIJSON2(8),HEXWORK   

         LA    R1,WAITWTO
         SVC   35


* --- LATCH TIME Extraction 
         MVC   CPUBIN(8),QWACAWTI   
* --- Conversion of Most Significant Bytes (MSB) ---
         L     R1,CPUBIN            
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   IOJSON(8),HEXWORK   
* --- Conversion of Less Significant Bytes (LSB) ---
         L     R1,CPUBIN+4           
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   IOSON2(8),HEXWORK   

         LA    R1,IOWTO
         SVC   35




*         LLGH  R3,0(,R2)       * R3=(R1) en 16bits no signed
*         AR    R3,R2           * R3 = Adresse de fin
*         SNAP  DCB=SNAPDCB,ID=50,PDATA=REGS,STORAGE=((R2),(R3))        




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

SEQWTO   DC    AL2(SEQEND-SEQWTO)
         DC    XL2'0000'
         DC    C'"db2_sequence_number": "'
SEQJSON  DC    CL8'        '         
         DC    C'",'
SEQEND   EQU   *

LOCWTO   DC    AL2(LOCEND-LOCWTO)
         DC    XL2'0000'
         DC    C'"db2_location_name": "'
LOCJSON  DC    CL16'                '         
         DC    C'",'
LOCEND   EQU   *

NETDWTO  DC    AL2(NETDEND-NETDWTO)
         DC    XL2'0000'
         DC    C'"db2_net_id": "'
NETDJSON DC    CL8'        '         
         DC    C'",'
NETDEND  EQU   *

LUWTO    DC    AL2(LUEND-LUWTO)
         DC    XL2'0000'
         DC    C'"db2_lu_name": "'
LUJSON   DC    CL8'        '         
         DC    C'",'
LUEND    EQU   *

CONNWTO  DC    AL2(CONNEND-CONNWTO)
         DC    XL2'0000'
         DC    C'"db2_connection_name": "'
CONNJSON DC    CL8'        '         
         DC    C'",'
CONNEND  EQU   *

PLANWTO  DC    AL2(PLANEND-PLANWTO)
         DC    XL2'0000'
         DC    C'"db2_plan_name": "'
PLANJSON DC    CL8'        '         
         DC    C'",'
PLANEND  EQU   *

AUTHWTO  DC    AL2(AUTHEND-AUTHWTO)
         DC    XL2'0000'
         DC    C'"db2_auth_id": "'
AUTHJSON DC    CL8'        '         
         DC    C'",'
AUTHEND  EQU   *

CORRWTO  DC    AL2(CORREND-CORRWTO)
         DC    XL2'0000'
         DC    C'"db2_correlation_id": "'
CORRJSON DC    CL8'        '         
         DC    C'",'
CORREND  EQU   *

EUSRWTO  DC    AL2(EUSREND-EUSRWTO)
         DC    XL2'0000'
         DC    C'"db2_end_user_id": "'
EUSRJSON DC    CL8'        '         
         DC    C'",'
EUSREND  EQU   *

CPUWTO   DC    AL2(CPUEND-CPUWTO)
         DC    XL2'0000'
         DC    C'"db2_class2_cpu_time": "'
CPUJSON  DC    CL8'        '
         DC    C'-'
CPUJSON2 DC    CL8' '                       
         DC    C'",'
CPUEND   EQU   *

ELAPWTO  DC    AL2(ELAPEND-ELAPWTO)
         DC    XL2'0000'
         DC    C'"db2_class2_elapsed_time": "'
ELAPJSON DC    CL8'        '
         DC    C'-'
ELAJSON2 DC    CL8' '                        
         DC    C'",'
ELAPEND  EQU   *

WAITWTO  DC    AL2(WAITEND-WAITWTO)
         DC    XL2'0000'
         DC    C'"db2_latch_wait_time": "'
WAITJSON DC    CL8'        '
         DC    C'-'
WAIJSON2 DC    CL8' '                       
         DC    C'",'
WAITEND  EQU   *

IOWTO    DC    AL2(IOEND-IOWTO)
         DC    XL2'0000'
         DC    C'"db2_io_wait_time": "'
IOJSON   DC    CL8'        '
         DC    C'-'
IOSON2   DC    CL8' '                        
         DC    C'" },'
IOEND    EQU   *



         DS    0F
WTOSIID  DC    AL2(14)          * total length (4+6+4 )
         DC    XL2'0000'        * MCS Flags
         DC    C'SSID: '        * Label
SIID     DC    CL4' '           * SSID string (ex: DDBG)



TEMPVAL  DS    F                    * 32 bits Temp stockage 
HEXWORK  DS    CL9                  * working zone for UNPK

* --- For Bin/Hexa convertion
MASK0F   DC    8X'0F'               * 8 bytes 0x0F
HEXTAB   DC    C'0123456789ABCDEF'  * Convertion table

         DS    0F       --Aligne

* Warning : comma to cols number 72 
SNAPDCB  DCB   DSORG=PS,MACRF=(W),DDNAME=SNAP,RECFM=VBA,               X
               LRECL=125,BLKSIZE=882

         END
