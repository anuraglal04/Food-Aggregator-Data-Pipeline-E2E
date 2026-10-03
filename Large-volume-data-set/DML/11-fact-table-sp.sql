use role sysadmin;
use warehouse adhoc_wh;
use database bigdata_db;
SET WAREHOUSE_SIZE = 'MEDIUM';


CREATE OR REPLACE PROCEDURE clean_sch.fact_table_sp()
RETURNS text
LANGUAGE SQL
AS
BEGIN
    -- defining the sql statement as local variable 
    LET merge_dml_statement := 
    '
        MERGE INTO consumption_sch.order_item_fact AS target
        USING (
            SELECT 
                oi.Order_Item_ID AS order_item_id,
                oi.Order_ID_fk AS order_id,
                c.CUSTOMER_HK AS customer_dim_key,
                ca.CUSTOMER_ADDRESS_HK AS customer_address_dim_key,
                r.RESTAURANT_HK AS restaurant_dim_key, 
                rl.restaurant_location_hk as restaurant_location_dim_key,
                m.Menu_Dim_HK AS menu_dim_key,
                da.DELIVERY_AGENT_HK AS delivery_agent_dim_key,
                dd.DATE_DIM_HK AS order_date_dim_key,
                oi.Quantity::number(2) AS quantity,
                oi.Price AS price,
                oi.Subtotal AS subtotal,
                o.PAYMENT_METHOD,
                d.delivery_status AS delivery_status,
                d.estimated_time AS estimated_time
            FROM 
                clean_sch.order_item_stm oi
            JOIN 
                clean_sch.orders_stm o ON oi.Order_ID_fk = o.Order_ID
            JOIN 
                clean_sch.delivery_stm d ON o.Order_ID = d.Order_ID_fk
            JOIN 
                consumption_sch.CUSTOMER_DIM c on o.Customer_ID_fk = c.customer_id
            JOIN 
                consumption_sch.CUSTOMER_ADDRESS_DIM ca on c.Customer_ID = ca.CUSTOMER_ID_fk
            JOIN 
                consumption_sch.restaurant_dim r on o.Restaurant_ID_fk = r.restaurant_id
            JOIN 
                consumption_sch.menu_dim m ON oi.MENU_ID_fk = m.menu_id
            JOIN 
                consumption_sch.delivery_agent_dim da ON d.Delivery_Agent_ID_fk = da.delivery_agent_id
            JOIN 
                consumption_sch.restaurant_location_dim rl on r.LOCATION_ID_FK = rl.location_id
            JOIN 
                CONSUMPTION_SCH.DATE_DIM dd on dd.calendar_date = date(o.order_date)
        ) AS source_stm
        ON 
            target.order_item_id = source_stm.order_item_id and 
            target.order_id = source_stm.order_id
        WHEN MATCHED THEN
            -- Update existing fact record
            UPDATE SET
                target.customer_dim_key = source_stm.customer_dim_key,
                target.customer_address_dim_key = source_stm.customer_address_dim_key,
                target.restaurant_dim_key = source_stm.restaurant_dim_key,
                target.restaurant_location_dim_key = source_stm.restaurant_location_dim_key,
                target.menu_dim_key = source_stm.menu_dim_key,
                target.delivery_agent_dim_key = source_stm.delivery_agent_dim_key,
                target.order_date_dim_key = source_stm.order_date_dim_key,
                target.quantity = source_stm.quantity,
                target.price = source_stm.price,
                target.subtotal = source_stm.subtotal,
                target.delivery_status = source_stm.delivery_status,
                target.estimated_time = source_stm.estimated_time
        WHEN NOT MATCHED THEN
            -- Insert new fact record
            INSERT (
                order_item_id,
                order_id,
                customer_dim_key,
                customer_address_dim_key,
                restaurant_dim_key,
                restaurant_location_dim_key,
                menu_dim_key,
                delivery_agent_dim_key,
                order_date_dim_key,
                quantity,
                price,
                subtotal,
                delivery_status,
                estimated_time
            )
            VALUES (
                source_stm.order_item_id,
                source_stm.order_id,
                source_stm.customer_dim_key,
                source_stm.customer_address_dim_key,
                source_stm.restaurant_dim_key,
                source_stm.restaurant_location_dim_key,
                source_stm.menu_dim_key,
                source_stm.delivery_agent_dim_key,
                source_stm.order_date_dim_key,
                source_stm.quantity,
                source_stm.price,
                source_stm.subtotal,
                source_stm.delivery_status,
                source_stm.estimated_time
            )
    ';

    -- run the copy command
    EXECUTE IMMEDIATE merge_dml_statement;

    -- if all goes good, the retunr will be executed
    return 'Fact Table SP Exeucted without any issue';

    -- in case the excption occurs, it will come to this point 
    EXCEPTION
        WHEN EXPRESSION_ERROR THEN
            RETURN 'Fact Table SP Failed with EXPRESSION_ERROR Exception';
        WHEN STATEMENT_ERROR THEN
            RETURN 'Fact Table SP Failed with STATEMENT_ERROR Exception';
        WHEN OTHER THEN
            RETURN 'Fact Table SP Failed with OTHER Exception';
