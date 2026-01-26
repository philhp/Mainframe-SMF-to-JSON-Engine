//SMFEXTRT JOB (DBA),'SMF EXTRACT',CLASS=A,MSGCLASS=X
//*
//*-------------------------------------------------------------------*
//* SUMMARY: SMF DATA EXTRACTION UTILITY                              *
//* PURPOSE: EXTRACT SPECIFIC SMF RECORDS (ex: 30, 101) FROM SYSTEM       *
//* MAN DATASETS TO A FLAT FILE FOR JSON PROCESSING.         *
//*-------------------------------------------------------------------*
//* CONFIGURATION
//*-------------------------------------------------------------------*
// SET OUTFILE='IBMUSER.SMF.OUT'
// SET MAN='SYS1.MAN2'
//*-------------------------------------------------------------------*
//* STEP 0: CLEANUP PREVIOUS OUTPUT FILE
//*-------------------------------------------------------------------*
//DEL      EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE &OUTFILE
  SET MAXCC = 0
/*
//*-------------------------------------------------------------------*
//* STEP 1: DUMP AND FILTER SMF RECORDS
//*-------------------------------------------------------------------*
//STEP1    EXEC PGM=IFASMFDP
//DUMPIN   DD  DISP=SHR,DSN=&MAN
//DUMPOUT  DD  DSN=&OUTFILE,DISP=(NEW,CATLG),UNIT=SYSDA,
//             SPACE=(CYL,(10,10),RLSE),
//             DCB=(RECFM=VBS,LRECL=32760)
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
  INDD(DUMPIN,OPTIONS(DUMP))
  OUTDD(DUMPOUT,TYPE(30,101))
/*