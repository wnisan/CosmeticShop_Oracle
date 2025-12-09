CREATE OR REPLACE PACKAGE pkg_json AS
  PROCEDURE export_orders(p_filename VARCHAR2, p_limit NUMBER DEFAULT NULL);
  PROCEDURE import_orders(p_filename VARCHAR2);
  FUNCTION test_json_operations RETURN VARCHAR2;
  PROCEDURE check_directory_access; 
END pkg_json;
/

CREATE OR REPLACE PACKAGE BODY pkg_json AS

  PROCEDURE check_directory_access IS
    v_dir_path VARCHAR2(4000);
    v_has_write NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ПРОВЕРКА ДОСТУПА К ДИРЕКТОРИИ COSM_JSON_DIR');
    
    BEGIN
      SELECT directory_path INTO v_dir_path
      FROM all_directories
      WHERE directory_name = 'COSM_JSON_DIR';
      DBMS_OUTPUT.PUT_LINE('Директория найдена: ' || v_dir_path);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ОШИБКА: Директория COSM_JSON_DIR не найдена!');
        RAISE_APPLICATION_ERROR(-20001, 'Директория COSM_JSON_DIR не найдена');
    END;
    
    -- Права на запись
    SELECT COUNT(*) INTO v_has_write
    FROM user_tab_privs
    WHERE table_name = 'COSM_JSON_DIR'
      AND privilege = 'WRITE';
    
    IF v_has_write = 0 THEN
      SELECT COUNT(*) INTO v_has_write
      FROM all_tab_privs
      WHERE grantee = USER
        AND table_name = 'COSM_JSON_DIR'
        AND privilege = 'WRITE';
    END IF;
    
    IF v_has_write > 0 THEN
      DBMS_OUTPUT.PUT_LINE('Права WRITE: ЕСТЬ');
    ELSE
      DBMS_OUTPUT.PUT_LINE('ВНИМАНИЕ: Права WRITE отсутствуют!');
    END IF;
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка проверки прав: ' || SQLERRM);
    RAISE;
  END;

  PROCEDURE export_orders(p_filename VARCHAR2, p_limit NUMBER DEFAULT NULL) IS
    v_file UTL_FILE.FILE_TYPE;
    v_count NUMBER := 0;
    v_dir_path VARCHAR2(4000);
    v_test_path VARCHAR2(4000);
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' ЭКСПОРТ ЗАКАЗОВ ');
    DBMS_OUTPUT.PUT_LINE('Файл: ' || p_filename);
    DBMS_OUTPUT.PUT_LINE('Лимит: ' || NVL(TO_CHAR(p_limit), 'без ограничений'));
    
    -- Проверка директории
    check_directory_access;
    
    -- Попытка открыть файл с детальной диагностикой
    BEGIN
      v_file := UTL_FILE.FOPEN('COSM_JSON_DIR', p_filename, 'W', 32767);
      DBMS_OUTPUT.PUT_LINE('Файл успешно открыт для записи');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ОШИБКА открытия файла: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Код ошибки: ' || SQLCODE);
        
        -- Дополнительная диагностика
        BEGIN
          SELECT directory_path INTO v_dir_path
          FROM all_directories
          WHERE directory_name = 'COSM_JSON_DIR';
          v_test_path := v_dir_path || '/' || p_filename;
          DBMS_OUTPUT.PUT_LINE('Полный путь: ' || v_test_path);
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Не удалось получить путь директории');
        END;
        RAISE;
    END;
    
    -- Экспорт данных
    BEGIN
      UTL_FILE.PUT(v_file, '[');
      
      FOR v_row IN (
        SELECT JSON_OBJECT(
          'order_id' VALUE o.order_id,
          'customer_email' VALUE c.email,
          'customer_name' VALUE c.full_name,
          'order_date' VALUE TO_CHAR(o.order_date, 'YYYY-MM-DD'),
          'status' VALUE o.status,
          'total_amount' VALUE o.total_amount
        ) AS json_data 
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
        WHERE p_limit IS NULL OR ROWNUM <= p_limit
        ORDER BY o.order_id
      ) LOOP
        IF v_count > 0 THEN
          UTL_FILE.PUT(v_file, ',');
        END IF;
        UTL_FILE.PUT_LINE(v_file, v_row.json_data);
        v_count := v_count + 1;
        
        -- Прогресс для больших файлов
        IF MOD(v_count, 100) = 0 THEN
          DBMS_OUTPUT.PUT('.');  
        END IF;
      END LOOP;
      
      UTL_FILE.PUT_LINE(v_file, ']');
      UTL_FILE.FCLOSE(v_file);
      
      DBMS_OUTPUT.NEW_LINE;
      DBMS_OUTPUT.PUT_LINE('Экспорт завершен успешно');
      DBMS_OUTPUT.PUT_LINE('Экспортировано заказов: ' || v_count);
      
    EXCEPTION
      WHEN OTHERS THEN
        IF UTL_FILE.IS_OPEN(v_file) THEN 
          UTL_FILE.FCLOSE(v_file); 
        END IF;
        DBMS_OUTPUT.PUT_LINE('ОШИБКА при экспорте данных: ' || SQLERRM);
        RAISE;
    END;
    
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('КРИТИЧЕСКАЯ ОШИБКА экспорта: ' || SQLERRM);
    RAISE;
  END;

