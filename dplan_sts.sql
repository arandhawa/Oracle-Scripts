set lines 132
select * from table(dbms_xplan.display_sqlset('MY10GSTS1_ZWA','&sql_id',sqlset_owner=>'DBMON'));
