-- Пакет для работы с мультимедиа
CREATE OR REPLACE PACKAGE pkg_media AS
  PROCEDURE upload_product_image(p_product_id NUMBER, p_filename VARCHAR2, p_image_path VARCHAR2);
  
  PROCEDURE get_product_image(p_product_id NUMBER, p_media_id NUMBER, p_image OUT BLOB);
  
  FUNCTION get_product_images(p_product_id NUMBER) RETURN SYS_REFCURSOR;
  
  PROCEDURE delete_product_image(p_media_id NUMBER);
  
  PROCEDURE update_product_image(p_media_id NUMBER, p_filename VARCHAR2, p_image_path VARCHAR2);
  
  PROCEDURE test_blob_media(p_product_id NUMBER, p_image_path VARCHAR2);
  
  PROCEDURE list_directory_files;
END pkg_media;
/

CREATE OR REPLACE PACKAGE BODY pkg_media AS

  PROCEDURE upload_product_image(p_product_id NUMBER, p_filename VARCHAR2, p_image_path VARCHAR2) IS
    v_file UTL_FILE.FILE_TYPE; -- Дескриптор файла
    v_blob BLOB;
    v_amount INTEGER := 32767;
    v_buffer RAW(32767);
    v_bytes_read INTEGER;
    v_product_exists NUMBER;
    v_file_size INTEGER := 0;
  BEGIN

    BEGIN
      SELECT 1 INTO v_product_exists FROM products WHERE product_id = p_product_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Товар с ID ' || p_product_id || ' не найден');
    END;
    
    IF p_filename IS NULL OR LENGTH(TRIM(p_filename)) = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Имя файла не может быть пустым');
    END IF;
    -- открывает файл на сервере Oracle
    v_file := UTL_FILE.FOPEN('COSM_IMAGES_DIR', p_filename, 'rb', 32767);
    
    DBMS_LOB.CREATETEMPORARY(v_blob, TRUE); -- пакет для работы с большими пакетами
    
    -- по чанкам 
    BEGIN
      LOOP
        BEGIN
        -- читает бинарные данные в буфер
          UTL_FILE.GET_RAW(v_file, v_buffer, v_amount);
          v_bytes_read := UTL_RAW.LENGTH(v_buffer);
          
          DBMS_OUTPUT.PUT_LINE('DEBUG: Прочитано ' || v_bytes_read || ' байт из файла');
          
          IF v_bytes_read > 0 THEN
          -- добавляет данные в конец BLOB
            DBMS_LOB.WRITEAPPEND(v_blob, v_bytes_read, v_buffer);
            v_file_size := v_file_size + v_bytes_read;
          END IF;
          
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('DEBUG: Достигнут конец файла. Всего прочитано: ' || v_file_size || ' байт');
            EXIT;
        END;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка в цикле чтения: ' || SQLERRM);
        RAISE;
    END;
    
    UTL_FILE.FCLOSE(v_file);
    
    IF v_file_size = 0 THEN
      RAISE_APPLICATION_ERROR(-20008, 'Файл пустой или не удалось прочитать данные');
    END IF;
    
    DECLARE
      v_mime_type VARCHAR2(100);
      v_extension VARCHAR2(10);
    BEGIN
      v_extension := UPPER(SUBSTR(p_filename, INSTR(p_filename, '.', -1) + 1));
      
      CASE v_extension
        WHEN 'JPG' THEN v_mime_type := 'image/jpeg';
        WHEN 'JPEG' THEN v_mime_type := 'image/jpeg';
        WHEN 'PNG' THEN v_mime_type := 'image/png';
        WHEN 'GIF' THEN v_mime_type := 'image/gif';
        WHEN 'BMP' THEN v_mime_type := 'image/bmp';
        WHEN 'WEBP' THEN v_mime_type := 'image/webp';
        ELSE v_mime_type := 'application/octet-stream';
      END CASE;
      
      INSERT INTO product_media(product_id, filename, mime_type, content)
      VALUES(p_product_id, p_filename, v_mime_type, v_blob);
      
      DBMS_OUTPUT.PUT_LINE('Изображение ' || p_filename || ' успешно загружено для товара ' || p_product_id);
      DBMS_OUTPUT.PUT_LINE('Размер файла: ' || v_file_size || ' байт');
    END;
    
  EXCEPTION
    WHEN UTL_FILE.INVALID_PATH THEN
      RAISE_APPLICATION_ERROR(-20002, 'Неверный путь к файлу: ' || p_filename);
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
      RAISE_APPLICATION_ERROR(-20003, 'Ошибка открытия файла: ' || p_filename);
    WHEN OTHERS THEN
      IF UTL_FILE.IS_OPEN(v_file) THEN
        UTL_FILE.FCLOSE(v_file);
      END IF;
      RAISE_APPLICATION_ERROR(-20004, 'Ошибка загрузки изображения: ' || SQLERRM);
  END;

