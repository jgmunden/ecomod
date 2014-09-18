--------------------------------------------------------
--  DDL for Table SDCFINF_TMP
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."SDCFINF_TMP" 
   (	"MISSION" VARCHAR2(10 BYTE), 
	"TECH" VARCHAR2(50 BYTE), 
	"VESSEL_NAME" VARCHAR2(30 BYTE), 
	"SPECIES_NAME" VARCHAR2(30 BYTE), 
	"SDATE" DATE, 
	"DEPTH" NUMBER(4,0), 
	"SLAT" VARCHAR2(15 BYTE), 
	"SLONG" NUMBER(8,2), 
	"NAFO" VARCHAR2(10 BYTE), 
	"GEAR" VARCHAR2(20 BYTE), 
	"REMARKS" VARCHAR2(100 BYTE)
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 532480 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
 

   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."MISSION" IS 'trip id';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."TECH" IS 'fish number ';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."VESSEL_NAME" IS 'fish length';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."SPECIES_NAME" IS 'fish weight ';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."SDATE" IS 'sample date';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."DEPTH" IS 'depth';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."SLAT" IS 'latitude';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."SLONG" IS 'longitude';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."NAFO" IS 'NAFO area';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."GEAR" IS 'gear type ';
 
   COMMENT ON COLUMN "GROUNDFISH"."SDCFINF_TMP"."REMARKS" IS 'comments ';
 
   COMMENT ON TABLE "GROUNDFISH"."SDCFINF_TMP"  IS 'Stomach Community Samples ';
  GRANT SELECT ON "GROUNDFISH"."SDCFINF_TMP" TO "MFD_STOMACH";
 
  GRANT SELECT ON "GROUNDFISH"."SDCFINF_TMP" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."SDCFINF_TMP" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."SDCFINF_TMP" TO "GREYSONP";
