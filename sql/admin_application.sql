-- Очистка перед тестами
BEGIN
  pkg_admin_runner.cleanup_test_data_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена или нет прав доступа.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при очистке тестовых данных: ' || SQLERRM);
    END CASE;
END;
/

-- Базовая инициализация: создание необходимых категорий и компаний для демонстрации
-- Эти данные используются в последующих тестах для создания товаров
BEGIN
  pkg_admin_runner.setup_basic_data_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Некоторые данные уже существуют.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена или нет прав доступа.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при базовой инициализации: ' || SQLERRM);
    END CASE;
END;
/

-- Управление категориями 
DECLARE
  v_category_id NUMBER;
BEGIN
  pkg_admin_runner.add_category_demo('DemoCat','Категория для демонстрации');
  pkg_admin_runner.list_categories_demo;

  v_category_id := pkg_admin_runner.get_category_id_by_name('DemoCat');
  IF v_category_id IS NOT NULL THEN
    pkg_admin_runner.update_category_demo(v_category_id, 'DemoCat Updated', 'Обновлённое описание');
    pkg_admin_runner.list_categories_demo;
    pkg_admin_runner.get_category_id_demo('DemoCat Updated');
    pkg_admin_runner.delete_category_by_name_demo('DemoCat Updated');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Категория DemoCat не найдена');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Категория с таким названием уже существует.');
      WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с генерацией ID категории.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или таблица не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('ℹКатегория не найдена.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка в управлении категориями: ' || SQLERRM);
    END CASE;
END;
/

-- Управление компаниями 
DECLARE
  v_company_id NUMBER;
BEGIN
  pkg_admin_runner.add_company_demo('DemoComp','USA','http://demo.com');
  pkg_admin_runner.list_companies_demo;

  v_company_id := pkg_admin_runner.get_company_id_by_name('DemoComp');
  IF v_company_id IS NOT NULL THEN
    pkg_admin_runner.update_company_demo(v_company_id,'DemoComp Updated','France','http://demo.com/updated');
    pkg_admin_runner.list_companies_demo;
    pkg_admin_runner.delete_company_by_name_demo('DemoComp Updated');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Компания DemoComp не найдена');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Компания с таким названием уже существует.');
      WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с генерацией ID компании.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или таблица не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('ℹКомпания не найдена.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка в управлении компаниями: ' || SQLERRM);
    END CASE;
END;
/

-- Управление товарами
DECLARE
  v_product_id NUMBER;
BEGIN
pkg_admin_runner.add_product_demo('L''Oreal','Skincare1','DEMO-SKU-1','Demo Product','Описание товара',49.99);
  pkg_admin_runner.list_products_demo;
  pkg_admin_runner.list_products_detailed_demo('После добавления DEMO-SKU-1');

  v_product_id := pkg_admin_runner.get_product_id_by_sku('DEMO-SKU-1');
  IF v_product_id IS NOT NULL THEN
    --pkg_admin_runner.update_product_by_sku_demo('DEMO-SKU-1','L''Oreal','Skincare','DEMO-SKU-1A','Demo Product Updated','Новый текст',59.99);
    pkg_admin_runner.list_products_detailed_demo('После обновления DEMO-SKU-1A');
    --pkg_admin_runner.delete_product_by_sku_demo('SKU-AUR-CL-001');
        --pkg_admin_runner.list_products_detailed_demo('После обновления DEMO-SKU-1A');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Товар DEMO-SKU-1 не найден');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с таким артикулом (SKU) уже существует.');
      WHEN SQLCODE = -2291 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Указана несуществующая категория или компания.');
      WHEN SQLCODE = -2290 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректные данные (отрицательная цена или количество).');
      WHEN SQLCODE = -12899 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Слишком длинные данные (артикул, название или описание превышают лимит).');
      WHEN SQLCODE = -1722 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректный формат числа (цена).');
      WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с генерацией ID товара или инвентаря.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или таблица не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товар не найден.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка в управлении товарами: ' || SQLERRM);
    END CASE;
END;
/

-- Демонстрация технологии мультимедийных типов данных 
-- Загрузка реальных изображений товаров из файловой системы в BLOB
DECLARE
  v_product_id NUMBER;
