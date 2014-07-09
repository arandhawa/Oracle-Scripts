
-- +--------------------------------------------------------------------------------+
-- |                             EnmoTech SQL Report                                |
-- |--------------------------------------------------------------------------------+
-- | Copyright (c) 2011-2012 Hongye DBA. All rights reserved. (www.enmotech.com)    |
-- +--------------------------------------------------------------------------------+
-- 
-- =================================================================================================================
-- ||                                                                                                             ||
-- || First Edition ( Complete at 2012-08-23 ) :                                                                  ||
-- ||   Based on the Oracle awrsqrpi.sql , and add "More Statistics" section which including :                    ||
-- ||   1. Tables in Plan                                                                                         ||
-- ||   2. Table Descriptions                                                                                     ||
-- ||   3. Indexes in Plan                                                                                        ||
-- ||   4. All Related Indexes                                                                                    ||
-- ||   5. Index Columns Detail                                                                                   ||
-- ||   6. Table Constraints                                                                                      ||
-- ||   7. Columns Histogram                                                                                      ||
-- ||                                                                                                             ||
-- || Second Edition ( Complete at 2012-08-24 ) :                                                                 ||
-- ||   Based on the First Edition                                                                                ||
-- ||   1. Add Partition Table/Index Statistics                                                                   ||
-- ||   2. Add Lob Statistics                                                                                     ||
-- ||   3. Modify Column's Histogram ,designed by PL/SQL which provide Links to help find Histogram Statistics    ||
-- ||   4. Tuning Column's Alignment                                                                              ||
-- ||                                                                                                             ||
-- || Third Edition ( Complete at 2012-09-01 ) :                                                                  ||
-- ||   Based on the Second Edition                                                                               ||
-- ||   1. Convert bound value(high_value and low_value) to the readable value                                    ||
-- ||   2. Convert endpoint_value (in dba_tab_histogram) to char when the data_type similar to char               ||
-- ||   3. remove "Indexes in Plan" section                                                                       ||
-- ||   4. Modify "All Related Tables" and "All Related Indexes" section, mark used objects with red color        ||
-- ||   5. Consider much more relations, which may collect more data (More complete table info and index info)    ||
-- ||                                                                                                             ||
-- =================================================================================================================

-- Get the common input
--@@awrinput.sql

-- The following list of SQL*Plus bind variables will be defined and assigned a value
-- by this SQL*Plus script:
--    variable dbid      number     - Database id
--    variable inst_num  number     - Instance number
--    variable bid       number     - Begin snapshot id
--    variable eid       number     - End snapshot id


clear break compute
repfooter off
ttitle off
btitle off 
set echo off veri off feedback off heading on space 1 flush on pause off termout on numwidth 10 underline on
set pagesize 60 linesize 80 newpage 1 recsep off trimspool on trimout on define "&" concat "." serveroutput on

--
-- Request the DB Id and Instance Number, if they are not specified

column instt_num  heading "Inst Num"  format 99999;
column instt_name heading "Instance"  format a12;
column dbb_name   heading "DB Name"   format a12;
column dbbid      heading "DB Id"     format a12 just c;
column host       heading "Host"      format a12;

prompt
prompt
prompt Instances in this Workload Repository schema
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select distinct
       (case when cd.dbid = wr.dbid and 
                  cd.name = wr.db_name and
                  ci.instance_number = wr.instance_number and
                  ci.instance_name   = wr.instance_name   and
                  ci.host_name       = wr.host_name 
             then '* '
             else '  '
        end) || wr.dbid   dbbid
     , wr.instance_number instt_num
     , wr.db_name         dbb_name
     , wr.instance_name   instt_name
     , wr.host_name       host
  from dba_hist_database_instance wr, v$database cd, v$instance ci;

prompt
prompt Using &&dbid for database Id
prompt Using &&inst_num for instance number


--
--  Set up the binds for dbid and instance_number

variable dbid       number;
variable inst_num   number;
begin
  :dbid      :=  &dbid;
  :inst_num  :=  &inst_num;
end;
/

--
--  Error reporting

whenever sqlerror exit;
variable max_snap_time char(10);
declare

  cursor cidnum is
     select 'X'
       from dba_hist_database_instance
      where instance_number = :inst_num
        and dbid            = :dbid;

  cursor csnapid is
     select to_char(max(end_interval_time),'dd/mm/yyyy')
       from dba_hist_snapshot
      where instance_number = :inst_num
        and dbid            = :dbid;

  vx     char(1);

begin

  -- Check Database Id/Instance Number is a valid pair
  open cidnum;
  fetch cidnum into vx;
  if cidnum%notfound then
    raise_application_error(-20200,
      'Database/Instance ' || :dbid || '/' || :inst_num ||
      ' does not exist in DBA_HIST_DATABASE_INSTANCE');
  end if;
  close cidnum;

  -- Check Snapshots exist for Database Id/Instance Number
  open csnapid;
  fetch csnapid into :max_snap_time;
  if csnapid%notfound then
    raise_application_error(-20200,
      'No snapshots exist for Database/Instance '||:dbid||'/'||:inst_num);
  end if;
  close csnapid;

end;
/
whenever sqlerror continue;


--
--  Ask how many days of snapshots to display

set termout on;
column instart_fmt noprint;
column inst_name   format a12  heading 'Instance';
column db_name     format a12  heading 'DB Name';
column snap_id     format 99999990 heading 'Snap Id';
column snapdat     format a18  heading 'Snap Started' just c;
column lvl         format 99   heading 'Snap|Level';