END;

call clean_sch.fact_table_sp();
------------------------------
SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.order_item_stm');
SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.orders_stm');
SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.delivery_stm');

SELECT COUNT(*)
FROM clean_sch.order_item oi
JOIN clean_sch.orders o ON oi.Order_ID_fk = o.Order_ID
JOIN clean_sch.delivery d ON o.Order_ID = d.Order_ID_fk
JOIN consumption_sch.customer_dim c ON o.Customer_ID_fk = c.customer_id
JOIN consumption_sch.customer_address_dim ca ON c.Customer_ID = ca.CUSTOMER_ID_fk
JOIN consumption_sch.restaurant_dim r ON o.Restaurant_ID_fk = r.restaurant_id
JOIN consumption_sch.menu_dim m ON oi.MENU_ID_fk = m.menu_id
JOIN consumption_sch.delivery_agent_dim da ON d.Delivery_Agent_ID_fk = da.delivery_agent_id
JOIN consumption_sch.restaurant_location_dim rl ON r.LOCATION_ID_FK = rl.location_id
JOIN consumption_sch.date_dim dd ON dd.calendar_date = DATE(o.order_date);

SELECT 'clean.order_item' t, COUNT(*) c FROM clean_sch.order_item
UNION ALL SELECT 'clean.orders', COUNT(*) FROM clean_sch.orders
UNION ALL SELECT 'clean.delivery', COUNT(*) FROM clean_sch.delivery
UNION ALL SELECT 'dim.customer', COUNT(*) FROM consumption_sch.customer_dim
UNION ALL SELECT 'dim.customer_address', COUNT(*) FROM consumption_sch.customer_address_dim
UNION ALL SELECT 'dim.restaurant', COUNT(*) FROM consumption_sch.restaurant_dim
UNION ALL SELECT 'dim.restaurant_location', COUNT(*) FROM consumption_sch.restaurant_location_dim
UNION ALL SELECT 'dim.menu', COUNT(*) FROM consumption_sch.menu_dim
UNION ALL SELECT 'dim.delivery_agent', COUNT(*) FROM consumption_sch.delivery_agent_dim
UNION ALL SELECT 'dim.date', COUNT(*) FROM consumption_sch.date_dim;

SELECT
    COUNT(*)                     AS order_items,
    COUNT(o.Order_ID)            AS matched_orders,
    COUNT(d.Order_ID_fk)         AS matched_delivery,
    COUNT(c.customer_id)         AS matched_customer,
    COUNT(ca.CUSTOMER_ID_fk)     AS matched_cust_address,
    COUNT(r.restaurant_id)       AS matched_restaurant,
    COUNT(m.menu_id)             AS matched_menu,
    COUNT(da.delivery_agent_id)  AS matched_agent,
    COUNT(rl.location_id)        AS matched_location,
    COUNT(dd.calendar_date)      AS matched_date
FROM clean_sch.order_item oi
LEFT JOIN clean_sch.orders o ON oi.Order_ID_fk = o.Order_ID
LEFT JOIN clean_sch.delivery d ON o.Order_ID = d.Order_ID_fk
LEFT JOIN consumption_sch.customer_dim c ON o.Customer_ID_fk = c.customer_id
LEFT JOIN consumption_sch.customer_address_dim ca ON c.Customer_ID = ca.CUSTOMER_ID_fk
LEFT JOIN consumption_sch.restaurant_dim r ON o.Restaurant_ID_fk = r.restaurant_id
LEFT JOIN consumption_sch.menu_dim m ON oi.MENU_ID_fk = m.menu_id
LEFT JOIN consumption_sch.delivery_agent_dim da ON d.Delivery_Agent_ID_fk = da.delivery_agent_id
LEFT JOIN consumption_sch.restaurant_location_dim rl ON r.LOCATION_ID_FK = rl.location_id
LEFT JOIN consumption_sch.date_dim dd ON dd.calendar_date = DATE(o.order_date);