BEGIN
  pkg_admin_runner.add_product_demo('L''Oreal','Skincare','DEMO-MEDIA-1','Hydrating Cream','Увлажняющий крем с изображением',29.99);
  pkg_admin_runner.add_product_demo('Estee Lauder','Makeup','DEMO-MEDIA-2','Matte Lipstick','Матовую помаду с изображением',24.99);
  pkg_admin_runner.add_product_demo('L''Oreal','Skincare','DEMO-MEDIA-3','Blush Compact','Компактная пудра с изображением',19.99);
  
  -- Установка инвентаря (если товары уже есть, значения обновятся)
  pkg_admin_runner.set_inventory_demo('DEMO-MEDIA-1', 50, 10);
  pkg_admin_runner.set_inventory_demo('DEMO-MEDIA-2', 30, 5);
  pkg_admin_runner.set_inventory_demo('DEMO-MEDIA-3', 40, 8);
  
  -- Загрузка реальных изображений в product_media (BLOB)
  v_product_id := pkg_admin_runner.get_product_id_by_sku('DEMO-MEDIA-1');
  IF v_product_id IS NOT NULL THEN
    BEGIN
      DELETE FROM product_media WHERE product_id = v_product_id; -- обновляем медиа дубликаты
      pkg_media.test_blob_media(v_product_id, 'cream.webp');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Предупреждение: Не удалось загрузить cream.webp для DEMO-MEDIA-1: ' || SQLERRM);
    END;
  END IF;
  
  v_product_id := pkg_admin_runner.get_product_id_by_sku('DEMO-MEDIA-2');
  IF v_product_id IS NOT NULL THEN
    BEGIN
      DELETE FROM product_media WHERE product_id = v_product_id;
      pkg_media.test_blob_media(v_product_id, 'lipstick.jpeg');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Предупреждение: Не удалось загрузить lipstick.jpeg для DEMO-MEDIA-2: ' || SQLERRM);
    END;
  END IF;
  
  v_product_id := pkg_admin_runner.get_product_id_by_sku('DEMO-MEDIA-3');
  IF v_product_id IS NOT NULL THEN
    BEGIN
      DELETE FROM product_media WHERE product_id = v_product_id;
      pkg_media.test_blob_media(v_product_id, 'blush.jpg');
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Предупреждение: Не удалось загрузить blush.jpg для DEMO-MEDIA-3: ' || SQLERRM);
    END;
  END IF;
  
  -- Вывод списка всех загруженных медиафайлов
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('СПИСОК ВСЕХ МЕДИАФАЙЛОВ В БД');
  pkg_admin_runner.list_media_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('ТОВАРЫ С ИЗОБРАЖЕНИЯМИ (детально)');
  pkg_admin_runner.list_products_with_media_demo('DEMO-MEDIA-%');

EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с таким артикулом уже существует.');
      WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с файлом. Файл не найден или нет прав доступа к директории COSM_IMAGES_DIR.');
      WHEN SQLCODE = -2290 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректные данные инвентаря (отрицательное количество).');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или пакет не найдены.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товар не найден.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при работе с мультимедиа: ' || SQLERRM);
    END CASE;
END;
/

-- JSON экспорт / импорт данных
-- Экспорт: данные из таблицы orders (100000 строк) экспортируются в файл orders_export.json
-- Импорт: данные из файла orders_import.json импортируются в таблицу orders
BEGIN
  DBMS_OUTPUT.PUT_LINE('ЭКСПОРТ ЗАКАЗОВ В JSON');
  pkg_admin_runner.export_orders_demo('orders_export.json', 1000);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -40441 OR SQLCODE = -40442 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректный формат JSON файла.');
      WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с файлом. Файл не найден или нет прав доступа к директории COSM_JSON_DIR.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или пакет не найдены.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при работе с JSON: ' || SQLERRM);
    END CASE;
END;
/

-- Проверка состояния заказов 
BEGIN
  DBMS_OUTPUT.PUT_LINE('Состояние заказов:');
  pkg_admin_runner.get_orders_statistics_demo;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка при проверке заказов: ' || SQLERRM);
END;
/

