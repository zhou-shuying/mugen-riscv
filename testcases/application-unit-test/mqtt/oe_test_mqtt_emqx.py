#!/usr/bin/python3

# Copyright (c) 2021. Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
####################################
# @Author    	:   Your Name
# @Contact   	:   your.email@example.com
# @Date      	:   2024-10-22
# @License   	:   Mulan PSL v2
# @Desc      	:   Test case for MQTT message exchange using EMQX as broker
#####################################

import os
import sys
import time
import paho.mqtt.client as mqtt

# Global variables
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "test/topic"
MQTT_MSG = "Hello MQTT"
CLIENT1_ID = "mqtt_client_pub"
CLIENT2_ID = "mqtt_client_sub"
received_message = None
ret = 0

# Callback for when a message is received by the client
def on_message(client, userdata, msg):
    global received_message
    received_message = msg.payload.decode()

# Set up MQTT clients and connection
try:
    # Publisher Client
    client_pub = mqtt.Client(CLIENT1_ID)
    client_pub.connect(MQTT_BROKER, MQTT_PORT, 60)

    # Subscriber Client
    client_sub = mqtt.Client(CLIENT2_ID)
    client_sub.on_message = on_message
    client_sub.connect(MQTT_BROKER, MQTT_PORT, 60)
    client_sub.subscribe(MQTT_TOPIC, qos=1)

    # Start the subscriber loop in a separate thread
    client_sub.loop_start()

    # Give time for subscriber to start properly
    time.sleep(2)

    # Publisher sends the message
    print(f"Publishing message: {MQTT_MSG}")
    client_pub.publish(MQTT_TOPIC, MQTT_MSG)

    # Wait for message to be received
    time.sleep(5)

    # Stop the subscriber loop
    client_sub.loop_stop()

    # Check if message was received correctly
    if received_message != MQTT_MSG:
        print(f"Received message is incorrect: {received_message}")
        ret += 1
    else:
        print(f"Message received correctly: {received_message}")

except Exception as e:
    print(f"Error during MQTT message exchange: {e}")
    ret += 1

# Exit with the appropriate return code
sys.exit(ret)
