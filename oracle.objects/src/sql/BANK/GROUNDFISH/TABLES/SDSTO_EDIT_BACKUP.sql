--------------------------------------------------------
--  DDL for Table SDSTO_EDIT_BACKUP
--------------------------------------------------------

  CREATE TABLE "GROUNDFISH"."SDSTO_EDIT_BACKUP" 
   (	"DATASOURCE" VARCHAR2(3 BYTE), 
	"MISSION" VARCHAR2(15 BYTE), 
	"SETNO" NUMBER(3,0), 
	"SAMPLE_INDEX" NUMBER(6,0), 
	"SPEC" NUMBER(4,0), 
	"FSHNO" NUMBER(6,0), 
	"STO_KEY" ROWID, 
	"PREYITEMCD" NUMBER(4,0), 
	"PREYITEM" VARCHAR2(25 BYTE), 
	"PREYSPECCD" NUMBER(4,0), 
	"PREYSPEC" VARCHAR2(25 BYTE), 
	"PWT" NUMBER(10,4), 
	"PLEN" NUMBER(5,1), 
	"PNUM" NUMBER(6,0), 
	"DIGESTION" VARCHAR2(1 BYTE), 
	"REMARKS" VARCHAR2(150 BYTE), 
	"STATUS_FLAG" NUMBER
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 65536 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "MFD_GROUNDFISH" ;
  GRANT SELECT ON "GROUNDFISH"."SDSTO_EDIT_BACKUP" TO "MFD_STOMACH";
 
  GRANT SELECT ON "GROUNDFISH"."SDSTO_EDIT_BACKUP" TO "RICARDD";
 
  GRANT SELECT ON "GROUNDFISH"."SDSTO_EDIT_BACKUP" TO "HUBLEYB";
 
  GRANT SELECT ON "GROUNDFISH"."SDSTO_EDIT_BACKUP" TO "GREYSONP";