prompt
prompt
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Entering the number of days (n) will result in the most recent
prompt (n) days of snapshots being listed.  Pressing <return> without
prompt specifying a number lists all completed snapshots.
prompt
prompt

set heading off;
column num_days new_value num_days noprint;
select    'Listing '
       || decode( nvl('&&num_days', 3.14)
                , 0    , 'no snapshots'
                , 3.14 , 'all Completed Snapshots'
                , 1    , 'the last day''s Completed Snapshots'
                , 'the last &num_days days of Completed Snapshots')
     , nvl('&&num_days', 3.14)  num_days
  from sys.dual;
set heading on;


--
-- List available snapshots

break on inst_name on db_name on host on instart_fmt skip 1;

ttitle off;

select to_char(s.startup_time,'dd Mon "at" HH24:mi:ss')  instart_fmt
     , di.instance_name                                  inst_name
     , di.db_name                                        db_name
     , s.snap_id                                         snap_id
     , to_char(s.end_interval_time,'dd Mon YYYY HH24:mi') snapdat
     , s.snap_level                                      lvl
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where s.dbid              = :dbid
   and di.dbid             = :dbid
   and s.instance_number   = :inst_num
   and di.instance_number  = :inst_num
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
   and s.end_interval_time >= decode( &num_days
                                   , 0   , to_date('31-JAN-9999','DD-MON-YYYY')
                                   , 3.14, s.end_interval_time
                                   , to_date(:max_snap_time,'dd/mm/yyyy') - (&num_days-1))
 order by db_name, instance_name, snap_id;

clear break;
ttitle off;


--
--  Ask for the snapshots Id's which are to be compared

prompt
prompt
prompt Specify the Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Begin Snapshot Id specified: &&begin_snap
prompt
prompt End   Snapshot Id specified: &&end_snap
prompt


--
--  Set up the snapshot-related binds

variable bid        number;
variable eid        number;
begin
  :bid       :=  &begin_snap;
  :eid       :=  &end_snap;
end;
/

prompt


--
--  Error reporting

whenever sqlerror exit;
declare

  cursor cspid(vspid dba_hist_snapshot.snap_id%type) is
     select end_interval_time
          , startup_time
       from dba_hist_snapshot
      where snap_id         = vspid
        and instance_number = :inst_num
        and dbid            = :dbid;

  bsnapt  dba_hist_snapshot.end_interval_time%type;
  bstart  dba_hist_snapshot.startup_time%type;
  esnapt  dba_hist_snapshot.end_interval_time%type;
  estart  dba_hist_snapshot.startup_time%type;

begin

  -- Check Begin Snapshot id is valid, get corresponding instance startup time
  open cspid(:bid);
  fetch cspid into bsnapt, bstart;
  if cspid%notfound then
    raise_application_error(-20200,
      'Begin Snapshot Id '||:bid||' does not exist for this database/instance');
  end if;
  close cspid;

  -- Check End Snapshot id is valid and get corresponding instance startup time
  open cspid(:eid);
  fetch cspid into esnapt, estart;
  if cspid%notfound then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid||' does not exist for this database/instance');
  end if;
  if esnapt <= bsnapt then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid||' must be greater than Begin Snapshot Id '||:bid);
  end if;
  close cspid;

  -- Check startup time is same for begin and end snapshot ids
  if ( bstart != estart) then
    raise_application_error(-20200,
      'The instance was shutdown between snapshots '||:bid||' and '||:eid);
  end if;

end;
/
whenever sqlerror continue;

-- Undefine substitution variables
--undefine dbid
--undefine inst_num
--undefine num_days
--undefine begin_snap
--undefine end_snap
--undefine db_name
--undefine inst_name





prompt
-- Get the SQL ID from the user
prompt 
prompt Specify the SQL Id
prompt ~~~~~~~~~~~~~~~~~~
prompt SQL ID specified:  &&sql_id


-- Assign value to bind variable
variable sqlid  VARCHAR2(13);
exec :sqlid := '&sql_id';


whenever sqlerror exit;
declare
  cursor csqlid(vsqlid dba_hist_sqlstat.sql_id%type) is
    select sql_id
      from dba_hist_sqlstat
    where snap_id    > :bid
      and snap_id   <= :eid
      and instance_number   = :inst_num
      and dbid              = :dbid
      and sql_id            = vsqlid;
  inpsqlid dba_hist_sqlstat.sql_id%type;
begin
-- Check if the sqlid is valid. It mustcontain an entry in the 
-- DBA_HIST_SQLSTAT table for the specified sqlid
  open csqlid(:sqlid);
  fetch csqlid into inpsqlid;
  if csqlid%notfound then
    raise_application_error(-20025,
    'SQL ID '||:sqlid||' does not exist for this database/instance');
  end if;
end;
/

whenever sqlerror continue;






-- Get the name of the report.
--@@awrinpnm.sql 'awrsqlrpt_' &&ext

clear break compute;
repfooter off;
ttitle off;
btitle off;

set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 linesize 80 newpage 1 recsep off;
set trimspool on trimout on define "&" concat "." serveroutput on;
set underline on;

set termout off;
column dflt_name new_value dflt_name noprint;
select 'enmotech_sqlrpt_'||:inst_num||'_'||:bid||'_'||:eid||'_'||:sqlid||'.html' dflt_name from dual;
set termout on;

