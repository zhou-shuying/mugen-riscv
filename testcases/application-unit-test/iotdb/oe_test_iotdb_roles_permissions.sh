#!/usr/bin/bash

# Licensed under Mulan PSL v2.
# @Desc       : Test case for IoTDB role management and permission control using multiple users

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

    # 创建时间序列 root.sg1.d1.s1
    create_timeseries="CREATE TIMESERIES root.sg1.d1.s1 WITH DATATYPE=FLOAT, ENCODING=RLE"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${create_timeseries}"
    CHECK_RESULT $? 0 0 "Failed to create timeseries root.sg1.d1.s1."
    
    # 创建两个用户，user1 和 user2
    create_user1="CREATE USER user1 'password1'"
    create_user2="CREATE USER user2 'password2'"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${create_user1}"
    CHECK_RESULT $? 0 0 "Failed to create user1."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${create_user2}"
    CHECK_RESULT $? 0 0 "Failed to create user2."

    # 为 user1 创建一个专门的角色 role_user1，授予读写权限
    create_role_user1="CREATE ROLE role_user1"
    grant_write_privileges_user1="GRANT WRITE_DATA ON root.sg1.d1.s1 TO ROLE role_user1"
    grant_read_privileges_user1="GRANT READ_DATA ON root.sg1.d1.s1 TO ROLE role_user1"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${create_role_user1}"
    CHECK_RESULT $? 0 0 "Failed to create role_user1."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${grant_write_privileges_user1}"
    CHECK_RESULT $? 0 0 "Failed to grant write privileges to role_user1."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${grant_read_privileges_user1}"
    CHECK_RESULT $? 0 0 "Failed to grant read privileges to role_user1."

    # 将 role_user1 赋给 user1
    assign_role_to_user1="GRANT ROLE role_user1 TO user1"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${assign_role_to_user1}"
    CHECK_RESULT $? 0 0 "Failed to assign role_user1 to user1."

    # 为 user2 创建一个只读角色 role_user2，授予只读权限
    create_role_user2="CREATE ROLE role_user2"
    grant_read_privileges_user2="GRANT READ_DATA ON root.sg1.d1.s1 TO ROLE role_user2"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${create_role_user2}"
    CHECK_RESULT $? 0 0 "Failed to create role_user2."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${grant_read_privileges_user2}"
    CHECK_RESULT $? 0 0 "Failed to grant read privileges to role_user2."

    # 将 role_user2 赋给 user2
    assign_role_to_user2="GRANT ROLE role_user2 TO user2"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${assign_role_to_user2}"
    CHECK_RESULT $? 0 0 "Failed to assign role_user2 to user2."

    LOG_INFO "End to prepare the test environment."
}


function run_test() {
    LOG_INFO "Start to run test."

    # Step 1: 验证 user1 是否可以写入数据
    insert_data_user1="INSERT INTO root.sg1.d1(timestamp, s1) VALUES (1626006830000, 25.5)"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u user1 -pw password1 -e "${insert_data_user1}"
    CHECK_RESULT $? 0 0 "User1 failed to insert data."

    # Step 2: 验证 user2 没有写权限，应该失败
    # Step 2: 验证 user2 没有写权限，应该失败
    insert_data_user2="INSERT INTO root.sg1.d1(timestamp, s1) VALUES (1626006830000, 30.0)"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u user2 -pw password2 -e "${insert_data_user2}"
    if [ $? -eq 1 ]; then
       LOG_INFO "User2 does not have write permission as expected."
    else
       LOG_ERROR "User2 should not have permission to insert data but succeeded."
       exit 1
    fi

    # Step 3: 验证 user1 可以查询数据
    query_data_user1="SELECT s1 FROM root.sg1.d1"
    query_result1=$(${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u user1 -pw password1 -e "${query_data_user1}")
    echo "${query_result1}" | grep "25.5"
    CHECK_RESULT $? 0 0 "User1 failed to query data."

    # Step 4: 验证 user2 可以查询数据，但不能写
    query_data_user2="SELECT s1 FROM root.sg1.d1"
    query_result2=$(${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u user2 -pw password2 -e "${query_data_user2}")
    echo "${query_result2}" | grep "25.5"
    CHECK_RESULT $? 0 0 "User2 failed to query data."

    LOG_INFO "End to run test."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."

    # 删除用户和角色
    delete_user1="DROP USER user1"
    delete_user2="DROP USER user2"
    delete_role_user1="DROP ROLE role_user1"
    delete_role_user2="DROP ROLE role_user2"
    delete_timeseries="DELETE TIMESERIES root.sg1.d1.s1"
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${delete_user1}"
    CHECK_RESULT $? 0 0 "Failed to delete user1."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${delete_user2}"
    CHECK_RESULT $? 0 0 "Failed to delete user2."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${delete_role_user1}"
    CHECK_RESULT $? 0 0 "Failed to delete role_user1."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${delete_role_user2}"
    CHECK_RESULT $? 0 0 "Failed to delete role_user2."
    ${IOTDB_CLI} -h 127.0.0.1 -p 6667 -u root -pw root -e "${delete_timeseries}"
    CHECK_RESULT $? 0 0 "Failed to delete timeseries root.sg1.d1.s1."

    LOG_INFO "End to restore the test environment."
}

main "$@"