-- CRUD-запросы (INSERT, SELECT, UPDATE, DELETE) к двум таблицам БД: bookstore.Buyer и  bookstore.Book

-- Добавить нового пользователя в таблицу bookstore.Buyer
 INSERT INTO bookstore.Buyer(name, email, phone_number, valid_from_DTTM,  valid_to_DTTM) VALUES 
    ('Tanya', 'tanya@work.ru', '+7-012-345-67-89', CURRENT_DATE, NULL);

-- Добавить новую книгу в таблицу bookstore.Book 
INSERT INTO bookstore.Book(publishing_id, name, author, price) VALUES
    (1, 'Приключения Алисы в Стране Чудес', 'Льюис Кэрролл', 3000);


-- Вывести все записи с покупателями, действительные на данный момент
SELECT * FROM bookstore.Buyer WHERE valid_to_DTTM IS NULL;

-- Вывести название, автора и цену для всех книг ценой меньше 1000, отсортировать в порядке возрастания цены
SELECT name, author, price FROM bookstore.Book WHERE price < 1000 ORDER BY price;

-- Вывести все книги Льюиса Кэрролла, в названии которых есть имя "Алиса" в любом склонении
SELECT * FROM bookstore.Book WHERE author = 'Льюис Кэрролл' AND name LIKE '%Алис%';

-- Посчитать количество записей, актуальных на начало 2022 года, в таблице покупателей
SELECT COUNT(*)  FROM bookstore.Buyer WHERE valid_from_DTTM < '2022-01-01' AND '2022-01-01' <= valid_to_DTTM;

-- Посчитать количество разных книг в каждом издательстве 
-- Вывести id издательства и количество книг, отсортировать по убыванию количества
SELECT publishing_id, COUNT(*) FROM bookstore.Book GROUP BY(publishing_id) ORDER BY COUNT(*) DESC;

-- Поднять на 100 цену книги "Преступление и наказание", изданной издательством с id = 2
UPDATE bookstore.Book SET price = price + 100 WHERE name = 'Преступление и наказание' AND publishing_id = 2;

-- Снизить на 10% цену всех книг пятого издательства 
UPDATE bookstore.Book SET price = price * 0.9 WHERE publishing_id = 5;

-- Поменять автора книг с "Ф.М.Достоевский" на "Фёдор Михайлович Достоевский"
UPDATE bookstore.Book SET author = 'Фёдор Михайлович Достоевский' WHERE author = 'Ф.М.Достоевский';
