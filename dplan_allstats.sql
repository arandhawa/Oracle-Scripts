-- Purpose:     show plan with extended stats
set lines 180
select * from table(dbms_xplan.display_cursor('&sql_id','&child_no','allstats  +peeked_binds'))
/
