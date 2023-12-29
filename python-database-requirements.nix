# Packages to support the database not listed in the base requirements.txt
{ ps }:
with ps; [
  psycopg2
  pgcli
  mysqlclient
  mariadb
]