prompt
prompt Specify the Report Name
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt The default report file name is &dflt_name..  To use this name,
prompt press <return> to continue, otherwise enter an alternative.
prompt

set heading off;
column report_name new_value report_name noprint;
select 'Using the report name ' || nvl('&&report_name','&dflt_name')
     , nvl('&&report_name','&dflt_name') report_name
  from sys.dual;

set heading off pagesize 50000 echo off feedback off;

undefine dflt_name




set linesize 8000
set termout on;
spool &report_name;
prompt

select 'WARNING: timed_statistics setting changed between begin/end snaps: TIMINGS ARE INVALID'
  from dual
 where not exists
      (select null
         from dba_hist_parameter b
            , dba_hist_parameter e
        where b.snap_id         = :bid
          and e.snap_id         = :eid
          and b.dbid            = :dbid
          and e.dbid            = :dbid
          and b.instance_number = :inst_num
          and e.instance_number = :inst_num
          and b.parameter_hash  = e.parameter_hash
          and b.parameter_name = 'timed_statistics'
          and b.value           = e.value);

select output from table(dbms_workload_repository.awr_sql_report_html( :dbid, :inst_num, :bid, :eid, :sqlid));



--=========================================================================
--|
--|   Statistics
--|
--=========================================================================

prompt <a class='awr' name="contents"></a> <hr width="100%">

prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>More Statistics</b></font><hr align="left" width="460">

prompt <table width="80%" border="1"> <tr><th colspan="4" class='awrbg'>All Contents</th></tr> -
<tr> <td nowrap align="center" class='awrc' width="25%"><a class="awr" href="#all_related_tables">All Related Tables</a></td> -
<td nowrap align="center" class='awrc' width="25%"><a class="awr" href="#table_descriptions">Table Descriptions</a></td> -
<td nowrap align="center" class='awrc' width="25%"><a class="awr" href="#all_related_indexes">All Related Indexes</a></td> -
<td nowrap align="center" class='awrc' width="25%"><a class="awr" href="#index_columns_detail">Index Columns Detail</a></td>  </tr> 

prompt <tr> <td nowrap align="center" class='awrnc' width="25%"><a class="awr" href="#table_constraints">Table Constraints</a></td> -
<td nowrap align="center" class='awrnc' width="25%"><a class="awr" href="#partition_statistics">Partition Statistics</a></td> -
<td nowrap align="center" class='awrnc' width="25%"><a class="awr" href="#lob_statistics">Lob Statistics</a></td> -
<td nowrap align="center" class='awrnc' width="25%"><a class="awr" href="#columns_histogram">Columns Histogram</a></td>  </tr> 
prompt </table> <p>

--=========================================================================
--|
--|   All Related Tables
--|
--=========================================================================
prompt <a class='awr' name="all_related_tables"></a>
set termout on heading off
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>All Related Tables</b></font><hr align="left" width="460">
prompt <font class="awr"> <li>   Lines with Red Color means used in the plan ! </li></font></br>

prompt <table width='80%' border="1"> 
prompt <tr><th class='awrbg'>Owner</th>
prompt <th class='awrbg'>Table Name</th>
prompt <th class='awrbg'>Tablespace</th>
prompt <th class='awrbg'>Table Type</th>
prompt <th class='awrbg'>Status</th>
prompt <th class='awrbg'>Rows</th>
prompt <th class='awrbg'>Blocks</th>
prompt <th class='awrbg'>Avg Row Len</th>
prompt <th class='awrbg'>Chain Count</th>
prompt <th class='awrbg'>Degree</th>
prompt <th class='awrbg'>Cache</th>
prompt <th class='awrbg'>Analyzed</th></tr>

select '<tr> <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||owner||'</b></font>',owner)||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||table_name||'</b></font>',table_name)||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||tablespace_name||'</b></font>',tablespace_name)||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||table_type||'</b></font>',table_type)||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||status||'</b></font>',status)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||num_rows||'</b></font>',num_rows)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||blocks||'</b></font>',blocks)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||avg_row_len||'</b></font>',avg_row_len)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||chain_cnt||'</b></font>',chain_cnt)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||degree||'</b></font>',degree)||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||cache||'</b></font>',cache)||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'T','<font color="red"><b>'||to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss')||'</b></font>',to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss'))||'</td></tr>'
  from (select s.tips,
		       t.owner,
               t.table_name,
			   t.tablespace_name,
			   case when t.cluster_name is not null then 'Cluster Table' 
                    when t.iot_name is not null then 'IOT' 
                    when t.partitioned='YES' then 'Partition Table' 
                    else 'Normal Table' 
                end table_type,
			   t.status,
			   t.num_rows,
			   t.blocks,
			   t.avg_row_len,
			   t.chain_cnt,
			   t.degree,
			   t.cache,
			   t.last_analyzed
		  from dba_tables t,
		       (select s.object_owner owner,
			           decode(object_type,'TABLE',s.object_name,i.table_name) object_name,
			           max(decode(object_type,'TABLE','T','I')) tips
			      from dba_indexes i,dba_hist_sql_plan s 
			     where s.sql_id=:sqlid 
				   and s.object_owner=i.owner(+) 
				   and s.object_name=i.index_name(+)
				  group by object_owner,decode(object_type,'TABLE',s.object_name,i.table_name)) s
		 where t.owner=s.owner
		   and t.table_name=s.object_name);
