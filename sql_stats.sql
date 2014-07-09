alter session set nls_date_format='yyyymmdd hh24:mi:ss';
col PLAN_HASH for 9999999999
SELECT INST_ID,
       LAST_ACTIVE_TIME,
       PLAN_HASH_VALUE "PLAN_HASH",
       DISK_READS,
       BUFFER_GETS,
       ROWS_PROCESSED,
       EXECUTIONS,
       round(BUFFER_GETS/EXECUTIONS) "BG/E",
       round(DISK_READS/EXECUTIONS) "DR/E",
       round(ELAPSED_TIME/1000/EXECUTIONS) "EL(ms)/E"
FROM gv$sqlstats
WHERE sql_id='&sql_id';
