-- Пакет администратора: CRUD‑операции для категорий, компаний, товаров, инвентаря и медиа
-- Здесь только бизнес‑логика работы с таблицами, без демонстрационных сценариев

-- Создание пакета администратора
CREATE OR REPLACE PACKAGE pkg_admin AS
  -- категории
  PROCEDURE create_category(p_name VARCHAR2, p_description VARCHAR2);
  PROCEDURE update_category(p_category_id NUMBER, p_name VARCHAR2, p_description VARCHAR2);
  PROCEDURE delete_category(p_category_id NUMBER);

  -- компании
  PROCEDURE create_company(p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2);
  PROCEDURE update_company(p_company_id NUMBER, p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2);
  PROCEDURE delete_company(p_company_id NUMBER);

  -- продукты
  PROCEDURE create_product(p_company_id NUMBER, p_category_id NUMBER, p_sku VARCHAR2, p_name VARCHAR2, p_description VARCHAR2, p_price NUMBER);
  PROCEDURE update_product(p_product_id NUMBER, p_company_id NUMBER, p_category_id NUMBER, p_sku VARCHAR2, p_name VARCHAR2, p_description VARCHAR2, p_price NUMBER);
  PROCEDURE delete_product(p_product_id NUMBER);

  -- инвентаризация
  PROCEDURE set_inventory(p_product_id NUMBER, p_quantity NUMBER, p_restock_level NUMBER);

  -- медиа
  PROCEDURE add_product_media(p_product_id NUMBER, p_filename VARCHAR2, p_mime_type VARCHAR2, p_content BLOB);
  PROCEDURE delete_product_media(p_media_id NUMBER);
END pkg_admin;
/

CREATE OR REPLACE PACKAGE BODY pkg_admin AS

  PROCEDURE create_category(p_name VARCHAR2, p_description VARCHAR2) IS
  BEGIN
    IF p_name IS NULL OR TRIM(p_name) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20010, 'Название категории не может быть пустым');
    END IF;
    INSERT INTO categories(name, description) VALUES(p_name, p_description);
  END;

  PROCEDURE update_category(p_category_id NUMBER, p_name VARCHAR2, p_description VARCHAR2) IS
  BEGIN
    IF p_category_id IS NULL THEN RAISE_APPLICATION_ERROR(-20011, 'ID категории обязателен'); END IF;
    UPDATE categories SET name = p_name, description = p_description WHERE category_id = p_category_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20012, 'Категория не найдена'); END IF;
  END;

  PROCEDURE delete_category(p_category_id NUMBER) IS
  BEGIN
    IF p_category_id IS NULL THEN RAISE_APPLICATION_ERROR(-20013, 'ID категории обязателен'); END IF;
    DELETE FROM categories WHERE category_id = p_category_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20014, 'Категория не найдена'); END IF;
  END;

  PROCEDURE create_company(p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2) IS
  BEGIN
    IF p_name IS NULL OR TRIM(p_name) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20020, 'Название компании не может быть пустым');
    END IF;
    INSERT INTO companies(name, country, website) VALUES(p_name, p_country, p_website);
  END;

  PROCEDURE update_company(p_company_id NUMBER, p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2) IS
  BEGIN
    IF p_company_id IS NULL THEN RAISE_APPLICATION_ERROR(-20021, 'ID компании обязателен'); END IF;
    UPDATE companies SET name = p_name, country = p_country, website = p_website WHERE company_id = p_company_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20022, 'Компания не найдена'); END IF;
  END;

  PROCEDURE delete_company(p_company_id NUMBER) IS
  BEGIN
    IF p_company_id IS NULL THEN RAISE_APPLICATION_ERROR(-20023, 'ID компании обязателен'); END IF;
    DELETE FROM companies WHERE company_id = p_company_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20024, 'Компания не найдена'); END IF;
  END;

  PROCEDURE create_product(p_company_id NUMBER, p_category_id NUMBER, p_sku VARCHAR2, p_name VARCHAR2, p_description VARCHAR2, p_price NUMBER) IS
    v_inventory_id NUMBER;
  BEGIN
    IF p_company_id IS NULL OR p_category_id IS NULL OR p_sku IS NULL OR p_name IS NULL OR p_price IS NULL THEN
      RAISE_APPLICATION_ERROR(-20030, 'Обязательные поля товара не заполнены');
    END IF;
    v_inventory_id := seq_inventory.NEXTVAL; -- следующее уникальное значение из последовательности
    INSERT INTO inventory(inventory_id, quantity, restock_level)
    VALUES(v_inventory_id, 0, 0);
    INSERT INTO products(company_id, category_id, inventory_id, sku, name, description, price)
    VALUES(p_company_id, p_category_id, v_inventory_id, p_sku, p_name, p_description, p_price);
  END;

  PROCEDURE update_product(p_product_id NUMBER, p_company_id NUMBER, p_category_id NUMBER, p_sku VARCHAR2, p_name VARCHAR2, p_description VARCHAR2, p_price NUMBER) IS
  BEGIN
    IF p_product_id IS NULL THEN RAISE_APPLICATION_ERROR(-20031, 'ID товара обязателен'); END IF;
    UPDATE products
       SET company_id = p_company_id,
           category_id = p_category_id,
           sku = p_sku,
           name = p_name,
           description = p_description,
           price = p_price
     WHERE product_id = p_product_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20032, 'Товар не найден'); END IF;
  END;

  PROCEDURE delete_product(p_product_id NUMBER) IS
  BEGIN
    IF p_product_id IS NULL THEN RAISE_APPLICATION_ERROR(-20033, 'ID товара обязателен'); END IF;
    DELETE FROM products WHERE product_id = p_product_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20034, 'Товар не найден'); END IF;
  END;

  PROCEDURE set_inventory(p_product_id NUMBER, p_quantity NUMBER, p_restock_level NUMBER) IS
    v_inventory_id NUMBER;
  BEGIN
    SELECT inventory_id INTO v_inventory_id FROM products WHERE product_id = p_product_id;
    UPDATE inventory SET quantity = p_quantity, restock_level = p_restock_level, updated_at = SYSDATE
    WHERE inventory_id = v_inventory_id;
    IF SQL%ROWCOUNT = 0 THEN RAISE_APPLICATION_ERROR(-20035, 'Инвентарь не найден'); END IF;
  END;

  PROCEDURE add_product_media(p_product_id NUMBER, p_filename VARCHAR2, p_mime_type VARCHAR2, p_content BLOB) IS
  BEGIN
    INSERT INTO product_media(product_id, filename, mime_type, content)
    VALUES(p_product_id, p_filename, p_mime_type, p_content);
  END;

  PROCEDURE delete_product_media(p_media_id NUMBER) IS
  BEGIN
    DELETE FROM product_media WHERE media_id = p_media_id;
  END;
END pkg_admin;
/


BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET "_ORACLE_SCRIPT"=true';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_admin TO COSM_ROLE_ADMIN';
  DBMS_OUTPUT.PUT_LINE('Права на пакет pkg_admin предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав: ' || SQLERRM);
END;
/