-- Импорт заказов из JSON файла через pkg_admin_runner
BEGIN
  pkg_admin_runner.import_orders_demo('orders_export.json');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -40441 OR SQLCODE = -40442 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректный формат JSON файла.');
      WHEN SQLCODE = -22288 OR SQLCODE = -29283 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Файл orders_import.json не найден или нет прав доступа.');
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Нарушение уникальности при импорте (заказ с таким ID уже существует).');
      WHEN SQLCODE = -2291 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: В JSON указан несуществующий клиент.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Пакет pkg_json не найден.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при импорте из orders_import.json: ' || SQLERRM);
    END CASE;
END;
/

-- Фильтрация и сортировка продукции по категориям 
-- Демонстрация фильтрации по категориям, компаниям, диапазону цен и сортировки
BEGIN
  DBMS_OUTPUT.PUT_LINE('ФИЛЬТРАЦИЯ И СОРТИРОВКА ПРОДУКЦИИ');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Фильтрация по категории "Skincare":');
  pkg_admin_runner.filter_by_category_demo('Skincare');
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Фильтрация по компании "L''Oreal":');
  pkg_admin_runner.filter_by_company_demo('L''Oreal');
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Фильтрация по диапазону цен от $10 до $60:');
  pkg_admin_runner.filter_by_price_range_demo(10, 60);
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Сортировка товаров по цене (по убыванию):');
  pkg_admin_runner.sort_products_demo('price','DESC');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товары не найдены по заданным критериям.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при фильтрации и сортировке: ' || SQLERRM);
    END CASE;
END;
/

-- Фильтрация и сортировка 
BEGIN
  pkg_admin_runner.list_all_products_sorted_demo('price', 'ASC');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товары не найдены.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении списка товаров: ' || SQLERRM);
    END CASE;
END;
/

-- Демонстрация ручной фильтрации по категории "Skincare"
BEGIN
  pkg_admin_runner.list_products_by_category_view_demo('Skincare');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('В категории Skincare нет товаров.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при фильтрации по категории: ' || SQLERRM);
    END CASE;
END;
/

BEGIN
  pkg_admin_runner.list_products_price_range_demo(10, 50, 'DESC');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет товаров в указанном диапазоне цен.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при фильтрации товаров по цене: ' || SQLERRM);
    END CASE;
END;
/
-- Аналитика продукции:
-- - Популярные товары
-- - Общее количество товаров
-- - Сумма выручки
BEGIN
  DBMS_OUTPUT.PUT_LINE('АНАЛИТИКА ПРОДУКЦИИ');
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Базовая аналитика (общее количество товаров, выручка):');
  pkg_admin_runner.analytics_basic_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Расширенная аналитика:');
  pkg_admin_runner.analytics_extended_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Прогноз продаж:');
  pkg_admin_runner.analytics_forecast_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Общая статистика администратора:');
  pkg_admin_runner.analytics_admin_general_stats_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Прогнозирование и конверсия:');
  pkg_admin_runner.analytics_predict_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или пакет не найдены.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных для аналитики.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении аналитики: ' || SQLERRM);
    END CASE;
END;
/

-- Аналитика через пакет pkg_shop (популярные товары, общее количество, выручка)
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('АНАЛИТИКА ЧЕРЕЗ PKG_SHOP');
  DBMS_OUTPUT.PUT_LINE('Общее количество товаров:');
  pkg_admin_runner.get_total_products_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Топ-5 популярных товаров:');
  pkg_admin_runner.list_popular_products_demo(5);
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных для аналитики.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении аналитики через pkg_shop: ' || SQLERRM);
    END CASE;
END;
/

-- Дополнительная статистика администратора
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('ДОПОЛНИТЕЛЬНАЯ СТАТИСТИКА');
  pkg_admin_runner.analytics_admin_general_stats_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных для аналитики клиентов.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении аналитики клиентов: ' || SQLERRM);
    END CASE;
END;
/

