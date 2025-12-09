-- Пакет валидации данных для таблиц: централизованные проверки перед изменением записей
CREATE OR REPLACE PACKAGE pkg_validation AS
  PROCEDURE check_category(p_name VARCHAR2, p_description VARCHAR2);
  PROCEDURE check_company(p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2);
  PROCEDURE check_product(
    p_company_id   NUMBER,
    p_category_id  NUMBER,
    p_inventory_id NUMBER,
    p_sku          VARCHAR2,
    p_name         VARCHAR2,
    p_price        NUMBER
  );
  PROCEDURE check_inventory(p_quantity NUMBER, p_restock_level NUMBER);
  PROCEDURE check_customer(p_email VARCHAR2, p_full_name VARCHAR2, p_phone VARCHAR2);
  PROCEDURE check_order(p_status VARCHAR2, p_total_amount NUMBER);
  PROCEDURE check_order_item(p_quantity NUMBER, p_price NUMBER);
  PROCEDURE check_payment(p_amount NUMBER, p_method VARCHAR2);
END pkg_validation;
/

CREATE OR REPLACE PACKAGE BODY pkg_validation AS

  PROCEDURE assert_condition(p_condition BOOLEAN, p_error_code NUMBER, p_message VARCHAR2) IS
  BEGIN
    IF NOT p_condition THEN
      RAISE_APPLICATION_ERROR(p_error_code, p_message);
    END IF;
  END;

  PROCEDURE check_category(p_name VARCHAR2, p_description VARCHAR2) IS
  BEGIN
    assert_condition(p_name IS NOT NULL AND LENGTH(TRIM(p_name)) >= 3,
                     -20901, 'Название категории должно содержать минимум 3 символа');
    assert_condition(LENGTH(p_name) <= 100,
                     -20902, 'Название категории не должно превышать 100 символов');
    IF p_description IS NOT NULL THEN
      assert_condition(LENGTH(p_description) <= 4000,
                       -20903, 'Описание категории слишком длинное (до 4000 символов)');
    END IF;
  END;

  PROCEDURE check_company(p_name VARCHAR2, p_country VARCHAR2, p_website VARCHAR2) IS
  BEGIN
    assert_condition(p_name IS NOT NULL AND LENGTH(TRIM(p_name)) >= 3,
                     -20911, 'Название компании должно содержать минимум 3 символа');
    assert_condition(LENGTH(p_name) <= 150,
                     -20912, 'Название компании не должно превышать 150 символов');
    IF p_country IS NOT NULL THEN
      assert_condition(LENGTH(p_country) <= 80,
                       -20913, 'Название страны не должно превышать 80 символов');
    END IF;
    IF p_website IS NOT NULL THEN
      assert_condition(LENGTH(p_website) <= 255,
                       -20914, 'URL сайта не должен превышать 255 символов');
      assert_condition(REGEXP_LIKE(p_website, '^(https?://).+\..+', 'i'),
                       -20915, 'URL сайта должен начинаться с http:// или https:// и содержать домен');
    END IF;
  END;

  PROCEDURE check_product(
    p_company_id   NUMBER,
    p_category_id  NUMBER,
    p_inventory_id NUMBER,
    p_sku          VARCHAR2,
    p_name         VARCHAR2,
    p_price        NUMBER
  ) IS
  BEGIN
    assert_condition(p_company_id IS NOT NULL,
                     -20921, 'Компания товара должна быть задана');
    assert_condition(p_category_id IS NOT NULL,
                     -20922, 'Категория товара должна быть задана');
    assert_condition(p_inventory_id IS NOT NULL,
                     -20923, 'Инвентарь товара должен быть задан');
    assert_condition(p_sku IS NOT NULL AND LENGTH(TRIM(p_sku)) >= 5,
                     -20924, 'SKU должен содержать минимум 5 символов');
    assert_condition(LENGTH(p_sku) <= 64,
                     -20925, 'SKU не должен превышать 64 символа');
    assert_condition(p_name IS NOT NULL AND LENGTH(TRIM(p_name)) >= 3,
                     -20926, 'Название товара должно содержать минимум 3 символа');
    assert_condition(LENGTH(p_name) <= 200,
                     -20927, 'Название товара не должно превышать 200 символов');
    assert_condition(p_price IS NOT NULL AND p_price >= 0,
                     -20928, 'Цена товара должна быть неотрицательной');
  END;

  PROCEDURE check_inventory(p_quantity NUMBER, p_restock_level NUMBER) IS
  BEGIN
    assert_condition(p_quantity IS NOT NULL AND p_quantity >= 0,
                     -20931, 'Количество на складе должно быть неотрицательным');
    assert_condition(p_restock_level IS NOT NULL AND p_restock_level >= 0,
                     -20932, 'Уровень пополнения должен быть неотрицательным');
  END;

  PROCEDURE check_customer(p_email VARCHAR2, p_full_name VARCHAR2, p_phone VARCHAR2) IS
  BEGIN
    assert_condition(p_email IS NOT NULL AND REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
                     -20941, 'Некорректный адрес электронной почты');
    assert_condition(LENGTH(p_email) <= 200,
                     -20942, 'Email не должен превышать 200 символов');
    assert_condition(p_full_name IS NOT NULL AND LENGTH(TRIM(p_full_name)) >= 3,
                     -20943, 'Имя клиента должно содержать минимум 3 символа');
    assert_condition(LENGTH(p_full_name) <= 200,
                     -20944, 'Имя клиента не должно превышать 200 символов');
    IF p_phone IS NOT NULL THEN
      assert_condition(LENGTH(p_phone) <= 50,
                       -20945, 'Телефон не должен превышать 50 символов');
    END IF;
  END;

  PROCEDURE check_order(p_status VARCHAR2, p_total_amount NUMBER) IS
  BEGIN
    assert_condition(p_status IS NOT NULL,
                     -20951, 'Статус заказа обязателен');
    assert_condition(LENGTH(p_status) <= 30,
                     -20952, 'Статус заказа не должен превышать 30 символов');
    assert_condition(p_total_amount IS NULL OR p_total_amount >= 0,
                     -20953, 'Сумма заказа должна быть неотрицательной');
  END;

  PROCEDURE check_order_item(p_quantity NUMBER, p_price NUMBER) IS
  BEGIN
    assert_condition(p_quantity IS NOT NULL AND p_quantity > 0,
                     -20961, 'Количество товара в заказе должно быть больше нуля');
    assert_condition(p_price IS NOT NULL AND p_price >= 0,
                     -20962, 'Цена позиции заказа должна быть неотрицательной');
  END;

  PROCEDURE check_payment(p_amount NUMBER, p_method VARCHAR2) IS
  BEGIN
    assert_condition(p_amount IS NOT NULL AND p_amount >= 0,
                     -20971, 'Сумма платежа должна быть неотрицательной');
    assert_condition(p_method IS NOT NULL AND LENGTH(TRIM(p_method)) >= 2,
                     -20972, 'Способ оплаты должен содержать минимум 2 символа');
    assert_condition(LENGTH(p_method) <= 50,
                     -20973, 'Способ оплаты не должен превышать 50 символов');
  END;

END pkg_validation;
/