prompt </table> <p>
prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />


--=========================================================================
--|
--|   Table Descriptions
--|
--=========================================================================
prompt <a class='awr' name="table_descriptions"></a>
set termout on heading off
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Table Descriptions</b></font><hr align="left" width="460">

prompt <table width='80%' border="1"> -
<tr><th class='awrbg'>Owner</th> -
<th class='awrbg'>Table Name</th> -
<th class='awrbg'>Column Name</th> -
<th class='awrbg'>Data Type</th> -
<th class='awrbg'>Data Length</th> -
<th class='awrbg'>is Null</th> -
<th class='awrbg'>Distinct Num</th> -
<th class='awrbg'>Buckets Num</th> -
<th class='awrbg'>Histogram Type</th> -
<th class='awrbg'>Analyzed</th></tr>

select '<tr> <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||owner||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||table_name||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||column_name||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||data_type||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||data_length||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||nullable||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||num_distinct||'</td>
             <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||num_buckets||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||
			 decode(histogram,'NONE','NONE','<a class=''awr'' HREF="#'||owner||'_'||table_name||'_'||column_name||'">'||histogram||'</a>')||'</td>
             <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss')||'</td> </tr>'
  from (select t.owner,
               t.table_name,
			   t.column_name,
			   t.data_type,
			   t.data_length,
			   t.nullable,
			   t.num_distinct,
			   t.num_buckets,
			   t.histogram,
			   t.last_analyzed
		  from dba_tab_columns t,
	           (select distinct s.object_owner owner,
	                   decode(object_type,'TABLE',s.object_name,i.table_name) object_name
	              from dba_indexes i,dba_hist_sql_plan s 
	             where s.sql_id=:sqlid 
	              and s.object_owner=i.owner(+) 
	              and s.object_name=i.index_name(+)) p
         where t.owner=p.owner
           and t.table_name=p.object_name
         order by t.owner,t.table_name,t.column_id);
prompt </table> <p>
prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />


--=========================================================================
--|
--|   All Related Indexes
--|
--=========================================================================
prompt <a class='awr' name="all_related_indexes"></a>
set termout on
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>All Related Indexes</b></font><hr align="left" width="460">
prompt <font class="awr"> <li>   Lines with Red Color means used in the plan ! </li></font></br>

prompt <table width='100%' border="1"> 
prompt <tr><th class='awrbg'>Index Owner</th>
prompt <th class='awrbg'>Index Name</th>
prompt <th class='awrbg'>Index Type</th>
prompt <th class='awrbg'>Tablespace</th>
prompt <th class='awrbg'>Table Owner</th>
prompt <th class='awrbg'>Table Name</th>
prompt <th class='awrbg'>Unique</th>
prompt <th class='awrbg'>Blevel</th>
prompt <th class='awrbg'>Leaf Blks</th>
prompt <th class='awrbg'>Dictinct Keys</th>
prompt <th class='awrbg'>Cluster Factor</th>
prompt <th class='awrbg'>Num Rows</th>
prompt <th class='awrbg'>Analyzed</th>
prompt <th class='awrbg'>Degree</th>
prompt <th class='awrbg'>Partitioned</th></tr>

select '<tr><td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||owner||'</b></font>',owner)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||index_name||'</b></font>',index_name)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||index_type||'</b></font>',index_type)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||tablespace_name||'</b></font>',tablespace_name)||'</td>
			<td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||table_owner||'</b></font>',table_owner)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||table_name||'</b></font>',table_name)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||uniqueness||'</b></font>',uniqueness)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||blevel||'</b></font>',blevel)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||leaf_blocks||'</b></font>',leaf_blocks)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||distinct_keys||'</b></font>',distinct_keys)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||clustering_factor||'</b></font>',clustering_factor)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||num_rows||'</b></font>',num_rows)||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss')||'</b></font>',to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss'))||'</td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||degree||'</b></font>',degree)||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||partitioned||'</b></font>',partitioned)||'</td></tr>'
from ( select p.tips,
              i.owner,
              i.index_name,
              i.index_type,
              i.tablespace_name,
              i.table_owner,
              i.table_name,
              i.uniqueness,
              i.blevel,
              i.leaf_blocks,
              i.distinct_keys,
              i.clustering_factor,
              i.num_rows,
              i.last_analyzed,
              i.degree,
              i.partitioned
         from dba_indexes i,
		      (select min(decode(s.object_type,'INDEX','I','T')) tips,decode(s.object_type,'INDEX',s.object_name,d.index_name) object_name,s.object_owner
			     from dba_hist_sql_plan s,dba_indexes d
				where s.sql_id=:sqlid
				  and ((s.object_owner=d.owner and s.object_name=d.index_name and s.object_type='INDEX')
				       or (s.object_owner=d.table_owner and s.object_name=d.table_name and s.object_type='TABLE'))
				group by decode(s.object_type,'INDEX',s.object_name,d.index_name),s.object_owner) p
        where i.owner=p.object_owner
		  and p.object_name =i.index_name
        order by table_owner,table_name);
prompt </table> <p>
prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />


--=========================================================================
--|
--|   Index Columns Detail
--|
--=========================================================================
prompt <a class='awr' name="index_columns_detail"></a>
set termout on
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Index Columns Detail</b></font><hr align="left" width="460">
prompt <font class="awr"> <li>   Lines with Red Color means used in the plan ! </li></font></br>

