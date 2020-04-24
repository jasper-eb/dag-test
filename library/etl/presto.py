import presto

from jinja2 import Template


class PrestoClient(object):
    def __init__(self, username, host, password=None, port=8080, https=False):
        self.username = username
        self.password = password
        self.host = host
        self.port = port
        self.https = https
        self.conn = None

    def _get_http_connection(self):
        conn = presto.dbapi.connect(
            host=self.host,
            port=self.port,
            user=self.username,
        )
        return conn

    def _get_https_connection(self):
        conn = presto.dbapi.connect(
            host=self.host,
            port=self.port,
            user=self.username,
            http_scheme='https',
            auth=presto.auth.BasicAuthentication(self.username, self.password),
        )
        return conn

    def get_connection(self):
        if self.conn:
            return self.conn

        if self.https:
            self.conn = self._get_https_connection()
            return self.conn
        else:
            self.conn = self._get_http_connection()
            return self.conn

    def get_cursor(self):
        if not self.conn:
            self.get_connection()
        return self.conn.cursor()

    def select(self, query):
        cur = self.get_connection().get_cursor()
        rs = cur.execute(query)
        return rs

    def transaction(self, query):
        conn = self.get_connection()
        cur = conn.get_cursor()
        cur.execute(query)
        conn.commit()


class PrestoETLClient(PrestoClient):
    def __init__(self, queries_dict, username, host, password=None, port=8080, https=False):
        super().__init__(username, password, host, port, https)
        self.queries_dict = queries_dict

    def _template_query(self, file_path, context={}):
        lines = '\n'.join(open(file_path, 'r').readlines())
        template = Template(lines)
        return template.render(**context)

    def run(self):
        for query, parameters in self.queries_dict:
            templated_query = self._template_query(query, parameters or {})
            self.transaction(templated_query)