-- альтернатива при ошибке
  PROCEDURE upload_product_image_simple(p_product_id NUMBER, p_filename VARCHAR2) IS
    v_bfile BFILE;
    v_blob BLOB;
    v_file_size INTEGER;
  BEGIN
    
    v_bfile := BFILENAME('COSM_IMAGES_DIR', p_filename);
    
    IF DBMS_LOB.FILEEXISTS(v_bfile) = 0 THEN
      RAISE_APPLICATION_ERROR(-20009, 'Файл не найден: ' || p_filename);
    END IF;
    
    DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);
    v_file_size := DBMS_LOB.GETLENGTH(v_bfile);
    DBMS_OUTPUT.PUT_LINE('Размер файла: ' || v_file_size || ' байт');
    
    DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);
    DBMS_LOB.LOADFROMFILE(v_blob, v_bfile, v_file_size);
    DBMS_LOB.CLOSE(v_bfile);
    
    DECLARE
      v_mime_type VARCHAR2(100);
      v_extension VARCHAR2(10);
    BEGIN
      v_extension := UPPER(SUBSTR(p_filename, INSTR(p_filename, '.', -1) + 1));
      
      CASE v_extension
        WHEN 'JPG' THEN v_mime_type := 'image/jpeg';
        WHEN 'JPEG' THEN v_mime_type := 'image/jpeg';
        WHEN 'PNG' THEN v_mime_type := 'image/png';
        WHEN 'GIF' THEN v_mime_type := 'image/gif';
        WHEN 'BMP' THEN v_mime_type := 'image/bmp';
        ELSE v_mime_type := 'application/octet-stream';
      END CASE;
      
      INSERT INTO product_media(product_id, filename, mime_type, content)
      VALUES(p_product_id, p_filename, v_mime_type, v_blob);
      
      DBMS_OUTPUT.PUT_LINE('Изображение загружено (альтернативный метод)');
      DBMS_OUTPUT.PUT_LINE('Размер: ' || v_file_size || ' байт');
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      IF DBMS_LOB.ISOPEN(v_bfile) = 1 THEN
        DBMS_LOB.CLOSE(v_bfile);
      END IF;
      RAISE_APPLICATION_ERROR(-20010, 'Ошибка альтернативной загрузки: ' || SQLERRM);
  END;

  PROCEDURE get_product_image(p_product_id NUMBER, p_media_id NUMBER, p_image OUT BLOB) IS
  BEGIN
    SELECT content INTO p_image
    FROM product_media
    WHERE product_id = p_product_id AND media_id = p_media_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20005, 'Изображение не найдено');
  END;

  FUNCTION get_product_images(p_product_id NUMBER) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT media_id, filename, mime_type, uploaded_at,
             DBMS_LOB.GETLENGTH(content) as file_size
      FROM product_media
      WHERE product_id = p_product_id
      ORDER BY uploaded_at DESC;
    
    RETURN v_cursor;
  END;

  PROCEDURE delete_product_image(p_media_id NUMBER) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM product_media WHERE media_id = p_media_id;
    
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20006, 'Изображение с ID ' || p_media_id || ' не найдено');
    END IF;
    
    DELETE FROM product_media WHERE media_id = p_media_id;
    DBMS_OUTPUT.PUT_LINE('Изображение с ID ' || p_media_id || ' удалено');
  END;

  PROCEDURE update_product_image(p_media_id NUMBER, p_filename VARCHAR2, p_image_path VARCHAR2) IS
    v_product_id NUMBER;
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM product_media WHERE media_id = p_media_id;
    
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20007, 'Медиа с ID ' || p_media_id || ' не найдено');
    END IF;
    
    SELECT product_id INTO v_product_id FROM product_media WHERE media_id = p_media_id;
    DELETE FROM product_media WHERE media_id = p_media_id;
    upload_product_image(v_product_id, p_filename, p_image_path);
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20007, 'Медиа с ID ' || p_media_id || ' не найдено');
  END;

  PROCEDURE test_blob_media(p_product_id NUMBER, p_image_path VARCHAR2) IS
    v_filename VARCHAR2(255);
    v_media_id NUMBER;
    v_blob BLOB;
    v_blob_size NUMBER;
    v_mime_type VARCHAR2(100);
    v_dir_path VARCHAR2(4000);
    v_binary_preview VARCHAR2(200);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ТЕСТ BLOB МУЛЬТИМЕДИА');
    DBMS_OUTPUT.PUT_LINE('Product ID: ' || p_product_id);
    DBMS_OUTPUT.PUT_LINE('Путь к изображению: ' || p_image_path);
    
    BEGIN
      SELECT directory_path INTO v_dir_path
      FROM all_directories
      WHERE directory_name = 'COSM_IMAGES_DIR';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ОШИБКА: Директория COSM_IMAGES_DIR не найдена!');
        RETURN;
    END;
    
    DECLARE
      v_last_slash NUMBER;
      v_last_backslash NUMBER;
      v_start_pos NUMBER;
    BEGIN
      v_last_slash := INSTR(p_image_path, '/', -1);
      v_last_backslash := INSTR(p_image_path, '\', -1);
      v_start_pos := GREATEST(NVL(v_last_slash, 0), NVL(v_last_backslash, 0));
      
      IF v_start_pos > 0 THEN
        v_filename := SUBSTR(p_image_path, v_start_pos + 1);
      ELSE
        v_filename := p_image_path;
      END IF;
    END;
    
    DBMS_OUTPUT.PUT_LINE('Имя файла: ' || v_filename);
    BEGIN

      upload_product_image(p_product_id, v_filename, p_image_path);
    EXCEPTION
      WHEN OTHERS THEN
   
        upload_product_image_simple(p_product_id, v_filename);
    END;
    
    BEGIN
      SELECT media_id INTO v_media_id
      FROM product_media
      WHERE product_id = p_product_id
        AND ROWNUM = 1
      ORDER BY uploaded_at DESC;
      
      SELECT content, DBMS_LOB.GETLENGTH(content), mime_type
      INTO v_blob, v_blob_size, v_mime_type
      FROM product_media
      WHERE media_id = v_media_id;
      
      IF v_blob_size > 0 THEN
        DECLARE
          v_chunk RAW(50);
        BEGIN
          v_chunk := DBMS_LOB.SUBSTR(v_blob, LEAST(50, v_blob_size), 1);
          v_binary_preview := RAWTOHEX(v_chunk);
        END;
      ELSE
        v_binary_preview := 'EMPTY';
      END IF;
      
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('РЕЗУЛЬТАТЫ ЗАГРУЗКИ');
      DBMS_OUTPUT.PUT_LINE('Media ID: ' || v_media_id);
      DBMS_OUTPUT.PUT_LINE('Размер BLOB: ' || v_blob_size || ' байт');
      DBMS_OUTPUT.PUT_LINE('MIME тип: ' || v_mime_type);
      
      -- SELECT таблица
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('SELECT ИЗ PRODUCT_MEDIA');
      DBMS_OUTPUT.PUT_LINE('MEDIA_ID | FILENAME | MIME_TYPE | FILE_SIZE | BLOB_PREVIEW');
      DBMS_OUTPUT.PUT_LINE('---------|----------|-----------|-----------|--------------');
      
      FOR r IN (
        SELECT 
          media_id,
          filename,
          mime_type,
          DBMS_LOB.GETLENGTH(content) as file_size,
          RAWTOHEX(DBMS_LOB.SUBSTR(content, LEAST(20, DBMS_LOB.GETLENGTH(content)), 1)) as blob_preview
        FROM product_media
        WHERE product_id = p_product_id
        ORDER BY uploaded_at DESC
      ) LOOP
        DBMS_OUTPUT.PUT_LINE(
          RPAD(TO_CHAR(r.media_id), 9) || ' | ' ||
          RPAD(r.filename, 8) || ' | ' ||
          RPAD(r.mime_type, 9) || ' | ' ||
          RPAD(TO_CHAR(r.file_size) || 'b', 9) || ' | ' ||
          r.blob_preview || '...'
        );
      END LOOP;
      
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('SELECT ИЗ V_PRODUCT_MEDIA');
      DBMS_OUTPUT.PUT_LINE('PRODUCT_NAME | SKU | FILENAME | SIZE_KB | UPLOADED_AT');
      DBMS_OUTPUT.PUT_LINE('-------------|-----|----------|---------|------------');
      
      FOR r IN (
        SELECT 
          product_name,
          sku,
          filename,
          file_size_kb,
          TO_CHAR(uploaded_at, 'DD.MM.YYYY HH24:MI') as uploaded_time
        FROM v_product_media
        WHERE product_id = p_product_id
        ORDER BY uploaded_at DESC
      ) LOOP
        DBMS_OUTPUT.PUT_LINE(
          RPAD(r.product_name, 13) || ' | ' ||
          RPAD(r.sku, 3) || ' | ' ||
          RPAD(r.filename, 8) || ' | ' ||
          RPAD(TO_CHAR(r.file_size_kb) || 'KB', 7) || ' | ' ||
          r.uploaded_time
        );
      END LOOP;
      
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('ТЕСТ УСПЕШНО ЗАВЕРШЕН');
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: изображение не было загружено в БД');
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка в test_blob_media: ' || SQLERRM);
  END;

  PROCEDURE list_directory_files IS
    v_dir_path VARCHAR2(4000);
    v_file UTL_FILE.FILE_TYPE;
    v_test_files SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('blush.jpg', 'lipstick.jpeg');
    v_buffer RAW(1);
  BEGIN
    BEGIN
      SELECT directory_path INTO v_dir_path
      FROM all_directories
      WHERE directory_name = 'COSM_IMAGES_DIR';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ОШИБКА: Директория COSM_IMAGES_DIR не найдена!');
        RETURN;
    END;
    
    FOR i IN 1..v_test_files.COUNT LOOP
      BEGIN
        v_file := UTL_FILE.FOPEN('COSM_IMAGES_DIR', v_test_files(i), 'rb', 1);
        
        BEGIN
          UTL_FILE.GET_RAW(v_file, v_buffer, 1);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;
          WHEN OTHERS THEN NULL;
        END;
        
        UTL_FILE.FCLOSE(v_file);
        DBMS_OUTPUT.PUT_LINE('' || v_test_files(i) || ' - НАЙДЕН и доступен для чтения');
        
      EXCEPTION
        WHEN OTHERS THEN
          IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
          END IF;
          IF SQLCODE = -29283 THEN
            DBMS_OUTPUT.PUT_LINE('' || v_test_files(i) || ' - НЕ НАЙДЕН (файл не существует)');
          ELSE
            DBMS_OUTPUT.PUT_LINE('' || v_test_files(i) || ' - ОШИБКА доступа: ' || SUBSTR(SQLERRM, 1, 100));
          END IF;
      END;
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка при проверке файлов: ' || SQLERRM);
  END;

END pkg_media;
/

-- Предоставление прав на пакет
BEGIN
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_media TO COSM_ROLE_ADMIN';
  EXECUTE IMMEDIATE 'GRANT EXECUTE ON pkg_media TO COSM_ROLE_USER';
  DBMS_OUTPUT.PUT_LINE('Права на пакет pkg_media предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав: ' || SQLERRM);
END;
/

-- Создание представления для просмотра медиа
CREATE OR REPLACE VIEW v_product_media AS
SELECT pm.media_id,
       pm.product_id,
       p.name as product_name,
       p.sku,
       pm.filename,
       pm.mime_type,
       pm.uploaded_at,
       NVL(DBMS_LOB.GETLENGTH(pm.content), 0) as file_size_bytes,
       ROUND(NVL(DBMS_LOB.GETLENGTH(pm.content), 0) / 1024, 2) as file_size_kb
FROM product_media pm
JOIN products p ON p.product_id = pm.product_id;

-- Предоставление прав на представление
BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON v_product_media TO COSM_ROLE_USER';
  DBMS_OUTPUT.PUT_LINE('Права на представление v_product_media предоставлены');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Ошибка предоставления прав на представление: ' || SQLERRM);
END;
/

-- Создание индекса для быстрого поиска медиа по товару
CREATE INDEX idx_product_media_product ON product_media(product_id);

-- Статистика по медиа
BEGIN
  DBMS_OUTPUT.PUT_LINE('СТАТИСТИКА ПО МЕДИА');
  FOR r IN (
    SELECT 
      COUNT(*) as total_media,
      COUNT(DISTINCT product_id) as products_with_media,
      ROUND(AVG(file_size_kb), 2) as avg_kb
    FROM v_product_media
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Всего изображений: ' || r.total_media);
    DBMS_OUTPUT.PUT_LINE('Товаров с изображениями: ' || r.products_with_media);
    DBMS_OUTPUT.PUT_LINE('Средний размер: ' || r.avg_kb || ' KB');
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ошибка получения статистики медиа: ' || SQLERRM);
END;
/