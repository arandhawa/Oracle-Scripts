-- awr_iowl.sql
-- AWR CPU and IO Workload Report
-- Karl Arao, Oracle ACE (bit.ly/karlarao), OCP-DBA, RHCE
-- http://karlarao.wordpress.com
--
-- NOTE: 
-- 
-- Changes: 
-- 

set echo off verify off

COLUMN blocksize NEW_VALUE _blocksize NOPRINT
select distinct block_size blocksize from v$datafile;

COLUMN dbid NEW_VALUE _dbid NOPRINT
select dbid from v$database;

COLUMN instancenumber NEW_VALUE _instancenumber NOPRINT
select instance_number instancenumber from v$instance;

ttitle center 'AWR IO Workload Report' skip 2
set pagesize 50000
set linesize 250

col tm          format a15              heading "Snap|Start|Time"
col id          format 99999            heading "Snap|ID"
col inst        format 90               heading "i|n|s|t|#"
col dur         format 999990.00        heading "Snap|Dur|(m)"
col cpu         format 90               heading "C|P|U"
col cap         format 9999990.00       heading "***|Total|CPU|Time|(s)"
col dbt         format 999990.00        heading "DB|Time"
col dbc         format 99990.00         heading "DB|CPU"
col bgc         format 99990.00         heading "Bg|CPU"
col rman        format 9990.00          heading "RMAN|CPU"
col aas         format 90.0             heading "A|A|S"
col totora      format 9999990.00       heading "***|Total|Oracle|CPU|(s)"
col busy        format 9999990.00       heading "Busy|Time"
col load        format 990.00           heading "OS|Load"
col totos       format 9999990.00       heading "***|Total|OS|CPU|(s)"
col mem         format 999990.00        heading "Physical|Memory|(mb)"
col IORs        format 99990.000        heading "IOPs|r"
col IOWs        format 99990.000        heading "IOPs|w"
col IORedo      format 99990.000        heading "IOPs|redo"
col IORmbs      format 99990.000        heading "IO r|(mb)/s"
col IOWmbs      format 99990.000        heading "IO w|(mb)/s"
col redosizesec format 99990.000        heading "Redo|(mb)/s"
col logons      format 990              heading "Sess"
col logone      format 990              heading "Sess|End"
col exsraw      format 99990.000        heading "Exec|raw|delta"
col exs         format 9990.000         heading "Exec|/s"
col oracpupct   format 990              heading "Oracle|CPU|%"
col rmancpupct  format 990              heading "RMAN|CPU|%"
col oscpupct    format 990              heading "OS|CPU|%"
col oscpuusr    format 990              heading "U|S|R|%"
col oscpusys    format 990              heading "S|Y|S|%"
col oscpuio     format 990              heading "I|O|%"
col SIORs       format 99990.000        heading "IOPs|Single|Block|r"
col MIORs       format 99990.000        heading "IOPs|Multi|Block|r"
col TIORmbs     format 99990.000        heading "Read|(mb)/s"
col SIOWs       format 99990.000        heading "IOPs|Single|Block|w"
col MIOWs       format 99990.000        heading "IOPs|Multi|Block|w"
col TIOWmbs     format 99990.000        heading "Write|(mb)/s"
col TIOR        format 99990.000        heading "Total|IOPs|r"
col TIOW        format 99990.000        heading "Total|IOPs|w"
col TIOALL      format 99990.000        heading "Total|IOPs|ALL"
col readratio   format 990              heading "Read|Ratio"
col writeratio  format 990              heading "Write|Ratio"
col diskiops    format 99990.000        heading "HW|Disk|IOPs"
col numdisks    format 99990.000        heading "HW|# of|Disks"

