-- Представление, которое показывает общие продажи и количество продаж для каждой книги, 
-- а также разницу в количестве между текущим и предыдущим значениями по количеству проданных книг.

DROP VIEW IF EXISTS views.books_total_sales;
CREATE VIEW views.books_total_sales AS
WITH sales_each_book AS (
    SELECT 
        b.name AS book_name,
        b.author,
        bs.sale_price AS book_price,
        COALESCE(SUM(bs.quantity * bs.sale_price), 0.00) AS total_sales,
        COALESCE(SUM(bs.quantity), 0) AS total_quantity
    FROM 
        bookstore.Book AS b
    LEFT JOIN 
        bookstore.Book_x_Sale AS bs ON b.book_id = bs.book_id
    GROUP BY 
        b.book_id, b.name, b.author, bs.sale_price
)
SELECT
    seb.book_name,
    seb.author,
    seb.book_price,
    seb.total_sales,
    seb.total_quantity,
        COALESCE(LAG(seb.total_quantity) OVER (ORDER BY seb.total_quantity DESC), 0) AS prev_total_quantity,
    COALESCE(seb.total_quantity, 0) - COALESCE(LAG(seb.total_quantity) OVER (ORDER BY seb.total_quantity DESC), 0) AS difference
FROM sales_each_book AS seb
ORDER BY seb.total_quantity DESC;

-- Представление, которое показывает для каждой книги дату с наибольшим количеством продаж. 
-- В случае, если несколько дней имеют одинаковое количество продаж, все такие дни будут выведены.

DROP VIEW IF EXISTS views.top_days_per_book;
CREATE VIEW views.top_days_per_book AS 
WITH sales_details AS (
    SELECT
        b.book_id,
        b.name AS book_name,
        s.DTTM::DATE AS sale_date,
        COUNT(s.sale_id) AS total_count
    FROM    
        bookstore.Book AS b
    LEFT JOIN
        bookstore.Book_x_Sale AS bs ON b.book_id = bs.book_id
    LEFT JOIN
        bookstore.Sale AS s ON bs.sale_id = s.sale_id
    GROUP BY 
        b.book_id, b.name, s.DTTM::DATE
),
most_frequent_day AS (
    SELECT
        book_id,
        sale_date,
        RANK() OVER (PARTITION BY book_id ORDER BY total_count DESC) AS day_rank
    FROM 
        sales_details
)
SELECT
    sd.book_id,
    sd.book_name,
    mfd.sale_date
FROM
    sales_details AS sd
LEFT JOIN
    most_frequent_day AS mfd ON sd.book_id = mfd.book_id AND sd.sale_date = mfd.sale_date
WHERE
    mfd.day_rank = 1
ORDER BY
    sd.book_name, mfd.day_rank;

-- Представление, содержащее для каждого покупателя список складов, с которых он чаще всего совершал покупки.  
-- В случае, если несколько складов являются наиболее частыми, все такие склады будут выведены.
DROP VIEW IF EXISTS views.most_frequent_warehouse_for_buyers;
CREATE VIEW views.most_frequent_warehouse_for_buyers AS
WITH buyer_x_warehouse_statistics AS (
    SELECT
        s.buyer_id,
        s.warehouse_id,
        COUNT(s.sale_id) AS sales_count
    FROM
        bookstore.Sale AS s
    GROUP BY
        s.buyer_id, s.warehouse_id
),
top_warehouses AS (
    SELECT
        bws.buyer_id,
        bws.warehouse_id,
        bws.sales_count,
        RANK() OVER (PARTITION BY bws.buyer_id ORDER BY bws.sales_count DESC) AS rnk
    FROM
        buyer_x_warehouse_statistics AS bws
)
SELECT
    b.name AS buyer_name,
    tw.warehouse_id,
    tw.sales_count
FROM
    top_warehouses AS tw
INNER JOIN
    bookstore.Buyer AS b ON tw.buyer_id = b.buyer_id
WHERE
    tw.rnk = 1
ORDER BY
    b.name, tw.sales_count DESC;