prompt <table width='60%' border="1"> 
prompt <tr><th class='awrbg'>Index Owner</th>
prompt <th class='awrbg'>Index Name</th>
prompt <th class='awrbg'>Table Owner</th>
prompt <th class='awrbg'>Table Name</th>
prompt <th class='awrbg'>Column Name</th>
prompt <th class='awrbg'>Position</th>
prompt <th class='awrbg'>Descend</th></tr>

select '<tr><td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||index_owner||'</b></font>',index_owner)||'</b></font></td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||index_name||'</b></font>',index_name)||'</b></font></td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||table_owner||'</b></font>',table_owner)||'</b></font></td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||table_name||'</b></font>',table_name)||'</b></font></td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||column_name||'</b></font>',column_name)||'</b></font></td>
            <td align="right" class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||column_position||'</b></font>',column_position)||'</b></font></td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||decode(tips,'I','<font color="red"><b>'||descend||'</b></font>',descend )||'</b></font></td></tr>'
from ( select p.tips,
              i.index_owner,
              i.index_name,
              i.table_owner,
              i.table_name,
              i.column_name,
              i.column_position,
              i.descend 
         from dba_ind_columns i,
		      (select min(decode(s.object_type,'INDEX','I','T')) tips,decode(s.object_type,'INDEX',s.object_name,d.index_name) object_name,s.object_owner
			     from dba_hist_sql_plan s,dba_indexes d
				where s.sql_id=:sqlid
				  and ((s.object_owner=d.owner and s.object_name=d.index_name and s.object_type='INDEX')
				       or (s.object_owner=d.table_owner and s.object_name=d.table_name and s.object_type='TABLE'))
				group by decode(s.object_type,'INDEX',s.object_name,d.index_name),s.object_owner) p
        where i.index_owner=p.object_owner
		  and p.object_name =i.index_name
        order by index_owner,index_name,column_position);
prompt </table> <p>
prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />

--=========================================================================
--|
--|   Table Constraints
--|
--=========================================================================
prompt <a class='awr' name="table_constraints"></a>
set termout on
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Table Constraints</b></font><hr align="left" width="460">

prompt <table width='80%' border="1"> 
prompt <tr><th class='awrbg'>Owner</th>
prompt <th class='awrbg'>Table Name</th>
prompt <th class='awrbg'>Constraint Name</th>
prompt <th class='awrbg'>Constraint Type</th>
prompt <th class='awrbg'>Ref. Owner</th>
prompt <th class='awrbg'>Ref. Constraint</th>
prompt <th class='awrbg'>Status</th>
prompt <th class='awrbg'>Deferred</th>
prompt <th class='awrbg'>Validated</th>
prompt <th class='awrbg'>Last Change</th></tr>

select '<tr><td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||owner||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||table_name||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||constraint_name||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||constraint_type||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||r_owner||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||r_constraint_name||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||status||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||deferred||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||validated||'</td>
            <td class="awr'||decode(mod(rownum,2),0,'nc">','c">')||to_char(last_change,'yyyy-mm-dd hh24:mi:ss')||'</td> </tr>'
  from ( select c.owner,
                table_name,
                constraint_name,
                constraint_type,
                r_owner,
                r_constraint_name,
                status,
                deferred,
                validated,
                last_change
           from dba_constraints c,
		   		(select distinct s.object_owner owner,
			            decode(object_type,'TABLE',s.object_name,i.table_name) object_name
			       from dba_indexes i,dba_hist_sql_plan s 
			      where s.sql_id=:sqlid 
			        and s.object_owner=i.owner(+) 
				    and s.object_name=i.index_name(+)) p
          where c.owner=p.owner
		    and c.table_name=p.object_name
          order by c.owner,table_name,constraint_type);
prompt </table> <p>
prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />

--=========================================================================
--|
--|   Partition Objects : Table and Index
--|
--=========================================================================
prompt <a class='awr' name="partition_statistics"></a>
set termout on
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Partition Statistics</b></font><hr align="left" width="460">

--Partition Summary
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Partition Summary</b></font><hr align="left" width="460">

prompt <table width='80%' border="1"> -
<tr><th class='awrbg'>Owner</th> -
<th class='awrbg'>Object Name</th> -
<th class='awrbg'>Object Type</th> -
<th class='awrbg'>Partition Type</th> -
<th class='awrbg'>Partition Count</th> -
<th class='awrbg'>Partition Column</th> -
<th class='awrbg'>SubPartition Type</th> -
<th class='awrbg'>SubPartition Count</th> -
<th class='awrbg'>SubPartition Column</th></tr>