SELECT * FROM
( 
  SELECT s0.snap_id id,
  TO_CHAR(s0.END_INTERVAL_TIME,'YY/MM/DD HH24:MI') tm,
  s0.instance_number inst,
  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) dur,
  ((s5t1.value - s5t0.value) / 1000000)/60 /  round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2) aas,
  round(s2t1.value,2) AS load,
    ((round(DECODE(s8t1.value,null,'null',(s8t1.value - s8t0.value) / 1000000),2)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                                + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                                + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                                + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as rmancpupct,
    (((s19t1.value - s19t0.value)/100) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                                                                                + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                                                                                + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                                                                                + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2)*60)*s3t1.value))*100 as oscpuio,
   (((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as SIORs,
   ((s21t1.value - s21t0.value) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as MIORs,
   (((s22t1.value - s22t0.value)/1024/1024) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as TIORmbs,
   (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as SIOWs,
   ((s24t1.value - s24t0.value) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as MIOWs,
   (((s25t1.value - s25t0.value)/1024/1024) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as TIOWmbs,
   ((s13t1.value - s13t0.value)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as IORedo, 
   (((s14t1.value - s14t0.value)/1024/1024)  / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as redosizesec,
    ( (((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as TIOR,
    ( (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value)) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as TIOW,
    ( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
    ) as TIOALL,
    ( (((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) * 100
      as readratio,
    ( (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) * 100
      as writeratio,
    ((
      ( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
      )
    * 
      ( (((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) 
    )
    +
    (
      ( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
      )
    * 
      ( (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) 
    *
      (2)  -- this is the RAID penalty
    )) 
      as diskiops,
    ((
      ( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
      )
    * 
      ( (((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) 
    )
    +
    (
      ( ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) / ((round(EXTRACT(DAY FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 1440 
                                  + EXTRACT(HOUR FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) * 60 
                                  + EXTRACT(MINUTE FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) 
                                  + EXTRACT(SECOND FROM s1.END_INTERVAL_TIME - s0.END_INTERVAL_TIME) / 60, 2))*60)
      )
    * 
      ( (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value)) / ((((s20t1.value - s20t0.value) - (s21t1.value - s21t0.value)) + (s21t1.value - s21t0.value)) + (((s23t1.value - s23t0.value) - (s24t1.value - s24t0.value)) + (s24t1.value - s24t0.value) + (s13t1.value - s13t0.value))) ) 
    *
      (2)  -- this is the RAID penalty
    )) / 180
      as numdisks
FROM dba_hist_snapshot s0,
  dba_hist_snapshot s1,
  dba_hist_osstat s19t0,        -- IOWAIT_TIME
  dba_hist_osstat s19t1,
  dba_hist_osstat s2t1,         -- osstat just get the end value
  dba_hist_osstat s3t1,         -- osstat just get the end value
  dba_hist_sys_time_model s5t0,
  dba_hist_sys_time_model s5t1,
  dba_hist_sys_time_model s8t0,
  dba_hist_sys_time_model s8t1,
  dba_hist_sysstat s13t0,       -- redo writes, diffed
  dba_hist_sysstat s13t1,
  dba_hist_sysstat s14t0,       -- redo size, diffed
  dba_hist_sysstat s14t1,
  dba_hist_sysstat s20t0,       -- physical read total IO requests, diffed
  dba_hist_sysstat s20t1,
  dba_hist_sysstat s21t0,       -- physical read total multi block requests, diffed
  dba_hist_sysstat s21t1,  
  dba_hist_sysstat s22t0,       -- physical read total bytes, diffed
  dba_hist_sysstat s22t1,  
  dba_hist_sysstat s23t0,       -- physical write total IO requests, diffed
  dba_hist_sysstat s23t1,
  dba_hist_sysstat s24t0,       -- physical write total multi block requests, diffed
  dba_hist_sysstat s24t1,
  dba_hist_sysstat s25t0,       -- physical write total bytes, diffed
  dba_hist_sysstat s25t1
WHERE s0.dbid            = &_dbid    -- CHANGE THE DBID HERE!
AND s1.dbid              = s0.dbid
AND s2t1.dbid            = s0.dbid
AND s3t1.dbid            = s0.dbid
AND s5t0.dbid            = s0.dbid
AND s5t1.dbid            = s0.dbid
AND s8t0.dbid            = s0.dbid
AND s8t1.dbid            = s0.dbid
AND s13t0.dbid            = s0.dbid
AND s13t1.dbid            = s0.dbid
AND s14t0.dbid            = s0.dbid
AND s14t1.dbid            = s0.dbid
AND s19t0.dbid            = s0.dbid
AND s19t1.dbid            = s0.dbid
AND s20t0.dbid            = s0.dbid
AND s20t1.dbid            = s0.dbid
AND s21t0.dbid            = s0.dbid
AND s21t1.dbid            = s0.dbid
AND s22t0.dbid            = s0.dbid
AND s22t1.dbid            = s0.dbid
AND s23t0.dbid            = s0.dbid
AND s23t1.dbid            = s0.dbid
AND s24t0.dbid            = s0.dbid
AND s24t1.dbid            = s0.dbid
AND s25t0.dbid            = s0.dbid
AND s25t1.dbid            = s0.dbid
AND s0.instance_number   = &_instancenumber   -- CHANGE THE INSTANCE_NUMBER HERE!
AND s1.instance_number   = s0.instance_number
AND s2t1.instance_number = s0.instance_number
AND s3t1.instance_number = s0.instance_number
AND s5t0.instance_number = s0.instance_number
AND s5t1.instance_number = s0.instance_number
AND s8t0.instance_number = s0.instance_number
AND s8t1.instance_number = s0.instance_number
AND s13t0.instance_number = s0.instance_number
AND s13t1.instance_number = s0.instance_number
AND s14t0.instance_number = s0.instance_number
AND s14t1.instance_number = s0.instance_number
AND s19t0.instance_number = s0.instance_number
AND s19t1.instance_number = s0.instance_number
AND s20t0.instance_number = s0.instance_number
AND s20t1.instance_number = s0.instance_number
AND s21t0.instance_number = s0.instance_number
AND s21t1.instance_number = s0.instance_number
AND s22t0.instance_number = s0.instance_number
AND s22t1.instance_number = s0.instance_number
AND s23t0.instance_number = s0.instance_number
AND s23t1.instance_number = s0.instance_number
AND s24t0.instance_number = s0.instance_number
AND s24t1.instance_number = s0.instance_number
AND s25t0.instance_number = s0.instance_number
AND s25t1.instance_number = s0.instance_number
AND s1.snap_id            = s0.snap_id + 1
AND s2t1.snap_id          = s0.snap_id + 1
AND s3t1.snap_id          = s0.snap_id + 1
AND s5t0.snap_id          = s0.snap_id
AND s5t1.snap_id          = s0.snap_id + 1
AND s8t0.snap_id          = s0.snap_id
AND s8t1.snap_id          = s0.snap_id + 1
AND s13t0.snap_id         = s0.snap_id
AND s13t1.snap_id         = s0.snap_id + 1
AND s14t0.snap_id         = s0.snap_id
AND s14t1.snap_id         = s0.snap_id + 1
AND s19t0.snap_id         = s0.snap_id
AND s19t1.snap_id         = s0.snap_id + 1
AND s20t0.snap_id         = s0.snap_id
AND s20t1.snap_id         = s0.snap_id + 1
AND s21t0.snap_id         = s0.snap_id
AND s21t1.snap_id         = s0.snap_id + 1
AND s22t0.snap_id         = s0.snap_id
AND s22t1.snap_id         = s0.snap_id + 1
AND s23t0.snap_id         = s0.snap_id
AND s23t1.snap_id         = s0.snap_id + 1
AND s24t0.snap_id         = s0.snap_id
AND s24t1.snap_id         = s0.snap_id + 1
AND s25t0.snap_id         = s0.snap_id
AND s25t1.snap_id         = s0.snap_id + 1
AND s19t0.stat_name       = 'IOWAIT_TIME'
AND s19t1.stat_name       = s19t0.stat_name
AND s2t1.stat_name       = 'LOAD'
AND s3t1.stat_name       = 'NUM_CPUS'
AND s5t0.stat_name       = 'DB time'
AND s5t1.stat_name       = s5t0.stat_name
AND s8t0.stat_name       = 'RMAN cpu time (backup/restore)'
AND s8t1.stat_name       = s8t0.stat_name
AND s13t0.stat_name       = 'redo writes'
AND s13t1.stat_name       = s13t0.stat_name
AND s14t0.stat_name       = 'redo size'
AND s14t1.stat_name       = s14t0.stat_name
AND s20t0.stat_name       = 'physical read total IO requests'
AND s20t1.stat_name       = s20t0.stat_name
AND s21t0.stat_name       = 'physical read total multi block requests'
AND s21t1.stat_name       = s21t0.stat_name
AND s22t0.stat_name       = 'physical read total bytes'
AND s22t1.stat_name       = s22t0.stat_name
AND s23t0.stat_name       = 'physical write total IO requests'
AND s23t1.stat_name       = s23t0.stat_name
AND s24t0.stat_name       = 'physical write total multi block requests'
AND s24t1.stat_name       = s24t0.stat_name
AND s25t0.stat_name       = 'physical write total bytes'
AND s25t1.stat_name       = s25t0.stat_name
)
-- WHERE 
-- id in (338)
-- aas > 1
-- oscpuio > 50
-- rmancpupct > 0
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'D') >= 1     -- Day of week: 1=Sunday 7=Saturday
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'D') <= 7
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'HH24MI') >= 0900     -- Hour
-- AND TO_CHAR(s0.END_INTERVAL_TIME,'HH24MI') <= 1800
-- AND s0.END_INTERVAL_TIME >= TO_DATE('2010-jan-17 00:00:00','yyyy-mon-dd hh24:mi:ss')     -- Data range
-- AND s0.END_INTERVAL_TIME <= TO_DATE('2010-aug-22 23:59:59','yyyy-mon-dd hh24:mi:ss')
ORDER BY id ASC;