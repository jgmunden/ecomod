--------------------------------------------------------
--  DDL for Table GSANALPARMS
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."GSANALPARMS" 
   (	"SERIES" VARCHAR2(15 BYTE), 
	"MISSION" VARCHAR2(15 BYTE), 
	"REGION" VARCHAR2(5 BYTE), 
	"VES_SURVEY" VARCHAR2(15 BYTE), 
	"SPEC" NUMBER(4,0), 
	"DAYNIGHT" NUMBER(1,0), 
	"NOADJ" NUMBER, 
	"WTADJ" NUMBER, 
	"SIGMAADJ" NUMBER
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 163840 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
 

   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."SERIES" IS 'Series';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."MISSION" IS 'Trip Identification';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."REGION" IS 'Region';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."VES_SURVEY" IS 'vessel or Survey ID';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."SPEC" IS 'Species';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."DAYNIGHT" IS 'Day Night Flag 0=Day 1=Night';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."NOADJ" IS 'Catch adjustment coefficient';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."WTADJ" IS 'Weight adjustment coefficient';
 
   COMMENT ON COLUMN "GROUNDFISH"."GSANALPARMS"."SIGMAADJ" IS 'Calculate Sigma flag 1/0';
 
   COMMENT ON TABLE "GROUNDFISH"."GSANALPARMS"  IS 'Analysis Parameters ';
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "MFLIB" WITH GRANT OPTION;
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "ABUNDY";
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "VDC";
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "VDC_DEV";
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."GSANALPARMS" TO "GREYSONP";
