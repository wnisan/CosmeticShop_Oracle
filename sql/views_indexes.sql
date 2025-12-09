-- Создание индексов для таблиц 
BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_products_company ON products(company_id)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_products_company создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_products_company: ' || SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_products_category ON products(category_id)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_products_category создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_products_category: ' || SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_products_price ON products(price)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_products_price создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_products_price: ' || SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_orders_customer ON orders(customer_id)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_orders_customer создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_orders_customer: ' || SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_order_items_product ON order_items(product_id)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_order_items_product создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_order_items_product: ' || SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE INDEX idx_inventory_quantity ON inventory(quantity)';
  DBMS_OUTPUT.PUT_LINE('Индекс idx_inventory_quantity создан');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания idx_inventory_quantity: ' || SQLERRM);
END;
/

-- Создание представлений
BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE VIEW v_product_overview AS
SELECT p.product_id,
       p.sku,
       p.name AS product_name,
       c.name AS category_name,
       co.name AS company_name,
       p.price,
       NVL(i.quantity,0) AS quantity
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
  JOIN companies co ON co.company_id = p.company_id
  LEFT JOIN inventory i ON i.inventory_id = p.inventory_id';
  DBMS_OUTPUT.PUT_LINE('Представление v_product_overview создано');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания v_product_overview: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE VIEW v_popular_products AS
SELECT oi.product_id,
       p.name AS product_name,
       SUM(oi.quantity) AS total_sold
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
 GROUP BY oi.product_id, p.name
 ORDER BY total_sold DESC';
  DBMS_OUTPUT.PUT_LINE('Представление v_popular_products создано');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания v_popular_products: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE VIEW v_revenue_by_month AS
SELECT TO_CHAR(o.order_date, ''YYYY-MM'') AS ym,
       SUM(o.total_amount) AS revenue
  FROM orders o
 GROUP BY TO_CHAR(o.order_date, ''YYYY-MM'')';
  DBMS_OUTPUT.PUT_LINE('Представление v_revenue_by_month создано'); 
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания v_revenue_by_month: ' || SQLERRM);
END;
/

-- Удаления индексов
BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE PROCEDURE drop_all_indexes AS
BEGIN
  FOR idx IN (SELECT index_name FROM user_indexes WHERE table_name IN (
               ''PRODUCTS'', ''ORDERS'', ''ORDER_ITEMS'', ''INVENTORY'', ''CUSTOMERS''
             ) AND index_name LIKE ''IDX_%'') 
  LOOP
    EXECUTE IMMEDIATE ''DROP INDEX '' || idx.index_name;
    DBMS_OUTPUT.PUT_LINE(''Индекс '' || idx.index_name || '' удален'');
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(''Ошибка удаления индексов: '' || SQLERRM);
END;';
DBMS_OUTPUT.PUT_LINE('Процедура drop_all_indexes создана'); 
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания drop_all_indexes: ' || SQLERRM);
END;
/
