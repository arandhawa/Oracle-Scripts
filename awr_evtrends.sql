-- Purpose:     Tim Gorman's script to display event trends
/**********************************************************************
 * File:        awr_evtrends.sql
 * Type:        SQL*Plus script
 * Author:      Tim Gorman (Evergreen Database Technologies, Inc.)
 * Date:        15-Jul-2003
 *
 * Description:
 *      Query to display "trends" for specific statistics captured in
 *	the AWR repository, and display summarized totals daily and
 *	hourly as a ratio using the RATIO_FOR_REPORT analytic function.
 *
 *	The intent is to find the readings with the greatest deviation
 *	from the average value, as these are likely to be "periods of
 *	interest" for further, more detailed research...
 *
 * Modifications:
 *	TGorman 25aug08	adapted from similar script for STATSPACK
 *	Kerry Osborne 15Jun09 skip the listing of events
 *********************************************************************/
set echo off feedback off timing off pagesize 200 linesize 200
set trimout on trimspool on verify off
col sort0 noprint
col day format a6 heading "Day"
col hr format a6 heading "Hour"
col time_waited format 999,999,999,990.00 heading "Secs Waited"
col rtr format 990.00 heading "Ratio"

prompt
/* skip this part - KSO
prompt Some useful database statistics to search upon:
col name format a60 heading "Name"
select  chr(9)||name name
from	v$event_name
order by 1;
*/
accept V_EVENTNAME prompt "What wait-event do you want to analyze? "

col spoolname new_value V_SPOOLNAME noprint
select	replace(replace(replace(lower('&&V_EVENTNAME'),' ','_'),'(',''),')','') spoolname
from	dual;

spool awr_evtrends_&&V_SPOOLNAME
clear breaks computes
break on report
col ratio format a50 heading "Percentage of total over all days"
col name format a30 heading "Statistic Name"
prompt
prompt Daily trends for "&&V_EVENTNAME"...
select	sort0,
	day,
	name,
	time_waited,
	(ratio_to_report(time_waited) over (partition by name)*100) rtr,
	rpad('*', round((ratio_to_report(time_waited) over (partition by name)*100)/2, 0), '*') ratio
from	(select	sort0,
		day,
		name,
		sum(time_waited)/1000000 time_waited
	 from	(select	to_char(ss.end_interval_time, 'YYYYMMDD') sort0,
			to_char(ss.end_interval_time, 'DD-MON') day,
			s.snap_id,
			s.event_name name,
			nvl(decode(greatest(s.time_waited_micro,
					    nvl(lag(s.time_waited_micro)
						    over (partition by	s.dbid,
									s.instance_number,
									s.event_name order by s.snap_id),0)),
				   s.time_waited_micro,
				   s.time_waited_micro - lag(s.time_waited_micro)
							     over (partition by	s.dbid,
										s.instance_number,
										s.event_name order by s.snap_id),
					  s.time_waited_micro), 0) time_waited
		 from	dba_hist_system_event			s,
			dba_hist_snapshot			ss
		 where	s.event_name like '%'||'&&V_EVENTNAME'||'%'
		 and	ss.snap_id = s.snap_id
		 and	ss.dbid = s.dbid
		 and	ss.instance_number = s.instance_number)
	 group by sort0,
		  day,
		  name)
order by sort0, name;

clear breaks computes
break on day skip 1 on hr on report
col ratio format a50 heading "Percentage of total over all hours for each day"
prompt
prompt Daily/hourly trends for "&&V_EVENTNAME"...
select	sort0,
	day,
	hr,
	name,
	time_waited,
	(ratio_to_report(time_waited) over (partition by day, name)*100) rtr,
	rpad('*', round((ratio_to_report(time_waited) over (partition by day, name)*100)/2, 0), '*') ratio
from	(select	sort0,
		day,
		hr,
		name,
		sum(time_waited)/1000000 time_waited
	 from	(select	to_char(ss.end_interval_time, 'YYYYMMDDHH24') sort0,
			to_char(ss.end_interval_time, 'DD-MON') day,
			to_char(ss.end_interval_time, 'HH24')||':00' hr,
			s.snap_id,
			s.event_name name,
			nvl(decode(greatest(s.time_waited_micro,
				   nvl(lag(s.time_waited_micro)
					   over (partition by	s.dbid,
								s.instance_number,
								s.event_name order by s.snap_id),0)),
				   s.time_waited_micro,
				   s.time_waited_micro - lag(s.time_waited_micro)
							     over (partition by	s.dbid,
										s.instance_number,
										s.event_name order by s.snap_id),
					  s.time_waited_micro), 0) time_waited
		 from	dba_hist_system_event			s,
			dba_hist_snapshot			ss
		 where	s.event_name like '%'||'&&V_EVENTNAME'||'%'
		 and	ss.snap_id = s.snap_id
		 and	ss.dbid = s.dbid
		 and	ss.instance_number = s.instance_number)
	 group by sort0,
		  day,
		  hr,
		  name)
order by sort0, name;
spool off
set verify on feedback 6

