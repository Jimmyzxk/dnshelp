#!/bin/bash

# =============================
# 一键流媒体解锁助手 v3.0
# 支持 Ubuntu, CentOS, Debian 系统
# =============================

clear

# 美化界面显示
echo -e "\n====================================================="
echo -e "  欢迎使用 DNS 流媒体解锁助手 v3.0\n"
echo -e "  请选择当前机器类型进行配置："
echo -e "  A 机器: 解锁 Netflix 的 VPS"
echo -e "  B 机器: 无法解锁 Netflix 的 VPS\n"
echo -e "  请选择操作类型："
echo -e "====================================================="
echo -e "  [ A ] 配置 A 机器（解锁流媒体）"
echo -e "  [ B ] 配置 B 机器（通过 A 机器解锁流媒体）"
echo -e "====================================================="
read -p "请输入您的选择 (A 或 B): " machine_type

# 检测操作系统类型
if [ -f /etc/lsb-release ]; then
    DISTRO="ubuntu"
elif [ -f /etc/redhat-release ]; then
    DISTRO="centos"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
else
    echo -e "\n  ⚠️ 未知操作系统，暂不支持。请检查您的环境。\n"
    exit 1
fi

# 公共安装依赖函数
install_dependencies() {
    echo -e "\n  正在安装依赖包，请稍候..."
    if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
        sudo apt update -y
        sudo apt install -y net-tools wget iptables
    elif [ "$DISTRO" == "centos" ]; then
        sudo yum update -y
        sudo yum install -y net-tools wget iptables
    fi
    echo -e "\n  ✅ 依赖安装完成！"
}

# 配置 A 机器（解锁流媒体的 VPS）
configure_A() {
    echo -e "\n  配置 A 机器（解锁 Netflix 流媒体）... 🛠️"
    install_dependencies

    # 安装并配置 Dnsmasq 和 SNIproxy
    echo -e "\n  正在安装 Dnsmasq 和 SNIproxy，帮助解锁流媒体..."
    wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh
    bash dnsmasq_sniproxy.sh -f

    # 配置防火墙规则
    echo -e "\n  配置防火墙规则，只允许 B 机器访问 DNS 服务..."
    read -p "请输入 B 机器的 IP 地址: " b_ip
    iptables -I INPUT -p udp --dport 53 -j DROP
    iptables -I INPUT -s "$b_ip" -p udp --dport 53 -j ACCEPT
    echo -e "\n  ✅ 防火墙规则已配置！仅允许 B 机器访问 DNS 服务。"

    # 保存防火墙规则
    if [ "$DISTRO" == "ubuntu" ] || [ "$DISTRO" == "debian" ]; then
        sudo apt install -y iptables-persistent
        sudo netfilter-persistent save
    elif [ "$DISTRO" == "centos" ]; then
        service iptables save
    fi

    echo -e "\n  ✅ A 机器配置完成！解锁流媒体已准备好！"
}

# 配置 B 机器（通过 A 机器解锁流媒体）
configure_B() {
    echo -e "\n  配置 B 机器（通过 A 机器解锁流媒体）... 🔐"
    install_dependencies

    # 修改 B 机器的 DNS 配置
    read -p "请输入 A 机器的 IP 地址（提供解锁服务）: " a_ip
    echo -e "\n  正在修改 B 机器的 DNS 设置..."
    sudo sed -i "s/nameserver .*/nameserver $a_ip/" /etc/resolv.conf
    echo -e "\n  ✅ DNS 已修改为 A 机器的 IP ($a_ip)，流媒体解锁已启用！"

    # 锁定 resolv.conf 防止重启后恢复
    echo -e "\n  锁定 /etc/resolv.conf 文件，防止系统重置 DNS..."
    sudo chattr +i /etc/resolv.conf
    echo -e "\n  ✅ /etc/resolv.conf 文件已锁定，配置永久生效！"

    echo -e "\n  ✅ B 机器配置完成！流媒体解锁成功。"
}

# 主流程逻辑
if [[ "$machine_type" == "A" || "$machine_type" == "a" ]]; then
    configure_A
elif [[ "$machine_type" == "B" || "$machine_type" == "b" ]]; then
    configure_B
else
    echo -e "\n  ⚠️ 输入无效，请重新运行脚本并输入 A 或 B。"
    exit 1
fi

# 结束提示
echo -e "\n====================================================="
echo -e "  🏁 配置完成！感谢使用 DNS 流媒体解锁助手 v3.0"
echo -e "  🎉 您的流媒体解锁配置已成功完成！"
echo -e "====================================================="
