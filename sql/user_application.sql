-- Полный список товаров (без фильтрации) 
BEGIN
  DBMS_OUTPUT.PUT_LINE('ID | SKU | Название | Категория | Компания | Цена');
  pkg_admin_runner.list_all_products_sorted_demo('PRICE', 'ASC');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра товаров. Обратитесь к администратору.');
      WHEN SQLCODE = -1403 THEN 
        DBMS_OUTPUT.PUT_LINE('В каталоге пока нет товаров');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке каталога');
    END CASE;
END;
/

-- Фильтрация по категории (пример: Skincare) 
BEGIN
  pkg_admin_runner.list_user_products_by_category_demo('Skincare');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра товаров');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('В категории Skincare нет товаров');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при фильтрации по категории');
    END CASE;
END;
/

-- Фильтрация по бренду (пример: L''Oreal)
BEGIN
  pkg_admin_runner.list_user_products_by_company_demo('L''Oreal');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра товаров');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('️ У бренда L''Oreal нет товаров в каталоге');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при фильтрации по бренду');
    END CASE;
END;
/

-- Фильтрация по цене (10–50) и сортировка по убыванию
BEGIN
  pkg_admin_runner.list_products_price_range_demo(10, 50, 'DESC');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для фильтрации товаров');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE(' Нет товаров в диапазоне $10–$50');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при фильтрации по цене');
    END CASE;
END;
/

-- Популярные товары (топ-5)
BEGIN
  pkg_admin_runner.list_popular_products_demo(5);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра популярных товаров');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE(' Пока нет данных о популярных товарах');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке популярных товаров');
    END CASE;
END;
/

-- Базовая статистика для пользователя 
BEGIN
  pkg_admin_runner.get_total_products_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра статистики');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке статистики');
    END CASE;
END;
/

-- Обзор каталога 
BEGIN
  pkg_admin_runner.list_user_products_overview_demo(10);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра каталога');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE(' Каталог товаров пуст');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке каталога');
    END CASE;
END;
/

-- Выборка по поисковому ключу (пример: serum)
DECLARE
  v_keyword VARCHAR2(50) := 'Sea';
BEGIN
  pkg_admin_runner.search_user_products_demo(v_keyword);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для поиска товаров');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('По запросу "' || v_keyword || '" ничего не найдено');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при поиске товаров');
    END CASE;
END;
/

-- Сравнение цен в пределах категории (пример: Makeup) 
BEGIN
  pkg_admin_runner.compare_prices_by_category_demo('Makeup');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для сравнения цен');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE(' В категории Makeup нет товаров для сравнения');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при сравнении цен');
    END CASE;
END;
/

-- Актуальные акции ( товары дешевле $30) 
BEGIN
  pkg_admin_runner.list_user_promotions_demo(30);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра акций');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Пока нет товаров по акции (дешевле $30)');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке акционных товаров');
    END CASE;
END;
/

-- Итоговые пользовательские метрики 
BEGIN
  pkg_admin_runner.get_user_statistics_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: У вас нет прав для просмотра статистики');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка при загрузке статистики');
    END CASE;
END;
/