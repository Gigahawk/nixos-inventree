{ ps }:
with ps; [
  # Invoke is required for many admin tasks, for some reason it's not included
  invoke
  # Packages to support the database not listed in the base requirements.txt
  psycopg2
  pgcli
  mysqlclient
  mariadb
]