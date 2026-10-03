
use role sysadmin;
use warehouse adhoc_wh;
use database bigdata_db;

-- delete al the stage data
delete from  bigdata_db.STAGE_SCH.CUSTOMER;
delete from  bigdata_db.STAGE_SCH.CUSTOMERADDRESS;
delete from  bigdata_db.STAGE_SCH.DELIVERY;
delete from  bigdata_db.STAGE_SCH.DELIVERYAGENT;
delete from  bigdata_db.STAGE_SCH.LOCATION;
delete from  bigdata_db.STAGE_SCH.MENU;
delete from  bigdata_db.STAGE_SCH.ORDERITEM;
delete from  bigdata_db.STAGE_SCH.ORDERS;
delete from  bigdata_db.STAGE_SCH.RESTAURANT;

-- clean the stream objects in stage
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.CUSTOMER_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.CUSTOMERADDRESS_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.DELIVERY_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.DELIVERYAGENT_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.LOCATION_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.MENU_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.ORDERITEM_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.ORDERS_stm;
create or replace temporary table x as select * from bigdata_db.STAGE_SCH.RESTAURANT_stm;

-- delete all clean data
delete from bigdata_db.CLEAN_SCH.CUSTOMER;
delete from bigdata_db.CLEAN_SCH.CUSTOMER_ADDRESS;
delete from bigdata_db.CLEAN_SCH.DELIVERY;
delete from bigdata_db.CLEAN_SCH.DELIVERY_AGENT;
delete from bigdata_db.CLEAN_SCH.MENU;
delete from bigdata_db.CLEAN_SCH.ORDERS;
delete from bigdata_db.CLEAN_SCH.ORDER_ITEM;
delete from bigdata_db.CLEAN_SCH.RESTAURANT;
delete from bigdata_db.CLEAN_SCH.RESTAURANT_LOCATION;


-- clean the stream objects in clean
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.CUSTOMER_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.CUSTOMER_ADDRESS_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.DELIVERY_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.DELIVERY_AGENT_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.MENU_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.ORDERS_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.ORDER_ITEM_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.RESTAURANT_stm;
create or replace temporary table x as select * from bigdata_db.CLEAN_SCH.RESTAURANT_LOCATION_stm;


-- delete all the consumption layer objects
delete from bigdata_db.CONSUMPTION_SCH.CUSTOMER_ADDRESS_DIM;
delete from bigdata_db.CONSUMPTION_SCH.CUSTOMER_DIM;
delete from bigdata_db.CONSUMPTION_SCH.DATE_DIM;
delete from bigdata_db.CONSUMPTION_SCH.DELIVERY_AGENT_DIM;
delete from bigdata_db.CONSUMPTION_SCH.MENU_DIM;
delete from bigdata_db.CONSUMPTION_SCH.ORDER_ITEM_FACT;
delete from bigdata_db.CONSUMPTION_SCH.RESTAURANT_DIM;
delete from bigdata_db.CONSUMPTION_SCH.RESTAURANT_LOCATION_DIM;

-- also load the data once again by force

