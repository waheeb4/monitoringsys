FROM mysql:9.7

ENV MYSQL_ROOT_PASSWORD=my-pwd

COPY schema.sql /docker-entrypoint-initdb.d/schema.sql
