

#!/bin/bash

# 定义颜色代码
# color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
# text
BOLD=$(tput bold)
# reset
RESET=$(tput sgr0)


# 配置列表
declare -a config_lines
# user
declare -a user
# host
declare -a host
# port
declare -a port
# password
declare -a password

# 加载服务列表
function load_server_list() {
    local file="./cssh_config.conf"
    if [ ! -f "$file" ]; then
        echo "Config file not found: $file"
        return 1
    fi
    while read -r line || [[ -n "$line" ]]; do
        # 过滤空行
        if [ -z "$line" ]; then
            continue
        fi
        # 去掉行首的空格
        line=${line##*( )}
        # 判断行首是否为 #
        if [[ $line != \#* ]]; then
            # 将非注释行添加到数组中
            config_lines+=("$line")
        fi
    done < "$file"
}

# 打印服务列表
function show_server_list() {
    local show_delay=0
    printf "${BOLD}${MAGENTA}server list:${RESET}\n"
    for line_index in "${!config_lines[@]}"; do
        # 将每个项拆分为数组
        read -ra items <<< "${config_lines[line_index]}"
        # 打印每个项
        local length=${#items[@]}
        if [ $length -ge 3 ]; then
            local l_desc=${items[0]}
            local l_user=${items[1]}
            local l_host=${items[2]}
            local l_port=${items[3]}
            local delay=0
            if [ $show_delay -eq 1 ]; then
                delay=$(ping -c 4 -i 0.2 -W 1 "$l_host" | grep 'round-trip' | awk -F '/' '{print $5}')
            fi
            printf "${YELLOW}$line_index${RESET} ${GREEN}$l_desc $l_user $l_host $l_port ${YELLOW}$delay${RESET}\n"
        fi
    done
}

# 选择服务
function select_server() {
    length=${#config_lines[@]}
    local select_success=0
    local select_index=0
    while true; do
        read -p "${CYAN}please input index: ${RESET}" select_index
        if [[ $select_index =~ ^[0-9]+$ ]]; then
            if [ $select_index -ge 0 ] && [ $select_index -lt 100 ]; then
                select_success=1
                break
            else
                printf "${RED}Enter out of bounds, re-enter${RESET}\n"
            fi
        else
            printf "${RED}The number entered is not a number, please re-enter!${RESET}\n"
        fi
    done
    if [ $select_success -eq 1 ]; then
        local line_content=${config_lines[select_index]}
        # 将每个项拆分为数组
        read -ra items <<< "$line_content"
        # 赋值
        user=${items[1]}
        host=${items[2]}
        port=${items[3]}
        password=${items[4]}
        return 0
    fi
    return 1
}

# 登陆
function ssh_login() {
    expect -c "
        set timeout 5
        spawn ssh $user@$host -p $port
        expect {
            \"yes/no\" {
                send \"yes\r\"
                exp_continue
            }
            \"password:\" {
                send \"$password\r\"
            }
        }
        interact
    "
}

# 
function entry() {
    load_server_list
    show_server_list
    select_server
    ssh_login
}

entry
