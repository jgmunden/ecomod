--------------------------------------------------------
--  DDL for Table SP_CONVERT
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."SP_CONVERT" 
   (	"LINE_NO" NUMBER, 
	"ITEM" VARCHAR2(20 BYTE), 
	"SPNAME" VARCHAR2(25 BYTE), 
	"CORR_ITEM" VARCHAR2(20 BYTE), 
	"CORR_SPNAME" VARCHAR2(20 BYTE), 
	"CORRECTION" VARCHAR2(100 BYTE), 
	"SPECIES_CD" VARCHAR2(20 BYTE), 
	"ITEM_CD" VARCHAR2(20 BYTE), 
	"RESEARCH_CD" VARCHAR2(20 BYTE), 
	"COMMON_NAME" VARCHAR2(50 BYTE), 
	"SCIENTIFIC_NAME" VARCHAR2(50 BYTE), 
	"DUMMY" VARCHAR2(10 BYTE)
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 286720 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "MFLIB" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "VDC";
 
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "VDC_DEV";
 
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."SP_CONVERT" TO "GREYSONP";
