#!/bin/sh

# 
# date : 2016/12/11
# author : istuary xi'an bigdata team
# 
# note : 脚本需要和包含所有组件的目录在同一级目录下, 运行后, 可以获取一份

# brief : 根据 hdp-util stack (/var/www/html/local_repo/HDP-UTIL/centos7/), 获取一个完整的组建目录
#         列表, 每个组建下面的 rpm 安装包, 用一个同名的空文件代替, 同时过滤掉非 rpm 安装
#         包文件, 该目录用于去所有安装 hdp 组建的机器上, 获取每一个 rpm 包的 spec 文件

function get_hdp_util_stack_rpm_tree()
{
    # 获取参数
    local hdp_util_stack_dir=$1

    # 切换到 root 账户的主目录
    mkdir -p ./hdp_util_stack_rpm_treedir/ && rm -rf ./hdp_util_stack_rpm_treedir/*

    all_modules_dirs=`ls $hdp_util_stack_dir` 
    for single_module in $all_modules_dirs
    do
        echo "entry $hdp_util_stack_dir/$single_module"

        if [ -d $hdp_util_stack_dir/$single_module ]; then
            local all_rpms=`ls $hdp_util_stack_dir/$single_module/`

            for single_rpm in $all_rpms
            do
                is_rpm=`echo $single_rpm | grep -E "noarch.rpm|x86_64.rpm"`
                if [ "$is_rpm" != "" ]; then
                    mkdir -p ./hdp_util_stack_rpm_treedir/$single_module/
                    cat /dev/null > ./hdp_util_stack_rpm_treedir/$single_module/$single_rpm 
                fi
            done
        fi
        echo "leave $hdp_util_stack_dir/$single_module"
    done
}


# main 
if [ $# -ne 1 ]; then
    echo "Usage : ./get_hdp_util_stack_rpm_tree.sh hdp_util_stack_dir"
    exit 1
fi

get_hdp_util_stack_rpm_tree $@
