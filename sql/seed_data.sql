BEGIN
  -- Очистка таблиц 
  DELETE FROM order_items;
  DELETE FROM payments;
  DELETE FROM orders;
  DELETE FROM customers;
  DELETE FROM product_suppliers;
  DELETE FROM products;
  DELETE FROM inventory;
  DELETE FROM suppliers;
  DELETE FROM companies;
  DELETE FROM categories;
  
  -- Сбрасывание последовательности 
  -- EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_categories RESTART START WITH 1';
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Таблицы очищены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка очистки: ' || SQLERRM);
  ROLLBACK;
END;
/

-- Вставка данных
BEGIN
  -- категории 
  INSERT INTO categories(category_id, name, description) 
  VALUES(seq_categories.NEXTVAL, 'Skincare', 'Cleansers, moisturizers, serums');
  
  INSERT INTO categories(category_id, name, description) 
  VALUES(seq_categories.NEXTVAL, 'Makeup', 'Foundations, lipsticks, eyeliners');
  
  INSERT INTO categories(category_id, name, description) 
  VALUES(seq_categories.NEXTVAL, 'Haircare', 'Shampoos, conditioners, treatments');
  
  INSERT INTO categories(category_id, name, description) 
  VALUES(seq_categories.NEXTVAL, 'Fragrance', 'Perfumes and colognes');

  -- компании 
  INSERT INTO companies(company_id, name, country, website) 
  VALUES(seq_companies.NEXTVAL, 'Aurora Beauty', 'USA', 'https://aurora.com');
  
  INSERT INTO companies(company_id, name, country, website) 
  VALUES(seq_companies.NEXTVAL, 'Velvet Glow', 'France', 'https://velvetglow.com');
  
  INSERT INTO companies(company_id, name, country, website) 
  VALUES(seq_companies.NEXTVAL, 'OceanMist', 'UK', 'https://oceanmist.com');

  -- Поставщики
  INSERT INTO suppliers(supplier_id, name, contact_email, phone) 
  VALUES(seq_suppliers.NEXTVAL, 'Global Cosmetics Supply', 'Supply@gmail.com', '+375-29-525-63-14');
  
  INSERT INTO suppliers(supplier_id, name, contact_email, phone) 
  VALUES(seq_suppliers.NEXTVAL, 'EuroBeauty Logistics', 'EuroBeauty@gmail.com', '+375-33-531-96-02');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Основные данные вставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка вставки основных данных: ' || SQLERRM);
  ROLLBACK;
END;
/

BEGIN
  -- Продукты с инвентарем
  DECLARE
    v_inventory_id NUMBER;
    v_company_id NUMBER;
    v_category_id NUMBER;
  BEGIN
    -- ID компаний и категорий
    SELECT company_id INTO v_company_id FROM companies WHERE name='Aurora Beauty';
    SELECT category_id INTO v_category_id FROM categories WHERE name='Skincare';
    
    -- Aurora Beauty, Skincare - Gentle Foam Cleanser
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-AUR-CL-001', 'Gentle Foam Cleanser', 'Mild facial cleanser for daily use', 12.50);

    -- Aurora Beauty, Skincare - Hydrating Day Cream
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-AUR-MO-002', 'Hydrating Day Cream', 'Lightweight moisturizer with SPF 15', 18.90);

    -- Velvet Glow, Makeup - Velvet Matte Lipstick
    SELECT company_id INTO v_company_id FROM companies WHERE name='Velvet Glow';
    SELECT category_id INTO v_category_id FROM categories WHERE name='Makeup';
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-VEL-LP-010', 'Velvet Matte Lipstick', 'Long-lasting matte finish', 15.00);

    -- Velvet Glow, Makeup - Silk Finish Foundation
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-VEL-FO-011', 'Silk Finish Foundation', 'Medium coverage liquid foundation', 22.00);

    -- OceanMist, Haircare - Sea Minerals Shampoo
    SELECT company_id INTO v_company_id FROM companies WHERE name='OceanMist';
    SELECT category_id INTO v_category_id FROM categories WHERE name='Haircare';
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-OCM-SH-101', 'Sea Minerals Shampoo', 'Strengthening shampoo with marine minerals', 9.99);

    -- OceanMist, Haircare - Deep Repair Conditioner
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-OCM-CO-102', 'Deep Repair Conditioner', 'Nourishing conditioner for dry hair', 11.49);

    -- Aurora Beauty, Fragrance - Midnight Blossom
    SELECT company_id INTO v_company_id FROM companies WHERE name='Aurora Beauty';
    SELECT category_id INTO v_category_id FROM categories WHERE name='Fragrance';
    v_inventory_id := seq_inventory.NEXTVAL;
    INSERT INTO inventory(inventory_id, quantity, restock_level) VALUES(v_inventory_id, 100, 20);
    INSERT INTO products(product_id, company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(seq_products.NEXTVAL, v_company_id, v_category_id, v_inventory_id, 'SKU-AUR-PR-050', 'Midnight Blossom', 'Eau de parfum with floral notes', 39.00);

    DBMS_OUTPUT.PUT_LINE('Продукты созданы');
  END;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания продуктов: ' || SQLERRM);
END;
/


BEGIN
  -- Отношения между продуктом и поставщиком
  INSERT INTO product_suppliers(product_id, supplier_id, lead_time_days)
  SELECT p.product_id, s.supplier_id, 5 FROM products p, suppliers s WHERE s.name='Global Cosmetics Supply' AND p.sku IN ('SKU-AUR-CL-001','SKU-AUR-MO-002','SKU-OCM-SH-101');

  INSERT INTO product_suppliers(product_id, supplier_id, lead_time_days)
  SELECT p.product_id, s.supplier_id, 7 FROM products p, suppliers s WHERE s.name='EuroBeauty Logistics' AND p.sku IN ('SKU-VEL-LP-010','SKU-VEL-FO-011','SKU-OCM-CO-102','SKU-AUR-PR-050');

  DBMS_OUTPUT.PUT_LINE('Связи с поставщиками созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания связей с поставщиками: ' || SQLERRM);
END;
/

BEGIN
  -- Клиенты 
  INSERT INTO customers(customer_id, email, full_name, phone) 
  VALUES(seq_customers.NEXTVAL, 'alice@gail.com', 'Alice Johnson', '+375-25-836-10-76');
  
  INSERT INTO customers(customer_id, email, full_name, phone) 
  VALUES(seq_customers.NEXTVAL, 'bob@gmail.com', 'Bob Smith', '+375-29-847-88-68');

  -- Заказы 
  INSERT INTO orders(order_id, customer_id, status) 
  SELECT seq_orders.NEXTVAL, customer_id, 'PAID' FROM customers WHERE email='alice@gmail.com';
  
  -- Элементы заказа
  INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price)
  SELECT seq_order_items.NEXTVAL, o.order_id, p.product_id, 2, p.price 
  FROM orders o, products p
  WHERE o.order_id = (SELECT MIN(order_id) FROM orders) AND p.sku='SKU-VEL-LP-010';

  -- Платежи
  INSERT INTO payments(payment_id, order_id, amount, method)
  SELECT seq_payments.NEXTVAL, o.order_id, o.total_amount, 'CARD' 
  FROM orders o WHERE o.order_id = (SELECT MIN(order_id) FROM orders);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Данные клиентов и заказов созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания данных клиентов: ' || SQLERRM);
  ROLLBACK;
END;
/
