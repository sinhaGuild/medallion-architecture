# Creating connectors in KSQLdb as part of docker-compose

```json
#
        echo "Waiting for Kafka Connect to start listening on $$KSQL_CONNECT_REST_ADVERTISED_HOST_NAME ⏳"
        while : ; do
          curl_status=$$(curl -s -o /dev/null -w %{http_code} http://$$KSQL_CONNECT_REST_ADVERTISED_HOST_NAME:$$KSQL_CONNECT_REST_PORT/connectors)
          echo -e $$(date) " Kafka Connect listener HTTP state: " $$curl_status " (waiting for 200)"
          if [ $$curl_status -eq 200 ] ; then
            break
          fi
          sleep 5
        done
        #
        echo "Creating connector"
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-01/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "ratings",
            "max.interval":750,
            "quickstart": "ratings",
            "tasks.max": 1
        }'
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-item_details_01/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "item_details_01",
            "max.interval":1,
            "iterations":1000,
            "schema.filename": "/data/schema/item_details.avsc",
            "schema.keyfield": "id",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
          }'
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-orders-us/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "kafka.topic": "orders",
            "schema.filename": "/data/schema/orders_us.avsc",
            "schema.keyfield": "orderid",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
        }'
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-orders-uk/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "kafka.topic": "orders_uk",
            "schema.filename": "/data/schema/orders_uk.avsc",
            "schema.keyfield": "orderid",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
        }'
```

# Confluent control center service

```yml
control-center:
  image: confluentinc/cp-enterprise-control-center:7.0.1
  container_name: control-center
  depends_on:
    - broker
    - schema-registry
  ports:
    - "9021:9021"
  environment:
    CONTROL_CENTER_BOOTSTRAP_SERVERS: "broker:29092"
    CONTROL_CENTER_CONNECT_CONNECT_CLUSTER: "ksqldb:8083"
    CONTROL_CENTER_SCHEMA_REGISTRY_URL: "http://schema-registry:8081"
    CONTROL_CENTER_KSQL_KSQLDB_URL: "http://ksqldb:8088"
    # The advertised URL needs to be the URL on which the browser
    #  can access the KSQL server (e.g. http://localhost:8088/info)
    CONTROL_CENTER_KSQL_KSQLDB_ADVERTISED_URL: "http://localhost:8088"
    # -v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v
    # Useful settings for development/laptop use - modify as needed for Prod
    CONFLUENT_METRICS_TOPIC_REPLICATION: 1
    CONTROL_CENTER_REPLICATION_FACTOR: 1
    CONTROL_CENTER_COMMAND_TOPIC_REPLICATION: 1
    CONTROL_CENTER_MONITORING_INTERCEPTOR_TOPIC_REPLICATION: 1
    CONTROL_CENTER_INTERNAL_TOPICS_PARTITIONS: 1
    CONTROL_CENTER_INTERNAL_TOPICS_REPLICATION: 1
    CONTROL_CENTER_MONITORING_INTERCEPTOR_TOPIC_PARTITIONS: 1
    CONTROL_CENTER_STREAMS_NUM_STREAM_THREADS: 1
    CONTROL_CENTER_STREAMS_CACHE_MAX_BYTES_BUFFERING: 104857600
  command:
    - bash
    - -c
    - |
      echo "Waiting two minutes for Kafka brokers to start and 
             necessary topics to be available"
      sleep 120  
      /etc/confluent/docker/run
```

# Import saved objects into kibana

```yml
command:
  - bash
  - -c
  - |
    /usr/local/bin/kibana-docker &
    echo "Waiting for Kibana to be ready ⏳"
    while [ $$(curl -H 'kbn-xsrf: true' -s -o /dev/null -w %{http_code} http://localhost:5601/api/saved_objects/_find?type=index-pattern&search_fields=title&search=*) -ne 200 ] ; do 
      echo -e "\t" $$(date) " Kibana saved objects request response: " $$(curl -H 'kbn-xsrf: true' -o /dev/null -w %{http_code} -s http://localhost:5601/api/saved_objects/_find?type=index-pattern&search_fields=title&search=*) $$(curl -H 'kbn-xsrf: true' -s http://localhost:5601/api/saved_objects/_find?type=index-pattern&search_fields=title&search=*) " (waiting for 200)"
      sleep 5  
    done

    echo -e "\t" $$(date) " Kibana saved objects request response: " $$(curl -H 'kbn-xsrf: true' -o /dev/null -w %{http_code} -s http://localhost:5601/api/saved_objects/_find?type=index-pattern&search_fields=title&search=*) $$(curl -H 'kbn-xsrf: true' -s http://localhost:5601/api/saved_objects/_find?type=index-pattern&search_fields=title&search=*)

    echo -e "\n--\n+> Pre-creating index pattern"
    curl -s -XPOST 'http://localhost:5601/api/saved_objects/index-pattern/orders_enriched' \
      -H 'kbn-xsrf: nevergonnagiveyouup' \
      -H 'Content-Type: application/json' \
      -d '{"attributes":{"title":"orders_enriched","timeFieldName":"ORDER_TIMESTAMP"}}'

    echo -e "\n--\n+> Setting the index pattern as default"
    curl -s -XPOST 'http://localhost:5601/api/kibana/settings' \
      -H 'kbn-xsrf: nevergonnagiveyouup' \
      -H 'content-type: application/json' \
      -d '{"changes":{"defaultIndex":"orders_enriched"}}'

    echo -e "\n--\n+> Opt out of Kibana telemetry"
    curl 'http://localhost:5601/api/telemetry/v2/optIn' \
        -H 'kbn-xsrf: nevergonnagiveyouup' \
        -H 'content-type: application/json' \
        -H 'accept: application/json' \
        --data-binary '{"enabled":false}' \
        --compressed

    sleep infinity
```

# Additional Databases

```yml
postgres:
  # *-----------------------------*
  # To connect to the DB:
  #   docker exec -it postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DB'
  # *-----------------------------*
  image: postgres:11
  container_name: postgres
  environment:
    - POSTGRES_USER=postgres
    - POSTGRES_PASSWORD=postgres
  volumes:
    - ./data/postgres:/docker-entrypoint-initdb.d/
```
