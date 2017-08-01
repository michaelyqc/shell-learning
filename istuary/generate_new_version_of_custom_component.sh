#!/bin/sh

#
# brief : 利用从安装 hdp 组建的机器上获取的 spec 文件, 修改 spec 文件及源文件, 重新
#           build 一套 isdp 的软件栈组建包
#
# date : 2016/12/11                                                                        
# author : istuary xi'an bigdata team                                                      
#


# 
function update_component_version()
{
    local old_version_source_file=$1
    local old_version_underline="1_5_0_0_001"
    local old_version_dot="1.5.0.0-001"
    local old_version="1.5.0.0"
    local old_build="001"
    local new_version_underline="2_0_0_0_001"
    local new_version_dot="2.0.0.0-001"
    local new_version="2.0.0.0"
    local new_build="001"
    local custom_component_dir="2.0.0.0-001"

    rm -rf ~/$custom_component_dir && mkdir -p ~/$custom_component_dir
    mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

    # copy source compress file and spec file
    cp -f $old_version_source_file/*.tar.gz ~/rpmbuild/SOURCES/
    cp -f $old_version_source_file/*.rpm.spec ~/rpmbuild/SPECS/

    for tar_package in `ls ~/rpmbuild/SOURCES`
    do
        tar -xzf ~/rpmbuild/SOURCES/$tar_package -C ~/rpmbuild/SOURCES/
        rm -rf ~/rpmbuild/SOURCES/$tar_package
    done

    # replace old version by new version
    # source file
    rename $old_version_underline $new_version_underline ~/rpmbuild/SOURCES/*
    rename $old_version $new_version ~/rpmbuild/SOURCES/*
    find ~/rpmbuild/SOURCES/* -type d -name "$old_version_dot" | xargs rename $old_version_dot $new_version_dot
    find ~/rpmbuild/SOURCES/* -type d -name "isdp" | xargs rename isdp jrbdp 
    # 文件内容替换
    local text_files=`grep -lr "/usr/isdp" ~/rpmbuild/SOURCES/*`
    for text_file in $text_files
    do
        is_text_file=`file $text_file | grep -E "ASCII text|script"`
        if [ -n "$is_text_file" ]; then
            sed -i 's/\/usr\/isdp/\/usr\/jrbdp/g' $text_file
        fi
    done
 
    # spec file
    rename $old_version_underline $new_version_underline ~/rpmbuild/SPECS/*
    rename $old_version_dot $new_version_dot ~/rpmbuild/SPECS/*
    sed -i 's/'$old_version_underline'/'$new_version_underline'/g' ~/rpmbuild/SPECS/*
    sed -i 's/'$old_version_dot'/'$new_version_dot'/g' ~/rpmbuild/SPECS/*
    sed -i 's/'$old_version'/'$new_version'/g' ~/rpmbuild/SPECS/*
    sed -i 's/'$old_build'.el6/'$new_build'.el6/g' ~/rpmbuild/SPECS/*
    sed -i 's/\/usr\/isdp/\/usr\/jrbdp/g' ~/rpmbuild/SPECS/*

    # rpmbuild
    cd ~/rpmbuild/
    for source_file_dir in `ls ~/rpmbuild/SOURCES`
    do
        cd SOURCES/
        tar -zcf ${source_file_dir}.tar.gz ${source_file_dir}/
        cd ../
        rm -rf ~/rpmbuild/SOURCES/${source_file_dir}
        local component_name=`echo $source_file_dir | cut -d '_' -f1`
        local is_noarch=`ls ~/rpmbuild/SPECS/$component_name* | grep noarch`
        
        if [ "$is_noarch" = "" ]; then
            rpmbuild -bb ~/rpmbuild/SPECS/$component_name*
        else
            rpmbuild -bb --target noarch ~/rpmbuild/SPECS/$component_name*
        fi
        
        if [ $? -ne 0 ]; then
            echo "$component_name rpm build failed"
            exit 1
        fi

    done

    cp -f ~/rpmbuild/RPMS/*/* ~/$custom_component_dir/
    cp -f ~/rpmbuild/SOURCES/*.tar.gz ~/$custom_component_dir/
    cp -f ~/rpmbuild/SPECS/*.rpm.spec ~/$custom_component_dir/
   
    rm -rf ~/rpmbuild
    return
}


# main function
if [ $# -ne 1 ]; then
    echo "Usage : ./release_new_version_of_custom_module.sh source_files_of_old_version_dir"
    exit 1
fi 


# check current user is root?
if [ `whoami` = "root" ]; then
    :
else
    echo "current user must be root"
    exit 1 
fi


# push stack and backup related dir
pushd ./
cd ~/
current_seconds=`date +%N`
mv rpmbuild rpmbuild.$current_seconds

# call rebuild function
update_component_version $1 

# pop stack and recover related dir
popd
mv rpmbuild.$current_seconds rpmbuild


