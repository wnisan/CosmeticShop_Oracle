-- Пакет с вызовом pkg_admin, pkg_shop, pkg_json, pkg_analytics. Добавление к ним вспомогательных функций (поиск ID, вывод курсоров),
-- Объединение действий в удобные сценарии (фильтры, аналитика, заказы) 

CREATE OR REPLACE PACKAGE pkg_admin_runner AS
  PROCEDURE setup_basic_data_demo;

  PROCEDURE add_category_demo(p_name IN VARCHAR2, p_desc IN VARCHAR2);
  PROCEDURE get_category_id_demo(p_name IN VARCHAR2);
  PROCEDURE update_category_demo(p_old_id IN NUMBER, p_new_name IN VARCHAR2, p_new_desc IN VARCHAR2);
  PROCEDURE list_categories_demo;
  PROCEDURE delete_category_by_name_demo(p_name IN VARCHAR2);

  PROCEDURE add_company_demo(p_name IN VARCHAR2, p_country IN VARCHAR2, p_website IN VARCHAR2);
  PROCEDURE get_company_id_demo(p_name IN VARCHAR2);
  PROCEDURE update_company_demo(p_id IN NUMBER, p_new_name IN VARCHAR2, p_new_country IN VARCHAR2, p_new_website IN VARCHAR2);
  PROCEDURE list_companies_demo;
  PROCEDURE delete_company_by_name_demo(p_name IN VARCHAR2);

  PROCEDURE add_product_demo(
    p_company_name   IN VARCHAR2,
    p_category_name  IN VARCHAR2,
    p_sku            IN VARCHAR2,
    p_title          IN VARCHAR2,
    p_description    IN VARCHAR2,
    p_price          IN NUMBER
  );
  PROCEDURE update_product_by_sku_demo(
    p_old_sku         IN VARCHAR2,
    p_company_name    IN VARCHAR2,
    p_category_name   IN VARCHAR2,
    p_new_sku         IN VARCHAR2,
    p_new_title       IN VARCHAR2,
    p_new_description IN VARCHAR2,
    p_new_price       IN NUMBER
  );
  PROCEDURE list_products_demo;
  PROCEDURE list_products_detailed_demo(p_note IN VARCHAR2 DEFAULT NULL);
  PROCEDURE delete_product_by_sku_demo(p_sku IN VARCHAR2);
  PROCEDURE set_inventory_demo(p_sku IN VARCHAR2, p_available IN NUMBER, p_reserved IN NUMBER);

  PROCEDURE add_media_demo(p_sku IN VARCHAR2, p_file_name IN VARCHAR2, p_mime IN VARCHAR2);
  PROCEDURE list_media_demo;
  PROCEDURE list_products_with_media_demo(p_sku_pattern IN VARCHAR2 DEFAULT NULL);

  PROCEDURE export_orders_demo(p_filename IN VARCHAR2, p_limit IN NUMBER DEFAULT NULL);
  PROCEDURE import_orders_demo(p_filename IN VARCHAR2);
  PROCEDURE test_json_package_demo;

  PROCEDURE filter_by_category_demo(p_category_name IN VARCHAR2);
  PROCEDURE filter_by_company_demo(p_company_name IN VARCHAR2);
  PROCEDURE filter_by_price_range_demo(p_min_price IN NUMBER, p_max_price IN NUMBER);
  PROCEDURE sort_products_demo(p_sort_by IN VARCHAR2, p_sort_dir IN VARCHAR2);

  PROCEDURE analytics_basic_demo;
  PROCEDURE analytics_extended_demo;
  PROCEDURE analytics_forecast_demo;
  PROCEDURE analytics_admin_general_stats_demo;
  PROCEDURE analytics_predict_demo;

  PROCEDURE ensure_customer_demo(p_email IN VARCHAR2, p_name IN VARCHAR2, p_phone IN VARCHAR2);
  PROCEDURE create_order_with_items_demo(
    p_email      IN VARCHAR2,
    p_skus       IN SYS.ODCIVARCHAR2LIST,
    p_quantities IN SYS.ODCINUMBERLIST,
    p_prices     IN SYS.ODCINUMBERLIST
  );
  PROCEDURE list_orders_by_email_demo(p_email IN VARCHAR2);
  PROCEDURE list_order_items_by_email_demo(p_email IN VARCHAR2);

  PROCEDURE cleanup_test_data_demo;
  PROCEDURE run_all_tests_simple_demo;

  -- Функции для получения ID 
  FUNCTION get_category_id_by_name(p_name IN VARCHAR2) RETURN NUMBER;
  FUNCTION get_company_id_by_name(p_name IN VARCHAR2) RETURN NUMBER;
  FUNCTION get_product_id_by_sku(p_sku IN VARCHAR2) RETURN NUMBER;

  -- Процедуры для SELECT запросов из тестов
  PROCEDURE list_products_before_import_demo;
  PROCEDURE list_products_after_import_demo;
  PROCEDURE list_products_by_category_view_demo(p_category_name IN VARCHAR2);
  PROCEDURE list_orders_by_email_sql_demo(p_email IN VARCHAR2);
  PROCEDURE list_order_items_by_email_sql_demo(p_email IN VARCHAR2);
  PROCEDURE create_order_manual_demo(
    p_email IN VARCHAR2,
    p_sku1 IN VARCHAR2,
    p_qty1 IN NUMBER,
    p_price1 IN NUMBER,
    p_sku2 IN VARCHAR2,
    p_qty2 IN NUMBER,
    p_price2 IN NUMBER
  );
  PROCEDURE get_performance_stats_demo;
  PROCEDURE get_view_data_demo;
  PROCEDURE get_general_metrics_demo;
  PROCEDURE get_orders_statistics_demo;
  PROCEDURE list_user_products_by_category_demo(p_category_name IN VARCHAR2);
  PROCEDURE list_user_products_by_company_demo(p_company_name IN VARCHAR2);
  PROCEDURE list_user_products_overview_demo(p_limit IN NUMBER DEFAULT 10);
  PROCEDURE search_user_products_demo(p_keyword IN VARCHAR2);
  PROCEDURE compare_prices_by_category_demo(p_category_name IN VARCHAR2);
  PROCEDURE list_user_promotions_demo(p_max_price IN NUMBER);
  PROCEDURE get_user_statistics_demo;

  -- Процедуры для обработки циклов FETCH
  PROCEDURE list_all_products_sorted_demo(p_sort_by IN VARCHAR2 DEFAULT 'price', p_sort_dir IN VARCHAR2 DEFAULT 'ASC');
  PROCEDURE list_products_price_range_demo(p_min_price IN NUMBER, p_max_price IN NUMBER, p_sort_dir IN VARCHAR2 DEFAULT 'DESC');
  PROCEDURE list_popular_products_demo(p_top IN NUMBER DEFAULT 5);
  PROCEDURE get_total_products_demo;
END pkg_admin_runner;
/

