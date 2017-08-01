#!/bin/sh

#
# brief : 从安装 hdp 组建的机器上, 通过 rpmrebuild 命令获取每一个 rpm 包的 spec 文件
#           想要获取但是机器实际未安装的 rpm 包, 存入当前目录 no_exist_rpm_package.list
#
# date : 2016/12/11                                                                        
# author : istuary xi'an bigdata team                                                      
#

function get_spec_file()
{
    # 切换到 root 账户的主目录
    local stack_dir=$1
    local all_components_dir=`ls $stack_dir/`
    
    mkdir -p ./hdp_rpm_spec_files/ && rm -rf ./hdp_rpm_spec_files/*
    rm -f ./no_exist_rpm_package.list
    
    echo "all_components_dir: $all_components_dir"

    for single_component in $all_components_dir
    do
        echo "entry $stack_dir/$single_component"
        
        if [ -d $stack_dir/$single_component ]; then
            local all_rpms=`ls $stack_dir/$single_component/`
            
            for single_rpm in $all_rpms
            do
                local is_rpm=`echo $single_rpm | grep -E "noarch.rpm|x86_64.rpm"`
                local words=${single_rpm//-/ }
                local words_num=`echo $words | wc -w`
                local second_last_index=$(($words_num-2))
                local last_index=$(($words_num-1))
                local index=0
                
                for word in $words 
                do
                    if [ $index -eq 0 ]; then
                        package_name=$word
                    elif [ $index -lt $second_last_index ]; then
                        package_name+=-$word
                    elif [ $index -eq $second_last_index ]; then
                        package_version=$word
                    elif [ $index -eq $last_index ]; then
                        package_release=`echo $word | cut -d '.' -f1`
                    fi
                         
                    ((index++))
                done
		
                local install_name=$(rpm -qa | grep "$package_name-$package_version-$package_release")
                if [ "$is_rpm" != "" -a "$install_name" != "" ]; then
                    mkdir -p ./hdp_rpm_spec_files/$single_component/
                    rpmrebuild -s tmp.spec $install_name
                    mv tmp.spec ./hdp_rpm_spec_files/$single_component/$single_rpm'.spec'
                else
                    echo "$package_name-$package_version-$package_release" >> no_exist_rpm_package.list
                fi
            done
        fi

        echo "leave $stack_dir/$single_component"
    done
}


# main 
if [ $# -ne 1 ]; then
    echo "Usage : ./get_hdp_rpm_spec_files.sh stack_dir"
    exit 1
fi

get_spec_file $@
