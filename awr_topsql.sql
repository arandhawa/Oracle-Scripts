-- awr_topsql.sql
-- AWR Top SQL Report, a version of "Top SQL" but across SNAP_IDs with AAS metric 
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- NOTES: SEE COMMENTS ON THE SCRIPT..ESPECIALLY ON SQL_TEXT, TIME_RANK, AND ORDER BY SECTIONS
--
-- Changes: 
-- 20100512     added timestamp to filter specific workload periods, must uncomment to use

set echo off verify off

COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v$database;

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v$instance;

ttitle center 'AWR Top SQL Report' skip 2
set pagesize 50000
set linesize 300

col snap_id     format 99999            heading "Snap|ID"
col tm          format a15              heading "Snap|Start|Time"
col inst        format 90               heading "i|n|s|t|#"
col dur         format 990.00          heading "Snap|Dur|(m)"
col sql_id      format a15              heading "SQL|ID"
col phv         format 99999999999      heading "Plan|Hash|Value"
col module      format a20              heading "Module"
col elap        format 999990.00        heading "Elapsed|Time|(s)"
col elapexec    format 999990.00        heading "Elapsed|Time|per exec|(s)"
col cput        format 999990.00        heading "CPU|Time|(s)"
col clwait      format 999999990        heading "Cluster|Wait"
col bget        format 99999999990      heading "LIO"
col dskr        format 99999999990      heading "PIO"
col rowp        format 99999999990      heading "Rows"
col exec        format 9999990          heading "Exec"
col prsc        format 999999990        heading "Parse|Count"
col pxexec      format 9999990          heading "PX|Exec"
col pctdbt      format 990              heading "DB Time|%"
col aas         format 990.00           heading "A|A|S"
col time_rank   format 90               heading "Time|Rank"
col sql_text    format a40              heading "SQL|Text"

     select *
       from (
             select
                  sqt.snap_id snap_id,
                  TO_CHAR(sqt.tm,'YY/MM/DD HH24:MI') tm,
                  sqt.inst inst,
                  sqt.dur dur,
                  sqt.sql_id sql_id,   
                  sqt.phv phv,                
                  to_clob(decode(sqt.module, null, null, sqt.module)) module,
                  nvl((sqt.elap), to_number(null)) elap,
                  nvl((sqt.elapexec), to_number(null)) elapexec,
                  nvl((sqt.cput), to_number(null)) cput,
                  sqt.clwait clwait,
                  sqt.bget bget, 
                  sqt.dskr dskr, 
                  sqt.rowp rowp,
                  sqt.exec exec, 
                  sqt.prsc prsc, 
                  sqt.pxexec pxexec,
                  sqt.aas aas,
                  sqt.time_rank time_rank
                  , nvl(st.sql_text, to_clob('** SQL Text Not Available **')) sql_text     -- PUT/REMOVE COMMENT TO HIDE/SHOW THE SQL_TEXT
             from        (
                          select snap_id, tm, inst, dur, sql_id, phv, module, elap, elapexec, cput, clwait, bget, dskr, rowp, exec, prsc, pxexec, aas, time_rank
                          from
                                             (
                                               select 
                                                      s0.snap_id snap_id,
                                                      s0.END_INTERVAL_TIME tm,
                                                      s0.instance_number inst,
                                                      round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                              + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                              + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                              + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
                                                      e.sql_id sql_id, 
                                                      e.plan_hash_value phv, 
                                                      max(e.module) module,
                                                      sum(e.elapsed_time_delta)/1000000 elap,
                                                      decode((sum(e.executions_delta)), 0, to_number(null), ((sum(e.elapsed_time_delta)) / (sum(e.executions_delta)) / 1000000)) elapexec,
                                                      sum(e.cpu_time_delta)/1000000     cput, 
                                                      sum(e.clwait_delta)/1000000 clwait,
                                                      sum(e.buffer_gets_delta) bget,
                                                      sum(e.disk_reads_delta) dskr, 
                                                      sum(e.rows_processed_delta) rowp,
                                                      sum(e.executions_delta)   exec,
                                                      sum(e.parse_calls_delta) prsc,
                                                      sum(px_servers_execs_delta) pxexec,
                                                      (sum(e.elapsed_time_delta)/1000000) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                            + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                            + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                            + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60) aas,
                                                      DENSE_RANK() OVER (
                                                      PARTITION BY s0.snap_id ORDER BY e.elapsed_time_delta DESC) time_rank
                                               from 
                                                   dba_hist_snapshot s0,
                                                   dba_hist_snapshot s1,
                                                   dba_hist_sqlstat e
                                                   where 
                                                    s0.dbid                   = &_dbid                -- CHANGE THE DBID HERE!
                                                    AND s1.dbid               = s0.dbid
                                                    and e.dbid                = s0.dbid                                                
                                                    AND s0.instance_number    = &_instancenumber      -- CHANGE THE INSTANCE_NUMBER HERE!
                                                    AND s1.instance_number    = s0.instance_number
                                                    and e.instance_number     = s0.instance_number                                                 
                                                    AND s1.snap_id            = s0.snap_id + 1
                                                    and e.snap_id             = s0.snap_id + 1                                              
                                               group by 
                                                    s0.snap_id, s0.END_INTERVAL_TIME, s0.instance_number, e.sql_id, e.plan_hash_value, e.elapsed_time_delta, s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME
                                             )
                          where 
                          time_rank <= 5                                     -- GET TOP 5 SQL ACROSS SNAP_IDs... YOU CAN ALTER THIS TO HAVE MORE DATA POINTS
                         ) 
                        sqt,
                        dba_hist_sqltext st 
             where st.sql_id(+)             = sqt.sql_id
             and st.dbid(+)                 = &_dbid
-- AND TO_CHAR(tm,'D') >= 1                                                  -- Day of week: 1=Sunday 7=Saturday
-- AND TO_CHAR(tm,'D') <= 7
-- AND TO_CHAR(tm,'HH24MI') >= 0900                                          -- Hour
-- AND TO_CHAR(tm,'HH24MI') <= 1800
-- AND tm >= TO_DATE('2010-jan-17 00:00:00','yyyy-mon-dd hh24:mi:ss')     -- Data range
-- AND tm <= TO_DATE('2010-aug-22 23:59:59','yyyy-mon-dd hh24:mi:ss')
-- AND snap_id in (338,339)
-- AND snap_id >= 335 and snap_id <= 339
-- AND snap_id = 3172
-- and sqt.sql_id = 'dj3n91vxsyaq5'
-- AND lower(st.sql_text) like 'select%'
-- AND lower(st.sql_text) like 'insert%'
-- AND lower(st.sql_text) like 'update%'
-- AND lower(st.sql_text) like 'merge%'
-- AND pxexec > 0
-- AND aas > .5
             order by 
             -- snap_id                             -- TO GET SQL OUTPUT ACROSS SNAP_IDs SEQUENTIALLY AND ASC
             nvl(sqt.elap, -1) desc, sqt.sql_id     -- TO GET SQL OUTPUT BY ELAPSED TIME
             )
where rownum <= 20
;

