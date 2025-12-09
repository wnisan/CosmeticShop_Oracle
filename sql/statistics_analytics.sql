-- Создание пакета для расширенной аналитики
CREATE OR REPLACE PACKAGE pkg_analytics AS
  TYPE ref_cursor IS REF CURSOR;
  
  -- Общая статистика (Процедура вернёт курсор с общей статистикой по магазину)
  PROCEDURE get_general_stats(p_result OUT ref_cursor);
  
  -- Статистика по категориям
  PROCEDURE get_category_stats(p_result OUT ref_cursor);
  
  -- Статистика по компаниям
  PROCEDURE get_company_stats(p_result OUT ref_cursor);
  
  -- Статистика продаж по периодам
  PROCEDURE get_sales_by_period(p_start_date DATE, p_end_date DATE, p_result OUT ref_cursor);
  
  -- Топ товаров по выручке
  PROCEDURE get_top_products_by_revenue(p_top NUMBER, p_result OUT ref_cursor);
  
  -- Статистика клиентов
  PROCEDURE get_customer_stats(p_result OUT ref_cursor);
  
  -- Анализ инвентаря
  PROCEDURE get_inventory_analysis(p_result OUT ref_cursor);
  
  -- Статистика заказов
  PROCEDURE get_order_stats(p_result OUT ref_cursor);
  
  -- Прогноз продаж
  FUNCTION predict_sales(p_days NUMBER) RETURN NUMBER;
  
  -- Средний чек
  FUNCTION get_average_order_value RETURN NUMBER;
  
  -- Конверсия клиентов
  FUNCTION get_customer_conversion RETURN NUMBER;
END pkg_analytics;
/

