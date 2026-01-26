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

PROC_101 CSECT   
*         IFASMFR (30)
* --- 1. MAPPING OFFICIEL DB2 ---
         IFASMFR (30)   *structures de base communes aux records SMF
         DSNDQWHS
         DSNDQWHC    
         DSNDQWAC
*DSNB10.SDSNMACS         

PROC_101 CSECT
         BAKR  R14,0         
         LR    R12,R15        
         USING PROC_101,R12

* --- DUMMY SECTION ---
*JSON_MAP DSECT               
*         COPY  MAPJSON       
*PROC_101 CSECT              
* -------------------------

* --- R1 = adresse vers PARMLIST
         L     R2,0(,R1)       * récupère ADDR_SMF
*         L     R4,4(,R1)        * récupère JSON_REC
*         USING JSON_MAP,R4

         OPEN  (SNAPDCB,OUTPUT)

* --- 1. TEST SUBTYPE AND EXTENDED HEADER FOR TYPE 101
*         TM    4(R2),X'04'      * Test du bit 3 : Extended Header ?
*         BNO   NOT_EXT          * Si le bit n'est pas à 1 
*         WTO   '-'
*         B     CHECKSUB
         
*NOT_EXT  WTO   '-'

*CHECKSUB TM    4(R2),X'02'      * Test du bit 2 : Subtypes present ?
*         BNO   NOTSUB          * Si le bit n'est pas à 1
*         WTO   ' '
*         B     STARTDB2
*NOTSUB   WTO   '-'



* --- IF NO SUBTYPE : PayLoad at Offset+18
* --- IF SUBTYPE : PayLoad at Offset+24 (add SMFHDR_WID + SMFHDR_STP)
* --- IF EXTENDED FOR DB2 trace : 
* Offset 18 SMFHDR_WID : Subsystem identification
* Offset 22 STF : Reserved
* Offset 23 RI : Reserved
* Offset 24 SEQ : Compression information
*
* --- Start Self definition section
* --- Triplette  (32bits),Length (16bits),Nb of time(16bits)
* Offest 28 Pointer to product section : 4 bytes
* Offest 32 Length of product section : 2 bytes
* Offset 34 1 bytes =0x01 if section exist 
*
* --- Start Product section Header Standard (QWHS)
* Offset 36 Offest Pointer to data section #1
*
* --- Start Accounting Control (QWAC)


* --- ACTIVATION DES CALQUES ---


* Extended: Les triplettes commencent après le header de 36 octets
STARTDB2 LA    R1,28(,R2)   * 1er triplette : Product section
         L     R3,0(,R1)    * R3=OFFSET of QWHS
         ALR   R3,R2
* --- Header Correlation         
         USING QWHS,R3      * Calque officiel DB2 pour le head

         LH    R1,QWHSIID     * Charge l'IFCID
         CVD   R1,DOUBLE      *convert R5 to decimal packed
         UNPK  IFCIJSON(3),DOUBLE+6(2)
         OI    IFCIJSON+2,X'F0'  * Sign correction
         LA    R1,IFCIWTO           Load Address
         SVC   35
*         LA    R4,QWHSSSID

*         MVC   SIID(4),QWHSSSID     Move: Destination(Longueur), Src
*         MVC   J_SSID,QWHSSSID
*         LA    R1,WTOSIID           Load Address
*         SVC   35

* --- Affichage Hexa simplifié ---
         L     R1,QWHSISEQ         * Charge la séquence (ex: 0000000A)
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5) 
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   SEQJSON(8),HEXWORK    * Copie les 8 digits dans le WTO
         LA    R1,SEQWTO            * Adresse du WTO pour la séquence
         SVC   35

         MVC   LOCJSON(16),QWHSLOCN * Copy 16 butes to WTO zone
         LA    R1,LOCWTO        * Adresse du bloc message
         SVC   35               * Write To Operator

         MVC   NETDJSON(8),QWHSNID     * NetworkID ex: "NETD    "
         LA    R1,NETDWTO        * Adresse du bloc message
         SVC   35               * Write To Operator

         MVC   LUJSON(8),QWHSLUNM   * LU LogicalUnit Name "DBBGLU1 "
         LA    R1,LUWTO        * Adresse du bloc message
         SVC   35               * Write To Operator

         LH    R1,QWHSLEN       * Charge la longueur (2 octets) dans R4
         AR    R3,R1            * Ajoute cette longueur à l'adresse de base R3

* --- Header Correlation
         USING QWHC,R3      * Calque officiel DB2 pour le head

         MVC   CONNJSON(8),QWHCCN  * Connexion Name
         LA    R1,CONNWTO    
         SVC   35              
         MVC   PLANJSON(8),QWHCPLAN  * Plan Name
         LA    R1,PLANWTO    
         SVC   35   

* --- Extraction de l'Auth ID (User) ---
         MVC   AUTHJSON(8),QWHCAID    * Copie les 8 octets de l'UserID
         LA    R1,AUTHWTO           * Prépare le WTO
         SVC   35
         
* --- Extraction du Correlation ID (Job Name / TSO ID) ---
         MVC   CORRJSON(8),QWHCCV    * Copie les 12 octets (Job/Task)
         LA    R1,CORRWTO           * Prépare le WTO
         SVC   35
 
* --- Extraction de l'User ID Distant (16 octets) ---
         MVC   EUSRJSON(8),QWHCEUID    * Copie l'ID utilisateur final
         LA    R1,EUSRWTO           * Prépare le WTO
         SVC   35



