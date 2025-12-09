-- Удаление таблиц + всех внешних ключей, которые ссылаются на эту таблицу
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE payments CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE order_items CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE orders CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE inventory CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE product_media CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE products CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE categories CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE companies CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE suppliers CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE product_suppliers CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Создание таблиц
BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE categories (
  category_id    NUMBER        PRIMARY KEY,
  name           VARCHAR2(100) NOT NULL UNIQUE,
  description    VARCHAR2(4000)
)';
DBMS_OUTPUT.PUT_LINE('Таблица categories создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания categories: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE companies (
  company_id     NUMBER        PRIMARY KEY,
  name           VARCHAR2(150) NOT NULL UNIQUE,
  country        VARCHAR2(80),
  website        VARCHAR2(255)
)';
DBMS_OUTPUT.PUT_LINE('Таблица companies создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания companies: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE products (
  product_id     NUMBER         PRIMARY KEY,
  company_id     NUMBER         NOT NULL,
  category_id    NUMBER         NOT NULL,
  inventory_id   NUMBER         NOT NULL UNIQUE,
  sku            VARCHAR2(64)   NOT NULL UNIQUE,
  name           VARCHAR2(200)  NOT NULL,
  description    VARCHAR2(4000),
  price          NUMBER(10,2)   NOT NULL CHECK (price >= 0),
  created_at     DATE           DEFAULT SYSDATE NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица products создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания products: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE product_media (
  media_id       NUMBER        PRIMARY KEY,
  product_id     NUMBER        NOT NULL,
  filename       VARCHAR2(255) NOT NULL,
  mime_type      VARCHAR2(100) NOT NULL,
  content        BLOB          NOT NULL,
  uploaded_at    DATE          DEFAULT SYSDATE NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица product_media создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания product_media: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE inventory (
  inventory_id   NUMBER       PRIMARY KEY,
  quantity       NUMBER       NOT NULL CHECK (quantity >= 0),
  restock_level  NUMBER       DEFAULT 0 NOT NULL,
  updated_at     DATE         DEFAULT SYSDATE NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица inventory создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания inventory: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE customers (
  customer_id    NUMBER        PRIMARY KEY,
  email          VARCHAR2(200) NOT NULL UNIQUE,
  full_name      VARCHAR2(200) NOT NULL,
  phone          VARCHAR2(50),
  created_at     DATE          DEFAULT SYSDATE NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица customers создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания customers: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE orders (
  order_id       NUMBER        PRIMARY KEY,
  customer_id    NUMBER        NOT NULL,
  order_date     DATE          DEFAULT SYSDATE NOT NULL,
  status         VARCHAR2(30)  DEFAULT ''NEW'' NOT NULL,
  total_amount   NUMBER(12,2)  DEFAULT 0 NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица orders создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания orders: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE order_items (
  order_item_id  NUMBER        PRIMARY KEY,
  order_id       NUMBER        NOT NULL,
  product_id     NUMBER        NOT NULL,
  quantity       NUMBER        NOT NULL CHECK (quantity > 0),
  price          NUMBER(10,2)  NOT NULL CHECK (price >= 0)
)';
DBMS_OUTPUT.PUT_LINE('Таблица order_items создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания order_items: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE payments (
  payment_id     NUMBER        PRIMARY KEY,
  order_id       NUMBER        NOT NULL,
  paid_at        DATE          DEFAULT SYSDATE NOT NULL,
  amount         NUMBER(12,2)  NOT NULL CHECK (amount >= 0),
  method         VARCHAR2(50)  NOT NULL
)';
DBMS_OUTPUT.PUT_LINE('Таблица payments создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания payments: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE suppliers (
  supplier_id    NUMBER        PRIMARY KEY,
  name           VARCHAR2(150) NOT NULL UNIQUE,
  contact_email  VARCHAR2(200),
  phone          VARCHAR2(50)
)';
DBMS_OUTPUT.PUT_LINE('Таблица suppliers создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания suppliers: ' || SQLERRM);
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE TABLE product_suppliers (
  product_id     NUMBER NOT NULL,
  supplier_id    NUMBER NOT NULL,
  lead_time_days NUMBER DEFAULT 7 NOT NULL,
  PRIMARY KEY (product_id, supplier_id)
)';
DBMS_OUTPUT.PUT_LINE('Таблица product_suppliers создана');
EXCEPTION WHEN OTHERS THEN 
  DBMS_OUTPUT.PUT_LINE('Ошибка создания product_suppliers: ' || SQLERRM);
END;
/

-- Добавление foreign key
BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE products ADD CONSTRAINT fk_prod_inventory 
FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE products ADD CONSTRAINT fk_prod_company 
FOREIGN KEY (company_id) REFERENCES companies(company_id)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE products ADD CONSTRAINT fk_prod_category 
FOREIGN KEY (category_id) REFERENCES categories(category_id)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE product_media ADD CONSTRAINT fk_media_product 
FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/


BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE orders ADD CONSTRAINT fk_ord_customer 
FOREIGN KEY (customer_id) REFERENCES customers(customer_id)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE order_items ADD CONSTRAINT fk_oi_order 
FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE order_items ADD CONSTRAINT fk_oi_product 
FOREIGN KEY (product_id) REFERENCES products(product_id)';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE payments ADD CONSTRAINT fk_pay_order 
FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE product_suppliers ADD CONSTRAINT fk_ps_product 
FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
ALTER TABLE product_suppliers ADD CONSTRAINT fk_ps_supplier 
FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
