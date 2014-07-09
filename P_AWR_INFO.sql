create or replace
PROCEDURE P_AWR_INFO
 AS
  TYPE T_VARCHAR IS TABLE OF VARCHAR2(1500 CHAR) INDEX BY BINARY_INTEGER;
  V_DBNAME  T_VARCHAR;
  V_INSNAME T_VARCHAR;

  TYPE T_NUM IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
	V_INSTANCE T_NUM;
	V_DBID T_NUM;
BEGIN
  select distinct(dbid),instance_number,instance_name,db_name
  BULK COLLECT INTO V_DBID,V_INSTANCE,V_INSNAME,V_DBNAME
  from wrm$_database_instance order by dbid;

   DBMS_OUTPUT.PUT_LINE('Database Awr INFO:');
   DBMS_OUTPUT.PUT_LINE('------------------------------------------- -----------');

    FOR I IN V_DBID.FIRST .. V_DBID.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(V_DBID(I) ||' . '|| V_INSTANCE(i)||' . '||V_INSNAME(I)||' . '||V_DBNAME(I));
    END LOOP;
END;

/*
select distinct(dbid),instance_number,instance_name,db_name
from wrm$_database_instance order by dbid;
*/
