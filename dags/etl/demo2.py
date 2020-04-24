from airflow import DAG
from airflow.operators.python_operator import PythonOperator

import pandas as pd

from datetime import datetime, timedelta

from library.etl.presto import PrestoETLClient

default_args = {
    "owner": "jasper",
    "depends_on_past": False,
    "start_date": datetime(2020, 4, 23, 10),
    "retries": 0,
    "retry_delay": timedelta(minutes=2),
    'schedule_interval': '@daily',
}

etl_1_parameters = [
    {
        "query": "../../resources/jasper/demo/drop.sql"
    },
    {
        "query": "../../resources/jasper/demo/ctas.sql",
        "parameters": {
            "date": datetime.today() - timedelta(days=1)
        }
    }
]

dag = DAG(
    "python-etl",
    description="Demo of presto ETL run through python",
    default_args=default_args,
)

presto_etl = PrestoETLClient(etl_1_parameters, default_args.get('owner'), 'presto-1.prod.dataf.eb')
etl_1 = PythonOperator(
    task_id='SomePrestoETL',
    python_callable=presto_etl.run(),
    dag=dag
)

def write_to_s3():
    presto_etl.select("SELECT")