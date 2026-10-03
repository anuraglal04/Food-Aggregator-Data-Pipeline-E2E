use role sysadmin;
use warehouse adhoc_wh;
use database bigdata_db;

create or replace task common.main_pipeline_task
    warehouse = adhoc_wh
    schedule = '3 minute'
    as
    select 'Running Big Data + Task Based Pipeline > ' || current_timestamp() ;

-- all copy task would be the child task of main_pipeline_task
create or replace task common.copy_csv2stg_location_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_location_sp();

create or replace task common.copy_csv2stg_restaurant_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_restaurant_sp();

create or replace task common.copy_csv2stg_customer_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_customer_sp();

create or replace task common.copy_csv2stg_customer_address_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_customer_address_sp();

create or replace task common.copy_csv2stg_menu_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_menu_sp();

create or replace task common.copy_csv2stg_delivery_agent_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_delivery_agent_sp();

create or replace task common.copy_csv2stg_delivery_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_delivery_sp();

create or replace task common.copy_csv2stg_orders_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_orders_sp();

create or replace task common.copy_csv2stg_order_items_tsk
    warehouse = adhoc_wh
    AFTER common.main_pipeline_task
        as
    call stage_sch.copy_csv2stg_order_items_sp();


-- level2
-- all copy task would be the child task of main_pipeline_task
create or replace task common.s2c_location_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_location_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.location_stm')
        as
    call stage_sch.s2c_location_sp();

create or replace task common.s2c_restaurant_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_restaurant_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.restaurant_stm')
        as
    call stage_sch.s2c_restaurant_sp();

create or replace task common.s2c_customer_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_customer_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.customer_stm')
        as
    call stage_sch.s2c_customer_sp();

create or replace task common.s2c_customer_address_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_customer_address_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.customeraddress_stm')
        as
    call stage_sch.s2c_customer_address_sp();

create or replace task common.s2c_menu_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_menu_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.menu_stm')
        as
    call stage_sch.s2c_menu_sp();

create or replace task common.s2c_delivery_agent_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_delivery_agent_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.deliveryagent_stm')
        as
    call stage_sch.s2c_delivery_agent_sp();

create or replace task common.s2c_delivery_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_delivery_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.delivery_stm')
        as
    call stage_sch.s2c_delivery_sp();


create or replace task common.s2c_orders_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_orders_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.orders_stm')
        as
    call stage_sch.s2c_orders_sp();


create or replace task common.s2c_order_items_tsk
    warehouse = adhoc_wh
    AFTER common.copy_csv2stg_order_items_tsk
    when
    system$stream_has_data('bigdata_db.stage_sch.orderitem_stm')
        as
    call stage_sch.s2c_order_items_sp();


-- Level-3 
-- ----------------------------------------------------------
-- all merge statement depends on previous one
create or replace task common.c2c_location_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_location_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.restaurant_location_stm')
        as
    call clean_sch.c2c_location_sp();

create or replace task common.c2c_restaurant_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_restaurant_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.restaurant_stm')
        as
    call clean_sch.c2c_restaurant_sp();

create or replace task common.c2c_customer_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_customer_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.customer_stm')
        as
    call clean_sch.c2c_customer_sp();

create or replace task common.c2c_customer_address_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_customer_address_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.customer_address_stm')
        as
    call clean_sch.c2c_customer_address_sp();

create or replace task common.c2c_menu_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_menu_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.menu_stm')
        as
    call clean_sch.c2c_menu_sp();

create or replace task common.c2c_delivery_agent_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_delivery_agent_tsk
    when
    system$stream_has_data('bigdata_db.clean_sch.delivery_agent_stm')
        as
    call clean_sch.c2c_delivery_agent_sp();

create or replace task common.date_dim_tsk
    warehouse = adhoc_wh
    AFTER common.s2c_orders_tsk
        as
    call clean_sch.date_dim_sp();

-- Layer-3.1
create or replace task common.order_item_fact_tsk
    warehouse = adhoc_wh
    AFTER common.date_dim_tsk, common.c2c_location_tsk, common.c2c_restaurant_tsk,common.c2c_customer_tsk,common.c2c_customer_address_tsk,common.c2c_menu_tsk,common.c2c_delivery_agent_tsk, common.s2c_orders_tsk, common.s2c_order_items_tsk,common.s2c_delivery_tsk
        as
    call clean_sch.fact_table_sp();

call clean_sch.fact_table_sp();



alter task common.order_item_fact_tsk resume;
alter task common.date_dim_tsk resume;
alter task common.c2c_delivery_agent_tsk resume;
alter task common.c2c_menu_tsk resume;
alter task common.c2c_customer_address_tsk resume;
alter task common.c2c_customer_tsk resume;
alter task common.c2c_restaurant_tsk resume;
alter task common.c2c_location_tsk resume;
alter task common.s2c_order_items_tsk resume;
alter task common.s2c_orders_tsk resume;
alter task common.s2c_delivery_tsk resume;
alter task common.s2c_delivery_agent_tsk resume;
alter task common.s2c_menu_tsk resume;
alter task common.s2c_customer_address_tsk resume;
alter task common.s2c_customer_tsk resume;
alter task common.s2c_restaurant_tsk resume;
alter task common.s2c_location_tsk resume;
alter task common.copy_csv2stg_order_items_tsk resume;
alter task common.copy_csv2stg_orders_tsk resume;
alter task common.copy_csv2stg_delivery_tsk resume;
alter task common.copy_csv2stg_delivery_agent_tsk resume;
alter task common.copy_csv2stg_menu_tsk resume;
alter task common.copy_csv2stg_customer_address_tsk resume;
alter task common.copy_csv2stg_customer_tsk resume;
alter task common.copy_csv2stg_restaurant_tsk resume;
alter task common.copy_csv2stg_location_tsk resume;

alter task common.main_pipeline_task resume;



--------------------------------------------------------

alter task common.main_pipeline_task suspend;

alter task common.copy_csv2stg_location_tsk suspend;
alter task common.copy_csv2stg_restaurant_tsk suspend;
alter task common.copy_csv2stg_customer_tsk suspend;
alter task common.copy_csv2stg_customer_address_tsk suspend;
alter task common.copy_csv2stg_menu_tsk suspend;
alter task common.copy_csv2stg_delivery_agent_tsk suspend;
alter task common.copy_csv2stg_delivery_tsk suspend;
alter task common.copy_csv2stg_orders_tsk suspend;
alter task common.copy_csv2stg_order_items_tsk suspend;
alter task common.s2c_location_tsk suspend;
alter task common.s2c_restaurant_tsk suspend;
alter task common.s2c_customer_tsk suspend;
alter task common.s2c_customer_address_tsk suspend;
alter task common.s2c_menu_tsk suspend;
alter task common.s2c_delivery_agent_tsk suspend;
alter task common.s2c_delivery_tsk suspend;
alter task common.s2c_orders_tsk suspend;
alter task common.s2c_order_items_tsk suspend;
alter task common.c2c_location_tsk suspend;
alter task common.c2c_restaurant_tsk suspend;
alter task common.c2c_customer_tsk suspend;
alter task common.c2c_customer_address_tsk suspend;
alter task common.c2c_menu_tsk suspend;
alter task common.c2c_delivery_agent_tsk suspend;
alter task common.date_dim_tsk suspend;
alter task common.order_item_fact_tsk suspend;

SELECT *
FROM TABLE(BIGDATA_DB.INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'MAIN_PIPELINE_TASK'
ORDER BY SCHEDULED_TIME;

