from peewee import*
import config

bookStoreDB = PostgresqlDatabase(config.DATABASE_NAME, user=config.DATABASE_USER, password=config.DATABASE_PASSWORD, host=config.DATABASE_HOST, port=config.DATABASE_PORT)

class BaseModel(Model):
    class Meta:
        database = bookStoreDB
        schema = 'bookstore'


class Book(BaseModel):
    book_id = AutoField()
    publishing_id = IntegerField()
    name = CharField()
    author = CharField()
    price = DecimalField()


class Warehouse(BaseModel):
    warehouse_id = AutoField()
    city = CharField()
    address = CharField()
    phone_number = CharField()
    capacity = IntegerField()
    current_stock = IntegerField()


class Genre(BaseModel):
    genre_id = AutoField()
    name = CharField()


class Publishing(BaseModel):
    publishing_id = AutoField()
    name = CharField()
    address = CharField()
    city = CharField()


class Book_x_Sale(BaseModel):
    book_id = IntegerField()
    sale_id = IntegerField()
    sale_price = DecimalField()
    quantity = IntegerField()


# get phone numbers of Warehouses in specific city
def get_phone_numbers(city: str) -> list:
    numbers: list = []
    for warehouse in Warehouse.select().where(Warehouse.city == city):
        numbers.append([warehouse.warehouse_id, warehouse.city, warehouse.phone_number, warehouse.address])
    return numbers

# print(get_phone_numbers('Москва'))
# print(get_phone_numbers('Бебринск'))


# instert new genre
def insert_genre(genre_name: str):
    Genre.create(name=genre_name)

# insert_genre('Подростковая проза')


# update address of publishing house
def update_address(new_address: str, publishing_name: str):
    Publishing.update(address=new_address).where(Publishing.name==publishing_name).execute()

# update_address('ул. Карла Маркса, 19', 'Калининградская книга')


# top selling books
def get_top_books():
    query = (Book
             .select(Book.name, fn.COALESCE(fn.SUM(Book_x_Sale.quantity), 0).alias('total_quantity'), 
                    fn.DENSE_RANK().over(order_by=[fn.COALESCE(fn.SUM(Book_x_Sale.quantity), 0)]).alias('place'))
            .join(Book_x_Sale, JOIN.LEFT_OUTER, on=(Book.book_id==Book_x_Sale.book_id))
            .group_by(Book.name)
            .order_by(fn.COALESCE(fn.SUM(Book_x_Sale.quantity), 0).desc()))
    for book in query:
        print(book.name, book.total_quantity, book.place)

# get_top_books()