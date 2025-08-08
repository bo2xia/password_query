# 使用官方 Python 3.9 镜像
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 复制项目文件
COPY . .

# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建 instance 目录并设置权限
RUN mkdir -p /app/instance && chmod -R 777 /app/instance

# 暴露端口
EXPOSE 5000

# 设置环境变量
ENV FLASK_APP=app.py
ENV SECRET_KEY=your-secure-secret-key  # 请替换为安全密钥

# 运行应用
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]