CREATE OR REPLACE PACKAGE BODY pkg_admin_runner AS
  -- Вспомогательные функции
  FUNCTION find_category_id(p_name VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT category_id
      INTO v_id
      FROM categories
     WHERE LOWER(name) = LOWER(p_name);
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RETURN NULL;
      ELSE
        RAISE;
      END IF;
  END;

  FUNCTION find_company_id(p_name VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT company_id
      INTO v_id
      FROM companies
     WHERE LOWER(name) = LOWER(p_name);
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RETURN NULL;
      ELSE
        RAISE;
      END IF;
  END;

  FUNCTION find_product_id(p_sku VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT product_id
      INTO v_id
      FROM products
     WHERE LOWER(sku) = LOWER(p_sku);
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RETURN NULL;
      ELSE
        RAISE;
      END IF;
  END;

  FUNCTION find_customer_id(p_email VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT customer_id
      INTO v_id
      FROM customers
     WHERE LOWER(email) = LOWER(p_email);
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RETURN NULL;
      ELSE
        RAISE;
      END IF;
  END;

  PROCEDURE print_divider(p_title VARCHAR2) IS
  BEGIN
    IF p_title IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE(p_title);
    END IF;
  END;

  -- Базовые данные
  PROCEDURE setup_basic_data_demo IS
  BEGIN
    BEGIN
      pkg_admin.create_category('Skincare', 'Средства для ухода за кожей');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
      pkg_admin.create_category('Makeup', 'Декоративная косметика');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
      pkg_admin.create_category('Haircare', 'Средства для волос');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
      pkg_admin.create_company('L''Oreal', 'France', 'http://loreal.com');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
      pkg_admin.create_company('Estee Lauder', 'USA', 'http://esteelauder.com');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
      pkg_admin.create_company('Nivea', 'Germany', 'http://nivea.com');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    DBMS_OUTPUT.PUT_LINE('setup_basic_data_demo: Готово');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('setup_basic_data_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Категории
  PROCEDURE add_category_demo(p_name IN VARCHAR2, p_desc IN VARCHAR2) IS
  BEGIN
    pkg_admin.create_category(p_name, p_desc);
    DBMS_OUTPUT.PUT_LINE('add_category_demo: Создана категория "' || p_name || '"');
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('add_category_demo: Категория с таким названием уже существует');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('add_category_demo: Проблема с генерацией ID категории');
        WHEN SQLCODE = -12899 THEN
          DBMS_OUTPUT.PUT_LINE('add_category_demo: Слишком длинные данные (название или описание)');
        ELSE
          DBMS_OUTPUT.PUT_LINE('add_category_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE get_category_id_demo(p_name IN VARCHAR2) IS
    v_id NUMBER;
  BEGIN
    v_id := find_category_id(p_name);
    IF v_id IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('get_category_id_demo: ID категории "' || p_name || '" = ' || v_id);
    ELSE
      DBMS_OUTPUT.PUT_LINE('get_category_id_demo: Категория "' || p_name || '" не найдена');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_category_id_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE update_category_demo(p_old_id IN NUMBER, p_new_name IN VARCHAR2, p_new_desc IN VARCHAR2) IS
  BEGIN
    pkg_admin.update_category(p_old_id, p_new_name, p_new_desc);
    DBMS_OUTPUT.PUT_LINE('update_category_demo: Обновлена категория ID=' || p_old_id);
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('update_category_demo: Категория с таким названием уже существует');
        WHEN SQLCODE = -20012 THEN
          DBMS_OUTPUT.PUT_LINE('update_category_demo: Категория не найдена');
        WHEN SQLCODE = -12899 THEN
          DBMS_OUTPUT.PUT_LINE('update_category_demo: Слишком длинные данные');
        ELSE
          DBMS_OUTPUT.PUT_LINE('update_category_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE list_categories_demo IS
  BEGIN
    print_divider('list_categories_demo: Список категорий');
    -- курсорный цикл по результатам SQL-запроса
    FOR r IN (
      SELECT category_id, name, description
        FROM categories
       ORDER BY name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.category_id || ' | ' || r.name || ' | ' || NVL(r.description, '-'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_categories_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE delete_category_by_name_demo(p_name IN VARCHAR2) IS
    v_id NUMBER;
  BEGIN
    v_id := find_category_id(p_name);
    IF v_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('delete_category_by_name_demo: Категория "' || p_name || '" не найдена');
      RETURN;
    END IF;
    pkg_admin.delete_category(v_id);
    DBMS_OUTPUT.PUT_LINE('delete_category_by_name_demo: Удалена категория "' || p_name || '" (ID=' || v_id || ')');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('delete_category_by_name_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Компании
  PROCEDURE add_company_demo(p_name IN VARCHAR2, p_country IN VARCHAR2, p_website IN VARCHAR2) IS
  BEGIN
    pkg_admin.create_company(p_name, p_country, p_website);
    DBMS_OUTPUT.PUT_LINE('add_company_demo: Создана компания "' || p_name || '"');
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('add_company_demo: Компания с таким названием уже существует');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('add_company_demo: Проблема с генерацией ID компании');
        WHEN SQLCODE = -12899 THEN
          DBMS_OUTPUT.PUT_LINE('add_company_demo: Слишком длинные данные');
        ELSE
          DBMS_OUTPUT.PUT_LINE('add_company_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE get_company_id_demo(p_name IN VARCHAR2) IS
    v_id NUMBER;
  BEGIN
    v_id := find_company_id(p_name);
    IF v_id IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('get_company_id_demo: ID компании "' || p_name || '" = ' || v_id);
    ELSE
      DBMS_OUTPUT.PUT_LINE('get_company_id_demo: Компания "' || p_name || '" не найдена');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_company_id_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE update_company_demo(p_id IN NUMBER, p_new_name IN VARCHAR2, p_new_country IN VARCHAR2, p_new_website IN VARCHAR2) IS
  BEGIN
    pkg_admin.update_company(p_id, p_new_name, p_new_country, p_new_website);
    DBMS_OUTPUT.PUT_LINE('update_company_demo: Обновлена компания ID=' || p_id);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('update_company_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_companies_demo IS
  BEGIN
    print_divider('list_companies_demo: Список компаний');
    FOR r IN (
      SELECT company_id, name, country, website
        FROM companies
       ORDER BY name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.company_id || ' | ' || r.name || ' | ' || NVL(r.country, '-') || ' | ' || NVL(r.website, '-'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_companies_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE delete_company_by_name_demo(p_name IN VARCHAR2) IS
    v_id NUMBER;
  BEGIN
    v_id := find_company_id(p_name);
    IF v_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('delete_company_by_name_demo: Компания "' || p_name || '" не найдена');
      RETURN;
    END IF;
    pkg_admin.delete_company(v_id);
    DBMS_OUTPUT.PUT_LINE('delete_company_by_name_demo: Удалена компания "' || p_name || '" (ID=' || v_id || ')');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('delete_company_by_name_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Товары
  PROCEDURE add_product_demo(
    p_company_name   IN VARCHAR2,
    p_category_name  IN VARCHAR2,
    p_sku            IN VARCHAR2,
    p_title          IN VARCHAR2,
    p_description    IN VARCHAR2,
    p_price          IN NUMBER
  ) IS
    v_company_id  NUMBER;
    v_category_id NUMBER;
    v_product_id  NUMBER;
  BEGIN
    v_product_id := find_product_id(p_sku);
    IF v_product_id IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('add_product_demo: Товар SKU=' || p_sku || ' уже существует, пропуск');
      RETURN;
    END IF;

    v_company_id := find_company_id(p_company_name);
    IF v_company_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('add_product_demo: Компания "' || p_company_name || '" не найдена');
      IF p_company_name IN ('L''Oreal', 'Estee Lauder', 'Nivea') THEN
        BEGIN
          IF p_company_name = 'L''Oreal' THEN
            pkg_admin.create_company('L''Oreal', 'France', 'http://loreal.com');
          ELSIF p_company_name = 'Estee Lauder' THEN
            pkg_admin.create_company('Estee Lauder', 'USA', 'http://esteelauder.com');
          ELSIF p_company_name = 'Nivea' THEN
            pkg_admin.create_company('Nivea', 'Germany', 'http://nivea.com');
          END IF;
          v_company_id := find_company_id(p_company_name);
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Компания "' || p_company_name || '" создана автоматически');
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('add_product_demo: Не удалось создать компанию "' || p_company_name || '"');
        END;
      END IF;
      IF v_company_id IS NULL THEN
        RETURN;
      END IF;
    END IF;
    v_category_id := find_category_id(p_category_name);
    IF v_category_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('add_product_demo: Категория "' || p_category_name || '" не найдена');
      RETURN;
    END IF;

    pkg_admin.create_product(
      v_company_id,
      v_category_id,
      p_sku,
      p_title,
      p_description,
      p_price
    );
    DBMS_OUTPUT.PUT_LINE('add_product_demo: Создан товар SKU=' || p_sku);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      DBMS_OUTPUT.PUT_LINE('add_product_demo: Товар SKU=' || p_sku || ' уже существует (нарушение уникальности), пропуск');
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Товар с таким артикулом (SKU) уже существует');
        WHEN SQLCODE = -2291 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Указана несуществующая категория или компания');
        WHEN SQLCODE = -2290 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Некорректные данные (отрицательная цена)');
        WHEN SQLCODE = -12899 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Слишком длинные данные (SKU, название или описание превышают лимит)');
        WHEN SQLCODE = -1722 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Некорректный формат числа (цена)');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('add_product_demo: Проблема с генерацией ID товара или инвентаря');
        ELSE
          DBMS_OUTPUT.PUT_LINE('add_product_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE update_product_by_sku_demo(
    p_old_sku         IN VARCHAR2,
    p_company_name    IN VARCHAR2,
    p_category_name   IN VARCHAR2,
    p_new_sku         IN VARCHAR2,
    p_new_title       IN VARCHAR2,
    p_new_description IN VARCHAR2,
    p_new_price       IN NUMBER
  ) IS
    v_product_id  NUMBER;
    v_company_id  NUMBER;
    v_category_id NUMBER;
  BEGIN
    v_product_id := find_product_id(p_old_sku);
    IF v_product_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Товар ' || p_old_sku || ' не найден');
      RETURN;
    END IF;
    v_company_id := find_company_id(p_company_name);
    IF v_company_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Компания "' || p_company_name || '" не найдена');
      RETURN;
    END IF;
    v_category_id := find_category_id(p_category_name);
    IF v_category_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Категория "' || p_category_name || '" не найдена');
      RETURN;
    END IF;

    pkg_admin.update_product(
      v_product_id,
      v_company_id,
      v_category_id,
      p_new_sku,
      p_new_title,
      p_new_description,
      p_new_price
    );
    DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Обновлён товар ' || p_old_sku || ' -> ' || p_new_sku);
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Товар с новым артикулом (SKU) уже существует');
        WHEN SQLCODE = -2291 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Указана несуществующая категория или компания');
        WHEN SQLCODE = -2290 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Некорректные данные (отрицательная цена)');
        WHEN SQLCODE = -20032 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Товар не найден');
        WHEN SQLCODE = -12899 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Слишком длинные данные');
        WHEN SQLCODE = -1722 THEN
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: Некорректный формат числа (цена)');
        ELSE
          DBMS_OUTPUT.PUT_LINE('update_product_by_sku_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE list_products_demo IS
  BEGIN
    print_divider('list_products_demo: Товары');
    FOR r IN (
      SELECT p.product_id,
             p.sku,
             p.name,
             c.name AS category_name,
             co.name AS company_name,
             p.price
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        JOIN companies co ON co.company_id = p.company_id
       ORDER BY p.product_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_id || ' | ' || r.sku || ' | ' || r.name || ' | ' ||
                           r.category_name || ' | ' || r.company_name || ' | $' || TO_CHAR(r.price, 'FM9999990.00'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_products_detailed_demo(p_note IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    print_divider('list_products_detailed_demo: ' || NVL(p_note, 'Детальный список'));
    FOR r IN (
      SELECT product_id,
             sku,
             product_name,
             category_name,
             company_name,
             price,
             quantity
        FROM v_product_overview
       ORDER BY product_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_id || ' | ' || r.sku || ' | ' || r.product_name || ' | ' ||
                           r.category_name || ' | ' || r.company_name || ' | $' ||
                           TO_CHAR(r.price, 'FM9999990.00') || ' | ' || r.quantity || ' шт');
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_detailed_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE delete_product_by_sku_demo(p_sku IN VARCHAR2) IS
    v_product_id NUMBER;
  BEGIN
    v_product_id := find_product_id(p_sku);
    IF v_product_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('delete_product_by_sku_demo: Товар SKU=' || p_sku || ' не найден');
      RETURN;
    END IF;
    pkg_admin.delete_product(v_product_id);
    DBMS_OUTPUT.PUT_LINE('delete_product_by_sku_demo: Удалён товар SKU=' || p_sku);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('delete_product_by_sku_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE set_inventory_demo(p_sku IN VARCHAR2, p_available IN NUMBER, p_reserved IN NUMBER) IS
    v_product_id NUMBER;
  BEGIN
    v_product_id := find_product_id(p_sku);
    IF v_product_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('set_inventory_demo: Товар SKU=' || p_sku || ' не найден');
      RETURN;
    END IF;

    pkg_admin.set_inventory(v_product_id, p_available, NVL(p_reserved, 0));
    DBMS_OUTPUT.PUT_LINE('set_inventory_demo: Установлен инвентарь для ' || p_sku ||
                         ' -> available=' || p_available || ', reserved=' || NVL(p_reserved, 0));
    list_products_detailed_demo('После установки инвентаря');
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -2290 THEN
          DBMS_OUTPUT.PUT_LINE('set_inventory_demo: Некорректные данные инвентаря (отрицательное количество)');
        WHEN SQLCODE = -20035 THEN
          DBMS_OUTPUT.PUT_LINE('set_inventory_demo: Инвентарь не найден');
        WHEN SQLCODE = -1403 THEN
          DBMS_OUTPUT.PUT_LINE('set_inventory_demo: Товар или инвентарь не найдены');
        ELSE
          DBMS_OUTPUT.PUT_LINE('set_inventory_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  -- Мультимедиа
  PROCEDURE add_media_demo(p_sku IN VARCHAR2, p_file_name IN VARCHAR2, p_mime IN VARCHAR2) IS
    v_product_id NUMBER;
  BEGIN
    v_product_id := find_product_id(p_sku);
    IF v_product_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('add_media_demo: Товар SKU=' || p_sku || ' не найден');
      RETURN;
    END IF;

    INSERT INTO product_media(product_id, filename, mime_type, content)
    VALUES(v_product_id, p_file_name, p_mime, EMPTY_BLOB());

    DBMS_OUTPUT.PUT_LINE('add_media_demo: Добавлен плейсхолдер медиа "' || p_file_name || '" для SKU=' || p_sku);
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
          DBMS_OUTPUT.PUT_LINE('add_media_demo: Проблема с файлом. Файл не найден или нет прав доступа');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('add_media_demo: Проблема с генерацией ID медиа');
        WHEN SQLCODE = -1403 THEN
          DBMS_OUTPUT.PUT_LINE('add_media_demo: Товар не найден');
        ELSE
          DBMS_OUTPUT.PUT_LINE('add_media_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE list_media_demo IS
  BEGIN
    print_divider('list_media_demo: Мультимедиа');
    FOR r IN (
      SELECT media_id, product_id, filename, mime_type, uploaded_at
        FROM product_media
       ORDER BY media_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.media_id || ' | product_id=' || r.product_id || ' | ' ||
                           r.filename || ' | ' || r.mime_type || ' | ' || TO_CHAR(r.uploaded_at, 'YYYY-MM-DD HH24:MI'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_media_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_products_with_media_demo(p_sku_pattern IN VARCHAR2 DEFAULT NULL) IS
  BEGIN
    IF p_sku_pattern IS NOT NULL THEN
      print_divider('list_products_with_media_demo: Товары с изображениями (SKU LIKE ''' || p_sku_pattern || ''')');
    ELSE
      print_divider('list_products_with_media_demo: Все товары с изображениями');
    END IF;
    
    FOR r IN (
      SELECT 
        pm.product_id,
        p.sku,
        p.name as product_name,
        pm.filename,
        pm.mime_type,
        ROUND(DBMS_LOB.GETLENGTH(pm.content) / 1024, 2) as size_kb,
        TO_CHAR(pm.uploaded_at, 'DD.MM.YYYY HH24:MI') as uploaded_time
      FROM product_media pm
      JOIN products p ON p.product_id = pm.product_id
      WHERE (p_sku_pattern IS NULL OR p.sku LIKE p_sku_pattern)
      ORDER BY pm.product_id, pm.uploaded_at DESC
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(
        'Товар: ' || r.product_name || ' (SKU: ' || r.sku || ') | ' ||
        'Изображение: ' || r.filename || ' | ' ||
        'Тип: ' || r.mime_type || ' | ' ||
        'Размер: ' || r.size_kb || ' KB | ' ||
        'Загружено: ' || r.uploaded_time
      );
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_with_media_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- JSON
  PROCEDURE export_orders_demo(p_filename IN VARCHAR2, p_limit IN NUMBER DEFAULT NULL) IS
  BEGIN
    pkg_json.export_orders(p_filename, p_limit);
    DBMS_OUTPUT.PUT_LINE('export_orders_demo: Экспорт заказов выполнен в ' || p_filename);
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
          DBMS_OUTPUT.PUT_LINE('export_orders_demo: Проблема с файлом. Файл не найден или нет прав доступа');
        WHEN SQLCODE = -942 OR SQLCODE = -1031 THEN
          DBMS_OUTPUT.PUT_LINE('export_orders_demo: Пакет pkg_json не найден или нет прав доступа');
        ELSE
          DBMS_OUTPUT.PUT_LINE('export_orders_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE import_orders_demo(p_filename IN VARCHAR2) IS
  BEGIN
    pkg_json.import_orders(p_filename);
    DBMS_OUTPUT.PUT_LINE('import_orders_demo: Импорт заказов выполнен из ' || p_filename);
  EXCEPTION
    WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -40441 OR SQLCODE = -40442 THEN
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: Некорректный формат JSON файла');
        WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: Файл не найден или нет прав доступа');
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: Нарушение уникальности при импорте (заказ с таким ID уже существует)');
        WHEN SQLCODE = -2291 THEN
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: В JSON указан несуществующий клиент');
        WHEN SQLCODE = -942 OR SQLCODE = -1031 THEN
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: Пакет pkg_json не найден или нет прав доступа');
        ELSE
          DBMS_OUTPUT.PUT_LINE('import_orders_demo: ОШИБКА - ' || SQLERRM);
      END CASE;
  END;

  PROCEDURE test_json_package_demo IS
    v_result VARCHAR2(4000);
  BEGIN
    v_result := pkg_json.test_json_operations;
    DBMS_OUTPUT.PUT_LINE('test_json_package_demo: ' || v_result);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('test_json_package_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Фильтры и сортировка 
  PROCEDURE print_products_from_cursor(p_cursor IN OUT pkg_shop.ref_cursor) IS -- уже открытый курсор из вне
    v_product_id NUMBER;
    v_sku        VARCHAR2(100);
    v_name       VARCHAR2(200);
    v_category   VARCHAR2(100);
    v_company    VARCHAR2(150);
    v_price      NUMBER;
    v_quantity   NUMBER;
  BEGIN
    LOOP
    -- чтение строк
      FETCH p_cursor INTO v_product_id, v_sku, v_name, v_category, v_company, v_price, v_quantity;
      EXIT WHEN p_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_product_id || ' | ' || v_sku || ' | ' || v_name || ' | ' ||
                           v_category || ' | ' || v_company || ' | $' || TO_CHAR(v_price, 'FM9999990.00') ||
                           ' | ' || NVL(v_quantity, 0) || ' шт');
    END LOOP;
    CLOSE p_cursor;
  END;

  PROCEDURE filter_by_category_demo(p_category_name IN VARCHAR2) IS
    v_category_id NUMBER;
    v_cursor pkg_shop.ref_cursor;
  BEGIN
    v_category_id := find_category_id(p_category_name);
    IF v_category_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('filter_by_category_demo: Категория "' || p_category_name || '" не найдена');
      RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('filter_by_category_demo: Фильтрация по категории=' || p_category_name);
    pkg_shop.list_products(v_category_id, NULL, NULL, NULL, 'name', 'ASC', v_cursor);
    print_products_from_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('filter_by_category_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE filter_by_company_demo(p_company_name IN VARCHAR2) IS
    v_company_id NUMBER;
    v_cursor     pkg_shop.ref_cursor;
  BEGIN
    v_company_id := find_company_id(p_company_name);
    IF v_company_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('filter_by_company_demo: Компания "' || p_company_name || '" не найдена');
      RETURN;
    END IF;
    DBMS_OUTPUT.PUT_LINE('filter_by_company_demo: Фильтрация по компании=' || p_company_name);
    pkg_shop.list_products(NULL, v_company_id, NULL, NULL, 'name', 'ASC', v_cursor);
    print_products_from_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('filter_by_company_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE filter_by_price_range_demo(p_min_price IN NUMBER, p_max_price IN NUMBER) IS
    v_cursor pkg_shop.ref_cursor;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('filter_by_price_range_demo: Цена от ' || NVL(p_min_price, 0) || ' до ' || NVL(p_max_price, 0));
    pkg_shop.list_products(NULL, NULL, p_min_price, p_max_price, 'price', 'DESC', v_cursor);
    print_products_from_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('filter_by_price_range_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE sort_products_demo(p_sort_by IN VARCHAR2, p_sort_dir IN VARCHAR2) IS
    v_cursor pkg_shop.ref_cursor;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('sort_products_demo: Сортировка по ' || p_sort_by || ' ' || p_sort_dir);
    pkg_shop.list_products(NULL, NULL, NULL, NULL, p_sort_by, p_sort_dir, v_cursor);
    print_products_from_cursor(v_cursor);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('sort_products_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Аналитика
  PROCEDURE analytics_basic_demo IS
    v_total_products NUMBER;
    v_total_revenue  NUMBER;
    v_total_orders   NUMBER;
    v_total_customers NUMBER;
  BEGIN
    v_total_products := pkg_shop.total_products;
    v_total_revenue  := pkg_shop.total_revenue;
    SELECT COUNT(*) INTO v_total_orders FROM orders;
    SELECT COUNT(*) INTO v_total_customers FROM customers;

    DBMS_OUTPUT.PUT_LINE('Товаров всего: ' || v_total_products);
    DBMS_OUTPUT.PUT_LINE('Заказов всего: ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE('Клиентов всего: ' || v_total_customers);
    DBMS_OUTPUT.PUT_LINE('Выручка: $' || TO_CHAR(NVL(v_total_revenue,0), 'FM9999990.00'));
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('analytics_basic_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE analytics_extended_demo IS
    v_cursor pkg_analytics.ref_cursor;
    v_metric VARCHAR2(200);
    v_value  VARCHAR2(4000);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('analytics_extended_demo: Общие метрики');
    pkg_analytics.get_general_stats(v_cursor);
    LOOP
      FETCH v_cursor INTO v_metric, v_value;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_metric || ': ' || v_value);
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('analytics_extended_demo: ОШИБКА - ' || SQLERRM);
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
  END;

  PROCEDURE analytics_forecast_demo IS
    v_prediction_7 NUMBER;
    v_prediction_30 NUMBER;
  BEGIN
    v_prediction_7 := pkg_analytics.predict_sales(7);
    v_prediction_30 := pkg_analytics.predict_sales(30);
    DBMS_OUTPUT.PUT_LINE('Прогноз продаж на 7 дней: $' || TO_CHAR(v_prediction_7, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('Прогноз продаж на 30 дней: $' || TO_CHAR(v_prediction_30, 'FM9999990.00'));
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('analytics_forecast_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE analytics_admin_general_stats_demo IS
    v_cursor pkg_analytics.ref_cursor;
    v_name   VARCHAR2(200);
    v_value  VARCHAR2(4000);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('analytics_admin_general_stats_demo:');
    pkg_analytics.get_general_stats(v_cursor);
    LOOP
      FETCH v_cursor INTO v_name, v_value;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_name || ': ' || v_value);
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('analytics_admin_general_stats_demo: ОШИБКА - ' || SQLERRM);
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
  END;

  PROCEDURE analytics_predict_demo IS
    v_prediction_7  NUMBER;
    v_prediction_30 NUMBER;
    v_avg_order     NUMBER;
    v_conversion    NUMBER;
  BEGIN
    v_prediction_7  := pkg_analytics.predict_sales(7);
    v_prediction_30 := pkg_analytics.predict_sales(30);
    v_avg_order     := pkg_analytics.get_average_order_value;
    v_conversion    := pkg_analytics.get_customer_conversion;

    DBMS_OUTPUT.PUT_LINE('7 дней: $' || TO_CHAR(v_prediction_7, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('30 дней: $' || TO_CHAR(v_prediction_30, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('Средний чек: $' || TO_CHAR(v_avg_order, 'FM9999990.00'));
    DBMS_OUTPUT.PUT_LINE('Конверсия клиентов: ' || TO_CHAR(v_conversion, 'FM9990.00') || '%');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('analytics_predict_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Клиенты и заказы
  PROCEDURE ensure_customer_demo(p_email IN VARCHAR2, p_name IN VARCHAR2, p_phone IN VARCHAR2) IS
    v_id NUMBER;
  BEGIN
    v_id := find_customer_id(p_email);
    IF v_id IS NULL THEN
      INSERT INTO customers(customer_id, email, full_name, phone)
      VALUES(NULL, p_email, p_name, p_phone);
      DBMS_OUTPUT.PUT_LINE('ensure_customer_demo: Создан клиент ' || p_email);
    ELSE
      DBMS_OUTPUT.PUT_LINE('ensure_customer_demo: Клиент уже существует (ID=' || v_id || ')');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ensure_customer_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE create_order_with_items_demo(
    p_email      IN VARCHAR2,
    p_skus       IN SYS.ODCIVARCHAR2LIST,
    p_quantities IN SYS.ODCINUMBERLIST,
    p_prices     IN SYS.ODCINUMBERLIST
  ) IS
    v_customer_id   NUMBER;
    v_order_id      NUMBER;
    v_product_id    NUMBER;
    v_inventory_id  NUMBER;
    v_current_qty   NUMBER;
    v_requested_qty NUMBER;
    v_total         NUMBER := 0;
  BEGIN
    IF p_skus.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Список SKU пуст');
      RETURN;
    END IF;
    IF p_skus.COUNT != p_quantities.COUNT OR p_skus.COUNT != p_prices.COUNT THEN
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Размеры массивов не совпадают');
      RETURN;
    END IF;

    ensure_customer_demo(p_email, p_email, NULL);
    v_customer_id := find_customer_id(p_email);
    IF v_customer_id IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Не удалось определить клиента ' || p_email);
      RETURN;
    END IF;

    FOR i IN 1 .. p_skus.COUNT LOOP
      v_product_id := find_product_id(p_skus(i));
      IF v_product_id IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Товар ' || p_skus(i) || ' не найден, пропуск');
        CONTINUE;
      END IF;
      
      v_requested_qty := NVL(p_quantities(i), 1);
      BEGIN
        SELECT i.inventory_id, i.quantity
          INTO v_inventory_id, v_current_qty
          FROM products p
          JOIN inventory i ON i.inventory_id = p.inventory_id
         WHERE p.product_id = v_product_id;
        
        IF v_current_qty < v_requested_qty THEN
          DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Недостаточно товара ' || p_skus(i) || 
                               ' (есть: ' || v_current_qty || ', требуется: ' || v_requested_qty || '), пропуск');
          CONTINUE;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Инвентарь для товара ' || p_skus(i) || ' не найден, пропуск');
          CONTINUE;
      END;
    END LOOP;

    INSERT INTO orders(order_id, customer_id, status)
    VALUES(NULL, v_customer_id, 'NEW')
    RETURNING order_id INTO v_order_id;

    FOR i IN 1 .. p_skus.COUNT LOOP
      v_product_id := find_product_id(p_skus(i));
      IF v_product_id IS NULL THEN
        CONTINUE;
      END IF;
      
      v_requested_qty := NVL(p_quantities(i), 1);
      BEGIN
        SELECT i.inventory_id, i.quantity
          INTO v_inventory_id, v_current_qty
          FROM products p
          JOIN inventory i ON i.inventory_id = p.inventory_id
         WHERE p.product_id = v_product_id;
        
        IF v_current_qty < v_requested_qty THEN
          CONTINUE;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          CONTINUE;
      END;
      
      INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price)
      VALUES(NULL, v_order_id, v_product_id, v_requested_qty, NVL(p_prices(i), 0));
      v_total := v_total + v_requested_qty * NVL(p_prices(i), 0);
    END LOOP;

    IF v_total > 0 THEN
      UPDATE orders SET status = 'PAID', total_amount = v_total WHERE order_id = v_order_id;
      INSERT INTO payments(payment_id, order_id, amount, method)
      VALUES(NULL, v_order_id, v_total, 'CARD');
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Создан заказ ' || v_order_id || ' для ' || p_email);
    ELSE
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: Не удалось создать заказ - нет доступных товаров');
      DELETE FROM orders WHERE order_id = v_order_id;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('create_order_with_items_demo: ОШИБКА - ' || SQLERRM);
      IF v_order_id IS NOT NULL THEN
        BEGIN
          DELETE FROM orders WHERE order_id = v_order_id;
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;
      END IF;
  END;

  PROCEDURE list_orders_by_email_demo(p_email IN VARCHAR2) IS
  BEGIN
    print_divider('list_orders_by_email_demo: ' || p_email);
    FOR r IN (
      SELECT o.order_id, o.order_date, o.status, o.total_amount
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
       WHERE LOWER(c.email) = LOWER(p_email)
       ORDER BY o.order_id DESC
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('Order ' || r.order_id || ' | ' || TO_CHAR(r.order_date, 'YYYY-MM-DD') ||
                           ' | ' || r.status || ' | $' || TO_CHAR(r.total_amount, 'FM9999990.00'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_orders_by_email_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_order_items_by_email_demo(p_email IN VARCHAR2) IS
  BEGIN
    print_divider('list_order_items_by_email_demo: ' || p_email);
    FOR r IN (
      SELECT o.order_id,
             p.sku,
             p.name,
             oi.quantity,
             oi.price,
             oi.quantity * oi.price AS total_line
        FROM order_items oi
        JOIN products p ON p.product_id = oi.product_id
        JOIN orders o ON o.order_id = oi.order_id
        JOIN customers c ON c.customer_id = o.customer_id
       WHERE LOWER(c.email) = LOWER(p_email)
       ORDER BY o.order_id DESC
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('Order ' || r.order_id || ' | ' || r.sku || ' | ' || r.name ||
                           ' | qty=' || r.quantity || ' | price=' || TO_CHAR(r.price, 'FM9999990.00') ||
                           ' | total=' || TO_CHAR(r.total_line, 'FM9999990.00'));
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_order_items_by_email_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Функции для получения ID
  FUNCTION get_category_id_by_name(p_name IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN find_category_id(p_name);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION get_company_id_by_name(p_name IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN find_company_id(p_name);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION get_product_id_by_sku(p_sku IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN find_product_id(p_sku);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- Процедуры для SELECT запросов из тестов
  PROCEDURE list_products_before_import_demo IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Состояние товаров перед импортом');
    FOR r IN (
      SELECT p.sku, p.name, c.name category_name, co.name company_name, p.price, NVL(i.quantity,0) quantity
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        JOIN companies co ON co.company_id = p.company_id
        LEFT JOIN inventory i ON i.inventory_id = p.inventory_id
       ORDER BY p.product_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.name || ' | ' || r.category_name || ' | ' ||
                           r.company_name || ' | $' || r.price || ' | ' || r.quantity || ' шт');
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_before_import_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_products_after_import_demo IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Состояние после импорта ');
    FOR r IN (
      SELECT p.sku, p.name, c.name category_name, co.name company_name, p.price, NVL(i.quantity,0) quantity
        FROM products p
        JOIN categories c ON c.category_id = p.category_id
        JOIN companies co ON co.company_id = p.company_id
        LEFT JOIN inventory i ON i.inventory_id = p.inventory_id
       ORDER BY p.product_id
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.name || ' | ' || r.category_name || ' | ' ||
                           r.company_name || ' | $' || r.price || ' | ' || r.quantity || ' шт');
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_after_import_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_products_by_category_view_demo(p_category_name IN VARCHAR2) IS
  BEGIN
    FOR r IN (
      SELECT product_id, sku, product_name, category_name, company_name, price, NVL(quantity,0) quantity
        FROM v_product_overview
       WHERE category_name = p_category_name
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_id || ' | ' || r.sku || ' | ' || r.product_name || ' | ' ||
                           r.category_name || ' | ' || r.company_name || ' | $' || r.price ||
                           ' | ' || r.quantity || ' шт');
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_products_by_category_view_demo: ОШИБКА - ' || SQLERRM);
  END;

  

  PROCEDURE list_orders_by_email_sql_demo(p_email IN VARCHAR2) IS
  BEGIN
    FOR r IN (
      SELECT o.order_id, o.status, o.total_amount, c.full_name, c.email
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
       WHERE c.email = p_email
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('Order ID: ' || r.order_id || ' | Status: ' || r.status || 
                           ' | Total: $' || r.total_amount || ' | Customer: ' || r.full_name);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_orders_by_email_sql_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE list_order_items_by_email_sql_demo(p_email IN VARCHAR2) IS
  BEGIN
    FOR r IN (
      SELECT oi.order_item_id, p.name, oi.quantity, oi.price, (oi.quantity * oi.price) AS line_total
        FROM order_items oi
        JOIN products p ON p.product_id = oi.product_id
        JOIN orders o ON o.order_id = oi.order_id
        JOIN customers c ON c.customer_id = o.customer_id
       WHERE c.email = p_email
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('Item ID: ' || r.order_item_id || ' | Product: ' || r.name || 
                           ' | Qty: ' || r.quantity || ' | Price: $' || r.price || 
                           ' | Total: $' || r.line_total);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('list_order_items_by_email_sql_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE create_order_manual_demo(
    p_email IN VARCHAR2,
    p_sku1 IN VARCHAR2,
    p_qty1 IN NUMBER,
    p_price1 IN NUMBER,
    p_sku2 IN VARCHAR2,
    p_qty2 IN NUMBER,
    p_price2 IN NUMBER
  ) IS
    v_customer_id NUMBER;
    v_order_id NUMBER;
    v_product_id1 NUMBER;
    v_product_id2 NUMBER;
  BEGIN
    BEGIN
      v_customer_id := find_customer_id(p_email);
      IF v_customer_id IS NULL THEN
        INSERT INTO customers(email, full_name, phone)
        VALUES(p_email, 'Test User', '+375-25-019-15-29');
        v_customer_id := find_customer_id(p_email);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -1 THEN
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Клиент с таким email уже существует');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Проблема с генерацией ID клиента');
        ELSE
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Ошибка работы с клиентом - ' || SQLERRM);
      END CASE;
      RETURN;
    END;

    BEGIN
      INSERT INTO orders(order_id, customer_id, status) VALUES(NULL, v_customer_id, 'NEW')
      RETURNING order_id INTO v_order_id;

      v_product_id1 := find_product_id(p_sku1);
      IF v_product_id1 IS NOT NULL THEN
        INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price)
        VALUES(NULL, v_order_id, v_product_id1, p_qty1, p_price1);
      END IF;

      v_product_id2 := find_product_id(p_sku2);
      IF v_product_id2 IS NOT NULL THEN
        INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price)
        VALUES(NULL, v_order_id, v_product_id2, p_qty2, p_price2);
      END IF;

      INSERT INTO payments(payment_id, order_id, amount, method) 
      VALUES(NULL, v_order_id, (p_qty1 * p_price1 + p_qty2 * p_price2), 'CARD');
      UPDATE orders SET status = 'PAID' WHERE order_id = v_order_id;

      DBMS_OUTPUT.PUT_LINE('Создан тестовый заказ ID= ' || v_order_id);
    EXCEPTION WHEN OTHERS THEN
      CASE 
        WHEN SQLCODE = -2290 THEN
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Некорректные данные заказа (отрицательная цена или количество)');
        WHEN SQLCODE = -2291 THEN
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Указан несуществующий товар или клиент');
        WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Проблема с генерацией ID заказа');
        ELSE
          DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: Ошибка создания заказа - ' || SQLERRM);
      END CASE;
      IF v_order_id IS NOT NULL THEN
        BEGIN
          DELETE FROM orders WHERE order_id = v_order_id;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
      END IF;
    END;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('create_order_manual_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE get_performance_stats_demo IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM v_product_overview WHERE category_name = 'Skincare';
    DBMS_OUTPUT.PUT_LINE('Товаров в категории Skincare: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM v_product_overview WHERE price BETWEEN 10 AND 50;
    DBMS_OUTPUT.PUT_LINE('Товаров от $10 до $50: ' || v_count);

    FOR r IN (
      SELECT * FROM (
        SELECT product_name, total_sold,
               ROW_NUMBER() OVER (ORDER BY total_sold DESC) AS rank_num
          FROM v_popular_products
      ) WHERE rank_num <= 10
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('#' || r.rank_num || ' | ' || r.product_name || ' | Продано: ' || r.total_sold);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_performance_stats_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE get_view_data_demo IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' v_product_overview (топ 10) ');
    FOR r IN (SELECT * FROM v_product_overview WHERE ROWNUM <= 10) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.product_name || ' | $' || r.price);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' v_popular_products (топ 5) ');
    FOR r IN (SELECT * FROM v_popular_products WHERE ROWNUM <= 5) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_name || ' | Продано: ' || r.total_sold);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' v_revenue_by_month ');
    FOR r IN (SELECT * FROM v_revenue_by_month ORDER BY ym) LOOP
      DBMS_OUTPUT.PUT_LINE(r.ym || ' | Выручка: $' || r.revenue);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_view_data_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE get_general_metrics_demo IS
    v_count NUMBER;
    v_sum NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM categories;
    DBMS_OUTPUT.PUT_LINE('Количество категорий: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM companies;
    DBMS_OUTPUT.PUT_LINE('Количество компаний: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM products;
    DBMS_OUTPUT.PUT_LINE('Количество товаров: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM customers;
    DBMS_OUTPUT.PUT_LINE('Количество клиентов: ' || v_count);

    SELECT COUNT(*) INTO v_count FROM orders;
    DBMS_OUTPUT.PUT_LINE('Количество заказов: ' || v_count);

    SELECT NVL(SUM(total_amount),0) INTO v_sum FROM orders;
    DBMS_OUTPUT.PUT_LINE('Общая выручка ($): ' || v_sum);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_general_metrics_demo: ОШИБКА - ' || SQLERRM);
  END;

  PROCEDURE get_orders_statistics_demo IS
    v_count NUMBER;
    v_total_amount NUMBER;
  BEGIN
    SELECT COUNT(*), NVL(SUM(total_amount), 0) INTO v_count, v_total_amount FROM orders;
    DBMS_OUTPUT.PUT_LINE('Статистика заказов:');
    DBMS_OUTPUT.PUT_LINE('  Всего заказов: ' || v_count);
    DBMS_OUTPUT.PUT_LINE('  Общая сумма: $' || TO_CHAR(v_total_amount, 'FM9999990.00'));
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('get_orders_statistics_demo: ОШИБКА - ' || SQLERRM);
  END;

  -- Процедуры для пользователя
  PROCEDURE list_user_products_by_category_demo(p_category_name IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Товары категории ' || p_category_name );
    FOR r IN (
      SELECT sku, product_name, company_name, price
        FROM v_product_overview
       WHERE LOWER(category_name) = LOWER(p_category_name)
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.product_name || ' | $' || r.price || ' | ' || r.company_name);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра товаров. Обратитесь к администратору.');
      ELSIF SQLCODE = -1403 THEN
        -- NO_DATA_FOUND - это нормально, просто нет товаров
        NULL;
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_user_products_by_category_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE list_user_products_by_company_demo(p_company_name IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Товары бренда ' || p_company_name );
    FOR r IN (
      SELECT product_id, sku, product_name, price
        FROM v_product_overview
       WHERE LOWER(company_name) = LOWER(p_company_name)
       ORDER BY product_name
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_id || ' | ' || r.sku || ' | ' || r.product_name || ' | $' || r.price);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра товаров. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_user_products_by_company_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE list_user_products_overview_demo(p_limit IN NUMBER DEFAULT 10) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('SKU | Название | Категория | Компания | Цена');
    FOR r IN (
      SELECT sku, product_name, category_name, company_name, price
        FROM v_product_overview
       WHERE ROWNUM <= p_limit
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.product_name || ' | ' ||
                           r.category_name || ' | ' || r.company_name || ' | $' || r.price);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра каталога. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_user_products_overview_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE search_user_products_demo(p_keyword IN VARCHAR2) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Найденные товары по ключу "' || p_keyword );
    FOR r IN (
      SELECT sku, product_name, price
        FROM v_product_overview
       WHERE LOWER(product_name) LIKE '%' || LOWER(p_keyword) || '%'
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.product_name || ' | $' || r.price);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для поиска товаров. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('search_user_products_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE compare_prices_by_category_demo(p_category_name IN VARCHAR2) IS
  BEGIN
    FOR r IN (
      SELECT product_name,
             price,
             DENSE_RANK() OVER (ORDER BY price ASC) AS price_rank
        FROM v_product_overview
       WHERE category_name = p_category_name
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE('#' || r.price_rank || ' | ' || r.product_name || ' | $' || r.price);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для сравнения цен. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('compare_prices_by_category_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE list_user_promotions_demo(p_max_price IN NUMBER) IS
  BEGIN
    FOR r IN (
      SELECT sku, product_name, company_name, price
        FROM v_product_overview
       WHERE price < p_max_price
       ORDER BY price
    ) LOOP
      DBMS_OUTPUT.PUT_LINE(r.sku || ' | ' || r.product_name || ' | ' || r.company_name || ' | $' || r.price);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра акций. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_user_promotions_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE get_user_statistics_demo IS
    v_count NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Публичная статистика ');
    
    SELECT COUNT(DISTINCT category_name) INTO v_count FROM v_product_overview;
    DBMS_OUTPUT.PUT_LINE('Всего уникальных категорий: ' || v_count);
    
    SELECT COUNT(DISTINCT company_name) INTO v_count FROM v_product_overview;
    DBMS_OUTPUT.PUT_LINE('Всего уникальных брендов: ' || v_count);
    
    SELECT COUNT(*) INTO v_count FROM v_product_overview;
    DBMS_OUTPUT.PUT_LINE('Всего доступных товаров: ' || v_count);
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра статистики. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('get_user_statistics_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  -- Процедуры для обработки циклов FETCH
  PROCEDURE list_all_products_sorted_demo(p_sort_by IN VARCHAR2 DEFAULT 'price', p_sort_dir IN VARCHAR2 DEFAULT 'ASC') IS
    v_cursor pkg_shop.ref_cursor;
    v_product_id NUMBER;
    v_sku VARCHAR2(100);
    v_name VARCHAR2(200);
    v_category VARCHAR2(100);
    v_company VARCHAR2(150);
    v_price NUMBER;
    v_quantity NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Все товары, сортировка по ' || p_sort_by || ' ' || p_sort_dir);
    pkg_shop.list_products(NULL, NULL, NULL, NULL, p_sort_by, p_sort_dir, v_cursor);
    LOOP
      FETCH v_cursor INTO v_product_id, v_sku, v_name, v_category, v_company, v_price, v_quantity;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_product_id || ' | ' || v_sku || ' | ' || v_name || ' | ' ||
                           v_category || ' | ' || v_company || ' | $' || v_price || ' | ' || v_quantity || ' шт');
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра товаров. Обратитесь к администратору.');
      ELSIF SQLCODE = -1403 THEN
        -- NO_DATA_FOUND - это нормально, просто нет товаров
        NULL;
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_all_products_sorted_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE list_products_price_range_demo(p_min_price IN NUMBER, p_max_price IN NUMBER, p_sort_dir IN VARCHAR2 DEFAULT 'DESC') IS
    v_cursor pkg_shop.ref_cursor;
    v_product_id NUMBER;
    v_sku VARCHAR2(100);
    v_name VARCHAR2(200);
    v_category VARCHAR2(100);
    v_company VARCHAR2(150);
    v_price NUMBER;
    v_quantity NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(' Товары $' || p_min_price || '-$' || p_max_price );
    pkg_shop.list_products(NULL, NULL, p_min_price, p_max_price, 'price', p_sort_dir, v_cursor);
    LOOP
      FETCH v_cursor INTO v_product_id, v_sku, v_name, v_category, v_company, v_price, v_quantity;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_product_id || ' | ' || v_sku || ' | ' || v_name || ' | ' ||
                           v_category || ' | ' || v_company || ' | $' || v_price ||
                           ' | ' || v_quantity || ' шт');
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для фильтрации товаров. Обратитесь к администратору.');
      ELSIF SQLCODE = -1403 THEN
        -- NO_DATA_FOUND - это нормально, просто нет товаров
        NULL;
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_products_price_range_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE list_popular_products_demo(p_top IN NUMBER DEFAULT 5) IS
    v_cursor pkg_shop.ref_cursor;
    v_product_id NUMBER;
    v_name VARCHAR2(200);
    v_total_sold NUMBER;
    v_rank NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('РЕЙТИНГ | НАЗВАНИЕ | ПРОДАНО');
    pkg_shop.popular_products(p_top, v_cursor);
    LOOP
      FETCH v_cursor INTO v_product_id, v_name, v_total_sold, v_rank;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('#' || v_rank || ' | ID ' || v_product_id || ' | ' || v_name || ' | Продано: ' || v_total_sold);
    END LOOP;
    CLOSE v_cursor;
  EXCEPTION
    WHEN OTHERS THEN
      IF v_cursor%ISOPEN THEN
        CLOSE v_cursor;
      END IF;
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра популярных товаров. Обратитесь к администратору.');
      ELSIF SQLCODE = -1403 THEN
        -- NO_DATA_FOUND - это нормально, просто нет данных
        NULL;
      ELSE
        DBMS_OUTPUT.PUT_LINE('list_popular_products_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  PROCEDURE get_total_products_demo IS
    v_total_products NUMBER;
  BEGIN
    v_total_products := pkg_shop.total_products();
    DBMS_OUTPUT.PUT_LINE('Всего товаров: ' || v_total_products);
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Ошибка доступа: У вас нет прав для просмотра статистики. Обратитесь к администратору.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('get_total_products_demo: ОШИБКА - ' || SQLERRM);
        RAISE;
      END IF;
  END;

  -- Очистка тестовых данных
  PROCEDURE cleanup_test_data_demo IS
    TYPE t_varchar_list IS TABLE OF VARCHAR2(100);
    v_skus t_varchar_list := t_varchar_list(
      'TEST-SKU-001','UPDATED-SKU-001','INV-SKU-001','MEDIA-SKU-001',
      'JSON-SKU-001','JSON-SKU-002','FILTER-SKU-1','FILTER-SKU-2',
      'FILTER-SKU-3','FILTER-SKU-4','ORDER-SKU-1','ORDER-SKU-2',
      'SKU-TEST-1','SKU-TEST-2'
    );
  BEGIN
    DBMS_OUTPUT.PUT_LINE('cleanup_test_data_demo: Удаление тестовых записей');
    FOR i IN 1 .. v_skus.COUNT LOOP
      BEGIN
        delete_product_by_sku_demo(v_skus(i));
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END LOOP;

    BEGIN delete_category_by_name_demo('TestCat'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN delete_category_by_name_demo('UpdatedCat'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN delete_company_by_name_demo('TestComp'); EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN delete_company_by_name_demo('UpdatedComp'); EXCEPTION WHEN OTHERS THEN NULL; END;

    DELETE FROM customers WHERE email IN ('test@gmail.com','test.customer@gmail.com');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('cleanup_test_data_demo: ОШИБКА - ' || SQLERRM);
  END;


END pkg_admin_runner;
/

-- Предоставление прав на пакет и создание синонима (вызывать от имени администратора)
BEGIN
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_admin_runner TO COSM_ROLE_USER';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_admin_runner TO COSM_USER';
  DBMS_OUTPUT.PUT_LINE('Права на пакет pkg_admin_runner предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав: ' || SQLERRM);
END;
/

-- Создание публичного синонима для пользователя
BEGIN
  EXECUTE IMMEDIATE 'CREATE OR REPLACE PUBLIC SYNONYM pkg_admin_runner FOR COSM_ADMIN.pkg_admin_runner';
  DBMS_OUTPUT.PUT_LINE('Публичный синоним pkg_admin_runner создан');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка создания синонима: ' || SQLERRM);
END;
/