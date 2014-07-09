create or replace
PROCEDURE P_AWR_RANGE
(P_DBNAME   IN VARCHAR2 DEFAULT '',
 P_INSTANCE IN NUMBER DEFAULT 1) AS
  V_DBID   NUMBER;
  V_DBNAME V$DATABASE.NAME%TYPE;

  TYPE T_VARCHAR IS TABLE OF VARCHAR2(1500 CHAR) INDEX BY BINARY_INTEGER;
  O_STENDT T_VARCHAR;
  O_SNAPID T_VARCHAR;
BEGIN

  IF P_DBNAME IS NOT NULL THEN
    SELECT DISTINCT DBID, DB_NAME
      INTO V_DBID, V_DBNAME
      FROM DBA_HIST_DATABASE_INSTANCE
     WHERE DB_NAME = P_DBNAME;
  ELSE
    SELECT DBID, NAME INTO V_DBID, V_DBNAME FROM V$DATABASE;
  END IF;

  select
         instart_fmt || ' - ' || max(snapdat),
         min(snap_id)|| ' - ' || max(snap_id)
    BULK COLLECT
    INTO O_STENDT, O_SNAPID
    from (select to_char(s.startup_time, 'yyyy-mm-dd hh24:mi:ss') instart_fmt,
                 di.instance_name inst_name,
                 di.db_name db_name,
                 s.snap_id snap_id,
                 to_char(s.end_interval_time, 'yyyy-mm-dd hh24:mi:ss') snapdat,
                 s.snap_level lvl
            from dba_hist_snapshot s, dba_hist_database_instance di
           where s.dbid = V_DBID
             and di.dbid = V_DBID
             and s.instance_number = P_INSTANCE
             and di.instance_number = P_INSTANCE
             and di.instance_number = s.instance_number
             and di.startup_time = s.startup_time
           order by snap_id)
   group by instart_fmt;

   DBMS_OUTPUT.PUT_LINE('Database Start / End Time 1 Range:');
   DBMS_OUTPUT.PUT_LINE('------------------------------------------- -----------');

    FOR I IN O_STENDT.FIRST .. O_STENDT.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(O_STENDT(I) ||' ... '|| O_SNAPID(i));
    END LOOP;

END;