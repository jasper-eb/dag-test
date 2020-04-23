SELECT
    org_id,
    SUM(free_tix) AS total_free_tickets,
    SUM(paid_tix) AS total_paid_tickets,
    SUM(total_gtf) AS total_gtf

FROM hive.team_data_foundry.data_science_airflow_demo

GROUP BY 1
