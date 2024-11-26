#!/bin/bash

# 一键流媒体解锁脚本 - 针对 A 和 B 机器
clear
echo "====================================================="
echo "  欢迎使用 DNS 流媒体解锁助手 v2.0"
echo "  请根据机器类型选择操作（A 或 B）"
echo "====================================================="
echo "A 机器: 解锁 Netflix 的 VPS"
echo "B 机器: 无法解锁 Netflix 的 VPS"
echo "====================================================="
read -p "请确认当前机器类型 [A/B]: " machine_type

# 检测操作系统
if [ -f /etc/lsb-release ]; then
    DISTRO="ubuntu"
elif [ -f /etc/redhat-release ]; then
    DISTRO="centos"
else
    echo "不支持的操作系统，请检查您的系统环境。"
    exit 1
fi

# 公共功能函数
install_dependencies() {
    echo "正在安装依赖..."
    if [ "$DISTRO" == "ubuntu" ]; then
        sudo apt update
        sudo apt install -y net-tools wget iptables
    elif [ "$DISTRO" == "centos" ]; then
        sudo yum update -y
        sudo yum install -y net-tools wget iptables
    fi
    echo "依赖安装完成！"
}

# A 机器操作
configure_A() {
    echo "正在配置 A 机器（解锁 Netflix 的 VPS）..."
    install_dependencies
    echo "安装并配置 Dnsmasq 和 SNIproxy..."
    wget --no-check-certificate -O dnsmasq_sniproxy.sh https://raw.githubusercontent.com/myxuchangbin/dnsmasq_sniproxy_install/master/dnsmasq_sniproxy.sh
    bash dnsmasq_sniproxy.sh -f

    # 配置防火墙规则
    echo "配置防火墙规则..."
    read -p "请输入 B 机器的 IP 地址: " b_ip
    iptables -I INPUT -p udp --dport 53 -j DROP
    iptables -I INPUT -s "$b_ip" -p udp --dport 53 -j ACCEPT
    echo "防火墙规则配置完成！仅允许 B 机器访问 DNS 服务。"
    
    # 保存防火墙规则
    if [ "$DISTRO" == "ubuntu" ]; then
        sudo apt install -y iptables-persistent
        sudo netfilter-persistent save
    elif [ "$DISTRO" == "centos" ]; then
        service iptables save
    fi

    echo "A 机器配置完成！"
}

# B 机器操作
configure_B() {
    echo "正在配置 B 机器（无法解锁 Netflix 的 VPS）..."
    install_dependencies

    # 修改系统 DNS
    read -p "请输入 A 机器的 IP 地址: " a_ip
    echo "正在修改 /etc/resolv.conf..."
    sudo sed -i "s/nameserver .*/nameserver $a_ip/" /etc/resolv.conf
    echo "DNS 已修改为 A 机器的 IP ($a_ip)。"

    # 锁定 resolv.conf
    echo "锁定 /etc/resolv.conf 文件，防止系统重置 DNS..."
    sudo chattr +i /etc/resolv.conf
    echo "/etc/resolv.conf 文件已锁定！"

    echo "B 机器配置完成！"
}

# 主逻辑
if [[ "$machine_type" == "A" || "$machine_type" == "a" ]]; then
    configure_A
elif [[ "$machine_type" == "B" || "$machine_type" == "b" ]]; then
    configure_B
else
    echo "无效选择，请重新运行脚本并输入 A 或 B。"
    exit 1
fi

echo "====================================================="
echo "配置完成！感谢使用 DNS 流媒体解锁助手 v2.0"
echo "====================================================="
