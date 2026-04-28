FROM mysql:latest

ENV MYSQL_ROOT_PASSWORD=my-pwd

COPY schema.sql /docker-entrypoint-initdb.d/schema.sql
