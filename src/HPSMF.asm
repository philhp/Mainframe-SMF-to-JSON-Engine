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
*
* COL 1  COL10 COL 16                                          COL 72
*        |     |                                               |
START    CSECT
* --- GENERATION DES DSECT SMF ---
         IFASMFR (30)
START    CSECT

         BAKR  R14,0        Branch And StacK Register(PUSH ALL)
         LR    R12,R15
         USING START,R12

* --- 1. Déclarer les routines comme externes ---
         EXTRN PROC_101
         EXTRN PROC_30         



         OPEN  (SMFFILE,INPUT)

          WTO   '[ '

BOUCLE   GET   SMFFILE            * L'adresse du record arrive dans R1
* R1 adresse du RDW
         LR    R2,R1              * On sauve l'adresse de début

* --- NOUVEAU : ACTIVATION DU CALQUE MACRO ---
         USING SMF30RHD,R2       * R2 mappe maintenant le header std

* --- Traitement de RTY (Offset +5, longueur 1) ---
         SR    R4,R4             * Nettoie R4
*         IC    R4,5(,R2)        * Insert Character
         IC    R4,SMF30RTY      * Utilise le label macro (Offset+5)
*-- Convertion au format EBCDIC         
*-- Ex: si R4 = 65h, DOUBLE contiendra 000000000000101C
         CVD   R4,DOUBLE           * Binaire (R4) -> Décimal packé
* -- UNPK Addr cible sur 3 octets max, 
* si DOUBLE = 000000000000101C  DOUBLE+6=01 sur 2 octets soit 0101C
         UNPK  RTYJSON(3),DOUBLE+6(2)
         OI    RTYJSON+2,X'F0'

* --- Traitement de la DATE (Offset +10, longueur 4) ---
* Format SMF : [SS][YY][DD][DF] -> 4 octets packés SS:Siecle
         UNPK  DOUBLE(7),SMF30DTE     * Déballe 4 octets vers 7 octets
* Résultat dans DOUBLE : F0 F0 FY FY FD FD FD CF (Le C final est le signe)
         
         MVC   DATEJSON(2),DOUBLE+2   * On prend l'année (YY)
         MVI   DATEJSON+2,C'.'        * On place le point séparateur
         MVC   DATEJSON+3(3),DOUBLE+4 * On prend les 3 chiffres du jour

* --- Traitement de TIME (Offset +6) ---
         L     R5,SMF30TME         * Charge le binaire (00604A17)
         SR    R4,R4               * Nettoie R4 (Paire R4-R5)
* --- 1. Supprimer les centièmes ---
         L     R9,=F'100'          * Diviseur
         DR    R4,R9               * R5 = secondes, R4 = centièmes
* --- 2. Extraire les Secondes ---
         SR    R4,R4               * On prépare R4 pour la division
         L     R9,=F'60'
         DR    R4,R9               * R5 = minutes totales, R4 = sec
         CVD   R4,DOUBLE           * Convertit secondes en packé
         UNPK  TIMEJSON+6(2),DOUBLE+6(2) * Stocke SS
         OI    TIMEJSON+7,X'F0'
* --- 3. Extraire les Minutes et Heures ---
         SR    R4,R4
         DR    R4,R9               * R5 = Heures, R4 = Minutes <--- !!
         
         CVD   R4,DOUBLE           * Convertit minutes en packé
         UNPK  TIMEJSON+3(2),DOUBLE+6(2) * Stocke MM
         OI    TIMEJSON+4,X'F0'
         
         CVD   R5,DOUBLE           * Convertit heures en packé
         UNPK  TIMEJSON(2),DOUBLE+6(2)   * Stocke HH
         OI    TIMEJSON+1,X'F0'         

* --- Extraction du SID (Offset +14) ---

         MVC   SIDJSON,SMF30SID
* --- AFFICHAGE DU JSON ---
         LA    R1,RTYWTO      * On pointe sur le header du messag
         SVC   35               * Envoi à la console
         LA    R1,SIDWTO      * On pointe sur le header du messag
         SVC   35               * Envoi à la console
         LA    R1,DATEWTO      * On pointe sur le header du messag
         SVC   35               * Envoi à la console
         LA    R1,TIMEWTO      * On pointe sur le header du messag
         SVC   35               * Envoi à la console

* --- Aiguillage vers les routines ---
         LR    R1,R2
         CLI   5(R1),X'65'         * Est-ce du DB2 (101) ?
         BNE   NEXT1

         ST    R2,ADDR_SMF         * adresse du record
*         LA    R3,JSON_REC         * On prend l'adresse de la zone
*         ST    R3,ADDR_JSN         * On la met dans la liste       
         LA    R1,PARMLIST        * R1 pointe sur la liste (Std IBM)

         L     R15,=V(PROC_101)  *CALL SUBROUTINE with R1:Offset
         BASR  R14,R15     * 2. On saute dedans (R14 = retour)
         B     BOUCLE          

NEXT1    CLI   5(R1),X'1E'         * Est-ce JOB (30) ?
         BNE   NEXT2

         L     R15,=V(PROC_30)  *CALL SUBROUTINE with R1:Offset
         BASR  R14,R15     * 2. On saute dedans (R14 = retour)
         B     BOUCLE          

         

NEXT2    WTO   '}, '

         B     BOUCLE
         

EOF      CLOSE (SMFFILE)


         WTO   '] '

         PR

         LTORG

PARMLIST DS    0F                  * Début de la liste
ADDR_SMF DS    A                   * Pointeur vers le Record SMF
ADDR_JSN DS    A                   * Pointeur vers le JSON

         DS    0D       --alignement 64bits le plus strict (8 octets)
DOUBLE   DS    D

         DS    0F                   --alignement 32bits
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



      
         DS    0F       --Aligne

* --- Définitions des zones ---
SMFFILE  DCB   DDNAME=SMFFILE,                                         X
               DSORG=PS,                                               X
               MACRF=GL,                                               X
               EODAD=EOF

* --- STRUCTURE POUR AFFICHER LE JSON ---
*         DS    0F
*WTO_JSON DS    0H
*         DC    AL2(40)   * Longueur (à ajuster selon MAPJSON)
*         DC    XL2'0000'
* --- ZONE DE STOCKAGE JSON ---
*         DS    0D                  * Alignement 64 bits
*JSON_REC EQU   *              * Label pour le début
*         COPY  MAPJSON      * L'assembleur injecte le texte ici

         END   START
