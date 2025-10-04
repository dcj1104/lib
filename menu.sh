#!/bin/bash
# 一个整合脚本管理器，可以从远程加载并运行子脚本
# 用法：bash <(curl -Ls https://raw.githubusercontent.com/dcj1104/lib/refs/heads/main/main.sh)

# ================== 配置区 ==================
# 脚本列表（名称|URL），一行一个
SCRIPTS=(
  "修改Banner|https://raw.githubusercontent.com/dcj1104/lib/refs/heads/main/banner.sh"
  "修改ssh端口|https://raw.githubusercontent.com/dcj1104/lib/refs/heads/main/change-ssh-port.sh"
  # 你可以继续添加，比如：
  # "安装Docker|https://raw.githubusercontent.com/xxx/xxx/docker.sh"
)
# ================== 配置区结束 ==============


# 打印菜单
print_menu() {
  clear
  echo "========================================="
  echo "   脚本管理器 (by Moreanp) "
  echo "========================================="
  echo
  local i=1
  for item in "${SCRIPTS[@]}"; do
    name="${item%%|*}"
    echo "  $i) $name"
    ((i++))
  done
  echo "  0) 退出"
  echo
}

# 主循环
while true; do
  print_menu
  read -rp "请输入要执行的选项编号: " choice

  if [[ "$choice" == "0" ]]; then
    echo "退出脚本管理器"
    exit 0
  fi

  # 判断输入是否合法
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#SCRIPTS[@]} )); then
    selected="${SCRIPTS[choice-1]}"
    name="${selected%%|*}"
    url="${selected#*|}"

    echo
    echo "👉 正在执行 [$name] ..."
    echo "-----------------------------------------"
    bash <(curl -Ls "$url")
    echo "-----------------------------------------"
    echo "✅ [$name] 执行完毕，按回车键返回菜单..."
    read -r
  else
    echo "❌ 输入无效，请重新选择"
    sleep 1
  fi
done
