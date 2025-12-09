-- триггеры которые перед insert/update проверяют входные данные

-- Категории
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_categories_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_categories_validate
BEFORE INSERT OR UPDATE ON categories
FOR EACH ROW
BEGIN
  pkg_validation.check_category(:NEW.name, :NEW.description);
END;
/

-- Компании
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_companies_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_companies_validate
BEFORE INSERT OR UPDATE ON companies
FOR EACH ROW
BEGIN
  pkg_validation.check_company(:NEW.name, :NEW.country, :NEW.website);
END;
/

-- Инвентарь
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_inventory_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_inventory_validate
BEFORE INSERT OR UPDATE ON inventory
FOR EACH ROW
BEGIN
  pkg_validation.check_inventory(:NEW.quantity, :NEW.restock_level);
END;
/

-- Товары
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_products_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_products_validate
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
BEGIN
  pkg_validation.check_product(
    :NEW.company_id,
    :NEW.category_id,
    :NEW.inventory_id,
    :NEW.sku,
    :NEW.name,
    :NEW.price
  );
END;
/

-- Клиенты
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_customers_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_customers_validate
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW
BEGIN
  pkg_validation.check_customer(:NEW.email, :NEW.full_name, :NEW.phone);
END;
/

-- Заказы
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_orders_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_orders_validate
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
BEGIN
  pkg_validation.check_order(:NEW.status, :NEW.total_amount);
END;
/

-- Позиции заказа
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_order_items_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_order_items_validate
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW
BEGIN
  pkg_validation.check_order_item(:NEW.quantity, :NEW.price);
END;
/

-- Платежи
BEGIN
  EXECUTE IMMEDIATE 'DROP TRIGGER trg_biu_payments_validate';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE TRIGGER trg_biu_payments_validate
BEFORE INSERT OR UPDATE ON payments
FOR EACH ROW
BEGIN
  pkg_validation.check_payment(:NEW.amount, :NEW.method);
END;
/






