CREATE SCHEMA views;

-- Publishing View
CREATE VIEW views.Publishing_view AS
SELECT
    publishing_id,
    name,
    address,
    city
FROM bookstore.Publishing;

-- Warehouse View
CREATE VIEW views.Warehouse_view AS
SELECT
    warehouse_id,
    city,
    address,
    phone_number,
    capacity,
    current_stock
FROM bookstore.Warehouse;

-- Delivery Service View
CREATE VIEW views.Delivery_service_view AS
SELECT
    delivery_service_id,
    name
FROM bookstore.Delivery_service;

-- Buyer View
CREATE VIEW views.Buyer_view AS
SELECT
    buyer_id,
    CASE 
        WHEN LENGTH(name) <= 2 THEN REPEAT('*', LENGTH(name))
        ELSE CONCAT(SUBSTRING(name, 1, 3), REPEAT('*', LENGTH(name) - 3))
    END AS name,
    CONCAT(REPEAT('*', POSITION('@' IN email) - 1), SUBSTRING(email, POSITION('@' IN email))) AS email,
    CONCAT(SUBSTRING(phone_number, 1, 4), '********') AS phone_number,
    valid_from_DTTM,
    valid_to_DTTM
FROM bookstore.Buyer;

-- Genre View
CREATE VIEW views.Genre_view AS
SELECT
    genre_id,
    name
FROM bookstore.Genre;

-- Book View
CREATE VIEW views.Book_view AS
SELECT
    book_id,
    name,
    author,
    price
FROM bookstore.Book

-- Sale View
CREATE VIEW views.Sale_view AS
SELECT
    sale_id,
    buyer_id,
    delivery_service_id,
    warehouse_id,
    address,
    DTTM
FROM bookstore.Sale;

-- Book x Warehouse View
CREATE VIEW views.Book_x_warehouse_view AS
SELECT
    bw.book_id,
    b.name AS book_name,
    bw.warehouse_id,
    w.city AS warehouse_city,
    w.address AS warehouse_address,
    bw.quantity
FROM bookstore.Book_x_Warehouse bw
LEFT JOIN bookstore.Book b ON bw.book_id = b.book_id
LEFT JOIN bookstore.Warehouse w ON bw.warehouse_id = w.warehouse_id;

-- Warehouse x Delivery Service View
CREATE VIEW views.Warehouse_X_delivery_service_view AS
SELECT
    wds.warehouse_id,
    w.city AS warehouse_city,
    w.address AS warehouse_address,
    wds.delivery_service_id,
    ds.name AS delivery_service_name
FROM bookstore.Warehouse_x_Delivery_service wds
LEFT JOIN bookstore.Warehouse w ON wds.warehouse_id = w.warehouse_id
LEFT JOIN bookstore.Delivery_service ds ON wds.delivery_service_id = ds.delivery_service_id;

-- Book x Sale View
CREATE VIEW views.Book_x_sale_view AS
SELECT
    bs.book_id,
    b.name AS book_name,
    bs.sale_id,
    s.DTTM AS sale_date,
    bs.sale_price,
    bs.quantity
FROM bookstore.Book_x_Sale bs
LEFT JOIN bookstore.Book b ON bs.book_id = b.book_id
LEFT JOIN bookstore.Sale s ON bs.sale_id = s.sale_id;

-- Warehouse x Publishing View
CREATE VIEW views.Warehouse_x_publishing_view AS
SELECT
    wp.warehouse_id,
    w.city AS warehouse_city,
    w.address AS warehouse_address,
    wp.publishing_id,
    p.name AS publishing_name
FROM bookstore.Warehouse_x_publishing wp
LEFT JOIN bookstore.Warehouse w ON wp.warehouse_id = w.warehouse_id
LEFT JOIN bookstore.Publishing p ON wp.publishing_id = p.publishing_id;

-- Book x Genre View
CREATE VIEW views.Book_x_genre_view AS
SELECT
    bg.book_id,
    b.name AS book_name,
    bg.genre_id,
    g.name AS genre_name
FROM bookstore.Book_x_genre bg
LEFT JOIN bookstore.Book b ON bg.book_id = b.book_id
LEFT JOIN bookstore.Genre g ON bg.genre_id = g.genre_id;
