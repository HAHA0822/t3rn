#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "================================================================"
        echo "===========================  HaHa  ============================="
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 执行脚本"
        echo "2) 查看日志"
        echo "3) 重启节点"
        echo "4) 清除旧版本"
        echo "5) 退出"
        
        read -p "请输入你的选择 [1-3]: " choice
        
        case $choice in
            1)
                execute_script
                ;;
            2)
                view_logs
                ;;
            3)
                restart_node
                ;;
            4)
                cleanup_old_files
                ;;
            5)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选择，请重新输入。"
                ;;
        esac
    done
}

# 执行脚本函数
function execute_script() {
    # 下载文件
    if [ -f "executor-linux-v0.27.0.tar.gz" ]; then
        echo "文件 executor-linux-v0.27.0.tar.gz 已存在，跳过下载。"
    else
        echo "正在下载 executor-linux-v0.27.0.tar.gz..."
        wget https://github.com/t3rn/executor-release/releases/download/v0.27.0/executor-linux-v0.27.0.tar.gz

        # 检查下载是否成功
        if [ $? -eq 0 ]; then
            echo "下载成功。"
        else
            echo "下载失败，请检查网络连接或下载地址。"
            exit 1
        fi

        # 解压文件到当前目录
        echo "正在解压文件..."
        tar -xvzf executor-linux-v0.27.0.tar.gz
    fi

    # 检查解压是否成功
    if [ $? -eq 0 ]; then
        echo "解压成功。"
    else
        echo "解压失败，请检查 tar.gz 文件。"
        exit 1
    fi

    # 检查解压后的文件名是否包含 'executor'
    echo "正在检查解压后的文件或目录名称是否包含 'executor'..."
    if ls | grep -q 'executor'; then
        echo "检查通过，找到包含 'executor' 的文件或目录。"
    else
        echo "未找到包含 'executor' 的文件或目录，可能文件名不正确。"
        exit 1
    fi

    # 设置环境变量
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'

    # 提示用户输入私钥
    read -p "请输入 PRIVATE_KEY_LOCAL 的值: " PRIVATE_KEY_LOCAL

    # 设置私钥变量
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 删除压缩文件
    echo "删除压缩包..."
    rm executor-linux-v0.27.0.tar.gz

    # 切换目录并执行脚本
    echo "切换目录并执行 ./executor..."
    cd ~/executor/executor/bin

    # 重定向日志输出
    # ./executor > "$LOGFILE" 2>&1 &

    # 使用 pm2 启动 executor
    pm2 start ./executor --name executor --log "$LOGFILE" --env NODE_ENV=$NODE_ENV --env LOG_LEVEL=$LOG_LEVEL --env LOG_PRETTY=$LOG_PRETTY --env ENABLED_NETWORKS=$ENABLED_NETWORKS --env PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL" 

    # 显示 pm2 进程列表
    pm2 list

    # 显示后台进程 PID
    echo "executor 进程已启动，PID: $!"

    echo "操作完成。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看日志函数
function view_logs() {
    # if [ -f "$LOGFILE" ]; then
    #     echo "显示日志文件内容（最后 50 行）："
    #     tail -n 50 -f "$LOGFILE"
    # else
    #     echo "日志文件不存在。"
    # fi
    pm2 logs executor

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 删除解压文件和压缩包的函数
function cleanup_old_files() {
    # 定义解压后的文件夹路径和压缩包路径
    EXTRACTED_DIR="$HOME/executor"

    # 检查并删除解压后的文件夹
    if [ -d "$EXTRACTED_DIR" ]; then
        echo "找到解压后的文件夹: $EXTRACTED_DIR"
        echo "正在删除解压后的文件夹..."
        rm -rf "$EXTRACTED_DIR"
        if [ $? -eq 0 ]; then
            echo "解压后的文件夹已成功删除。"
        else
            echo "删除文件夹失败，请检查权限或其他问题。"
            return 1  # 如果删除失败，返回错误代码
        fi
    else
        echo "未找到解压后的文件夹: $EXTRACTED_DIR"
    fi

    echo "清理完成。"
    return 0  # 成功完成时返回0
}

function restart_node(){
    # 设置环境变量
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'

    # 提示用户输入私钥
    read -p "请输入 PRIVATE_KEY_LOCAL 的值: " PRIVATE_KEY_LOCAL

    # 设置私钥变量
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 切换目录并执行脚本
    echo "切换目录并执行 ./executor..."
    cd ~/executor/executor/bin

    # 重定向日志输出
    # ./executor > "$LOGFILE" 2>&1 &

    # 使用 pm2 启动 executor
    pm2 start ./executor --name executor --log "$LOGFILE" --env NODE_ENV=$NODE_ENV --env LOG_LEVEL=$LOG_LEVEL --env LOG_PRETTY=$LOG_PRETTY --env ENABLED_NETWORKS=$ENABLED_NETWORKS --env PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 显示 pm2 进程列表
    pm2 list

    # 显示后台进程 PID
    echo "executor 进程已启动，PID: $!"

    echo "操作完成。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 启动主菜单
main_menu
