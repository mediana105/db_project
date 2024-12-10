CREATE SCHEMA bookstore;

-- Table Publishing (издательство)
CREATE TABLE bookstore.Publishing (
    publishing_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL
);

-- Table Warehouse (склад)
CREATE TABLE bookstore.Warehouse (
    warehouse_id SERIAL PRIMARY KEY,
    city VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    capacity INTEGER NOT NULL,
    current_stock INTEGER NOT NULL,
    CONSTRAINT check_current_stock_capacity CHECK (current_stock >= 0 AND current_stock <= capacity)
);

-- Table Delivery_service (служба доставки)
CREATE TABLE bookstore.Delivery_service (
    delivery_service_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

-- Table Buyer (покупатель)
CREATE TABLE bookstore.Buyer (
    buyer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(20) NOT NULL,
    valid_from_DTTM TIMESTAMP NOT NULL,
    valid_to_DTTM TIMESTAMP,
    CONSTRAINT check_DTTM_validity CHECK (valid_to_DTTM IS NULL OR valid_to_DTTM > valid_from_DTTM),
    CONSTRAINT check_email_format CHECK (email IS NULL OR email LIKE '%@%.%')
);

-- Table Genre (жанр)
CREATE TABLE bookstore.Genre (
    genre_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

-- Table Book (книга)
CREATE TABLE bookstore.Book (
    book_id SERIAL PRIMARY KEY,
    publishing_id INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL, 
    price NUMERIC(15, 2) NOT NULL CHECK (price >= 0),
    CONSTRAINT FK_BookPublishing FOREIGN KEY (publishing_id) REFERENCES bookstore.Publishing(publishing_id)
);

-- Table Sale (продажа)
CREATE TABLE bookstore.Sale (
    sale_id SERIAL PRIMARY KEY,
    buyer_id INTEGER NOT NULL,
    delivery_service_id INTEGER NOT NULL,
    warehouse_id INTEGER NOT NULL,
    address VARCHAR(255) NOT NULL,
    DTTM TIMESTAMP NOT NULL,
    CONSTRAINT FK_SaleBuyer FOREIGN KEY (buyer_id) REFERENCES bookstore.Buyer(buyer_id),
    CONSTRAINT FK_SaleWarehouse FOREIGN KEY (warehouse_id) REFERENCES bookstore.Warehouse(warehouse_id),
    CONSTRAINT FK_SaleDeliveryService FOREIGN KEY (delivery_service_id) REFERENCES bookstore.Delivery_service(delivery_service_id)
);

-- Table Book_x_warehouse (книга-склад)
CREATE TABLE bookstore.Book_x_Warehouse (
    warehouse_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (warehouse_id, book_id),
    CONSTRAINT FK_Book_x_WarehouseWarehouse FOREIGN KEY (warehouse_id) REFERENCES bookstore.Warehouse(warehouse_id),
    CONSTRAINT FK_Book_x_WarehouseBook FOREIGN KEY (book_id) REFERENCES bookstore.Book(book_id)
);

-- Table Warehouse_X_delivery_service (склад-служба доставки)
CREATE TABLE bookstore.Warehouse_x_Delivery_service (
    warehouse_id INTEGER NOT NULL,
    delivery_service_id INTEGER NOT NULL,
    PRIMARY KEY (warehouse_id, delivery_service_id),
    CONSTRAINT FK_Warehouse_x_Delivery_serviceWarehouse FOREIGN KEY (warehouse_id) REFERENCES bookstore.Warehouse(warehouse_id),
    CONSTRAINT FK_Warehouse_x_Delivery_serviceDelivery_service FOREIGN KEY (delivery_service_id) REFERENCES bookstore.Delivery_service(delivery_service_id)
);

-- Table Book_x_sale (книга-продажа)
CREATE TABLE bookstore.Book_x_Sale (
    book_id INTEGER NOT NULL,
    sale_id INTEGER NOT NULL,
    sale_price NUMERIC(15, 2) NOT NULL CHECK (sale_price >= 0),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (book_id, sale_id),
    CONSTRAINT FK_Book_x_saleBook FOREIGN KEY (book_id) REFERENCES bookstore.Book(book_id),
    CONSTRAINT FK_Book_x_saleSale FOREIGN KEY (sale_id) REFERENCES bookstore.Sale(sale_id)
);

-- Table Warehouse_x_publishing (склад-издательство)
CREATE TABLE bookstore.Warehouse_x_publishing (
    warehouse_id INTEGER NOT NULL,
    publishing_id INTEGER NOT NULL,
    PRIMARY KEY (warehouse_id, publishing_id),
    CONSTRAINT FK_Warehouse_x_publishingWarehouse FOREIGN KEY (warehouse_id) REFERENCES bookstore.Warehouse(warehouse_id),
    CONSTRAINT FK_Warehouse_x_publishingPublishing FOREIGN KEY (publishing_id) REFERENCES bookstore.Publishing(publishing_id)
);

-- Table Book_x_genre (книга-жанр)
CREATE TABLE bookstore.Book_x_genre (
    genre_id INTEGER NOT NULL,
    book_id INTEGER NOT NULL,
    PRIMARY KEY (genre_id, book_id),
    CONSTRAINT FK_Book_x_genreBook FOREIGN KEY (book_id) REFERENCES bookstore.Book(book_id),
    CONSTRAINT FK_Book_x_genreGenre FOREIGN KEY (genre_id) REFERENCES bookstore.Genre(genre_id)
);