select '<tr><td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.owner||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.tname||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||pc.object_type||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.ptype||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.pcount||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||pc.columns||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.sptype||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||o.spcount||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||spc.columns||'</td></tr>'
  from ( select owner,object_type,name,max(decode(column_position,1,column_name,null))
                         ||max(decode(column_position,2,', '||column_name,null))
                         ||max(decode(column_position,3,', '||column_name,null))
                         ||max(decode(column_position,4,', '||column_name,null))
                         ||max(decode(column_position,5,', '||column_name,null)) columns
           from dba_PART_KEY_COLUMNS 
          group by owner,object_type,name) pc,
       ( select owner,name,max(decode(column_position,1,column_name,null))
                         ||max(decode(column_position,2,', '||column_name,null))
                         ||max(decode(column_position,3,', '||column_name,null))
                         ||max(decode(column_position,4,', '||column_name,null))
                         ||max(decode(column_position,5,', '||column_name,null)) columns
           from dba_subPART_KEY_COLUMNS 
          group by owner,object_type,name) spc,
       ( select OWNER,
                TABLE_NAME tname,
                PARTITIONING_TYPE ptype,
                SUBPARTITIONING_TYPE sptype,
                PARTITION_COUNT pcount,
                DEF_SUBPARTITION_COUNT spcount
           from dba_part_tables
          union all
         select OWNER,
                INDEX_NAME tname,
                PARTITIONING_TYPE ptype,
                SUBPARTITIONING_TYPE sptype,
                PARTITION_COUNT pcount,
                DEF_SUBPARTITION_COUNT spcount
           from dba_part_indexes) o,
		( select object_owner,
		         object_name
		    from dba_hist_sql_plan
		   where sql_id=:sqlid
		     and object_name is not null
           union
		  select owner,
		         table_name
		    from dba_hist_sql_plan s1,dba_indexes i1
		   where sql_id=:sqlid
		     and s1.object_type='INDEX'
		     and s1.object_owner=i1.owner
			 and s1.object_name=i1.index_name
           union
          select owner,
		         index_name
		    from dba_hist_sql_plan s2,dba_indexes i2
		   where sql_id=:sqlid
		     and s2.object_type='TABLE'
		     and s2.object_owner=i2.owner
			 and s2.object_name=i2.table_name) p
 where p.object_owner=pc.owner
   and p.object_owner=spc.owner(+)
   and p.object_owner=o.owner
   and p.object_name=pc.name
   and p.object_name=spc.name(+)
   and p.object_name=o.tname;
prompt </table> <p>

--Partition Table Detial
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Partition Table Detail</b></font><hr align="left" width="460">

prompt <table width='100%' border="1"> -
<tr><th class='awrbg'>Owner</th> -
<th class='awrbg'>Table Name</th> -
<th class='awrbg'>Partition No.</th> -
<th class='awrbg'>Partition Name</th> -
<th class='awrbg'>Sub Count</th> -
<th class='awrbg'>Tbs. Name</th> -
<th class='awrbg'>Rows</th> -
<th class='awrbg'>Blocks</th> -
<th class='awrbg'>Avg Space</th> -
<th class='awrbg'>Chaines</th> -
<th class='awrbg'>Avg Row Len</th> -
<th class='awrbg'>Last Analyzed</th></tr>

select '<tr><td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||table_owner||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||table_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||partition_position||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||partition_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||subpartition_count||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||tablespace_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||num_rows||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||blocks||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||avg_space||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||chain_cnt||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||avg_row_len||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss')||'</td></tr>'
  from dba_tab_partitions tp,
		   		(select distinct s.object_owner owner,
			            decode(object_type,'TABLE',s.object_name,i.table_name) object_name
			       from dba_indexes i,dba_hist_sql_plan s 
			      where s.sql_id=:sqlid 
			        and s.object_owner=i.owner(+) 
				    and s.object_name=i.index_name(+)) p
 where tp.table_owner=p.owner
   and tp.table_name=p.object_name
 order by table_owner,table_name,partition_position;
prompt </table> <p>


--Partition Index Detial
prompt <font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Partition Index Detail</b></font><hr align="left" width="460">

prompt <table width='100%' border="1"> -
<tr><th class='awrbg'>Owner</th> -
<th class='awrbg'>Index Name</th> -
<th class='awrbg'>Partition No.</th> -
<th class='awrbg'>Partition Name</th> -
<th class='awrbg'>Status</th> -
<th class='awrbg'>Sub Count</th> -
<th class='awrbg'>Tbs. Name</th> -
<th class='awrbg'>Blevel</th> -
<th class='awrbg'>Leaf Blocks</th> -
<th class='awrbg'>Distinct</th> -
<th class='awrbg'>Cluster Factor</th> -
<th class='awrbg'>Rows</th> -
<th class='awrbg'>Last Analyzed</th></tr>

select '<tr><td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||index_owner||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||index_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||partition_position||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||partition_name||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||status||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||subpartition_count||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||tablespace_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||blevel||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||leaf_blocks||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||distinct_keys||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||clustering_factor||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||num_rows||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||to_char(last_analyzed,'yyyy-mm-dd hh24:mi:ss')||'</td></tr>'
  from dba_ind_partitions ip,
		(select decode(s.object_type,'INDEX',s.object_name,d.index_name) object_name,s.object_owner
		   from dba_hist_sql_plan s,dba_indexes d
		  where s.sql_id=:sqlid
		    and ((s.object_owner=d.owner and s.object_name=d.index_name and s.object_type='INDEX')
		        or (s.object_owner=d.table_owner and s.object_name=d.table_name and s.object_type='TABLE'))
		  group by decode(s.object_type,'INDEX',s.object_name,d.index_name),s.object_owner) p
 where ip.index_owner=p.object_owner
   and ip.index_name=p.object_name
 order by index_owner,index_name,partition_position;
prompt </table> <p>

prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />


--=========================================================================
--|
--|   Lob Statistics
--|
--=========================================================================
prompt <a class='awr' name="lob_statistics"></a>
set termout on 
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Lob Statistics</b></font><hr align="left" width="460">

