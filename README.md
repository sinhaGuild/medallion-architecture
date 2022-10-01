## KSQL DB Installation parameters

> ### Through docker-compose

```bash
command:
      # In the command section, $ are replaced with $$ to avoid the error 'Invalid interpolation format for "command" option'
      - bash
      - -c
      - |
        #
        echo "Installing connector plugins"
        mkdir -p /home/appuser/confluent-hub-components/

        /home/appuser/bin/confluent-hub install --no-prompt --component-dir /home/appuser/confluent-hub-components/ --worker-configs /dev/null confluentinc/kafka-connect-datagen:0.6.0

        /home/appuser/bin/confluent-hub install --no-prompt --component-dir /home/appuser/confluent-hub-components/ --worker-configs /dev/null confluentinc/kafka-connect-elasticsearch:11.0.0

        /home/appuser/bin/confluent-hub install --no-prompt --component-dir /home/appuser/confluent-hub-components/ debezium/debezium-connector-mysql:1.9.3

        /home/appuser/bin/confluent-hub install --no-prompt --component-dir /home/appuser/confluent-hub-components/ debezium/debezium-connector-mongodb:1.9.3
```

> Creating connectors

```json
echo "Launching ksqlDB"
        /usr/bin/docker/run &
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

curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-item_details_01/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "kafka.topic": "item_details_01",
            "max.interval":1,
            "iterations":1000,
            "schema.filename": "/data/item_details.avsc",
            "schema.keyfield": "id",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
          }'
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-orders-us/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "kafka.topic": "orders",
            "schema.filename": "/data/orders_us.avsc",
            "schema.keyfield": "orderid",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
        }'
        curl -s -X PUT -H  "Content-Type:application/json" http://localhost:8083/connectors/source-datagen-orders-uk/config \
            -d '{
            "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
            "kafka.topic": "orders_uk",
            "schema.filename": "/data/orders_uk.avsc",
            "schema.keyfield": "orderid",
            "topic.creation.default.replication.factor": 1,
            "topic.creation.default.partitions": 6,
            "tasks.max": "1"
        }'
```