* --- 2eme triplette
         LA    R1,36(,R2)   * 2eme triplette : Accounting sec
         L     R3,0(,R1)    * R3=OFFSET of QWAC
         ALR   R3,R2
* --- Header Accounting         
         USING QWAC,R3      * Calque officiel DB2 pour le head

* --- Extraction du temps CPU (Classe 1) ---
         MVC   CPUBIN(8),QWACAJST     * Copie les 8 octets du STCK
* --- Conversion des 4 premiers octets (les plus significatifs) ---
         L     R1,CPUBIN            * Charge les 4 premiers octets
         ST    R1,TEMPVAL           * Stocke pour conversion
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   CPUJSON(8),HEXWORK
* --- Conversion des 4 octets suivants ---
         L     R1,CPUBIN+4          * Charge les 4 octets de droite
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   CPUJSON2(8),HEXWORK

* --- Envoi à la console ---
         LA    R1,CPUWTO
         SVC   35

* --- Extraction de l'ELAPSED TIME ---
         MVC   CPUBIN(8),QWACASC   
* --- Conversion simple des 4 octets du milieu (plus lisible) ---
         L     R1,CPUBIN           * Partie haute
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   ELAPJSON(8),HEXWORK
* --- Conversion simple des 4 octets de droit---
         L     R1,CPUBIN+4           * Partie basse
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   ELAJSON2(8),HEXWORK         
* --- Envoi à la console ---
         LA    R1,ELAPWTO
         SVC   35

* 1. Extraction du TEMPS DE LATCH (QWACAWLH - 8 octets)
         MVC   CPUBIN(8),QWACAWLH   * On récupère le STCK
* --- Conversion simple des 4 octets poids fort
         L     R1,CPUBIN            * On prend la partie haute
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   WAITJSON(8),HEXWORK   * Vers le WTO
* --- Conversion simple des 4 octets poids faible
         L     R1,CPUBIN+4           * Partie basse
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   WAIJSON2(8),HEXWORK   
* --- Envoi à la console ---
         LA    R1,WAITWTO
         SVC   35


* 1. Extraction du TEMPS DE LATCH (QWACAWLH - 8 octets)
         MVC   CPUBIN(8),QWACAWTI   * On récupère le STCK
* --- Conversion simple des 4 octets poids fort
         L     R1,CPUBIN            * On prend la partie haute
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   IOJSON(8),HEXWORK   * Vers le WTO
* --- Conversion simple des 4 octets poids faible
         L     R1,CPUBIN+4           * Partie basse
         ST    R1,TEMPVAL
         UNPK  HEXWORK(9),TEMPVAL(5)
         NC    HEXWORK(8),MASK0F
         TR    HEXWORK(8),HEXTAB
         MVC   IOSON2(8),HEXWORK   
* --- Envoi à la console ---
         LA    R1,IOWTO
         SVC   35




         LLGH  R3,0(,R2)           * R3=(R1) en 16bits non signé
         AR    R3,R2               * R3 = Adresse de fin
         SNAP  DCB=SNAPDCB,ID=50,PDATA=REGS,STORAGE=((R2),(R3))        




         CLOSE (SNAPDCB)
         PR

* --- Zone de données de la routine ---
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
CPUJSON2 DC    CL8' '               * Partie basse du STCK         
         DC    C'",'
CPUEND   EQU   *

ELAPWTO  DC    AL2(ELAPEND-ELAPWTO)
         DC    XL2'0000'
         DC    C'"db2_class2_elapsed_time": "'
ELAPJSON DC    CL8'        '
         DC    C'-'
ELAJSON2 DC    CL8' '               * Partie basse du STCK         
         DC    C'",'
ELAPEND  EQU   *

WAITWTO  DC    AL2(WAITEND-WAITWTO)
         DC    XL2'0000'
         DC    C'"db2_latch_wait_time": "'
WAITJSON DC    CL8'        '
         DC    C'-'
WAIJSON2 DC    CL8' '               * Partie basse du STCK         
         DC    C'",'
WAITEND  EQU   *

IOWTO    DC    AL2(IOEND-IOWTO)
         DC    XL2'0000'
         DC    C'"db2_io_wait_time": "'
IOJSON   DC    CL8'        '
         DC    C'-'
IOSON2   DC    CL8' '               * Partie basse du STCK         
         DC    C'" },'
IOEND    EQU   *









         DS    0F
WTOSIID  DC    AL2(14)          * total length (4+6+4 )
         DC    XL2'0000'        * MCS Flags
         DC    C'SSID: '        * Label
SIID     DC    CL4' '           * SSID string (ex: DDBG)



TEMPVAL  DS    F                    * Stockage temporaire 32 bits
HEXWORK  DS    CL9                  * Zone de travail pour UNPK

* --- For Bin/Hexa convertion
MASK0F   DC    8X'0F'               * 8 octets de 0F
HEXTAB   DC    C'0123456789ABCDEF'  * Ta table de traduction

         DS    0F       --Aligne
* --- LA DEFINITION DU DCB POUR LE SNAP (OBLIGATOIRE) ---
* Attention : La virgule en fin de ligne et le 'X' en colonne 72
SNAPDCB  DCB   DSORG=PS,MACRF=(W),DDNAME=SNAP,RECFM=VBA,               X
               LRECL=125,BLKSIZE=882

         END
