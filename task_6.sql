-- 1. В результате выполнения запроса будут получены самые дорогие книги для каждого склада в Москве или Санкт-Петербурге.
-- Если таких книг несколько, будут выведены все из них.
-- Формат вывода: id, название и стоимость  книги, id склада, город, в котором расположен склад

SELECT w_id, city, b_id, name, CASE WHEN price IS NULL THEN 0 ELSE price END AS price
FROM (
    SELECT  b.book_id AS b_id,
            b.name AS name,
            b.price AS price,
            w.warehouse_id as w_id,
            w.city as city,
            rank() OVER (PARTITION BY w.warehouse_id ORDER BY b.price DESC) as place

    FROM bookstore.Warehouse AS w
    LEFT JOIN bookstore.Book_x_warehouse AS bw ON bw.warehouse_id = w.warehouse_id
    LEFT JOIN bookstore.Book AS b ON b.book_id = bw.book_id
    WHERE w.city = 'Москва' OR w.city = 'Санкт-Петербург'
) AS sorted_books
WHERE sorted_books.place = 1;


-- 2. В результате выполнения запроса будет получена общая стоимость всех заказов, сделанных в каждом году 
-- (в котором был сделан хотя бы 1 заказ), и сумма, на которую заказы отличаются от предыдущего года
-- Формат вывода: год, суммарная стоимость заказов за этот год, разность с суммой за предыдущий год.

WITH sum_by_year AS (
    SELECT  year, SUM(sale_price * quantity) AS total_price
    FROM (
        SELECT  EXTRACT(YEAR FROM s.DTTM) AS year,
                bs.sale_price AS sale_price,
                bs.quantity AS  quantity
        FROM bookstore.Sale AS s INNER JOIN bookstore.Book_x_sale AS bs ON bs.sale_id = s.sale_id
    ) AS year_info
    GROUP BY year
)

SELECT year::INTEGER, 
        total_price, 
        CASE WHEN prev_year = year - 1
            THEN total_price - prev_price 
            ELSE total_price 
        END as diff
FROM (
    SELECT  year,
            total_price,
            lag(year) OVER (ORDER BY year ASC) AS prev_year,
            lag(total_price) OVER (ORDER BY year ASC) AS prev_price
    FROM sum_by_year
) AS perv_year_price;


-- 3. В результате выполнения запроса будут получены склады, доставка с которых производилась преимущественно
-- компанией "cdek"
-- Формат вывода: id склада, количество доставок с этого склада cdek-ом, процент, который составляют 
-- эти доставки от всех доставок с этого склада
WITH delivery_in_sale AS (
    SELECT  w.warehouse_id AS w_id, 
            COUNT(*) AS delivery_cnt,
            d.name as delivery_name
    FROM bookstore.Warehouse AS w
    INNER JOIN bookstore.sale AS s ON s.warehouse_id = w.warehouse_id
    INNER JOIN bookstore.delivery_service AS d ON d.delivery_service_id = s.delivery_service_id
    GROUP BY w.warehouse_id, s.delivery_service_id, d.name
)

SELECT w_id, delivery_cnt, ROUND(delivery_cnt * 100 / all_deliveries_cnt::NUMERIC, 2) AS percent
FROM (
    SELECT  w_id,
            delivery_name,
            delivery_cnt,
            SUM(delivery_cnt) OVER (PARTITION BY w_id) as all_deliveries_cnt,
            rank() OVER(PARTITION BY w_id ORDER BY delivery_cnt DESC) as place
    FROM delivery_in_sale
) AS deliveries_cnt
WHERE delivery_name = 'cdek' AND place = 1;


-- 4. В результате выполнения запроса будут получены все покупатели, которые покупали учебную литературу не реже других жанров
-- Формат вывода: id покупателя, имя покупателя, количество купленных им учебных книг и их список через запятую
WITH genres_cnt AS (
    SELECT  buyer.buyer_id AS buyer_id,
            buyer.name AS buyer_name,
            g.genre_id AS genre_id,
            g.name AS genre_name,
            SUM (bs.quantity) AS genre_sales_cnt

    FROM bookstore.Buyer as buyer
    INNER JOIN bookstore.Sale AS s ON s.buyer_id = buyer.buyer_id
    INNER JOIN bookstore.Book_x_sale AS bs ON bs.sale_id = s.sale_id
    INNER JOIN bookstore.Book AS b ON bs.book_id = b.book_id
    INNER JOIN bookstore.Book_x_genre AS bg ON bg.book_id = b.book_id
    INNER JOIN bookstore.Genre AS g ON bg.genre_id = g.genre_id

    GROUP BY buyer.buyer_id, buyer.name, g.genre_id, g.name
)

SELECT  buyer_id, buyer_name, genre_sales_cnt,
        string_agg(b.name, ', ') AS books_list
FROM (
    SELECT  buyer_id, buyer_name, genre_id, genre_name, genre_sales_cnt,
            rank() OVER (PARTITION BY buyer_id ORDER BY genre_sales_cnt DESC) AS place
    FROM genres_cnt
) AS genres_places

LEFT JOIN bookstore.Book_x_genre AS bg ON bg.genre_id = genres_places.genre_id
LEFT JOIN bookstore.Book AS b ON bg.book_id = b.book_id

WHERE genre_name = 'Учебная литература' AND place = 1
GROUP BY buyer_id, buyer_name, genre_sales_cnt;

-- 5. В результате выполнения запроса будет получен список всех актуальных на данный момент покупателей, сумма стоимостей 
-- совершенных ими покупок и сумма, на которую стоимость их покупок отличается от максимальной. Список отсортирован по стоимости трат.
-- Формат вывода: id покупателя, имя покупателя, сумма его трат, разница между максимальной суммой и суммой его покупок
WITH sales_sum AS (
    SELECT  buyer.buyer_id AS buyer_id,
            buyer.name AS buyer_name,
            SUM (bs.sale_price * bs.quantity) AS buyer_purchase
    FROM bookstore.Buyer AS buyer
    LEFT JOIN bookstore.Sale AS s ON buyer.buyer_id = s.buyer_id
    LEFT JOIN bookstore.Book_x_sale AS bs ON s.sale_id = bs.sale_id

    WHERE buyer.valid_to_dttm IS NULL
    GROUP BY buyer.buyer_id, buyer.name
)

SELECT buyer_id,
        buyer_name,
        buyer_purchase_price,
        CASE WHEN max_purchase_price IS NULL THEN 0 ELSE max_purchase_price - buyer_purchase_price END AS diff
FROM (
    SELECT  buyer_id,
            buyer_name,
            CASE WHEN buyer_purchase IS NULL THEN 0 ELSE buyer_purchase END AS buyer_purchase_price,
            first_value(buyer_purchase) OVER (ORDER BY buyer_purchase DESC NULLS LAST) AS max_purchase_price
    FROM sales_sum
) AS sum_and_first_value
ORDER BY buyer_purchase_price;
