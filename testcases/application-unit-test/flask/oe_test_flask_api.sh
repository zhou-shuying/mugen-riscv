#!/usr/bin/bash

# Licensed under Mulan PSL v2.
# @Desc       : Test case to verify Flask API responses

source ${OET_PATH}/libs/locallibs/common_lib.sh

function config_params() {
    LOG_INFO "Start to configure parameters."
    FLASK_PORT=5000
    FLASK_API_URL="http://127.0.0.1:${FLASK_PORT}/api"
    LOG_INFO "End to configure parameters."
}

function pre_test() {
    LOG_INFO "Start to prepare the test environment."

    # 创建和启动 Flask API，完全抑制输出
nohup python3 -c "
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/api', methods=['GET'])
def api_route():
    return jsonify({'message': 'Hello, Flask!'})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=$FLASK_PORT)
" > /dev/null 2>&1 &


    FLASK_PID=$!
    LOG_INFO "Flask PID: ${FLASK_PID}"

    # 等待 Flask 启动
    sleep 3
    LOG_INFO "End to prepare the test environment."
}

function run_test() {
    LOG_INFO "Start to run the test."

    # 发送 HTTP 请求并检查响应
    RESPONSE=$(curl -s -w "\n" "${FLASK_API_URL}")
    EXPECTED_RESPONSE='{"message":"Hello, Flask!"}'

    if [[ "$RESPONSE" == "$EXPECTED_RESPONSE" ]]; then
        LOG_INFO "API response is correct: ${RESPONSE}"
    else
        LOG_ERROR "API response is incorrect: ${RESPONSE}"
        exit 1
    fi

    LOG_INFO "End to run the test."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."

    # 终止 Flask 进程
    if [[ -n "${FLASK_PID}" ]]; then
        kill -9 "${FLASK_PID}" && LOG_INFO "Flask API process (PID: ${FLASK_PID}) terminated."
    fi

    LOG_INFO "End to restore the test environment."
}

main "$@"
