set lines 155
select * from table(dbms_xplan.display_cursor(format=>'all,last,allstats,peeked_binds'));
