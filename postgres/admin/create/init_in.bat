rem create bases and roles for students
psql -h 192.168.54.21 -p 5432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_create_db.sql
psql -h 192.168.54.21 -p 5432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_create_roles.sql
rem psql --host="spsu.ru" --port=55432 --username="solovenko" -c "SET CLIENT_ENCODING TO 'utf8'" -f preliminary_preparation.sql
Pause