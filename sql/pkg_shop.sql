-- Создание пакета магазина 
CREATE OR REPLACE PACKAGE pkg_shop AS
  TYPE ref_cursor IS REF CURSOR;

  -- фильтрация и сортировка
  PROCEDURE list_products(p_category_id NUMBER DEFAULT NULL,
                          p_company_id  NUMBER DEFAULT NULL,
                          p_min_price   NUMBER DEFAULT NULL,
                          p_max_price   NUMBER DEFAULT NULL,
                          p_sort_by     VARCHAR2 DEFAULT 'price',
                          p_sort_dir    VARCHAR2 DEFAULT 'ASC',
                          p_result OUT ref_cursor);

  -- анализ
  PROCEDURE popular_products(p_top NUMBER, p_result OUT ref_cursor);
  FUNCTION total_products RETURN NUMBER;
  FUNCTION total_revenue RETURN NUMBER;
END pkg_shop;
/

CREATE OR REPLACE PACKAGE BODY pkg_shop AS
  PROCEDURE list_products(p_category_id NUMBER, p_company_id NUMBER, p_min_price NUMBER, p_max_price NUMBER,
                          p_sort_by VARCHAR2, p_sort_dir VARCHAR2, p_result OUT ref_cursor) IS
    v_sql CLOB := 'SELECT product_id, sku, product_name, category_name, company_name, price, quantity FROM v_product_overview WHERE 1=1';
    v_sort_by VARCHAR2(100);
    v_sort_dir VARCHAR2(10);
  BEGIN
    IF p_category_id IS NOT NULL THEN 
      v_sql := v_sql || ' AND product_id IN (SELECT product_id FROM products WHERE category_id = ' || p_category_id || ')'; 
    END IF;
    IF p_company_id IS NOT NULL THEN 
      v_sql := v_sql || ' AND product_id IN (SELECT product_id FROM products WHERE company_id = ' || p_company_id || ')'; 
    END IF;
    IF p_min_price IS NOT NULL THEN 
      v_sql := v_sql || ' AND price >= ' || p_min_price; 
    END IF;
    IF p_max_price IS NOT NULL THEN 
      v_sql := v_sql || ' AND price <= ' || p_max_price; 
    END IF;

    v_sort_by := p_sort_by;
    v_sort_dir := p_sort_dir;
    
    IF UPPER(v_sort_by) NOT IN ('PRICE','PRODUCT_NAME','CATEGORY_NAME','COMPANY_NAME','QUANTITY') THEN
      v_sort_by := 'PRICE';
    END IF;
    IF UPPER(v_sort_dir) NOT IN ('ASC','DESC') THEN
      v_sort_dir := 'ASC';
    END IF;
    
    v_sql := v_sql || ' ORDER BY ' || CASE UPPER(v_sort_by)
                                      WHEN 'PRODUCT_NAME' THEN 'product_name'
                                      WHEN 'CATEGORY_NAME' THEN 'category_name'
                                      WHEN 'COMPANY_NAME' THEN 'company_name'
                                      WHEN 'QUANTITY' THEN 'quantity'
                                      ELSE 'price' END || ' ' || UPPER(v_sort_dir);

    OPEN p_result FOR v_sql;
  END;

  PROCEDURE popular_products(p_top NUMBER, p_result OUT ref_cursor) IS
  BEGIN
    OPEN p_result FOR
      'SELECT * FROM (
         SELECT product_id, product_name, total_sold,
                DENSE_RANK() OVER (ORDER BY total_sold DESC) AS rnk
           FROM v_popular_products)
       WHERE rnk <= :b1'
      USING p_top; -- переменная для безопасности (WHERE rnk <= ' || p_top)
  END;

  FUNCTION total_products RETURN NUMBER IS
    v_cnt NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt FROM products;
    RETURN v_cnt;
  END;

  FUNCTION total_revenue RETURN NUMBER IS
    v_sum NUMBER;
  BEGIN
    SELECT NVL(SUM(total_amount),0) INTO v_sum FROM orders;
    RETURN v_sum;
  END;
END pkg_shop;
/

-- Предоставление прав на пакет и создание синонимов (вызывать от имени администратора)
BEGIN
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_shop TO COSM_ROLE_USER';
  DBMS_OUTPUT.PUT_LINE('Права на пакет pkg_shop предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав: ' || SQLERRM);
END;
/

-- Создание публичных синонимов для пользователя
BEGIN
  EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM pkg_shop FOR COSM_ADMIN.pkg_shop';
  EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM v_product_overview FOR COSM_ADMIN.v_product_overview';
  EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM v_popular_products FOR COSM_ADMIN.v_popular_products';
  EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM v_revenue_by_month FOR COSM_ADMIN.v_revenue_by_month';
  DBMS_OUTPUT.PUT_LINE('Публичные синонимы созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания синонимов: ' || SQLERRM);
END;
/