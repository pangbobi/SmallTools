#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

checkOS_URL="https://raw.githubusercontent.com/pangbobi/SmallTools/dev/System/checkOS.sh"

# 编译安装给定版本的Python
Compile_Install_Python(){
    local PY_VERSION=$1
    local old_ver=$(cat $DIR_BASE/config.json |jq -r ".python.version")
    if [ "${PY_VERSION}" != "${old_ver}" ];then
        py_essential=$(cat $DIR_BASE/config.json |jq -r ".python.essential")
        if [ ! "$py_essential" ];then
            # 安装必要依赖
            if [ "${PM}" == "apt-get" ];then
                $PM install -y build-essential
                $PM install -y uuid-dev tk-dev liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libffi-dev
            else
                $PM groupinstall -y "Development tools"
                $PM install -y tk-devel xz-devel gdbm-devel sqlite-devel bzip2-devel readline-devel zlib-devel openssl-devel libffi-devel
            fi
            cat $DIR_BASE/config.json |jq -r '.python.essential'='"yes"' |sponge $DIR_BASE/config.json
        fi
        # 下载指定版本
        python_package="Python-$PY_VERSION.tgz"
        python_path="/usr/local/python3"
        wget https://www.python.org/ftp/python/$PY_VERSION/$python_package
        tar xzvf $python_package
        # 编译
        cd Python-$PY_VERSION || Red_Info "切换到 Python-$PY_VERSION 失败！"
        ./configure --prefix=$python_path --with-ssl
        mkdir $python_path
        make && make install
        # 建立软链
        rm -rf /usr/bin/python /usr/bin/pip
        ln -s $python_path/bin/python3 /usr/bin/python
        ln -s $python_path/bin/pip3 /usr/bin/pip
        cat $DIR_BASE/config.json |jq -r '.python.version'='"'$PY_VERSION'"' |sponge $DIR_BASE/config.json
        cat $DIR_BASE/config.json |jq -r '.python.path'='"'$python_path'"' |sponge $DIR_BASE/config.json
        # 通知并卸载安装包
        Green_Info "Python ${PY_VERSION}已安装"
        cd $DIR_BASE && rm -rf Python-$PY_VERSION*
    else
        Green_Info "之前已安装Python ${PY_VERSION}"
    fi
}

# 安装依赖
source <(curl -sL $checkOS_URL)

#######获取参数#########
while [[ $# -gt 0 ]];do
    KEY="$1"
    case $KEY in
        --latest)
        install_version=$(curl -s https://www.python.org/|grep "downloads/release/"|grep -Eo "Python [[:digit:]]+\.[[:digit:]]+\.[[:digit:]]"|sed s/"Python "//g);;
        -v|--version)
        install_version="$2"
        shift;;
        *)
        Yellow_Info "无效参数！";;
    esac
    shift
done

if [ "$install_version" ];then
    # 执行安装
    Compile_Install_Python "$install_version"
fi
