#!/bin/sh

#
# brief : 每个 rpm 包的制作, 会有一些差异化的修改动作, 分别用一个单独的函数处理
#
# date : 2017/01/13
# author : istuary xi'an bigdata team
#

set -x

    
# accumulo_2_5_0_0_1245-1.7.0.2.5.0.0-1245.el6.x86_64.rpm -> accumulo_rpm_fix
function accumulo_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local accumulo_monitor_jar="`find $source_dir/ -name "accumulo-monitor.jar"`"
    local accumulo_core_jar="`find $source_dir/ -name "accumulo-core.jar"`"

    cp -f /root/jrbdp-fix/accumulo-monitor.jar.$new_version $accumulo_monitor_jar
    cp -f /root/jrbdp-fix/accumulo-core.jar.$new_version $accumulo_core_jar

    return
}


# falcon_2_5_0_0_1245-0.10.0.2.5.0.0-1245.el6.noarch.rpm -> falcon_rpm_fix
function falcon_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local falcon_war="`find $source_dir/ -name "falcon.war"`"
    pushd .
    mkdir -p tmp-falcon && cd tmp-falcon && jar xf $falcon_war
    sed -i 's/2.5.0.0-1245/'$new_version'/g' WEB-INF/classes/falcon-buildinfo.properties
    sed -i 's/http:\/\/hortonworks.com\/hadoop\/falcon\//http:\/\/falcon.apache.org\/index.html/g' html/directives/navDv.html
    sed -i 's/https:\/\/docs.hortonworks.com.*html/http:\/\/falcon.apache.org\/GettingStarted.html/g' html/directives/navDv.html
    rm -f $falcon_war
    jar cf $falcon_war ./*
    popd 

    rm -rf tmp-falcon

    return    
}


# hadoop_2_5_0_0_1245-2.7.3.2.5.0.0-1245.el6.x86_64.rpm -> hadoop_rpm_fix
function hadoop_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
   
    local bin_hadoop="`find $source_dir/ -name "hadoop" | grep bin`"
    sed -i 's/jrbdp.version/hdp.version/g' $bin_hadoop

    local hadoop_common_jar="`find $source_dir/ -name "hadoop-common-2.7.3.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-hadoop && cd tmp-hadoop && jar xf $hadoop_common_jar 
    local common_properties="`find ./ -name "common-version-info.properties"`"
    sed -i 's/^version=.*$/version=2.7.3.'$new_version'/g' $common_properties
    sed -i 's/^date=.*$/date=2017-01-13T00:55Z/g' $common_properties
    sed -i 's/^url=.*$/url=git@github.com:JRZN\/hadoop.git/g' $common_properties
    rm -f $hadoop_common_jar
    jar cf $hadoop_common_jar ./* 
    popd 

    rm -rf tmp-hadoop
    cp -f /root/jrbdp-fix/aws-java-sdk-1.7.4.jar $source_dir/usr/hdp/2.5.0.0-1245/hadoop/lib/
    sed -i '/^.*aws-java-sdk-core-1.10.6.jar/a%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/hadoop\/lib\/aws-java-sdk-1.7.4.jar"' $spec_dir/*
    
    return    
}


# hadoop_2_5_0_0_1245-yarn-2.7.3.2.5.0.0-1245.el6.x86_64.rpm -> hadoop_yarn_rpm_fix
function hadoop_yarn_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hadoop_yarn_common_jar="`find $source_dir/ -name "hadoop-yarn-common-2.7.3.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-hadoop && cd tmp-hadoop && jar xf $hadoop_yarn_common_jar 
    local yarn_version_info="`find ./ -name "yarn-version-info.properties"`"
    sed -i 's/^version=.*$/version=2.7.3.'$new_version'/g' $yarn_version_info
    sed -i 's/^date=.*$/date=2017-03-13T00:55Z/g' $yarn_version_info
    sed -i 's/^url=.*$/url=git@github.com:JRZN\/hadoop.git/g' $yarn_version_info
    rm -f $hadoop_yarn_common_jar
    jar cf $hadoop_yarn_common_jar ./* 
    popd 

    rm -rf tmp-hadoop
    
    return    
}


# hbase_1_1_0_0_001-1.1.2.1.1.0.0-001.el6.noarch.rpm -> hbase_rpm_fix
function hbase_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hbase_common_jar="`find $source_dir/ -name "hbase-common-1.1.2.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-hbase && cd tmp-hbase && jar xf $hbase_common_jar 
    local package_info="`find ./ -name "package-info.class"`"
    cp /root/jrbdp-fix/hbase-common-package-info.class.$new_version $package_info
    local pom_properties="`find ./ -name "pom.properties"`"
    sed -i 's/1.1.2.2.5.0.0-1245/1.1.2.'$new_version'/g' $pom_properties
    local manifest="`find ./ -name "MANIFEST.MF"`"
    sed -i 's/1.1.2.2.5.0.0-1245/1.1.2.'$new_version'/g' $manifest
    rm -f $hbase_common_jar
    jar cf $hbase_common_jar ./* 
    popd 

    rm -rf tmp-hbase
    
    return    
}


# hive_2_5_0_0_1245-1.2.1000.2.5.0.0-1245.el6.noarch.rpm -> hive_rpm_fix
function hive_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hive_beeline_jar="`find $source_dir/ -name "hive-beeline-1.2.1000.2.5.0.0-1245.jar"`"
    cp -f /root/jrbdp-fix/hive-beeline-1.2.1000.${new_version}.jar $hive_beeline_jar
    
    return    
}
    

# hive_2_5_0_0_1245-jdbc-1.2.1000.2.5.0.0-1245.el6.noarch.rpm -> hive_jdbc_rpm_fix 
function hive_jdbc_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hive_jdbc_jar="`find $source_dir/ -name "hive-jdbc-1.2.1000.2.5.0.0-1245.jar"`"
    cp -f /root/jrbdp-fix/hive-jdbc-1.2.1000.${new_version}.jar $hive_jdbc_jar

    return    
}


# hive2_2_5_0_0_1245-jdbc-2.1.0.2.5.0.0-1245.el6.noarch.rpm -> hive2_jdbc_rpm_fix
function hive2_jdbc_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hive2_exec_jar="`find $source_dir/ -name "hive-exec-2.1.0.2.5.0.0-1245.jar"`"
    pushd .
    mkdir -p tmp-hive2 && cd tmp-hive2 && jar xf $hive2_exec_jar 
    local package_info="`find ./ -name "package-info.class" | grep "apache"`"
    cp /root/jrbdp-fix/hive2-exec-package-info.class $package_info
    rm -f $hive2_exec_jar
    jar cf $hive2_exec_jar ./* 
    popd 

    rm -rf tmp-hive2
 
    return    
}


# hive2_2_5_0_0_1245-2.1.0.2.5.0.0-1245.el6.noarch.rpm -> hive2_rpm_fix 
function hive2_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local hive2_common_jar="`find $source_dir/ -name "hive-common-2.1.0.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-hive2 && cd tmp-hive2 && jar xf $hive2_common_jar 
    local package_info="`find ./ -name "package-info.class"`"
    cp /root/jrbdp-fix/hive2-common-package-info.class $package_info
    local pom_properties="`find ./ -name "pom.properties"`"
    sed -i 's/2.1.0.2.5.0.0-1245/2.1.0.'$new_version'/g' $pom_properties
    local manifest="`find ./ -name "MANIFEST.MF"`"
    sed -i 's/2.1.0.2.5.0.0-1245/2.1.0.'$new_version'/g' $manifest
    rm -f $hive2_common_jar
    jar cf $hive2_common_jar ./* 
    popd 

    rm -rf tmp-hive2
    
    return    
}


# kafka_2_5_0_0_1245-0.10.0.2.5.0.0-1245.el6.noarch.rpm -> kafka_rpm_fix
function kafka_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local kafka_clients_jar="`find $source_dir/ -name "kafka-clients-0.10.0.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-kafka && cd tmp-kafka && jar xf $kafka_clients_jar 
    local kafka_version_properties="`find ./ -name "kafka-version.properties"`"
    sed -i 's/0.10.0.2.5.0.0-1245/0.10.0.'$new_version'/g' $kafka_version_properties
    rm -f $kafka_clients_jar
    jar cf $kafka_clients_jar ./* 
    popd 

    rm -rf tmp-kafka
  
    # add kafka monitor web 
    cp -f /root/jrbdp-fix/KafkaOffsetMonitor-assembly-0.2.0.jar $source_dir/usr/hdp/2.5.0.0-1245/kafka/bin/
    sed -i '/^.*connect-distributed.sh/a%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/kafka\/bin\/KafkaOffsetMonitor-assembly-0.2.0.jar"' $spec_dir/*

    return    
}


# oozie_2_5_0_0_1245-4.2.0.2.5.0.0-1245.el6.noarch.rpm -> oozie_rpm_fix
# oozie_2_5_0_0_1245-client-4.2.0.2.5.0.0-1245.el6.noarch.rpm -> oozie_rpm_fix
function oozie_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3

    local oozie_client_jar="`find $source_dir/ -name "oozie-client-4.2.0.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-oozie && cd tmp-oozie && jar xf $oozie_client_jar
    local buildinfo="`find ./ -name "oozie-buildinfo.properties"`"
    sed -i 's/4.2.0.2.5.0.0-1245/4.2.0.'$new_version'/g' $buildinfo
    rm -f $oozie_client_jar
    jar cf $oozie_client_jar ./*
    popd
    rm -rf tmp-oozie

    local oozie_war="`find $source_dir/ -name "oozie.war" | grep -v "webapps"`"
    pushd .
    mkdir  -p tmp-oozie && cd tmp-oozie && jar xf $oozie_war
    local oozie_client_jar_in_war="`find ./ -name "oozie-client-4.2.0.2.5.0.0-1245.jar"`"
    cp $oozie_client_jar $oozie_client_jar_in_war
    rm -f $oozie_war
    jar cf $oozie_war ./*
    popd
    rm -rf tmp-oozie

    pushd .
    mkdir -p tmp-oozie && cp -f $source_dir/usr/hdp/2.5.0.0-1245/oozie/oozie.war tmp-oozie && cd tmp-oozie && jar xf oozie.war && rm -rf oozie.war
    cp -f /root/jrbdp-fix/oozie/index.html ./docs && jar -cvfM oozie.war ./*
    rm -rf $source_dir/usr/hdp/2.5.0.0-1245/oozie/oozie.war && cp -f oozie.war $source_dir/usr/hdp/2.5.0.0-1245/oozie
    popd
#    sed -i '/^.*configuration.xsl/a%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/oozie\/oozie-server\/webapps\/oozie\/docs\/index.html"' $spec_dir/*

    return
}



# ranger_2_5_0_0_1245-admin-0.6.0.2.5.0.0-1245.el6.x86_64.rpm -> ranger_rpm_fix
function ranger_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3

    cp -f /root/jrbdp-fix/xa_core_db.sql $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/db/mysql/
    cp -f /root/jrbdp-fix/009-updated_schema.sql $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/db/mysql/patches/
    cp -f /root/jrbdp-fix/025-createistuaryadmin.sql $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/db/mysql/patches/
    cp -rf /root/jrbdp-fix/api $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/
    cp -rf /root/jrbdp-fix/mysql $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/db/
    cp -rf /root/jrbdp-fix/dba_script.py  $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/dba_script.py 
    cp -f /root/jrbdp-fix/ranger-plugins-common-0.6.0.2.5.0.0-1245.jar $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/ews/lib/ranger-plugins-common-0.6.0.2.5.0.0-1245.jar
    cp -f /root/jrbdp-fix/ranger-plugins-common-0.6.0.2.5.0.0-1245.jar $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/ews/webapp/WEB-INF/lib/ranger-plugins-common-0.6.0.2.5.0.0-1245.jar
    cp -f /root/jrbdp-fix/ServiceREST.class $source_dir/usr/hdp/2.5.0.0-1245/ranger-admin/ews/webapp/WEB-INF/classes/org/apache/ranger/rest/ServiceREST.class

    return    

}


# spark_2_5_0_0_1245-1.6.2.2.5.0.0-1245.el6.noarch.rpm -> spark_rpm_fix
function spark_rpm_fix()
{
    pushd ./
    
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local local_spark_env_sh="`find $source_dir/ -name "load-spark-env.sh"`"
    local spark_class="`find $source_dir/ -name "spark-class"`"

    sed -i 's/hdp-select/jrbdp-select/g' $local_spark_env_sh $spark_class
    sed -i 's/JRBDP/HDP/g' $local_spark_env_sh $spark_class

    cp -f /root/jrbdp-fix/kafka_2.10-0.10.0.0.jar $source_dir/usr/hdp/2.5.0.0-1245/spark/lib/
    cp -f /root/jrbdp-fix/kafka-clients-0.10.0.0.jar $source_dir/usr/hdp/2.5.0.0-1245/spark/lib/
    cp -f /root/jrbdp-fix/spark-streaming_2.10-1.6.2.jar $source_dir/usr/hdp/2.5.0.0-1245/spark/lib/
    cp -f /root/jrbdp-fix/spark-streaming-kafka-assembly_2.10-1.6.2.jar $source_dir/usr/hdp/2.5.0.0-1245/spark/lib/
    
    sed -i '/^.*datanucleus-api-jdo-3.2.6.jar/i%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/spark\/lib\/kafka_2.10-0.10.0.0.jar"' $spec_dir/*
    sed -i '/^.*datanucleus-api-jdo-3.2.6.jar/i%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/spark\/lib\/kafka-clients-0.10.0.0.jar"' $spec_dir/*
    sed -i '/^.*datanucleus-api-jdo-3.2.6.jar/i%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/spark\/lib\/spark-streaming_2.10-1.6.2.jar"' $spec_dir/*
    sed -i '/^.*datanucleus-api-jdo-3.2.6.jar/i%attr(0644, root, root) "\/usr\/hdp\/2.5.0.0-1245\/spark\/lib\/spark-streaming-kafka-assembly_2.10-1.6.2.jar"' $spec_dir/*
    
    popd  
}


# sqoop_2_5_0_0_1245-1.4.6.2.5.0.0-1245.el6.noarch.rpm -> sqoop_rpm_fix
function sqoop_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3

    local sqoop_jar="`find $source_dir/ -name "sqoop-1.4.6.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-sqoop && cd tmp-sqoop && jar xf $sqoop_jar
    cp -f /root/jrbdp-fix/org-apache-sqoop-Sqoop.class.$new_version ./org/apache/sqoop/Sqoop.class
    cp -f /root/jrbdp-fix/org-apache-sqoop-SqoopVersion.class.$new_version ./org/apache/sqoop/SqoopVersion.class
    cp -f /root/jrbdp-fix/com-cloudera-sqoop-SqoopVersion.class.$new_version ./com/cloudera/sqoop/SqoopVersion.class
    
    rm -f $sqoop_jar
    jar cf $sqoop_jar ./* 
   
    popd  
    
    rm -rf tmp-sqoop
    
    return    
}
    

# storm_2_5_0_0_1245-1.0.1.2.5.0.0-1245.el6.x86_64.rpm -> storm_rpm_fix
function storm_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3
    
    local storm_core_jar="`find $source_dir/ -name "storm-core-1.0.1.2.5.0.0-1245.jar"`"

    pushd .
    mkdir -p tmp-storm && cd tmp-storm && jar xf $storm_core_jar 
    local storm_core_properties="`find ./ -name "storm-core-version-info.properties"`"
    sed -i 's/^version=.*$/version=1.0.1.'$new_version'/g' $storm_core_properties
    sed -i 's/^date=.*$/date=2017-03-01T00:55Z/g' $storm_core_properties
    sed -i 's/^url=.*$/url=git@github.com:JRZN\/hadoop.git/g' $storm_core_properties
    local pom_properties="`find ./ -name "pom.properties"`"
    sed -i 's/1.0.1.2.5.0.0-1245/1.0.1.'$new_version'/g' $pom_properties
    local manifest="`find ./ -name "MANIFEST.MF"`"
    sed -i 's/1.0.1.2.5.0.0-1245/1.0.1.'$new_version'/g' $manifest
    rm -f $storm_core_jar
    jar cf $storm_core_jar ./* 
    popd 

    rm -rf tmp-storm
    
    return    
}


# zeppelin_2_5_0_0_1245-0.6.0.2.5.0.0-1245.el6.noarch.rpm -> zeppelin_rpm_fix
function zeppelin_rpm_fix()
{
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3

    local zeppelin_web_war="`find $source_dir/ -name "zeppelin-web-0.6.0.2.5.0.0-1245.war"`"

    pushd .
    mkdir -p tmp-zeppelin && cd tmp-zeppelin && jar xf $zeppelin_web_war
    sed -i 's/{{zeppelinVersion}}/0.6.0/g' ./app/home/home.html
    sed -i 's/{{zeppelinVersion}}/0.6.0.'$new_version'/g' ./components/navbar/navbar.html    
    
    rm -f $zeppelin_web_war
    jar cf $zeppelin_web_war ./* 
   
    popd  
    
    rm -rf tmp-zeppelin
    
    return    

}


# zookeeper_2_5_0_0_1245-3.4.6.2.5.0.0-1245.el6.noarch.rpm -> zookeeper_rpm_fix
function zookeeper_rpm_fix()
{
    pushd ./
    
    local source_dir=$1
    local new_version=$2
    local spec_dir=$3

    find $source_dir/ -name "HDP-NOTICES.txt" | xargs rm -f
    find $source_dir/ -name "HDP-LICENSE.txt" | xargs rm -f
    find $source_dir/ -name "HDP-CHANGES.txt" | xargs rm -f

    sed -i '/^.*HDP-NOTICES.txt.*$/d' $spec_dir/* 
    sed -i '/^.*HDP-LICENSE.txt.*$/d' $spec_dir/* 
    sed -i '/^.*HDP-CHANGES.txt.*$/d' $spec_dir/* 
    
    popd
}


# main fucntion 
if [ $# -ne 4 ]; then
    echo "Usage : ./difference-operation.sh rpm-name rpm-source-file-dir new-version spec-file-dir"
    exit 1
fi

case "$1" in
    accumulo_2_5_0_0_1245-1.7.0.2.5.0.0-1245.el6.x86_64.rpm)
    accumulo_rpm_fix $2 $3 $4
    ;;

    falcon_2_5_0_0_1245-0.10.0.2.5.0.0-1245.el6.noarch.rpm)
    falcon_rpm_fix $2 $3 $4
    ;;

    hadoop_2_5_0_0_1245-2.7.3.2.5.0.0-1245.el6.x86_64.rpm)
    hadoop_rpm_fix $2 $3 $4
    ;;

    hadoop_2_5_0_0_1245-yarn-2.7.3.2.5.0.0-1245.el6.x86_64.rpm)
    hadoop_yarn_rpm_fix $2 $3 $4
    ;;

    hbase_2_5_0_0_1245-1.1.2.2.5.0.0-1245.el6.noarch.rpm)
    hbase_rpm_fix $2 $3 $4
    # hbase_rpm_fix $2 $3 $4
    ;;

    hive_2_5_0_0_1245-1.2.1000.2.5.0.0-1245.el6.noarch.rpm)
    hive_rpm_fix $2 $3 $4
    # hive_rpm_fix $2 $3 $4
    ;;

    hive_2_5_0_0_1245-jdbc-1.2.1000.2.5.0.0-1245.el6.noarch.rpm)
    hive_jdbc_rpm_fix $2 $3 $4
    # hive_jdbc_rpm_fix $2 $3 $4
    ;;

    hive2_2_5_0_0_1245-2.1.0.2.5.0.0-1245.el6.noarch.rpm)
    # hive2_rpm_fix $2 $3 $4
    ;;
    
    hive2_2_5_0_0_1245-jdbc-2.1.0.2.5.0.0-1245.el6.noarch.rpm)
    # hive2_jdbc_rpm_fix $2 $3 $4
    ;;

    kafka_2_5_0_0_1245-0.10.0.2.5.0.0-1245.el6.noarch.rpm)
    kafka_rpm_fix $2 $3 $4
    ;;

    oozie_2_5_0_0_1245-4.2.0.2.5.0.0-1245.el6.noarch.rpm)
    oozie_rpm_fix $2 $3 $4
    ;;

    oozie_2_5_0_0_1245-client-4.2.0.2.5.0.0-1245.el6.noarch.rpm)
    oozie_rpm_fix $2 $3 $4
    ;;

    ranger_2_5_0_0_1245-admin-0.6.0.2.5.0.0-1245.el6.x86_64.rpm)
    ranger_rpm_fix $2 $3 $4
    ;;

    spark_2_5_0_0_1245-1.6.2.2.5.0.0-1245.el6.noarch.rpm)
    spark_rpm_fix $2 $3 $4
    ;;

    sqoop_2_5_0_0_1245-1.4.6.2.5.0.0-1245.el6.noarch.rpm)
    sqoop_rpm_fix $2 $3 $4
    # sqoop_rpm_fix $2 $3 $4
    ;;

    storm_2_5_0_0_1245-1.0.1.2.5.0.0-1245.el6.x86_64.rpm)
    storm_rpm_fix $2 $3 $4
    ;;

    zeppelin_2_5_0_0_1245-0.6.0.2.5.0.0-1245.el6.noarch.rpm)
    zeppelin_rpm_fix $2 $3 $4
    ;;

    zookeeper_2_5_0_0_1245-3.4.6.2.5.0.0-1245.el6.noarch.rpm)
    zookeeper_rpm_fix $2 $3 $4
    ;;

    *)
    echo "rpm-name $1 is incorrect"
    ;;
esac

exit 0
