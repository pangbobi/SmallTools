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
Red_Error(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
White_Text(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
Yellow_Warning(){
	echo -e "\033[33m\033[01m$1\033[0m"
}
Info=$(Green_Info [信息]) && Error=$(Red_Error [错误]) && Warning=$(Yellow_Warning [警告])

# 能用性检查
Avaliable_Check(){
    # 用户权限限制
    if [ "$(whoami)" != "root" ];then
        Red_Error "请使用root权限执行此脚本！"
        exit 1;
    fi
    # 系统位数限制
    is64bit=$(getconf LONG_BIT)
    if [ "${is64bit}" != '64' ];then
        Red_Error "抱歉, 当脚本不支持32位系统!";
    fi
    # 系统版本限制
    Centos6Check=$([ -f /etc/redhat-release ] && cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ];then
        Red_Error "Centos6不支持此脚本，请更换Centos7/8使用此脚本！"
        exit 1
    fi
    UbuntuCheck=$(cat /etc/issue|grep Ubuntu|awk '{print $2}'|cut -f 1 -d '.')
    if [ "${UbuntuCheck}" ] && [ "${UbuntuCheck}" -lt "16" ];then
        Red_Error "Ubuntu ${UbuntuCheck}不支持此脚本，建议更换Ubuntu18/20使用此脚本！"
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
        Red_Error "不支持的系统！"
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

# 直至输入不为空
Input_Avaliable_Content(){
    local prompt=$1
    while true; do
        read -p "${Info}${prompt}：" content
        [ -z "${content}" ] && Yellow_Warning "输入内容不可为空！" && continue
        break
    done
    echo $content
}

# 主函数
main(){
    Avaliable_Check
    Get_Pack_Manager
    Install_Curl_Wget
}
# 执行主函数
main
