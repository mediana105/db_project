-- Процедура, добавляющая новый заказ
-- call bookstore.add_sale(4, 1, 1, 'г.Санкт-Петербург, ул. Катемировская, д. 3а', NOW()::TIMESTAMP, '[{"book_id": 1, "quantity": 2, "sale_price": 10.00}, {"book_id": 5, "quantity": 1, "sale_price": 10.00}]'::JSONB);
CREATE OR REPLACE PROCEDURE bookstore.add_sale(
    buyer_id INTEGER,
    delivery_service_id INTEGER,
    warehouse_id_from INTEGER,
    address VARCHAR,
    current_dttm TIMESTAMP,
    books JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_sale_id INTEGER;
    total_quantity INTEGER = 0;
    book JSONB;
BEGIN
    -- Проверка количества книг на складе
    FOR book IN SELECT * FROM jsonb_array_elements(books) LOOP
        total_quantity := total_quantity + (book->>'quantity')::INTEGER;
    END LOOP;

    IF total_quantity > (SELECT current_stock from Warehouse WHERE warehouse_id=warehouse_id_from)
        THEN RAISE EXCEPTION 'Not enough stock in warehouse';
    END IF;
    -- Добавление новой продажи в Sale
    INSERT INTO bookstore.Sale (buyer_id, delivery_service_id, warehouse_id, address, DTTM)
    VALUES (buyer_id, delivery_service_id, warehouse_id_from, address, current_dttm)
    RETURNING sale_id INTO new_sale_id;

    -- Обновление количества книг из заказа на складе
    FOR book IN SELECT * FROM jsonb_array_elements(books) LOOP
        DECLARE
            book_sale_id INTEGER := (book->>'book_id')::INTEGER;
            book_quantity INTEGER := (book->>'quantity')::INTEGER;
            book_sale_price NUMERIC := (book->>'sale_price')::NUMERIC;
        BEGIN
            -- Добавление в Book_x_Sale
            
            INSERT INTO bookstore.Book_x_Sale (book_id, sale_id, sale_price, quantity)
            VALUES (book_sale_id, new_sale_id, book_sale_price, book_quantity);
            
            -- Обновление количества определенной книги в Warehouse
            UPDATE bookstore.Book_x_Warehouse
            SET quantity = quantity - book_quantity
            WHERE bookstore.Book_x_Warehouse.warehouse_id = warehouse_id_from AND book_id = book_sale_id;
        END;
    END LOOP;
    EXCEPTION 
        WHEN OTHERS THEN 
            RAISE NOTICE 'Not enough books in warehouse';
            ROLLBACK;
END;
$$;

-- Процедура, добавляющая новую книгу
-- call bookstore.add_book(1, 'Доктор Живаго', 'Пастернак Б.Л.', 300.99, '[{"warehouse_id": 1, "quantity": 4}, {"warehouse_id": 5, "quantity": 500}]'::JSONB, '{1, 5, 14}');
CREATE OR REPLACE PROCEDURE bookstore.add_book(
    publishing_id INTEGER,
    name VARCHAR,
    author VARCHAR,
    price NUMERIC,
    warehouses JSONB, 
    genres INTEGER ARRAY 
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_book_id INTEGER;
    warehouse JSONB;
    genre INTEGER; 
BEGIN
    -- Добавление в Book
    INSERT INTO bookstore.Book(publishing_id, name, author, price)
    VALUES (publishing_id, name, author, price) 
    RETURNING book_id INTO new_book_id;

    FOR warehouse IN SELECT * FROM jsonb_array_elements(warehouses) LOOP
        DECLARE
            warehouse_id INTEGER := (warehouse->>'warehouse_id')::INTEGER;
            book_quantity INTEGER := (warehouse->>'quantity')::INTEGER;
        BEGIN
            -- Добавление в Book_x_Warehouse
            INSERT INTO bookstore.Book_x_Warehouse (warehouse_id, book_id, quantity)
            VALUES (warehouse_id, new_book_id, book_quantity);

            -- Обновление текущей заполненности склада 
            UPDATE bookstore.Warehouse
            SET current_stock = current_stock + book_quantity
            WHERE bookstore.Warehouse.warehouse_id = warehouse_id;
        END;
    END LOOP; 

    FOREACH genre IN ARRAY genres LOOP
        -- Добавление в Book_x_genre
        INSERT INTO bookstore.Book_x_genre (book_id, genre_id)
        VALUES (new_book_id, genre);
    END LOOP; 

    EXCEPTION 
        WHEN OTHERS THEN 
            RAISE NOTICE 'Not enough capacity in warehouse';
            ROLLBACK;
END;
$$;