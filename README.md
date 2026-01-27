# Mainframe-SMF-to-JSON-Engine

A high-performance z/OS HLASM (High Level Assembler) engine designed to parse raw System Management Facilities (SMF) records and convert them into standardized, analytics-ready JSON.

## Overview
System Management Facilities (SMF) provide a massive amount of data regarding z/OS health and performance. However, raw SMF records are stored in complex, binary, variable-length formats (triplets/offsets) that are difficult for modern analytics platforms to ingest.

Mainframe-SMF-to-JSON-Engine bridges this gap. Built in HLASM for maximum speed and minimal CPU overhead, it transforms these records into clean, flat or nested JSON objects.

## Key Features
- Lightning Fast: Written in pure Assembly to process millions of records with near-zero latency.
- CDP Normalized: JSON keys follow the IBM Common Data Provider (CDP) standard for immediate integration.
- Modular Architecture: Features a central dispatcher with pluggable procedures (PROC_XXX) for different SMF types.
- Cloud Ready: Produces valid JSON output suitable for ingestion into AWS, Azure, or GCP data lakes.

## Sample JSON Output
```json
[ { "record_type": "101",
 "system_id": "PROD",
 "date": "26.016",
 "time": "17:32:03",
 "db2_ifcid": "003",
 "db2_sequence_number": "000008B6",
 "db2_location_name": "DALLASB         ",
 "db2_net_id": "NETD    ",
 "db2_lu_name": "DBBGLU1 ",
 "db2_connection_name": "DB2CALL ",
 "db2_plan_name": "QMF11   ",
 "db2_auth_id": "IBMUSER ",
 "db2_correlation_id": "IBMUSER ",
 "db2_end_user_id": "IBMUSER ",
 "db2_class2_cpu_time": "00000000-04375000",
 "db2_class2_elapsed_time": "00000000-04B159AC",
 "db2_latch_wait_time": "00000000-00000000",
 "db2_io_wait_time": "00000000-00000000" },
 { "record_type": "101",
 "system_id": "PROD",
 "date": "26.016",
 "time": "17:32:13",
 "db2_ifcid": "003",
 "db2_sequence_number": "000008B7",
 "db2_location_name": "DALLASB         ",
 "db2_net_id": "NETD    ",
 "db2_lu_name": "DBBGLU1 ",
 "db2_connection_name": "DB2CALL ",
 "db2_plan_name": "QMF11   ",
 "db2_auth_id": "IBMUSER ",
 "db2_correlation_id": "IBMUSER ",
 "db2_end_user_id": "IBMUSER ",
 "db2_class2_cpu_time": "00000000-04E064C8",
 "db2_class2_elapsed_time": "00000000-059AA844",
 "db2_latch_wait_time": "00000000-00000000",
 "db2_io_wait_time": "00000000-00000000" },
 { "record_type": "101",
 "system_id": "PROD",
 "date": "26.016",
 "time": "17:32:15",
 "db2_ifcid": "003",
 "db2_sequence_number": "000008B8",
 "db2_location_name": "DALLASB         ",
 "db2_net_id": "NETD    ",
 "db2_lu_name": "DBBGLU1 ",
 "db2_connection_name": "DB2CALL ",
 "db2_plan_name": "QMF11   ",
 "db2_auth_id": "IBMUSER ",
 "db2_correlation_id": "IBMUSER ",
 "db2_end_user_id": "IBMUSER ",
 "db2_class2_cpu_time": "00000000-00EED808",
 "db2_class2_elapsed_time": "00000000-012FC0A9",
 "db2_latch_wait_time": "00000000-00000000",
 "db2_io_wait_time": "00000000-00000000" } ]
```

## Technical Implementation
The engine utilizes z/OS system macros to map binary structures:

- DSNDQWHS: Standard Header Identification
- DSNDQWHC: Correlation Header (Plan, AuthID, Connection)
- DSNDQWAC: Accounting Class 2 (CPU and Elapsed times)

# Prerequisites
z/OS Environment with HLASM compiler.

SMF Data: A dumped SMF dataset.

# Quick Start
Follow these steps to deploy and run the SMF-to-JSON engine on your system.

1. Configuration

   Open the JCL located in jcl/SMF2JSON.jcl and customize the SET symbols at the top of the job:
   ```jcl
   // SET SRC='USER.SRC'         <-- Source PDS (.asm files)
   // SET SMFIN='USER.SMF.FILE'  <-- INPUT: Your raw SMF dump file   
   // SET OBJ='USER.OBJ'         <-- OUTPUT : intermediate object modules
   // SET LOAD='USER.LOAD'       <-- OUTPUT: Executable library
   ```
   You should have an existing SRC, OBJ, and LOAD PDS (e.g., USER.SRC, USER.OBJ, USER.LOAD)

2. Build & Run

   Submit the JCL to compile all modules (PROC101, PROC30, HPSMF), link-edit them, and execute the engine:

   Command: SUBMIT 'YOUR.PREFIX.JCL(SMF2JSON)'

   Check Results:
   Ensure all steps finished with RC=0000 or RC=0004.

   The JSON output will be available in the JSONOUT DD (either directed to SYSOUT or the dataset defined in the configuration).


