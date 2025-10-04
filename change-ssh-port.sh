#!/bin/bash

# 通用 SSH 端口修改脚本
# 支持 Ubuntu, Debian, CentOS, Fedora, RHEL, openSUSE 等主流发行版
# 用法: sudo ./change-ssh-port.sh [新端口号]

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 此脚本需要 root 权限执行" >&2
    exit 1
fi

# 获取新端口
NEW_PORT=${1:-}
if [ -z "$NEW_PORT" ]; then
    read -p "请输入新的 SSH 端口号 (1024-65535): " NEW_PORT
fi

# 验证端口号
if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
    echo "错误: 无效端口号 ($NEW_PORT)，请使用 1024-65535 之间的数字" >&2
    exit 1
fi

# 备份原始配置文件
BACKUP_FILE="/etc/ssh/sshd_config.$(date +%Y%m%d%H%M%S).bak"
cp /etc/ssh/sshd_config "$BACKUP_FILE"
echo "已创建配置文件备份: $BACKUP_FILE"

# 修改 SSH 配置
if grep -q "^Port " /etc/ssh/sshd_config; then
    sed -i "s/^Port .*/Port $NEW_PORT/" /etc/ssh/sshd_config
else
    # 如果不存在 Port 行，在文件开头添加
    echo -e "Port $NEW_PORT\n$(cat /etc/ssh/sshd_config)" > /etc/ssh/sshd_config.tmp
    mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
fi

# 配置防火墙 (支持 ufw, firewalld, iptables)
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q active; then
    ufw allow "$NEW_PORT/tcp"
    echo "已配置 UFW 防火墙开放端口 $NEW_PORT"
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state &>/dev/null; then
    firewall-cmd --permanent --add-port="$NEW_PORT/tcp"
    firewall-cmd --reload
    echo "已配置 firewalld 开放端口 $NEW_PORT"
elif command -v iptables >/dev/null 2>&1; then
    iptables -A INPUT -p tcp --dport "$NEW_PORT" -j ACCEPT
    # 尝试保存规则 (支持不同发行版)
    if command -v iptables-save >/dev/null 2>&1; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
        iptables-save > /etc/sysconfig/iptables 2>/dev/null
    fi
    echo "已配置 iptables 开放端口 $NEW_PORT"
fi

# SELinux 配置 (如果启用)
if command -v sestatus >/dev/null 2>&1 && sestatus | grep -q enabled; then
    if command -v semanage >/dev/null 2>&1; then
        semanage port -a -t ssh_port_t -p tcp "$NEW_PORT"
    else
        echo "警告: SELinux 已启用但 semanage 未安装，可能需要手动配置"
    fi
fi

# 重启 SSH 服务
if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null; then
    echo "SSH 服务已重启"
else
    echo "警告: 无法重启 SSH 服务，请手动执行: systemctl restart sshd"
fi

# 测试新端口
echo -e "\n配置完成！请在新终端中使用以下命令测试连接:"
echo "ssh -p $NEW_PORT $(whoami)@$(hostname -I | awk '{print $1}')"

echo -e "\n重要提示:"
echo "1. 测试新端口连接成功后再关闭旧端口 (22)"
echo "2. 防火墙使用命令: ufw delete allow 22/tcp 或 firewall-cmd --remove-port=22/tcp --permanent"
echo "3. 在 /etc/ssh/sshd_config 中删除 'Port 22' 行并重启 SSH 服务"
