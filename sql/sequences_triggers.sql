-- Удаление последовательностей
BEGIN 
  FOR r IN (
    SELECT seq_name FROM (
      SELECT 'seq_categories' seq_name FROM dual UNION ALL
      SELECT 'seq_companies' FROM dual UNION ALL
      SELECT 'seq_products' FROM dual UNION ALL
      SELECT 'seq_inventory' FROM dual UNION ALL
      SELECT 'seq_media' FROM dual UNION ALL
      SELECT 'seq_customers' FROM dual UNION ALL
      SELECT 'seq_orders' FROM dual UNION ALL
      SELECT 'seq_order_items' FROM dual UNION ALL
      SELECT 'seq_payments' FROM dual UNION ALL
      SELECT 'seq_suppliers' FROM dual
    )
  ) LOOP 
    BEGIN 
      EXECUTE IMMEDIATE 'DROP SEQUENCE ' || r.seq_name; 
    EXCEPTION WHEN OTHERS THEN NULL; 
    END; 
  END LOOP; 
END;
/

-- Создание последовательностей в процедурах
BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_categories START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_companies START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_products START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_inventory START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_media START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_customers START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_orders START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_order_items START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_payments START WITH 1 NOCACHE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_suppliers START WITH 1 NOCACHE';
  DBMS_OUTPUT.PUT_LINE('Последовательности созданы');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания последовательностей: ' || SQLERRM);
END;
/

-- Создание триггеров в процедурах
BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_categories
BEFORE INSERT ON categories FOR EACH ROW
BEGIN 
  IF :NEW.category_id IS NULL THEN 
    :NEW.category_id := seq_categories.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_companies
BEFORE INSERT ON companies FOR EACH ROW
BEGIN 
  IF :NEW.company_id IS NULL THEN 
    :NEW.company_id := seq_companies.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_products
BEFORE INSERT ON products FOR EACH ROW
BEGIN 
  IF :NEW.product_id IS NULL THEN 
    :NEW.product_id := seq_products.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_inventory
BEFORE INSERT ON inventory FOR EACH ROW
BEGIN 
  IF :NEW.inventory_id IS NULL THEN 
    :NEW.inventory_id := seq_inventory.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_media
BEFORE INSERT ON product_media FOR EACH ROW
BEGIN 
  IF :NEW.media_id IS NULL THEN 
    :NEW.media_id := seq_media.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_customers
BEFORE INSERT ON customers FOR EACH ROW
BEGIN 
  IF :NEW.customer_id IS NULL THEN 
    :NEW.customer_id := seq_customers.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_orders
BEFORE INSERT ON orders FOR EACH ROW
BEGIN 
  IF :NEW.order_id IS NULL THEN 
    :NEW.order_id := seq_orders.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_order_items
BEFORE INSERT ON order_items FOR EACH ROW
BEGIN 
  IF :NEW.order_item_id IS NULL THEN 
    :NEW.order_item_id := seq_order_items.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_payments
BEFORE INSERT ON payments FOR EACH ROW
BEGIN 
  IF :NEW.payment_id IS NULL THEN 
    :NEW.payment_id := seq_payments.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_suppliers
BEFORE INSERT ON suppliers FOR EACH ROW
BEGIN 
  IF :NEW.supplier_id IS NULL THEN 
    :NEW.supplier_id := seq_suppliers.NEXTVAL; 
  END IF; 
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Бизнес-триггеры
BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_ai_oi_decrement_inventory
AFTER INSERT ON order_items FOR EACH ROW
DECLARE
  v_inventory_id NUMBER;
BEGIN
  SELECT inventory_id INTO v_inventory_id FROM products WHERE product_id = :NEW.product_id;
  UPDATE inventory SET quantity = quantity - :NEW.quantity, updated_at = SYSDATE
  WHERE inventory_id = v_inventory_id;
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_ad_oi_restore_inventory
AFTER DELETE ON order_items FOR EACH ROW
DECLARE
  v_inventory_id NUMBER;
BEGIN
  SELECT inventory_id INTO v_inventory_id FROM products WHERE product_id = :OLD.product_id;
  UPDATE inventory SET quantity = quantity + :OLD.quantity, updated_at = SYSDATE
  WHERE inventory_id = v_inventory_id;
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_ai_oi_update_total
AFTER INSERT OR DELETE OR UPDATE OF quantity, price ON order_items FOR EACH ROW
BEGIN
  IF INSERTING THEN
    UPDATE orders SET total_amount = NVL(total_amount,0) + (:NEW.quantity * :NEW.price) WHERE order_id = :NEW.order_id;
  ELSIF DELETING THEN
    UPDATE orders SET total_amount = NVL(total_amount,0) - (:OLD.quantity * :OLD.price) WHERE order_id = :OLD.order_id;
  ELSIF UPDATING THEN
    UPDATE orders SET total_amount = NVL(total_amount,0) - (:OLD.quantity * :OLD.price) + (:NEW.quantity * :NEW.price) WHERE order_id = :NEW.order_id;
  END IF;
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
EXECUTE IMMEDIATE '
CREATE OR REPLACE TRIGGER trg_bi_oi_default_price
BEFORE INSERT ON order_items FOR EACH ROW
DECLARE
  v_price products.price%TYPE;
BEGIN
  IF :NEW.price IS NULL THEN
    SELECT price INTO v_price FROM products WHERE product_id = :NEW.product_id;
    :NEW.price := v_price;
  END IF;
END;';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
