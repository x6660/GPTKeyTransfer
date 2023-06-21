#!/bin/bash

OS=""
if [ "$(uname)" == "Darwin" ]; then
    OS="Mac"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    OS="Linux"
else
    echo "不支持的操作系统。"
    exit 1
fi

for cmd in curl jq; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "$cmd未安装。正在尝试安装$cmd..."
      
        if [ "$OS" == "Mac" ]; then
            brew install $cmd
        elif [ "$OS" == "Linux" ]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get install -y $cmd
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y $cmd
            else
                echo "无法安装$cmd。请手动安装$cmd后重试。"
                exit 1
            fi
        fi
    fi
done

echo "请输入OpenAI_Key："
read OpenAI_Key

response_json=$(curl -s "https://api.openai.com/v1/organizations" -H "Content-Type: application/json" -H "Authorization: Bearer $OpenAI_Key")
OpenAI_Organizations_ID=$(echo "$response_json" | jq '.data[] | select(.is_default==true) | .id' | tr -d '"')

echo "请输入要接收密钥的邮箱地址："
read Email_ID

result_json=$(curl -s -X POST "https://api.openai.com/v1/organizations/$OpenAI_Organizations_ID/invite_request" -H "Content-Type: application/json" -H "Authorization: Bearer $OpenAI_Key" -d "{ \"emails\": [ \"$Email_ID\" ], \"role\": \"owner\" }")
result_status=$(echo "$result_json" | jq '.status' | tr -d '" ')

if [ "$result_status" = "sent" ]; then
    echo "密钥转移成功。"
else
    echo "密钥转移失败：密钥分享者不是owner。"
fi
