rem create bases and roles for students
psql -h spsu.ru -p 55432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_drop_db.sql
psql -h spsu.ru -p 55432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_drop_roles.sql
Pause