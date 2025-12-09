-- Таблица для генерации чисел
BEGIN 
  EXECUTE IMMEDIATE 'DROP TABLE t_numbers PURGE'; -- без корзины 
EXCEPTION WHEN OTHERS THEN NULL; 
END;
/

-- Таблица с одним столбцом n (1-200000) для массовой вставки данных без циклов PL/SQL
BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE t_numbers AS SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 200000';
  DBMS_OUTPUT.PUT_LINE('Таблица t_numbers создана');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания t_numbers: ' || SQLERRM);
END;
/

-- Добвление дополнительных клиентов
BEGIN
  EXECUTE IMMEDIATE '
    INSERT INTO customers(email, full_name, phone)
    SELECT ''user''||n||''@gmail.com'', ''User ''||n, ''+1-555-''||TO_CHAR(3000+MOD(n,7000))
      FROM t_numbers WHERE n <= 5000
        AND NOT EXISTS (SELECT 1 FROM customers c WHERE c.email = ''user''||n||''@example.com'')';
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Клиенты добавлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка вставки клиентов: ' || SQLERRM);
  ROLLBACK;
END;
/

-- создание множества заказов (100000)
BEGIN
  EXECUTE IMMEDIATE '
    INSERT INTO orders(order_id, customer_id, order_date, status, total_amount)
    SELECT seq_orders.NEXTVAL,
           (SELECT customer_id FROM (
              SELECT customer_id, ROW_NUMBER() OVER (ORDER BY customer_id) rn FROM customers
            ) WHERE rn = MOD(n, (SELECT COUNT(*) FROM customers)) + 1),
           TRUNC(SYSDATE) - MOD(n, 365),
           ''PAID'',
           0
      FROM t_numbers WHERE n <= 100000';
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Заказы созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания заказов: ' || SQLERRM);
  ROLLBACK;
END;
/ 
BEGIN
  EXECUTE IMMEDIATE 'UPDATE orders o SET total_amount = (SELECT NVL(SUM(quantity*price),0) FROM order_items oi WHERE oi.order_id = o.order_id)';
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Общие суммы обновлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка обновления общих сумм: ' || SQLERRM);
  ROLLBACK;
END;
/

-- Создание индексов
BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_orders_date ON orders(order_date)';
  EXECUTE IMMEDIATE 'CREATE INDEX idx_orders_status ON orders(status)';
  DBMS_OUTPUT.PUT_LINE('Индексы созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания индексов: ' || SQLERRM);
END;
/

-- 10 популярных товаров
BEGIN
  EXECUTE IMMEDIATE 'EXPLAIN PLAN FOR SELECT * FROM ( SELECT oi.product_id, SUM(oi.quantity) AS total_sold FROM order_items oi GROUP 
  BY oi.product_id ORDER BY total_sold DESC ) WHERE ROWNUM <= 10';
  DBMS_OUTPUT.PUT_LINE('Операция 10 популярных товаров выполнена');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка Операции 10 популярных товаров: ' || SQLERRM);
END;
/

-- форматируем и возвращает план выполнения
BEGIN
  FOR r IN (SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)) LOOP
    DBMS_OUTPUT.PUT_LINE(r.plan_table_output);
  END LOOP;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка вывода плана: ' || SQLERRM);
END;
/