from airflow import DAG
from airflow.operators.papermill_operator import PapermillOperator

default_args = {
    "owner": "jasper",
    "depends_on_past": False,
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
    default_args=default_args
)

etl_1 = PapermillOperator(
    task_id="presto-etl",
    input_nb="notebooks/jasper/demo/etl.ipynb",
    parameters=etl_1_parameters,
)

etl_2 = PapermillOperator(
    task_id="pandas-render",
    input_nb="notebooks/jasper/demo/analysis.ipynb",
    output_nb="s3://eb-df-prod-jupyter-data/jasper/demo/output_nb.ipynb",
    parameters=etl_2_parameters,
)

etl_1 >> etl_2
