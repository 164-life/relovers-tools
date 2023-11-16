#!/bin/bash

# Check if the OS is Debian 11 or Ubuntu 20.04 or later
os_version=$(lsb_release -cs)
if [ "$os_version" != "bullseye" ] && [ "$os_version" != "focal" ] && [ "$os_version" != "hirsute" ]; then
    echo "This script is intended for Debian 11 or Ubuntu 20.04 or later."
    exit 1
fi

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run the script with sudo."
    exit 1
fi

# Display initial message
echo "PostgreSQL User名はlovers、PostgreSQL Database名はmk1に設定されています。"

# Prompt for PostgreSQL User Password
read -s -p "Enter PostgreSQL User Password: " postgres_password
echo
export _misskey_postgrespassword2="$postgres_password"

# Install required packages
echo -n "前提パッケージのインストール... "
start_time=$(date +%s)
if sudo apt install -y nano wget curl git build-essential lsb-release ca-certificates gnupg2; then
    echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
else
    echo -e "\e[31mError: パッケージのインストール中にエラーが発生しました。\e[0m"
    exit 1
fi

# Install Node.js
echo "Node Version 選択"
echo "Node.js v20 「2」を選択してください。"
sleep 4
wget -O install.sh https://164-life.github.io/Nodejs-Easy-Installer/install.sh && sudo -E bash ./install.sh && rm ./install.sh

# Enable corepack
echo -n "corepack有効化... "
start_time=$(date +%s)
if sudo corepack enable; then
    echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
else
    echo -e "\e[31mError: corepackの有効化中にエラーが発生しました。\e[0m"
    exit 1
fi

# Install PostgreSQL
read -p "PostgreSQL v15 をインストールしますか？ (y/n): " install_postgres
if [ "$install_postgres" == "y" ]; then
    echo -n "PostgreSQL Server ｖ15 をインストール... "
    start_time=$(date +%s)
    if sudo apt install -y postgresql-common && sudo sh /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -i -v 15; then
        echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
    else
        echo -e "\e[31mError: PostgreSQLのインストール中にエラーが発生しました。\e[0m"
        exit 1
    fi
    echo "PostgreSQL Server ｖ15 をインストールしました。"
else
    read -p "PostgreSQL Client v15 をインストールしますか？ (y/n): " install_postgres_client
    if [ "$install_postgres_client" == "y" ]; then
        echo -n "PostgreSQL Client ｖ15 をインストール... "
        start_time=$(date +%s)
        if sudo apt install -y postgresql-common && sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh && sudo apt install postgresql-client-15; then
            echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
        else
            echo -e "\e[31mError: PostgreSQL Clientのインストール中にエラーが発生しました。\e[0m"
            exit 1
        fi
        echo "PostgreSQL Client ｖ15 をインストールしました。"
    else
        echo "PostgreSQLのインストールはスキップされました。"
    fi
fi

# Install Redis
echo -n "Redis v7 をインストール... "
start_time=$(date +%s)
if curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $os_version main" | sudo tee /etc/apt/sources.list.d/redis.list && sudo apt update && sudo apt install redis && sudo systemctl enable redis-server; then
    echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
else
    echo -e "\e[31mError: Redisのインストール中にエラーが発生しました。\e[0m"
    exit 1
fi

# Configure PostgreSQL
echo -n "PostgreSQL 設定... "
start_time=$(date +%s)
if sudo -u postgres psql -c "CREATE ROLE misskey LOGIN PASSWORD '$_misskey_postgrespassword2'; CREATE DATABASE mk1 OWNER lovers;"; then
    echo -e "\e[34mOs\e[0m: $(($(date +%s) - start_time))s"
else
    echo -e "\e[31mError: PostgreSQLの設定中にエラーが発生しました。\e[0m"
    exit 1
fi

# Display final message
echo "初期工程は終わりました。後は各自 Misskeyの設定を行ってください。"
echo "PostgreSQL User 名: lovers"
echo "PostgreSQL User Password: $_misskey_postgrespassword2"
echo "PostgreSQL Database名: mk1"
