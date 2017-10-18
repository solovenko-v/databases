rem create bases and roles for students
psql -h 192.168.54.21 -p 5432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_drop_db.sql
psql -h 192.168.54.21 -p 5432 -d postgres -U solovenko -c "SET CLIENT_ENCODING TO 'utf8'" -f init_drop_roles.sql
Pause