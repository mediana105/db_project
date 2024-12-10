-- update warehouse stock when row into Book_x_Sale is added && trigger on Book_x_Sale
CREATE OR REPLACE FUNCTION bookstore.update_current_stock()
RETURNS TRIGGER AS $$
BEGIN

        UPDATE bookstore.Warehouse
        SET current_stock = current_stock - NEW.quantity
        WHERE warehouse_id = 
        (
            SELECT warehouse_id 
            FROM bookstore.Book_x_Sale
            WHERE sale_id = NEW.sale_id AND book_id=NEW.book_id 
        );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_current_stock_trigger
AFTER INSERT ON bookstore.Book_x_Sale
FOR EACH ROW
EXECUTE FUNCTION bookstore.update_current_stock();


-- prohibits normal update Buyer table && trigger on Buyer
CREATE OR REPLACE FUNCTION bookstore.update_buyer()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Update prohibited';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_buyer_trigger
BEFORE UPDATE ON bookstore.Buyer
FOR EACH ROW
EXECUTE FUNCTION bookstore.update_buyer();
