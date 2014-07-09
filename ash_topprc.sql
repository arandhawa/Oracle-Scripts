-- (c) Kyle Hailey 2007

set linesize 120
col entry_package for a25
col entry_procedure for a25
col cur_package for a25
col cur_procedure for a25
col calling_code for a70
select 
    count(*), 
    sql_id,
    procs1.object_name || decode(procs1.procedure_name,'','','.')||
    procs1.procedure_name ||' '||
    decode(procs2.object_name,procs1.object_name,'',
	 decode(procs2.object_name,'','',' => '||procs2.object_name)) 
    ||
    decode(procs2.procedure_name,procs1.procedure_name,'',
        decode(procs2.procedure_name,'','',null,'','.')||procs2.procedure_name)
    "calling_code"
from v$active_session_history  ash,
     all_procedures procs1,
     all_procedures procs2
 where
       ash.PLSQL_ENTRY_OBJECT_ID  = procs1.object_id (+)
   and ash.PLSQL_ENTRY_SUBPROGRAM_ID = procs1.SUBPROGRAM_ID (+)
   and ash.PLSQL_OBJECT_ID   = procs2.object_id (+)
   and ash.PLSQL_SUBPROGRAM_ID  = procs2.SUBPROGRAM_ID (+)
   and ash.sample_time > sysdate - &minutes/(60*24)
group by procs1.object_name, procs1.procedure_name, 
         procs2.object_name, procs2.procedure_name,sql_id
order by count(*)
/ 

