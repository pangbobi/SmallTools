#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# 脚本存储路径
DIR_BASE="/root"

#颜色信息
Green_Info(){
	echo -e "\033[32m\033[01m$1\033[0m\033[37m\033[01m$2\033[0m"
}
Red_Info(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
White_Info(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
Yellow_Info(){
	echo -e "\033[33m\033[01m$1\033[0m"
}

# 能用性检查
Avaliable_Check(){
    # 用户权限限制
    if [ "$(whoami)" != "root" ];then
        Red_Info "请使用root权限执行此脚本！"
        exit 1;
    fi
    # 系统位数限制
    is64bit=$(getconf LONG_BIT)
    if [ "${is64bit}" != '64' ];then
        Red_Info "抱歉, 当脚本不支持32位系统!";
    fi
    # 系统版本限制
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ];then
        Red_Info "Centos6不支持此脚本，请更换Centos7/8使用此脚本！"
        exit 1
    fi
    UbuntuCheck=$(cat /etc/issue|grep Ubuntu|awk '{print $2}'|cut -f 1 -d '.')
    if [ "${UbuntuCheck}" ] && [ "${UbuntuCheck}" -lt "16" ];then
        Red_Info "Ubuntu ${UbuntuCheck}不支持此脚本，建议更换Ubuntu18/20使用此脚本！"
        exit 1
    fi
}

# 获取系统安装工具
Get_Pack_Manager(){
	if [ "$(command -v apt-get)" ];then
        PM='apt-get'
    elif [ "$(command -v dnf)" ];then
        PM='dnf'
    elif [ "$(command -v yum)" ];then
        PM='yum'
    else
        Red_Info "不支持的系统！"
        exit 1
    fi
    echo $PM
}

# 安装系统软件
Install_Package(){
    $PM install "$1" -y
    $PM update -y
}

# 卸载系统软件
Remove_Package(){
	local PackageNmae=$1
	if [ "${PM}" == "apt-get" ];then
		isPackage=$(dpkg -l|grep ${PackageNmae})
	else
        isPackage=$(rpm -q ${PackageNmae}|grep "not installed")
	fi
    # 已安装则执行卸载
    if [ -z "${isPackage}" ];then
        $PM remove ${PackageNmae} -y
    fi
}

# 安装基础网络访问工具
Install_Curl_Wget(){
    if [ ! $(which curl) ];then
        Install_Package curl
    fi
    if [ ! $(which wget) ];then
        Install_Package wget
    fi
    if [ ! -f "$DIR_BASE/config.json" ];then
        Install_Package "jq moreutils"
        echo '{"jq-moreutils": "yes"}' > $DIR_BASE/config.json
    fi
}

# 编译安装Python
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
        cd Python-$PY_VERSION
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


# 主函数
main(){
    Avaliable_Check
    Get_Pack_Manager
    Install_Curl_Wget
    Compile_Install_Python "3.8.2"
}
# 执行主函数
main