CREATE OR REPLACE PACKAGE BODY pkg_analytics AS
  PROCEDURE get_general_stats(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        'Общее количество товаров' as metric_name,
        TO_CHAR(COUNT(*)) as metric_value
      FROM products
      UNION ALL
      SELECT 
        'Общее количество категорий',
        TO_CHAR(COUNT(*))
      FROM categories
      UNION ALL
      SELECT 
        'Общее количество компаний',
        TO_CHAR(COUNT(*))
      FROM companies
      UNION ALL
      SELECT 
        'Общее количество клиентов',
        TO_CHAR(COUNT(*))
      FROM customers
      UNION ALL
      SELECT 
        'Общее количество заказов',
        TO_CHAR(COUNT(*))
      FROM orders
      UNION ALL
      SELECT 
        'Общая выручка ($)',
        TO_CHAR(NVL(SUM(total_amount), 0), '999,999,999.99')
      FROM orders
      UNION ALL
      SELECT 
        'Средний чек ($)',
        TO_CHAR(NVL(AVG(total_amount), 0), '999,999.99')
      FROM orders
      UNION ALL
      SELECT 
        'Общее количество проданных товаров',
        TO_CHAR(NVL(SUM(quantity), 0))
      FROM order_items;
  END;

  PROCEDURE get_category_stats(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        c.name as category_name,
        COUNT(p.product_id) as product_count,
        NVL(SUM(oi.quantity), 0) as total_sold,
        NVL(SUM(oi.quantity * oi.price), 0) as total_revenue,
        ROUND(NVL(AVG(p.price), 0), 2) as avg_price
      FROM categories c
      LEFT JOIN products p ON p.category_id = c.category_id
      LEFT JOIN order_items oi ON oi.product_id = p.product_id
      GROUP BY c.category_id, c.name
      ORDER BY total_revenue DESC;
  END;

  PROCEDURE get_company_stats(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        co.name as company_name,
        co.country,
        COUNT(p.product_id) as product_count,
        NVL(SUM(oi.quantity), 0) as total_sold,
        NVL(SUM(oi.quantity * oi.price), 0) as total_revenue,
        ROUND(NVL(AVG(p.price), 0), 2) as avg_price
      FROM companies co
      LEFT JOIN products p ON p.company_id = co.company_id
      LEFT JOIN order_items oi ON oi.product_id = p.product_id
      GROUP BY co.company_id, co.name, co.country
      ORDER BY total_revenue DESC;
  END;

  PROCEDURE get_sales_by_period(p_start_date DATE, p_end_date DATE, p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        TO_CHAR(o.order_date, 'YYYY-MM') as period,
        COUNT(*) as order_count,
        SUM(o.total_amount) as total_revenue,
        ROUND(AVG(o.total_amount), 2) as avg_order_value,
        SUM(oi.quantity) as total_items_sold
      FROM orders o
      LEFT JOIN order_items oi ON oi.order_id = o.order_id
      WHERE o.order_date BETWEEN p_start_date AND p_end_date
      GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
      ORDER BY period;
  END;

  PROCEDURE get_top_products_by_revenue(p_top NUMBER, p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT * FROM (
        SELECT 
          p.product_id,
          p.name as product_name,
          p.sku,
          c.name as category_name,
          co.name as company_name,
          p.price,
          SUM(oi.quantity) as total_sold,
          SUM(oi.quantity * oi.price) as total_revenue,
          ROW_NUMBER() OVER (ORDER BY SUM(oi.quantity * oi.price) DESC) as rank_num
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        JOIN companies co ON co.company_id = p.company_id
        LEFT JOIN order_items oi ON oi.product_id = p.product_id
        GROUP BY p.product_id, p.name, p.sku, c.name, co.name, p.price
        ORDER BY total_revenue DESC
      ) WHERE rank_num <= p_top;
  END;

  PROCEDURE get_customer_stats(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        'Всего клиентов' as metric_name,
        TO_CHAR(COUNT(*)) as metric_value
      FROM customers
      UNION ALL
      SELECT 
        'Клиентов с заказами',
        TO_CHAR(COUNT(DISTINCT customer_id))
      FROM orders
      UNION ALL
      SELECT 
        'Среднее количество заказов на клиента',
        TO_CHAR(ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT customer_id), 0), 2))
      FROM orders
      UNION ALL
      SELECT 
        'Самый активный клиент (заказов)',
        TO_CHAR(MAX(order_count))
      FROM (
        SELECT customer_id, COUNT(*) as order_count
        FROM orders
        GROUP BY customer_id
      )
      UNION ALL
      SELECT 
        'Клиент с наибольшей выручкой ($)',
        TO_CHAR(MAX(total_spent))
      FROM (
        SELECT customer_id, SUM(total_amount) as total_spent
        FROM orders
        GROUP BY customer_id
      );
  END;

  PROCEDURE get_inventory_analysis(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        'Всего товаров на складе' as metric_name,
        TO_CHAR(SUM(quantity)) as metric_value
      FROM inventory
      UNION ALL
      SELECT 
        'Товаров с нулевым остатком',
        TO_CHAR(COUNT(*))
      FROM inventory
      WHERE quantity = 0
      UNION ALL
      SELECT 
        'Товаров ниже уровня пополнения',
        TO_CHAR(COUNT(*))
      FROM inventory
      WHERE quantity <= restock_level
      UNION ALL
      SELECT 
        'Общая стоимость инвентаря ($)',
        TO_CHAR(ROUND(SUM(i.quantity * p.price), 2))
      FROM inventory i
      JOIN products p ON p.inventory_id = i.inventory_id
      UNION ALL
      SELECT 
        'Средний остаток на товар',
        TO_CHAR(ROUND(AVG(quantity), 2))
      FROM inventory;
  END;

  PROCEDURE get_order_stats(p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      SELECT 
        status as order_status,
        COUNT(*) as order_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
        SUM(total_amount) as total_revenue,
        ROUND(AVG(total_amount), 2) as avg_order_value
      FROM orders
      GROUP BY status
      ORDER BY order_count DESC;
  END;

  FUNCTION predict_sales(p_days NUMBER) RETURN NUMBER IS
    v_avg_daily_sales NUMBER;
  BEGIN
    SELECT NVL(AVG(daily_revenue), 0) INTO v_avg_daily_sales
    FROM (
      SELECT TO_CHAR(order_date, 'YYYY-MM-DD') as day, SUM(total_amount) as daily_revenue
      FROM orders
      WHERE order_date >= SYSDATE - 30  -- Последние 30 дней
      GROUP BY TO_CHAR(order_date, 'YYYY-MM-DD')
    );
    
    RETURN ROUND(v_avg_daily_sales * p_days, 2);
  END;

  FUNCTION get_average_order_value RETURN NUMBER IS
    v_avg_value NUMBER;
  BEGIN
    SELECT NVL(AVG(total_amount), 0) INTO v_avg_value FROM orders;
    RETURN ROUND(v_avg_value, 2);
  END;

  FUNCTION get_customer_conversion RETURN NUMBER IS
    v_conversion NUMBER;
  BEGIN
    SELECT 
      ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2)
    INTO v_conversion
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id;
    
    RETURN v_conversion;
  END;
END pkg_analytics;
/

-- Предоставление прав на пакет
BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET "_ORACLE_SCRIPT"=true';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_analytics TO COSM_ROLE_ADMIN';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_analytics TO COSM_ROLE_USER';
  DBMS_OUTPUT.PUT_LINE('Права на пакет pkg_analytics предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав: ' || SQLERRM);
END;
/

-- Создание дополнительных представлений для аналитики
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT 
  TO_CHAR(order_date, 'YYYY-MM-DD') as sale_date,
  COUNT(*) as order_count,
  SUM(total_amount) as daily_revenue,
  ROUND(AVG(total_amount), 2) as avg_order_value,
  SUM(oi.quantity) as total_items_sold
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY TO_CHAR(order_date, 'YYYY-MM-DD')
ORDER BY sale_date DESC;

CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT 
  TO_CHAR(order_date, 'YYYY-MM') as month,
  COUNT(*) as order_count,
  SUM(total_amount) as monthly_revenue,
  ROUND(AVG(total_amount), 2) as avg_order_value,
  SUM(oi.quantity) as total_items_sold,
  COUNT(DISTINCT customer_id) as unique_customers
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month DESC;

CREATE OR REPLACE VIEW v_customer_analysis AS
SELECT 
  c.customer_id,
  c.full_name,
  c.email,
  COUNT(o.order_id) as total_orders,
  NVL(SUM(o.total_amount), 0) as total_spent,
  ROUND(NVL(AVG(o.total_amount), 0), 2) as avg_order_value,
  MIN(o.order_date) as first_order_date,
  MAX(o.order_date) as last_order_date,
  ROUND(SYSDATE - MAX(o.order_date), 0) as days_since_last_order
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY total_spent DESC;

CREATE OR REPLACE VIEW v_inventory_status AS
SELECT 
  p.product_id,
  p.name as product_name,
  p.sku,
  c.name as category_name,
  co.name as company_name,
  p.price,
  i.quantity,
  i.restock_level,
  CASE 
    WHEN i.quantity = 0 THEN 'Нет в наличии'
    WHEN i.quantity <= i.restock_level THEN 'Требует пополнения'
    ELSE 'В наличии'
  END as status,
  ROUND(i.quantity * p.price, 2) as inventory_value
FROM products p
JOIN categories c ON c.category_id = p.category_id
JOIN companies co ON co.company_id = p.company_id
LEFT JOIN inventory i ON i.inventory_id = p.inventory_id
ORDER BY inventory_value DESC;

-- Предоставление прав на представления
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_daily_sales TO COSM_ROLE_USER';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_monthly_sales TO COSM_ROLE_USER';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_customer_analysis TO COSM_ROLE_USER';
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_inventory_status TO COSM_ROLE_USER';
  DBMS_OUTPUT.PUT_LINE('Права на аналитические представления предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав на представления: ' || SQLERRM);
END;
/

-- Общая статистика (демонстрационный блок вызова pkg_analytics.get_general_stats)
DECLARE
  v_cursor SYS_REFCURSOR;
  v_metric_name VARCHAR2(100);
  v_metric_value VARCHAR2(100);
BEGIN
  pkg_analytics.get_general_stats(v_cursor);
  
  LOOP
    FETCH v_cursor INTO v_metric_name, v_metric_value;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_metric_name || ': ' || v_metric_value);
  END LOOP;
  CLOSE v_cursor;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка получения общей статистики: ' || SQLERRM);
    IF v_cursor%ISOPEN THEN
      CLOSE v_cursor;
    END IF;
END;
/

-- Статистика по категориям (топ-5)
SELECT * FROM (
  SELECT 
    category_name,
    product_count,
    total_sold,
    total_revenue,
    avg_price
  FROM (
    SELECT 
      c.name as category_name,
      COUNT(p.product_id) as product_count,
      NVL(SUM(oi.quantity), 0) as total_sold,
      NVL(SUM(oi.quantity * oi.price), 0) as total_revenue,
      ROUND(NVL(AVG(p.price), 0), 2) as avg_price
    FROM categories c
    LEFT JOIN products p ON p.category_id = c.category_id
    LEFT JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY c.category_id, c.name
  )
  ORDER BY total_revenue DESC
) WHERE ROWNUM <= 5;
/

-- Топ-5 товаров по выручке
SELECT * FROM (
  SELECT 
    product_name,
    sku,
    category_name,
    company_name,
    price,
    total_sold,
    total_revenue
  FROM (
    SELECT 
      p.name as product_name,
      p.sku,
      c.name as category_name,
      co.name as company_name,
      p.price,
      SUM(oi.quantity) as total_sold,
      SUM(oi.quantity * oi.price) as total_revenue
    FROM products p
    JOIN categories c ON c.category_id = p.category_id
    JOIN companies co ON co.company_id = p.company_id
    LEFT JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.name, p.sku, c.name, co.name, p.price
    ORDER BY total_revenue DESC
  )
) WHERE ROWNUM <= 5;
/

-- Анализ клиентов (топ-10)
SELECT * FROM (
  SELECT 
    full_name,
    email,
    total_orders,
    total_spent,
    avg_order_value,
    days_since_last_order
  FROM v_customer_analysis
  ORDER BY total_spent DESC
) WHERE ROWNUM <= 10;
/

-- Статус инвентаря
SELECT 
  product_name,
  sku,
  category_name,
  quantity,
  restock_level,
  status,
  inventory_value
FROM v_inventory_status
WHERE status != 'В наличии'
ORDER BY inventory_value DESC;
/

-- Прогноз продаж
DECLARE
  v_prediction_7_days NUMBER;
  v_prediction_30_days NUMBER;
  v_avg_order_value NUMBER;
  v_conversion_rate NUMBER;
BEGIN
  v_prediction_7_days := pkg_analytics.predict_sales(7);
  v_prediction_30_days := pkg_analytics.predict_sales(30);
  v_avg_order_value := pkg_analytics.get_average_order_value();
  v_conversion_rate := pkg_analytics.get_customer_conversion();
  
  DBMS_OUTPUT.PUT_LINE('Прогноз продаж на 7 дней: $' || v_prediction_7_days);
  DBMS_OUTPUT.PUT_LINE('Прогноз продаж на 30 дней: $' || v_prediction_30_days);
  DBMS_OUTPUT.PUT_LINE('Средний чек: $' || v_avg_order_value);
  DBMS_OUTPUT.PUT_LINE('Конверсия клиентов: ' || v_conversion_rate || '%');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка при расчете прогноза: ' || SQLERRM);
END;
/

-- Дополнительная аналитика через пакет
DECLARE
  v_cursor SYS_REFCURSOR;
  v_category_name VARCHAR2(100);
  v_product_count NUMBER;
  v_total_sold NUMBER;
  v_total_revenue NUMBER;
  v_avg_price NUMBER;
BEGIN

  DBMS_OUTPUT.PUT_LINE('СТАТИСТИКА ПО КАТЕГОРИЯМ');
  pkg_analytics.get_category_stats(v_cursor);
  
  LOOP
    FETCH v_cursor INTO v_category_name, v_product_count, v_total_sold, v_total_revenue, v_avg_price;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_category_name, 20) || ' | ' ||
      RPAD(v_product_count, 5) || ' | ' ||
      RPAD(v_total_sold, 8) || ' | $' ||
      RPAD(v_total_revenue, 10) || ' | $' ||
      v_avg_price
    );
  END LOOP;
  CLOSE v_cursor;
  
  DBMS_OUTPUT.PUT_LINE(CHR(10) || 'АНАЛИЗ ИНВЕНТАРЯ');
  pkg_analytics.get_inventory_analysis(v_cursor);
  
  DECLARE
    v_metric_name VARCHAR2(100);
    v_metric_value VARCHAR2(100);
  BEGIN
    LOOP
      FETCH v_cursor INTO v_metric_name, v_metric_value;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_metric_name || ': ' || v_metric_value);
    END LOOP;
    CLOSE v_cursor;
  END;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка получения статистики: ' || SQLERRM);
    IF v_cursor%ISOPEN THEN
      CLOSE v_cursor;
    END IF;