copy into stage_sch.location (locationid, city, state, zipcode, activeflag, 
                        createddate, modifieddate, _stg_file_name, 
                        _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
        from (
            select 
                t.$1::text as locationid,
                t.$2::text as city,
                t.$3::text as state,
                t.$4::text as zipcode,
                t.$5::text as activeflag,
                t.$6::text as createddate,
                t.$7::text as modifieddate,
                metadata$filename as _stg_file_name,
                metadata$file_last_modified as _stg_file_load_ts,
                metadata$file_content_key as _stg_file_md5,
                current_timestamp as _copy_data_ts
            from @stage_sch.csv_stg/location/ t
        )
        file_format = (format_name = 'stage_sch.csv_file_format')
        force = true
        on_error = continue;

copy into stage_sch.restaurant (restaurantid, name, cuisinetype, pricing_for_2, restaurant_phone, 
                      operatinghours, locationid, activeflag, openstatus, 
                      locality, restaurant_address, latitude, longitude, 
                      createddate, modifieddate, 
                      _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
        from (
            select 
                t.$1::number as restaurantid,        -- restaurantid as the first column
                t.$2::text as name,
                t.$3::text as cuisinetype,
                t.$4::text as pricing_for_2,
                t.$5::text as restaurant_phone,
                t.$6::text as operatinghours,
                t.$7::text as locationid,
                t.$8::text as activeflag,
                t.$9::text as openstatus,
                t.$10::text as locality,
                t.$11::text as restaurant_address,
                t.$12::text as latitude,
                t.$13::text as longitude,
                t.$14::text as createddate,
                t.$15::text as modifieddate,
                -- audit columns for tracking & debugging
                metadata$filename as _stg_file_name,
                metadata$file_last_modified as _stg_file_load_ts,
                metadata$file_content_key as _stg_file_md5,
                current_timestamp() as _copy_data_ts
            from @stage_sch.csv_stg/restaurant/ t
        )
        file_format = (format_name = 'stage_sch.csv_file_format')
        force = true
        on_error = continue;

copy into stage_sch.delivery (deliveryid,orderid, deliveryagentid, deliverystatus, 
                    estimatedtime, addressid, deliverydate, createddate, 
                    modifieddate, _stg_file_name, _stg_file_load_ts, 
                    _stg_file_md5, _copy_data_ts)
        from (
            select 
                t.$1::number as deliveryid,
                t.$2::text as orderid,
                t.$3::text as deliveryagentid,
                t.$4::text as deliverystatus,
                t.$5::text as estimatedtime,
                t.$6::text as addressid,
                t.$7::text as deliverydate,
                t.$8::text as createddate,
                t.$9::text as modifieddate,
                metadata$filename as _stg_file_name,
                metadata$file_last_modified as _stg_file_load_ts,
                metadata$file_content_key as _stg_file_md5,
                current_timestamp as _copy_data_ts
            from @stage_sch.csv_stg/delivery/ t
        )
        file_format = (format_name = 'stage_sch.csv_file_format')
        force = true
        on_error = continue;

copy into stage_sch.orders (orderid, customerid, restaurantid, orderdate, totalamount, 
                  status, paymentmethod, createddate, modifieddate,
                  _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
        from (
            select 
                t.$1::number as orderid,
                t.$2::text as customerid,
                t.$3::text as restaurantid,
                t.$4::text as orderdate,
                t.$5::text as totalamount,
                t.$6::text as status,
                t.$7::text as paymentmethod,
                t.$8::text as createddate,
                t.$9::text as modifieddate,
                metadata$filename as _stg_file_name,
                metadata$file_last_modified as _stg_file_load_ts,
                metadata$file_content_key as _stg_file_md5,
                current_timestamp as _copy_data_ts
            from @stage_sch.csv_stg/orders/ t
        )
        file_format = (format_name = 'stage_sch.csv_file_format')
        force = true
        on_error = continue;

copy into stage_sch.orderitem (orderitemid, orderid, menuid, quantity, price, 
                     subtotal, createddate, modifieddate,
                     _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts)
        from (
            select 
                t.$1::number as orderitemid,
                t.$2::text as orderid,
                t.$3::text as menuid,
                t.$4::text as quantity,
                t.$5::text as price,
                t.$6::text as subtotal,
                t.$7::text as createddate,
                t.$8::text as modifieddate,
                metadata$filename as _stg_file_name,
                metadata$file_last_modified as _stg_file_load_ts,
                metadata$file_content_key as _stg_file_md5,
                current_timestamp as _copy_data_ts
            from @stage_sch.csv_stg/order-items/ t
        )
        file_format = (format_name = 'stage_sch.csv_file_format')
        force = true
        on_error = continue;

