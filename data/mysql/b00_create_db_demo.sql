CREATE USER 'debezium'@'%' IDENTIFIED WITH mysql_native_password BY 'dbz';
CREATE USER 'replicator'@'%' IDENTIFIED BY 'replpass';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT  ON *.* TO 'debezium';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'replicator';
GRANT ALL PRIVILEGES ON demo.* TO 'debezium'@'%';

create database demo;

GRANT  SELECT, INSERT, UPDATE, DELETE ON demo.* TO mysql_user;
GRANT ALL PRIVILEGES ON demo.* TO 'mysql_user'@'%';