-- Работа с заказами 
BEGIN
  pkg_admin_runner.ensure_customer_demo('demo.customer@gmail.com','Demo Customer','+375-29-553-34-23');
  pkg_admin_runner.add_product_demo('L''Oreal','Skincare','DEMO-ORDER-1','Order Product 1','',25.99);
  pkg_admin_runner.add_product_demo('Estee Lauder','Makeup','DEMO-ORDER-2','Order Product 2','',45.99);

  pkg_admin_runner.set_inventory_demo('DEMO-ORDER-1', 10, 5);
  pkg_admin_runner.set_inventory_demo('DEMO-ORDER-2', 10, 5);
  pkg_admin_runner.create_order_with_items_demo(
    'demo.customer!@gmail.com',
    SYS.ODCIVARCHAR2LIST('DEMO-ORDER-1','DEMO-ORDER-2'),
    SYS.ODCINUMBERLIST(2,1),
    SYS.ODCINUMBERLIST(25.99,45.99)
  );
  pkg_admin_runner.list_orders_by_email_demo('demo.customer@gmail.com');
  pkg_admin_runner.list_order_items_by_email_demo('demo.customer@gmail.com');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Клиент или товар с такими данными уже существует.');
      WHEN SQLCODE = -2290 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректные данные заказа (отрицательная цена или количество).');
      WHEN SQLCODE = -2291 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Указан несуществующий товар или клиент.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товар или клиент не найдены.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при работе с заказами: ' || SQLERRM);
    END CASE;
END;
/

-- Прямой SQL контроль заказов 
BEGIN
  pkg_admin_runner.create_order_manual_demo(
    'test@gmail.com',
    'SKU-AUR-CL-001',
    2,
    12.50,
    'SKU-VEL-LP-010',
    1,
    15.00
  );
  
  pkg_admin_runner.list_orders_by_email_sql_demo('test@gmail.com');
  pkg_admin_runner.list_order_items_by_email_sql_demo('test@gmail.com');
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -1 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Клиент с таким email уже существует.');
      WHEN SQLCODE = -2290 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Некорректные данные заказа (отрицательная цена или количество).');
      WHEN SQLCODE = -2291 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Указан несуществующий товар (SKU не найден).');
      WHEN SQLCODE = -8002 OR SQLCODE = -8004 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Проблема с генерацией ID заказа.');
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Товар с указанным SKU не найден.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при создании заказа вручную: ' || SQLERRM);
    END CASE;
END;
/

-- Тестирование производительности базы данных 
-- Генерация не менее 100 000 строк данных для тестирования производительности
@@perf_generate_100k.sql

SET TIMING ON;

-- Тестирование производительности запросов
-- perf_generate_100k.sql создает:
-- 5000 клиентов\
-- 100000 заказов
-- Индексы для оптимизации
BEGIN
  DBMS_OUTPUT.PUT_LINE('ТЕСТИРОВАНИЕ ПРОИЗВОДИТЕЛЬНОСТИ');
  pkg_admin_runner.get_performance_stats_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных для статистики производительности.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении статистики производительности: ' || SQLERRM);
    END CASE;
END;
/

SET TIMING OFF;

-- Анализ планов запросов и производительности
BEGIN
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('АНАЛИЗ ПЛАНОВ ЗАПРОСОВ И ПРОИЗВОДИТЕЛЬНОСТИ');
  pkg_admin_runner.get_view_data_demo;
  
  DBMS_OUTPUT.PUT_LINE('');
  DBMS_OUTPUT.PUT_LINE('Общая производительность базы данных:');
  pkg_admin_runner.get_general_metrics_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура или представление не найдены.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Нет данных в представлениях.');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при получении данных представлений: ' || SQLERRM);
    END CASE;
END;
/

-- Завершение и очистка 
BEGIN
  pkg_admin_runner.cleanup_test_data_demo;
EXCEPTION
  WHEN OTHERS THEN
    CASE 
      WHEN SQLCODE = -942 OR SQLCODE = -1031 OR SQLCODE = -6502 OR SQLCODE = -6550 OR SQLCODE = -201 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка доступа: Процедура не найдена.');
      WHEN SQLCODE = -1403 THEN
        DBMS_OUTPUT.PUT_LINE('Тестовые данные не найдены (возможно, уже очищены).');
      ELSE
        DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE || ' - Ошибка при финальной очистке тестовых данных: ' || SQLERRM);
    END CASE;
END;
/


