--------------------------------------------------------
--  DDL for Table NFRAW_SPCODES
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."NFRAW_SPCODES" 
   (	"RESEARCH" VARCHAR2(4 BYTE), 
	"SPEC" VARCHAR2(4 BYTE), 
	"COMMON" VARCHAR2(30 BYTE), 
	"SCIENTIF" VARCHAR2(50 BYTE)
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "MFLIB";
 
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "VDC";
 
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "VDC_DEV";
 
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."NFRAW_SPCODES" TO "GREYSONP";