-- Импорт данных
PROCEDURE import_orders(p_filename VARCHAR2) IS
    v_file UTL_FILE.FILE_TYPE;
    v_buffer VARCHAR2(32767);
    v_json_data CLOB;
    v_customer_id NUMBER;
    v_processed NUMBER := 0;
    v_created NUMBER := 0;
    v_updated NUMBER := 0;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Импорт из: ' || p_filename);
    
    v_file := UTL_FILE.FOPEN('COSM_JSON_DIR', p_filename, 'R', 32767);
    BEGIN
      LOOP
        UTL_FILE.GET_LINE(v_file, v_buffer);
        v_json_data := v_json_data || v_buffer;
      END LOOP;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL; END;
    UTL_FILE.FCLOSE(v_file);
    
    IF v_json_data IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('Файл пустой');
      RETURN;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Длина JSON данных: ' || LENGTH(v_json_data) || ' символов');
    
    FOR rec IN (
      SELECT order_id, customer_email, customer_name, order_date, status, total_amount
      FROM JSON_TABLE(v_json_data, '$[*]' 
        COLUMNS (
          order_id       NUMBER PATH '$.order_id',
          customer_email VARCHAR2(200) PATH '$.customer_email',
          customer_name  VARCHAR2(200) PATH '$.customer_name',
          order_date     VARCHAR2(20) PATH '$.order_date',
          status         VARCHAR2(30) PATH '$.status',
          total_amount   NUMBER PATH '$.total_amount'
        )
      )
    ) LOOP
      v_processed := v_processed + 1;
      
      DBMS_OUTPUT.PUT('Обработка заказа ' || rec.order_id || ' для ' || rec.customer_email || '... ');
      
      BEGIN
        SELECT customer_id INTO v_customer_id 
        FROM customers 
        WHERE email = rec.customer_email;
        DBMS_OUTPUT.PUT('клиент найден (ID=' || v_customer_id || ')');
      EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO customers(customer_id, email, full_name)
        VALUES(seq_customers.NEXTVAL, rec.customer_email, NVL(rec.customer_name, rec.customer_email))
        RETURNING customer_id INTO v_customer_id;
        DBMS_OUTPUT.PUT('клиент создан (ID=' || v_customer_id || ')');
      END;
      -- вставка или обновление
      MERGE INTO orders o
      USING (
        SELECT 
          rec.order_id AS order_id,
          v_customer_id AS customer_id,
          rec.order_date AS order_date_str,
          rec.status AS status,
          rec.total_amount AS total_amount
        FROM dual
      ) src
      ON (o.order_id = src.order_id)
      WHEN MATCHED THEN UPDATE SET
        o.customer_id = src.customer_id,
        o.order_date = TO_DATE(src.order_date_str, 'YYYY-MM-DD'),
        o.status = NVL(src.status, 'NEW'),
        o.total_amount = NVL(src.total_amount, 0)
      WHEN NOT MATCHED THEN INSERT 
        (order_id, customer_id, order_date, status, total_amount)
        VALUES (src.order_id, src.customer_id, 
                TO_DATE(src.order_date_str, 'YYYY-MM-DD'),
                NVL(src.status, 'NEW'), NVL(src.total_amount, 0));
      
      IF SQL%ROWCOUNT = 1 THEN
        v_created := v_created + 1;
        DBMS_OUTPUT.PUT_LINE(' -> заказ создан');
      ELSE
        v_updated := v_updated + 1;
        DBMS_OUTPUT.PUT_LINE(' -> заказ обновлен');
      END IF;
      
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Импорт завершен: ' || v_processed || ' обработано, ' || 
                        v_created || ' создано, ' || v_updated || ' обновлено');
    
  EXCEPTION WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ОШИБКА импорта: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('Код ошибки: ' || SQLCODE);
    IF UTL_FILE.IS_OPEN(v_file) THEN UTL_FILE.FCLOSE(v_file); END IF;
    ROLLBACK;
    RAISE;
  END;

END pkg_json;
/