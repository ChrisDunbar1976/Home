import pyodbc
from contextlib import contextmanager

@contextmanager
def mssql(conn_str: str):
    cn = pyodbc.connect(conn_str, autocommit=False)
    try:
        yield cn
        cn.commit()
    except Exception:
        cn.rollback()
        raise
    finally:
        cn.close()
