#!/usr/bin/bash

# Copyright (c) 2024. NBD ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
####################################
# @Author       :   Shea
# @Contact      :   shea.zhou@leapfive.com
# @Date         :   2024/10/31
# @License      :   Mulan PSL v2
# @Desc         :   RPM package smoke test for neofetch
####################################

source ${OET_PATH}/libs/locallibs/common_lib.sh

# 配置需要的参数
function config_params() {
    LOG_INFO "Start to config params of the case."

    LOG_INFO "No params need to config."

    LOG_INFO "End to config params of the case."
}

# 测试环境准备
function pre_test() {
    LOG_INFO "Start to prepare the test environment."

    DNF_REMOVE "neofetch"  # 确保不存在旧版本
    LOG_INFO "End to prepare the test environment."
}

# 测试用例执行
function run_test() {
    LOG_INFO "Start to run test."

    # 动态查找并安装 neofetch RPM 包
    NEFETCH_RPM_PATH=$(find "${HOME}/rpmbuild/RPMS/" -name "neofetch-*.noarch.rpm" | head -n 1)
    if [ -z "${NEFETCH_RPM_PATH}" ]; then
        LOG_ERROR "Neofetch RPM package not found."
        exit 1
    fi
    dnf install -y "${NEFETCH_RPM_PATH}"
    CHECK_RESULT $? 0 0 "Failed to install neofetch package."

    # 检查 neofetch 是否安装成功
    rpm -q neofetch
    CHECK_RESULT $? 0 0 "Neofetch package query failed."

    # 预期信息获取
    OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    KERNEL_VERSION=$(uname -r)

    # 执行 neofetch 并保存输出
    neofetch > /tmp/neofetch_output 2>&1
    CHECK_RESULT $? 0 0 "Neofetch execution failed."

    # 输出 neofetch 内容用于调试
    cat /tmp/neofetch_output

    # 检查 neofetch 输出是否包含操作系统名称、版本和内核版本
    grep -q "${OS_NAME}" /tmp/neofetch_output
    CHECK_RESULT $? 0 0 "Expected OS name (${OS_NAME}) not found in Neofetch output."

    grep -q "${OS_VERSION}" /tmp/neofetch_output
    CHECK_RESULT $? 0 0 "Expected OS version (${OS_VERSION}) not found in Neofetch output."

    grep -q "${KERNEL_VERSION}" /tmp/neofetch_output
    CHECK_RESULT $? 0 0 "Expected kernel version (${KERNEL_VERSION}) not found in Neofetch output."

    LOG_INFO "End to run test."
}

# 清理环境
function post_test() {
    LOG_INFO "Start to restore the test environment."

    DNF_REMOVE "neofetch"
    rm -f /tmp/neofetch_output

    LOG_INFO "End to restore the test environment."
}

main "$@"