prompt <table width='100%' border="1"> -
<tr><th class='awrbg'>Owner</th> -
<th class='awrbg'>Table Name</th> -
<th class='awrbg'>Column Name</th> -
<th class='awrbg'>Segment Name</th> -
<th class='awrbg'>Tablespace Name</th> -
<th class='awrbg'>Index Name</th> -
<th class='awrbg'>Chunk</th> -
<th class='awrbg'>Pct Version</th> -
<th class='awrbg'>Retention</th> -
<th class='awrbg'>Cache</th> -
<th class='awrbg'>In Row</th> -
<th class='awrbg'>Format</th> -
<th class='awrbg'>Partitioned</th></tr>

select '<tr><td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||l.owner||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||table_name||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||column_name||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||segment_name||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||tablespace_name||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||index_name||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||chunk||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||pctversion||'</td>
            <td align="right" class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||retention||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||cache||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||in_row||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||format||'</td>
            <td class=''awr'||decode(mod(rownum,2),0,'n','')||'c''>'||partitioned||'</td></tr>'
  from dba_lobs l,
	   (select distinct s.object_owner owner,
	           decode(object_type,'TABLE',s.object_name,i.table_name) object_name
	      from dba_indexes i,dba_hist_sql_plan s 
	     where s.sql_id=:sqlid 
	       and s.object_owner=i.owner(+) 
	       and s.object_name=i.index_name(+)) p
 where l.owner=p.owner
   and l.table_name=p.object_name
 order by l.owner, table_name;
prompt </table> <p>

prompt <br /><a class='awr' HREF="#top">Back to Top</a>
prompt <br /><a class='awr' HREF="#contents">Back to More Statisticss</a><p />



--=========================================================================
--|
--|   Columns Histogram
--|
--=========================================================================
prompt <a class='awr' name="columns_histogram"></a>
set termout on serveroutput on
prompt <font size="+2" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b>Columns Histogram</b></font><hr align="left" width="460">

declare
  color_tips   varchar2(5);   
  cn           number;
  cv           varchar2(32);
  cd           date;
  cnv          nvarchar2(32);
  cr           rowid;
  cc           char(32);
  l_data_type  varchar2(100) :='';
  l_low_value  varchar2(32767);
  l_high_value varchar2(32767);
  l_value_str  varchar2(4000);
  l_real_value varchar2(4000);
