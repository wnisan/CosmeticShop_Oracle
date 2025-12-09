-- Усиление безопасности
BEGIN
  -- Отзыв прав
  FOR r IN (SELECT table_name FROM user_tables) LOOP
    BEGIN 
      EXECUTE IMMEDIATE 'REVOKE ALL ON '||r.table_name||' FROM PUBLIC'; 
    EXCEPTION WHEN OTHERS THEN NULL; 
    END;
  END LOOP;
  
  -- Предоставление прав на представления
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_product_overview TO COSM_ROLE_USER';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_popular_products TO COSM_ROLE_USER';
  
  DBMS_OUTPUT.PUT_LINE('Безопасность усилена');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка настройки безопасности: ' || SQLERRM);
  
END;
/

