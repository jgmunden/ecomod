--------------------------------------------------------
--  DDL for Table MV_REFRESH_LOG
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."MV_REFRESH_LOG" 
   (	"PK_TABLE_NAME" VARCHAR2(40 BYTE), 
	"FK_SYSTEM_ID" VARCHAR2(10 BYTE), 
	"DESCRIPTION" VARCHAR2(80 BYTE), 
	"USER_ID" VARCHAR2(16 BYTE), 
	"LAST_REFRESH" DATE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
 

   COMMENT ON COLUMN "GROUNDFISH"."MV_REFRESH_LOG"."PK_TABLE_NAME" IS 'Name of Materialized View Table';
 
   COMMENT ON COLUMN "GROUNDFISH"."MV_REFRESH_LOG"."FK_SYSTEM_ID" IS 'Id of the system with which MV is affiliated';
 
   COMMENT ON COLUMN "GROUNDFISH"."MV_REFRESH_LOG"."DESCRIPTION" IS 'Extended Discription of Materialized View Table';
 
   COMMENT ON COLUMN "GROUNDFISH"."MV_REFRESH_LOG"."USER_ID" IS 'User ID/Type of user/process doing refresh';
 
   COMMENT ON COLUMN "GROUNDFISH"."MV_REFRESH_LOG"."LAST_REFRESH" IS 'Id in message table ';
 
   COMMENT ON TABLE "GROUNDFISH"."MV_REFRESH_LOG"  IS 'Materialized Views Last Refresh Tracking Log';
  GRANT SELECT ON "GROUNDFISH"."MV_REFRESH_LOG" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."MV_REFRESH_LOG" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."MV_REFRESH_LOG" TO "GREYSONP";
