-- 81. Stored Procedure: Update Inventory after Sale
-- When a product is sold, update inventory automatically by reducing sold quantity.
DELIMITER $$

CREATE PROCEDURE update_inventory_stock_data(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_order_item_id INT,
    IN p_order_id INT,
    IN p_quantity INT,
    IN p_seller_id INT
)
BEGIN
    DECLARE v_count INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_product_name VARCHAR(50);
    
    SELECT price, product_name 
    INTO v_price, v_product_name
    FROM products
    WHERE product_id = p_product_id;

    SELECT COUNT(*) 
    INTO v_count
    FROM inventory 
    WHERE product_id = p_product_id AND stock >= p_quantity;

    IF v_count > 0 THEN
        INSERT INTO orders(order_id, order_date, customer_id, seller_id)
        VALUES (p_order_id, CURDATE(), p_customer_id, p_seller_id);

        INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_price)
        VALUES (p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, p_quantity * v_price);

        UPDATE inventory
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;

        SELECT CONCAT('Product sale added. Inventory updated for: ', v_product_name) AS message;

    ELSE
     
        SELECT CONCAT('Product ', v_product_name, ' is not available in required quantity.') AS message;
    END IF;
END$$

DELIMITER ;
