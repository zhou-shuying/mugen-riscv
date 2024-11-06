#!/usr/bin/bash

# Licensed under Mulan PSL v2.
# @Desc       : Test case for MQTTX MQTT message publishing and subscription using multiple clients

source ${OET_PATH}/libs/locallibs/common_lib.sh

function config_params() {
    LOG_INFO "Start to config params of the case."

    # Verify if EMQX_HOME is set
    if [ -z "${EMQX_HOME}" ]; then
        LOG_ERROR "EMQX_HOME is not set. Please set EMQX_HOME to the EMQX installation directory."
        exit 1
    fi

    LOG_INFO "End to config params of the case."
}

function pre_test() {
    LOG_INFO "Start to prepare the test environment."

    # Download and install MQTTX
    LOG_INFO "Downloading and installing MQTTX..."
    wget https://github.com/emqx/MQTTX/releases/download/v1.8.0/MQTTX-1.8.0-linux-x86_64.AppImage -O /usr/local/bin/mqttx
    chmod +x /usr/local/bin/mqttx
    if [[ $? -ne 0 ]]; then
        LOG_ERROR "Failed to download and install MQTTX."
        exit 1
    fi

    LOG_INFO "End to prepare the test environment."
}

function run_test() {
    LOG_INFO "Start to run test."

    # Setup parameters
    MQTT_BROKER="localhost"
    MQTT_PORT="1883"
    MQTT_TOPIC="test/topic"
    MQTT_MSG="Hello MQTT"
    CLIENT1="mqttx_pub"
    CLIENT2="mqttx_sub"

    # Step 1: Use MQTTX client to subscribe and keep waiting for message
    RECEIVED_MSG=""
    (RECEIVED_MSG=$(mqttx sub --host $MQTT_BROKER --port $MQTT_PORT --topic $MQTT_TOPIC --client-id $CLIENT2 --qos 0 --timeout 15) &)
    sleep 2  # Ensure subscription is ready

    # Step 2: Use MQTTX client to publish a message
    LOG_INFO "Publishing message: $MQTT_MSG"
    mqttx pub --host $MQTT_BROKER --port $MQTT_PORT --topic $MQTT_TOPIC --client-id $CLIENT1 --message "$MQTT_MSG"
    CHECK_RESULT $? 0 0 "Failed to publish message from $CLIENT1."

    # Step 3: Wait and verify the received message
    sleep 5
    if [ "$RECEIVED_MSG" == "$MQTT_MSG" ]; then
        LOG_INFO "Message received correctly: $RECEIVED_MSG"
    else
        LOG_ERROR "Received message is incorrect or empty: '$RECEIVED_MSG'"
        exit 1
    fi

    LOG_INFO "End to run test."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."

    # Remove MQTTX
    LOG_INFO "Uninstalling MQTTX..."
    rm -f /usr/local/bin/mqttx
    if [[ $? -ne 0 ]]; then
        LOG_ERROR "Failed to remove MQTTX."
    fi

    LOG_INFO "End to restore the test environment."
}

main "$@"
