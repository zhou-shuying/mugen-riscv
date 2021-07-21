#!/usr/bin/bash

# Copyright (c) 2021. Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #############################################
# @Author    :   huangrong
# @Contact   :   1820463064@qq.com
# @Date      :   2020/10/23
# @License   :   Mulan PSL v2
# @Desc      :   Testing doxygen command parameters
# #############################################

source "$OET_PATH/libs/locallibs/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    DNF_INSTALL doxygen
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start testing..."
    doxygen -s -g doxygen-mode | grep "Configuration file 'doxygen-mode' created."
    CHECK_RESULT $?
    doxygen doxygen-mode | grep "finished"
    CHECK_RESULT $?
    doxygen -u doxygen-mode | grep "Configuration file 'doxygen-mode' updated."
    CHECK_RESULT $?
    test -f doxygen-mode -a -f doxygen-mode.bak
    CHECK_RESULT $?
    doxygen doxygen-mode | grep "finished"
    CHECK_RESULT $?
    doxygen -w rtf rtf-mode
    CHECK_RESULT $?
    doxygen rtf-mode | grep "finished"
    CHECK_RESULT $?
    doxygen -w html HTMLheader HTMLfooter HTML-mode
    CHECK_RESULT $?
    grep "The standard CSS for doxygen" HTML-mode && grep "HTML header for doxygen" HTMLheader && grep "HTML footer for doxygen" HTMLfooter
    CHECK_RESULT $?
    doxygen -w latex Latexheader Latex-mode config_file
    CHECK_RESULT $?
    grep "stylesheet for doxygen" config_file && grep "Latex header for doxygen" Latexheader && grep "Latex footer for doxygen" Latex-mode
    CHECK_RESULT $?
    doxygen -e rtf rtf-extensions-file
    CHECK_RESULT $?
    grep "Generated by doxygen" rtf-extensions-file
    CHECK_RESULT $?
    doxygen -l test.xml
    CHECK_RESULT $?
    grep "doxygenlayout" test.xml
    CHECK_RESULT $?
    doxygen -f emoji outputFileName
    CHECK_RESULT $?
    grep "accept" outputFileName
    CHECK_RESULT $?
    doxygen -v | grep "$(rpm -qa doxygen | awk -F '-' '{print $2}')"
    CHECK_RESULT $?
    doxyindexer -o ./ test.xml | grep "Processing test.xml"
    CHECK_RESULT $?
    test -d doxysearch.db
    CHECK_RESULT $?
    doxysearch.cgi doxysearch.db | grep "Content-Type:application/javascript;charset=utf-8"
    CHECK_RESULT $?
    LOG_INFO "Finish test!"
}

function post_test() {
    LOG_INFO "start environment cleanup."
    rm -rf doxy* rtf* HTML* Latex* test.xml outputFileName html latex
    DNF_REMOVE
    LOG_INFO "Finish environment cleanup!"
}

main "$@"