begin
  dbms_output.enable(1024 * 1048576);
  --print histogram head
  dbms_output.put_line('<a name="histogram_contents">');
  dbms_output.put_line('<table width="40%" border="1"> <tr><th colspan="2" class=''awrbg''>Histogram Contents</th></tr>');
  dbms_output.put_line('<tr><th align="right" class=''awrbg''>Histogram No.</th><th align="left" class=''awrbg''>Histogram</th></tr>');
  for x in (select rownum id, histogram, owner, table_name, column_name
              from dba_tab_columns
             where (owner, table_name) in
                   (select distinct OBJECT_OWNER, OBJECT_NAME
                      from dba_hist_sql_plan
                     where object_owner is not null
                       and sql_id = :sqlid)
               and histogram != 'NONE') loop
    select decode(mod(x.id, 2), 0, 'n', '') into color_tips from dual;
    dbms_output.put_line('<tr> <td nowrap align="right" class="awr' || color_tips || 'c" width="30%"> ' || x.id || ' </td>');
    dbms_output.put_line('<td nowrap align="left" class="awr' || color_tips || 'c" width="70%"> <a class="awr" href="#' ||
                         x.owner || '_' || x.table_name || '_' ||
                         x.column_name || '"> Histogram : ' || x.histogram ||
                         ' on ' || x.owner || '.' || x.table_name || '.' ||
                         x.column_name || '</a></td> ');
  end loop;
  dbms_output.put_line('</table> </p>');

  --print histogram body
  for x in (select histogram, owner, table_name, column_name
              from dba_tab_columns
             where (owner, table_name) in
                   (select distinct OBJECT_OWNER, OBJECT_NAME
                      from dba_hist_sql_plan
                     where object_owner is not null
                       and sql_id = :sqlid)
               and histogram != 'NONE') loop
    dbms_output.put_line('<a name="' || x.owner || '_' 
	                     || x.table_name || '_' ||x.column_name || '">');
    dbms_output.put_line('<font size="+1" face="Arial,Helvetica,Geneva,sans-serif" color="#336699"><b> Histogram : ' 
	                     || x.histogram || ' on ' || x.owner || '.' ||x.table_name || '.' || x.column_name 
						 ||'</b></font><hr align="left" width="333">');
  
    dbms_output.put_line('<table width="80%" border="1"> <tr>
           <th class="awrbg">Owner</th>
           <th class="awrbg">table Name</th>
           <th class="awrbg">Column Name</th>
           <th class="awrbg">Histogram</th>
           <th class="awrbg">Data Type</th>
           <th class="awrbg">Num Nulls</th>
           <th class="awrbg">Density</th>
           <th class="awrbg">Num Distinct</th>
           <th class="awrbg">Bound</th></tr>');
    for y in (select data_type,
                     decode(nullable, 'Y', to_char(num_nulls), 'N') num_nulls,
                     density,
                     num_distinct,
					 low_value,
					 high_value
                from dba_tab_columns
               where owner = x.owner
                 and table_name = x.table_name
                 and column_name = x.column_name) loop
	  l_data_type:=y.data_type;
	  if (y.data_type = 'NUMBER') then
        dbms_stats.convert_raw_value(y.low_value, cn);
        l_low_value:=to_char(cn);
        dbms_stats.convert_raw_value(y.high_value, cn);
        l_high_value:=to_char(cn);
      elsif (y.data_type = 'VARCHAR2') then
        dbms_stats.convert_raw_value(y.low_value, cv);
        l_low_value:=cv;
        dbms_stats.convert_raw_value(y.high_value, cv);
        l_high_value:=cv;
      elsif (y.data_type = 'DATE') then
        dbms_stats.convert_raw_value(y.low_value, cd);
        l_low_value:=to_char(cd,'yyyy-mm-dd hh24:mi:ss');
        dbms_stats.convert_raw_value(y.high_value, cd);
        l_high_value:=to_char(cd,'yyyy-mm-dd hh24:mi:ss');
      elsif (y.data_type = 'NVARCHAR2') then
        dbms_stats.convert_raw_value(y.low_value, cnv);
        l_low_value:=to_char(cnv);
        dbms_stats.convert_raw_value(y.high_value, cnv);
        l_high_value:=to_char(cnv);
      elsif (y.data_type = 'ROWID') then
        dbms_stats.convert_raw_value(y.low_value, cr);
        l_low_value:=to_char(cr);
        dbms_stats.convert_raw_value(y.high_value, cr);
        l_high_value:=to_char(cr);
      elsif (y.data_type = 'CHAR') then
        dbms_stats.convert_raw_value(y.low_value, cc);
        l_low_value:=cc;
        dbms_stats.convert_raw_value(y.high_value, cc);
        l_high_value:=cc;
      else
        l_low_value:=y.low_value;
        l_high_value:=y.high_value;
      end if;
      dbms_output.put_line('<tr><td class="awrc">'||x.owner||'</td> <td class="awrc">' || x.table_name ||'</td><td class="awrc">' 
	                        ||x.column_name ||'</td> <td class="awrc">' || x.histogram ||'</td> <td class="awrc">' || y.data_type 
							||'</td> <td class="awrc">' || y.num_nulls  ||'</td> <td align="right" class="awrc">' || y.density 
							||'</td><td align="right" class="awrc">' ||y.num_distinct ||'</td><td class="awrc">' ||l_low_value||' -- '||l_high_value 
							|| '</td></tr>');
    end loop;
    dbms_output.put_line('<table></p>');
  
    dbms_output.put_line('<table width="60%" border="1"> <tr>
           <th class="awrbg">Owner</th>
           <th class="awrbg">table Name</th>
           <th class="awrbg">Column Name</th>
           <th class="awrbg">Endpoint No.</th>
           <th class="awrbg">Endpoint Value</th>
           <th class="awrbg">Actual Value</th></tr>');
    for z in (select rownum id, endpoint_number, endpoint_value, endpoint_actual_value
                from dba_tab_histograms
               where owner = x.owner
                 and table_name = x.table_name
                 and column_name = x.column_name
               order by endpoint_number) loop
      select decode(mod(z.id, 2), 0, 'n', '') into color_tips from dual;
	  -- Convert endpoint value to string
	  
	  if l_data_type IN ('CHAR', 'VARCHAR2', 'NCHAR', 'NVARCHAR2') THEN
	    l_value_str:= to_char(z.endpoint_value,'fm'||rpad('x',62,'x'));
        l_real_value:='';
        while ( l_value_str is not null ) loop
          l_real_value := l_real_value || chr(to_number(substr(l_value_str,1,2),'xx'));
          l_value_str := substr( l_value_str, 3 );
        end loop;
      ELSE
        l_real_value:=to_char(z.endpoint_value);
      END if;
	  
      dbms_output.put_line('<tr><td class="awr' || color_tips || 'c">'||x.owner||'</td> <td class="awr' || color_tips || 'c">' || x.table_name
	                       ||'</td> <td class="awr' || color_tips || 'c">'||x.column_name ||'</td> <td align="right" class="awr' || color_tips 
						   || 'c">'||z.endpoint_number ||'</td> <td align="right" class="awr' || color_tips || 'c">' ||l_real_value 
						   ||'</td> <td align="right" class="awr' || color_tips || 'c">' ||z.endpoint_actual_value || '</td></tr>');
    end loop;
    dbms_output.put_line('<table></p>');
    dbms_output.put_line('<br /><a class="awr" HREF="#top">Back to Top</a>');
    dbms_output.put_line('<br /><a class="awr" HREF="#contents">Back to More Statisticss</a>');
    dbms_output.put_line('<br /><a class="awr" HREF="#histogram_contents">Back to Histogram Contents</a><p />');
  end loop;
end;
/

--=========================================================================
--|
--|   Game Over !
--|
--=========================================================================

spool off;

prompt Report written to &report_name.


--print :dbid
--print :eid
--print :bid
--print :sqlid

-- undefine report name (created in awrinpnm.sql)
undefine :report_name

-- undefine sql_id
undefine :sql_id

undefine :NO_OPTIONS

undefine :top_n_events
undefine :num_days
undefine :top_n_sql
undefine :top_pct_sql
undefine :sh_mem_threshold
undefine :top_n_segstat

whenever sqlerror continue;
--
--  End of script file;