SELECT 'orders' t, COUNT(*) - COUNT(DISTINCT Order_ID) AS dup_keys FROM clean_sch.orders
UNION ALL SELECT 'delivery', COUNT(*) - COUNT(DISTINCT Order_ID_fk) FROM clean_sch.delivery
UNION ALL SELECT 'customer_dim', COUNT(*) - COUNT(DISTINCT customer_id) FROM consumption_sch.customer_dim
UNION ALL SELECT 'customer_address_dim', COUNT(*) - COUNT(DISTINCT CUSTOMER_ID_fk) FROM consumption_sch.customer_address_dim
UNION ALL SELECT 'restaurant_dim', COUNT(*) - COUNT(DISTINCT restaurant_id) FROM consumption_sch.restaurant_dim
UNION ALL SELECT 'menu_dim', COUNT(*) - COUNT(DISTINCT menu_id) FROM consumption_sch.menu_dim
UNION ALL SELECT 'delivery_agent_dim', COUNT(*) - COUNT(DISTINCT delivery_agent_id) FROM consumption_sch.delivery_agent_dim
UNION ALL SELECT 'restaurant_location_dim', COUNT(*) - COUNT(DISTINCT location_id) FROM consumption_sch.restaurant_location_dim
UNION ALL SELECT 'date_dim', COUNT(*) - COUNT(DISTINCT calendar_date) FROM consumption_sch.date_dim;

SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.order_item_stm');
SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.orders_stm');
SELECT SYSTEM$STREAM_HAS_DATA('clean_sch.delivery_stm');


-------------------------
USE ROLE SYSADMIN;
USE DATABASE bigdata_db;
ALTER WAREHOUSE adhoc_wh SET WAREHOUSE_SIZE = 'MEDIUM';
USE WAREHOUSE adhoc_wh;

MERGE INTO consumption_sch.order_item_fact AS target
USING (
    SELECT
        oi.Order_Item_ID AS order_item_id,
        oi.Order_ID_fk AS order_id,
        c.CUSTOMER_HK AS customer_dim_key,
        ca.CUSTOMER_ADDRESS_HK AS customer_address_dim_key,
        r.RESTAURANT_HK AS restaurant_dim_key,
        rl.restaurant_location_hk AS restaurant_location_dim_key,
        m.Menu_Dim_HK AS menu_dim_key,
        da.DELIVERY_AGENT_HK AS delivery_agent_dim_key,
        dd.DATE_DIM_HK AS order_date_dim_key,
        oi.Quantity::number(2) AS quantity,
        oi.Price AS price,
        oi.Subtotal AS subtotal,
        d.delivery_status AS delivery_status,
        d.estimated_time AS estimated_time
    FROM clean_sch.order_item oi
    JOIN clean_sch.orders o ON oi.Order_ID_fk = o.Order_ID
    JOIN clean_sch.delivery d ON o.Order_ID = d.Order_ID_fk
    JOIN consumption_sch.customer_dim c ON o.Customer_ID_fk = c.customer_id
    JOIN consumption_sch.customer_address_dim ca ON c.Customer_ID = ca.CUSTOMER_ID_fk
    JOIN consumption_sch.restaurant_dim r ON o.Restaurant_ID_fk = r.restaurant_id
    JOIN consumption_sch.menu_dim m ON oi.MENU_ID_fk = m.menu_id
    JOIN consumption_sch.delivery_agent_dim da ON d.Delivery_Agent_ID_fk = da.delivery_agent_id
    JOIN consumption_sch.restaurant_location_dim rl ON r.LOCATION_ID_FK = rl.location_id
    JOIN consumption_sch.date_dim dd ON dd.calendar_date = DATE(o.order_date)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY oi.Order_Item_ID, oi.Order_ID_fk
        ORDER BY oi.Order_Item_ID
    ) = 1
) AS source_stm
ON target.order_item_id = source_stm.order_item_id
   AND target.order_id = source_stm.order_id
WHEN MATCHED THEN UPDATE SET
    target.customer_dim_key = source_stm.customer_dim_key,
    target.customer_address_dim_key = source_stm.customer_address_dim_key,
    target.restaurant_dim_key = source_stm.restaurant_dim_key,
    target.restaurant_location_dim_key = source_stm.restaurant_location_dim_key,
    target.menu_dim_key = source_stm.menu_dim_key,
    target.delivery_agent_dim_key = source_stm.delivery_agent_dim_key,
    target.order_date_dim_key = source_stm.order_date_dim_key,
    target.quantity = source_stm.quantity,
    target.price = source_stm.price,
    target.subtotal = source_stm.subtotal,
    target.delivery_status = source_stm.delivery_status,
    target.estimated_time = source_stm.estimated_time
WHEN NOT MATCHED THEN INSERT (
    order_item_id, order_id, customer_dim_key, customer_address_dim_key,
    restaurant_dim_key, restaurant_location_dim_key, menu_dim_key,
    delivery_agent_dim_key, order_date_dim_key, quantity, price, subtotal,
    delivery_status, estimated_time
) VALUES (
    source_stm.order_item_id, source_stm.order_id, source_stm.customer_dim_key,
    source_stm.customer_address_dim_key, source_stm.restaurant_dim_key,
    source_stm.restaurant_location_dim_key, source_stm.menu_dim_key,
    source_stm.delivery_agent_dim_key, source_stm.order_date_dim_key,
    source_stm.quantity, source_stm.price, source_stm.subtotal,
    source_stm.delivery_status, source_stm.estimated_time
);