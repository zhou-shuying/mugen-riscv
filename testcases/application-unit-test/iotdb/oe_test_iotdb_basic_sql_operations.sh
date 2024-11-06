#!/usr/bin/bash

# Copyright (c) 2024. Your Company.
# ALL rights reserved. Licensed under Mulan PSL v2.
# @Desc       : Shell test case for IoTDB to create table, insert data, query data and verify result

source ${OET_PATH}/libs/locallibs/common_lib.sh

function config_params() {
    LOG_INFO "Start to config params of the case."

    # 使用 IOTDB_HOME 环境变量找到 IoTDB CLI
    if [ -z "${IOTDB_HOME}" ]; then
        LOG_ERROR "IOTDB_HOME is not set. Please set IOTDB_HOME to the IoTDB installation directory."
        exit 1
    fi

    IOTDB_CLI="${IOTDB_HOME}/sbin/start-cli.sh"
    
    if [ ! -f "${IOTDB_CLI}" ]; then
        LOG_ERROR "IoTDB CLI not found at ${IOTDB_CLI}. Please check your IOTDB_HOME setting."
        exit 1
    fi

    LOG_INFO "IoTDB CLI found at ${IOTDB_CLI}."
    LOG_INFO "End to config params of the case."
}

function pre_test() {
    LOG_INFO "Start to prepare the test environment."

    # DNF_INSTALL "iotdb"  # 如果需要，安装 IoTDB
    #CHECK_RESULT $? 0 0 "IoTDB installation failed."
   
    LOG_INFO "No remote package installation needed."

    LOG_INFO "End to prepare the test environment."
}

function run_test() {
    LOG_INFO "Start to run test."

    # Step 1: 创建时间序列
    create_sql="CREATE TIMESERIES root.sg1.d1.s1 WITH DATATYPE=FLOAT, ENCODING=RLE"
    ${IOTDB_CLI} -e "${create_sql}"
    CHECK_RESULT $? 0 0 "Failed to create timeseries."

    # Step 2: 插入数据
    insert_sql="INSERT INTO root.sg1.d1(timestamp, s1) VALUES (1626006830000, 25.5)"
    ${IOTDB_CLI} -e "${insert_sql}"
    CHECK_RESULT $? 0 0 "Failed to insert data."

    # Step 3: 查询数据
    query_sql="SELECT s1 FROM root.sg1.d1"
    query_result=$(${IOTDB_CLI} -e "${query_sql}")
    echo "${query_result}" | grep "25.5"
    CHECK_RESULT $? 0 0 "Query result is incorrect."

    LOG_INFO "End to run test."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."

    # 清理测试数据，删除时间序列
    delete_sql="DELETE TIMESERIES root.sg1.d1.s1"
    ${IOTDB_CLI} -e "${delete_sql}"
    CHECK_RESULT $? 0 0 "Failed to delete timeseries."

    DNF_REMOVE
    LOG_INFO "End to restore the test environment."
}

main "$@"
