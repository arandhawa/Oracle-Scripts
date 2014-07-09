-- Purpose:     show plan for statement in AWR history
---
--- http://kerryosborne.oracle-guy.com/
---
set lines 155
set pages 9999
SELECT * FROM table(dbms_xplan.display_awr('&sql_id',nvl('&plan_hash_value',null),null,'ADVANCED +ALLSTATS LAST +MEMSTATS LAST'))
--SELECT * FROM table(dbms_xplan.display_awr(nvl('&sql_id','a96b61z6vp3un'),nvl('&plan_hash_value',null),null,'typical +peeked_binds'))
/
