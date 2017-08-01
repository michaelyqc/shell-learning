#!/bin/sh

#
# brief : 利用从安装 hdp 组建的机器上获取的 spec 文件, 修改 spec 文件及源文件, 重新
#           build 一套 jrbdp 的软件栈组建包
#
# date : 2016/12/11                                                                        
# author : istuary xi'an bigdata team                                                      
#

function rebuild_rpm()
{
    # 获取参数 spec 文件, hdp rpm 包, 存放路径
    local spec_file=$1
    local rpm_file=$2
    local dest_path=$3
    local rpm_name=`echo ${rpm_file##*/}`

    # 清理上次产出环境
    mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    rm -rf ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}/*

    # 解压 rpm && 删除
    pushd ./ && cp $rpm_file ~/rpmbuild/SOURCES/ && cd ~/rpmbuild/SOURCES/
    rpm2cpio *.rpm | cpio -div && rm -f *.rpm

    popd && cp $spec_file ~/rpmbuild/SPECS/ 
    pushd ./ && cd ~/rpmbuild/SOURCES/

    # 文件内容替换
    local text_files=`grep -lrE "/usr/hdp|2.5.0.0-1245" ./*`
    for text_file in $text_files
    do
        is_text_file=`file $text_file | grep -E "ASCII text|script"`
        if [ -n "$is_text_file" ]; then
            sed -i 's/hdp.version/jrbdp.version/g' $text_file 
            sed -i 's/HDP_VERSION/JRBDP_VERSION/g' $text_file
            sed -i 's/\/usr\/hdp/\/usr\/jrbdp/g' $text_file
            sed -i 's/2.5.0.0-1245/2.0.0.0-001/g' $text_file
        fi
    done
    # 针对每个 rpm 包, 差异的修改操作, 调用如下脚本处理
    sh /root/difference-operation.sh $rpm_name ~/rpmbuild/SOURCES/ 2.0.0.0-001 ~/rpmbuild/SPECS/
    
    # 重命名 hdp->jrbdp, 2.5.0.0->2.0.0.0, 1245->001, 目录, 普通文件和软连接分开操作
    # 目录, 文件名称, 软连接名称本身含有版本信息, rename 只替换首次匹配 
    find ./ -type d -name "hdp" | xargs rename hdp jrbdp
    find ./ -type d -name "2.5.0.0-1245" | xargs rename 2.5.0.0-1245 2.0.0.0-001
    # hdp 会在部分组建的字母下, 使用带 hdp 的前缀, 如 spark 组建下的 hdplib
    find ./ -type d -name "hdpLib" | xargs rename hdp jrbdp 
    find ./ -type d | xargs rename 2.5.0.0-1245 2.0.0.0-001
    find ./ -type d | xargs rename 2.5.0.0 2.0.0.0
    # find ./ -type f | xargs rename hdp jrbdp
    find ./ -type f -name "hdp-select" | xargs rename hdp jrbdp 
    find ./ -type f | xargs rename 2.5.0.0-1245 2.0.0.0-001
    find ./ -type f | xargs rename 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename -s hdp jrbdp
    find ./ -type l | xargs rename -s 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename -s 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename -s 2.5.0.0-1245 2.0.0.0-001
    find ./ -type l | xargs rename -s 2.5.0.0-1245 2.0.0.0-001

    # 重新打包源文件
    rpm_name=`echo $rpm_name | sed 's/hdp-select/jrbdp-select/g'`
    rpm_name=`echo $rpm_name | sed 's/2_5_0_0_1245/2_0_0_0_001/g'`
    rpm_name=`echo $rpm_name | sed 's/2.5.0.0-1245/2.0.0.0-001/g'`
    rpm_name=`echo $rpm_name | sed 's/-1245/-001/g'`
    local rpm_name_length=`echo ${#rpm_name}`
    local rpm_dir=${rpm_name:0:$((rpm_name_length-4))}
    rm -rf ~/rpmbuild/$rpm_dir && mkdir ~/rpmbuild/$rpm_dir
    mv ./* ~/rpmbuild/$rpm_dir && mv ~/rpmbuild/$rpm_dir ./
    tar -zcf ${rpm_dir}.tar.gz ${rpm_dir}/ && mv $rpm_dir ~/rpmbuild/BUILDROOT/

    # 修改 spec 文件
    popd && pushd ./ && cd ~/rpmbuild/SPECS/
    local spec_file_name=`echo ${spec_file##*/}`
    sed -i 's/hdp-select/jrbdp-select/g' ./${spec_file_name}
    sed -i 's/usr\/hdp/usr\/jrbdp/g' ./${spec_file_name}
    sed -i 's/hdpLib/jrbdpLib/g' ./${spec_file_name}
    sed -i 's/_2_5_0_0_1245/_2_0_0_0_001/g' ./${spec_file_name}
    sed -i 's/2\.5\.0\.0-1245/2.0.0.0-001/g' ./${spec_file_name}
    sed -i 's/2\.5\.0\.0/2.0.0.0/g' ./${spec_file_name}
    sed -i 's/1245.el6/001.el6/g' ./${spec_file_name}

    # 重新生成 rpm 安装文件, 如果失败程序就直接退出不再继续生成
    cd ~/rpmbuild/
    local is_noarch=`echo $rpm_name| grep "noarch.rpm"`
    if [ "$is_noarch" == "" ]; then
        rpmbuild -bb ./SPECS/${spec_file_name}
    else
        rpmbuild -bb --target noarch ./SPECS/${spec_file_name}
    fi
    if [ $? -ne 0 ]; then
        echo "$rpm_name build failed"
        exit 1 
    fi

    popd
    
    # 拷贝新生成安装包到目标路径
    if [ "$is_noarch" == "" ]; then
        mv ~/rpmbuild/RPMS/x86_64/* $dest_path
    else
        mv ~/rpmbuild/RPMS/noarch/* $dest_path
    fi
}

function rebuild_jrbdp_version_rpm()
{
    local spec_file_dir=$1
    local hdp_stack_dir=$2

    rm -rf jrbdp-rpm && mkdir -p jrbdp-rpm
    for module in `ls $hdp_stack_dir`
    do
        if [ -d $hdp_stack_dir/$module ]; then
            for rpm_package in `ls $hdp_stack_dir/$module`
            do
                # 确定文件是 rpm 安装包且有对应的 spec 文件
                local is_rpm=$(echo $rpm_package | grep -E "noarch.rpm|x86_64.rpm")
                if [ "$is_rpm" != "" -a -f $spec_file_dir/$module/$rpm_package".spec" ]; then
                    mkdir -p jrbdp-rpm/$module
                    rebuild_rpm $spec_file_dir/$module/${rpm_package}.spec \
                            $hdp_stack_dir/$module/$rpm_package \
                            jrbdp-rpm/$module
                fi
            done
        fi
    done
}

# main function 
if [ $# -ne 2 ]; then
    echo "Usage : ./rebuild_jrbdp_version_rpm.sh spec_file_dir hdp_stack_dir"
    exit 1
fi 

# call rebuild function
rebuild_jrbdp_version_rpm $@
