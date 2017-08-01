#!/bin/bash

#
# brief : 
# date : 
#

function get_vrpms_spec_file()
{
    local vrpms_rpm_files=$1

    #
    rm -rf ~/vrpms_spec_file && mkdir -p ~/vrpms_spec_file
    
    for component in `find $vrpms_rpm_files -type d | cut -d '/' -f2`
    do
        for package in `ls $vrpms_rpm_files/$component/`
        do
            rpm --force --nodeps -ivh $vrpms_rpm_files/$component/$package
            rpmrebuild -s ${package}.spec ${package/.rpm/}
            mkdir -p ~/vrpms_spec_file/${component}
            mv ${package}.spec ~/vrpms_spec_file/${component}
        done
    done

    return
}

if [ $# -ne 1 ]; then
    echo "usage : get_vrpms_spec_file.sh vrpms_rpm_files"
    exit 0
fi

get_vrpms_spec_file $@
