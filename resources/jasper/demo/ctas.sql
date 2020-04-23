CREATE TABLE hive.team_data_foundry.data_science_airflow_demo
WITH (format = 'parquet')
AS
select
    event.event_id,
    event.org_id,
    coalesce(sum(f.f_free_item_qty),0) as free_tix,
    coalesce(sum(f.f_paid_item_qty),0) as paid_tix, -- this paid tickets includes offline
    cast(coalesce(sum(f.f_gts_usd),0) as double) as total_gts,
    cast(coalesce(sum(f.f_gtf_usd),0) as double) as total_gtf,
    case when sum(f.f_paid_item_qty) > 0 then (sum(f.f_gts_usd) * 1.0)/sum(f.f_paid_item_qty) else 0 end as atv_usd,
    coalesce(case when ((sum(f.f_item_qty) * 1.0)>avg(event.capacity)) then 1.0 else (sum(f.f_item_qty) * 1.0) / avg(event.capacity) end, 0) as sell_thru

from hive.team_data_insights.value_tier_event_level_data event
left join hive.dw.f_ticket_merchandise_purchase f
    on event.event_id = f.event_id and f.is_valid = 'y'
    and f.q_order_payment_type not in ('manual') -- joining on these to get the params we need

-- where f.trx_date >= '{{date}}'

group by 1,2
