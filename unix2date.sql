SELECT 
    TO_CHAR(TO_DATE('01011970','DDMMYYYY') + 1/24/60/60 * &1, 'DD-MON-YYYY HH24:MI:SS') "DATE"
FROM DUAL
/
