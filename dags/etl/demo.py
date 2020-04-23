from airflow import DAG
from airflow.operators.papermill_operator import PapermillOperator

from datetime import datetime, timedelta

default_args = {
    "owner": "jasper",
    "depends_on_past": False,
    "start_date": datetime(2020, 4, 23, 10),
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
    'schedule_interval': '@daily',
}

etl_1_parameters = {
    "date": "2020-04-23"
}

etl_2_parameters = {
    "query": "../../../resources/jasper/demo/query.sql"
}

dag = DAG(
    "notebook-etl",
    description="Demo of presto ETL run through a notebook",
    default_args=default_args,
)

etl_1 = PapermillOperator(
    task_id="presto-etl",
    input_nb="notebooks/jasper/demo/etl.ipynb",
    output_nb="/tmp/etl-output.ipynb",
    parameters=etl_1_parameters,
    dag=dag,
)

etl_2 = PapermillOperator(
    task_id="pandas-render",
    input_nb="notebooks/jasper/demo/analysis.ipynb",
    # output_nb="s3://eb-df-prod-jupyter-data/jasper/demo/output_nb.ipynb",
    output_nb="/tmp/analysis-output.ipynb",
    parameters=etl_2_parameters,
    dag=dag,
)

etl_1 >> [etl_2]
