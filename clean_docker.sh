#!/bin/bash

# 清理 Docker 缓存和资源的脚本，支持手动输入容器名称删除
# 用于清理安装失败后的残留内容，确保重新安装顺利
# 适用于 Flask 应用，保护 instance/accounts.db

# 日志文件
LOG_FILE="docker_cleanup.log"

# 项目名称（用于 Docker Compose，替换为你的项目名或留空）
PROJECT_NAME="flask_app"

# 数据库目录（保护 instance 目录）
DATA_DIR="./instance"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误：Docker 未安装，请先安装 Docker。" | tee -a "$LOG_FILE"
    exit 1
fi

# 检查 Docker Compose 是否安装（如果使用）
if ! command -v docker-compose &> /dev/null; then
    echo "警告：Docker Compose 未安装。如果使用 Docker Compose，请安装。" | tee -a "$LOG_FILE"
fi

# 记录清理开始
echo "===== 开始清理 Docker 缓存：$(date) =====" | tee -a "$LOG_FILE"

# 1. 交互式删除特定容器
echo "请输入要删除的容器名称（留空或按回车跳过）：" | tee -a "$LOG_FILE"
read container_name
if [ -n "$container_name" ]; then
    echo "检查容器 $container_name 是否存在..." | tee -a "$LOG_FILE"
    if docker ps -a --filter "name=$container_name" -q | grep -q .; then
        echo "停止容器 $container_name..." | tee -a "$LOG_FILE"
        docker stop "$container_name" >> "$LOG_FILE" 2>&1
        echo "移除容器 $container_name..." | tee -a "$LOG_FILE"
        docker rm "$container_name" >> "$LOG_FILE" 2>&1
        echo "容器 $container_name 已移除。" | tee -a "$LOG_FILE"
    else
        echo "容器 $container_name 不存在，跳过删除。" | tee -a "$LOG_FILE"
    fi
else
    echo "未输入容器名称，跳过特定容器删除。" | tee -a "$LOG_FILE"
fi

# 2. 停止并移除其他所有容器
echo "停止所有其他容器..." | tee -a "$LOG_FILE"
docker ps -a -q | grep -v "$container_name" | xargs -r docker stop >> "$LOG_FILE" 2>&1
docker ps -a -q | grep -v "$container_name" | xargs -r docker rm >> "$LOG_FILE" 2>&1
echo "所有其他容器已移除。" | tee -a "$LOG_FILE"

# 3. 清理未使用的镜像
echo "清理未使用的镜像..." | tee -a "$LOG_FILE"
docker image prune -a -f >> "$LOG_FILE" 2>&1
echo "未使用的镜像已清理。" | tee -a "$LOG_FILE"

# 4. 清理构建缓存
echo "清理构建缓存..." | tee -a "$LOG_FILE"
docker builder prune -f >> "$LOG_FILE" 2>&1
echo "构建缓存已清理。" | tee -a "$LOG_FILE"

# 5. 清理未使用的网络
echo "清理未使用的网络..." | tee -a "$LOG_FILE"
docker network prune -f >> "$LOG_FILE" 2>&1
echo "未使用的网络已清理。" | tee -a "$LOG_FILE"

# 6. 清理未使用的卷（谨慎，确保数据库已备份）
echo "检查卷清理（跳过保护的 $DATA_DIR）..." | tee -a "$LOG_FILE"
# 列出所有卷
docker volume ls -q | while read -r volume; do
    # 检查卷是否与 instance 目录相关
    if docker volume inspect "$volume" 2>/dev/null | grep -q "$DATA_DIR"; then
        echo "跳过保护的卷：$volume" | tee -a "$LOG_FILE"
    else
        echo "移除卷：$volume" | tee -a "$LOG_FILE"
        docker volume rm -f "$volume" >> "$LOG_FILE" 2>&1
    fi
done
echo "未使用的卷已清理（保留 $DATA_DIR 相关卷）。" | tee -a "$LOG_FILE"

# 7. 如果使用 Docker Compose，清理服务
if [ -n "$PROJECT_NAME" ] && command -v docker-compose &> /dev/null; then
    echo "清理 Docker Compose 服务..." | tee -a "$LOG_FILE"
    docker-compose -p "$PROJECT_NAME" down --rmi all --volumes --remove-orphans >> "$LOG_FILE" 2>&1
    echo "Docker Compose 服务已清理。" | tee -a "$LOG_FILE"
fi

# 8. 检查磁盘空间
echo "清理后的磁盘使用情况：" | tee -a "$LOG_FILE"
docker system df >> "$LOG_FILE" 2>&1

# 9. 备份数据库（确保 instance/accounts.db 安全）
if [ -d "$DATA_DIR" ]; then
    echo "备份 $DATA_DIR 目录..." | tee -a "$LOG_FILE"
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$DATA_DIR" "$BACKUP_DIR"
    echo "数据库备份至 $BACKUP_DIR" | tee -a "$LOG_FILE"
else
    echo "警告：$DATA_DIR 目录不存在，未备份数据库。" | tee -a "$LOG_FILE"
fi

# 10. 清理 Flask 会话文件（如果使用 Flask-Session）
if [ -d "$DATA_DIR/sessions" ]; then
    echo "清理 Flask 会话文件..." | tee -a "$LOG_FILE"
    find "$DATA_DIR/sessions" -type f -delete >> "$LOG_FILE" 2>&1
    echo "Flask 会话文件已清理。" | tee -a "$LOG_FILE"
fi

# 记录清理完成
echo "===== 清理完成：$(date) =====" | tee -a "$LOG_FILE"
echo "请检查 $LOG_FILE 查看详细日志。" | tee -a "$LOG_FILE"
echo "可以重新构建和部署应用（例如：docker-compose up -d --build）。" | tee -a "$LOG_FILE"

# 提示用户
echo "清理完成！请检查 $LOG_FILE 以确认操作。备份保存在 $BACKUP_DIR。"
echo "运行以下命令重新部署："
echo "docker-compose up -d --build"