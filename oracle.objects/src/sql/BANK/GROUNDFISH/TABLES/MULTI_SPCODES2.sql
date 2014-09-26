--------------------------------------------------------
--  DDL for Table MULTI_SPCODES2
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."MULTI_SPCODES2" 
   (	"RESEARCH" NUMBER(4,0), 
	"ICNAF" VARCHAR2(3 BYTE), 
	"FAO" VARCHAR2(3 BYTE), 
	"FAO_2002" VARCHAR2(3 BYTE), 
	"COMMON" VARCHAR2(38 BYTE), 
	"SCIENTIF" VARCHAR2(49 BYTE), 
	"COMMER" VARCHAR2(3 BYTE), 
	"NMFS" NUMBER, 
	"ENTR" NUMBER, 
	"DESCRIPTION" VARCHAR2(50 BYTE), 
	"IML" NUMBER(5,0), 
	"NFLD" NUMBER(5,0), 
	"IML_ENGLISHCOMMONNAME" VARCHAR2(50 BYTE), 
	"IML_FRENCHCOMMONNAME" VARCHAR2(50 BYTE), 
	"IML_SCIENTIFICNAME" VARCHAR2(50 BYTE), 
	"FAO_SCIENTIFIC_NAME" VARCHAR2(40 BYTE), 
	"FAO_FRENCH_NAME" VARCHAR2(40 BYTE), 
	"FAO_SPANISH_NAME" VARCHAR2(40 BYTE), 
	"FAO_ENGLISH_NAME" VARCHAR2(40 BYTE), 
	"TSN1" NUMBER, 
	"TSN2" NUMBER, 
	"TSN3" NUMBER
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "MFLIB" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "VDC" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "MFD_OBFMI" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "VDC_DEV" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."MULTI_SPCODES2" TO "GREYSONP";