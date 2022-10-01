CREATE SOURCE CONNECTOR DATAGEN_00_FINANCE WITH (
	 'connector.class'= 'io.confluent.kafka.connect.datagen.DatagenConnector',
            'key.converter'= 'org.apache.kafka.connect.storage.StringConverter',
            'value.converter'='io.confluent.connect.avro.AvroConverter',
            'value.converter.schema.registry.url'= 'http://schema-registry:8081',
            'kafka.topic'= 'campaign_finance',
            'max.interval'=750,
            'quickstart'= 'campaign_finance',
            'tasks.max'= 1
);

CREATE STREAM DEM_CONTRIBUTIONS AS SELECT * FROM FINANCE WHERE PARTY_AFFILIATION='DEM' EMIT CHANGES;

CREATE STREAM REP_CONTRIBUTIONS AS SELECT * FROM FINANCE WHERE PARTY_AFFILIATION='REP' EMIT CHANGES;

CREATE SINK CONNECTOR MYSQL_SINK_FINANCE_00 WITH (
      'connector.class'='io.confluent.connect.jdbc.JdbcSinkConnector',
    'connection.url'     ='jdbc:mysql://mysql:3306/demo',
    'topics'             ='campaign_finance',
    'key.converter'      ='org.apache.kafka.connect.storage.StringConverter',
    'value.converter'    ='io.confluent.connect.avro.AvroConverter',
    'value.converter.schema.registry.url'='http://schema-registry:8081',
    'connection.user'    ='msql_user',
    'connection.password'='Passw@rd',
    'auto.create'        ='true',
    'auto.evolve'        ='true',
    'insert.mode'        ='insert'
);

CREATE SINK CONNECTOR MONGO_SINK_FINANCE_DEMS_00 WITH (
    'connector.class'='com.mongodb.kafka.connect.MongoSinkConnector',
    'tasks.max'='1',
    'connection.uri'='mongodb://mongo:mongo@mongo:27017',
    'database'='Kafka',
    'collection'='dem_contributions',
    'topics'='DEM_CONTRIBUTIONS'
);

CREATE SINK CONNECTOR MONGO_SINK_FINANCE_REPS_01 WITH (
    'connector.class'='com.mongodb.kafka.connect.MongoSinkConnector',
    'tasks.max'='1',
    'connection.uri'='mongodb://mongo:mongo@mongo:27017',
    'database'='Kafka',
    'collection'='rep_contributions',
    'topics'='REP_CONTRIBUTIONS'
);

CREATE SOURCE CONNECTOR DBZM_SOURCE_MYSQL_00 WITH (
    'connector.class' = 'io.debezium.connector.mysql.MySqlConnector',
    'database.hostname' = 'mysql',
    'database.port' = '3306',
    'database.user' = 'debezium',
    'database.password' = 'dbz',
    'key.converter'= 'org.apache.kafka.connect.storage.StringConverter',
    'value.converter'= 'io.confluent.connect.avro.AvroConverter',
    'value.converter.schema.registry.url'= 'http://schema-registry:8081'
    'database.server.id' = '426',
    'database.server.name' = 'demo',
    'database.history.kafka.bootstrap.servers' = 'broker:29092',
    'database.history.kafka.topic' = 'dbhistory.demo' ,
    );