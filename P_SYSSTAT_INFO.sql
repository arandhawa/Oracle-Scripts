create or replace
PROCEDURE P_SYSSTAT_INFO
(P_DBID   IN NUMBER DEFAULT '',
 P_INSTANCE IN NUMBER DEFAULT 1,
 P_STATNAME IN VARCHAR2 DEFAULT 'DB time') AS
  TYPE T_VARCHAR IS TABLE OF VARCHAR2(1500 CHAR) INDEX BY BINARY_INTEGER;
  V_ETIME  T_VARCHAR;
  V_BTIME T_VARCHAR;
  V_LTIME T_VARCHAR;
  V_DTIME T_VARCHAR;

  TYPE T_NUM IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
	V_SNAP_ID T_NUM;
BEGIN
SELECT
    s.snap_id,TO_CHAR(s.begin_interval_time, 'mm/dd/yyyy HH24:MI:SS')  , TO_CHAR(s.end_interval_time, 'mm/dd/yyyy HH24:MI:SS'), 
	  lpad(TO_CHAR(ROUND(EXTRACT(DAY FROM  s.end_interval_time - s.begin_interval_time) * 1440 +
          EXTRACT(HOUR FROM s.end_interval_time - s.begin_interval_time) * 60 +
          EXTRACT(MINUTE FROM s.end_interval_time - s.begin_interval_time) +
          EXTRACT(SECOND FROM s.end_interval_time - s.begin_interval_time) / 60, 0)),3,0)
  , lpad(to_char(ROUND((e.value - b.value), 0)),3,0) 
  BULK COLLECT INTO V_SNAP_ID,V_BTIME,V_ETIME,V_LTIME,V_DTIME
FROM
    wrm$_snapshot       		s
  , wrm$_database_instance             	i
  , wrh$_sysstat 		e
  , wrh$_sysstat 		b
  , wrh$_stat_name			n
WHERE
      i.instance_number = s.instance_number
  AND i.instance_number = P_INSTANCE
  AND e.snap_id         = s.snap_id
  AND b.snap_id         = s.snap_id - 1
  AND e.stat_id         = b.stat_id
  AND e.instance_number = b.instance_number
  AND e.instance_number = s.instance_number
  AND e.stat_id		= n.stat_id
  AND n.stat_name	= P_STATNAME
  AND i.dbid		= s.dbid
  AND s.dbid            = b.dbid
  AND b.dbid            = e.dbid
  AND n.dbid		= e.dbid
  AND i.dbid = P_DBID
ORDER BY
    i.instance_name , s.snap_id;

   DBMS_OUTPUT.PUT_LINE('Awr INFO:SNAP_ID,Begin Time,End Time,Elapsed Time,Stat Info-'||p_statname);
   DBMS_OUTPUT.PUT_LINE('------------------------------------------- -----------');

    FOR I IN V_SNAP_ID.FIRST .. V_SNAP_ID.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(V_SNAP_ID(I) ||' . '|| V_BTIME(i)||' . '|| V_ETIME(i)||' . '||V_LTIME(I)|| ' . '||V_DTIME(I));
    END LOOP;

END;