END;
/

-- Ежемесячные продажи
SELECT * FROM v_monthly_sales 
ORDER BY month DESC;
/

-- Статистика по статусам заказов
DECLARE
  v_cursor SYS_REFCURSOR;
  v_order_status VARCHAR2(30);
  v_order_count NUMBER;
  v_percentage NUMBER;
  v_total_revenue NUMBER;
  v_avg_order_value NUMBER;
BEGIN
  pkg_analytics.get_order_stats(v_cursor);
  
  DBMS_OUTPUT.PUT_LINE('Статус | Количество | % | Выручка | Средний чек');
  
  LOOP
    FETCH v_cursor INTO v_order_status, v_order_count, v_percentage, v_total_revenue, v_avg_order_value;
    EXIT WHEN v_cursor%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(
      RPAD(v_order_status, 7) || ' | ' ||
      RPAD(v_order_count, 10) || ' | ' ||
      RPAD(v_percentage, 1) || '% | $' ||
      RPAD(NVL(v_total_revenue, 0), 7) || ' | $' ||
      NVL(v_avg_order_value, 0)
    );
  END LOOP;
  CLOSE v_cursor;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка получения статистики заказов: ' || SQLERRM);
    IF v_cursor%ISOPEN THEN
      CLOSE v_cursor;
    END IF;
END;
/