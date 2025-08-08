# 使用 Python 3.9 作为基础镜像
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 复制 requirements.txt 并安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 设置环境变量
ENV FLASK_APP=app.py
# 请替换为安全密钥
ENV SECRET_KEY=your-secure-secret-key

# 设置 UTF-8 支持（确保中文用户名正常）
ENV LANG=C.UTF-8

# 暴露端口
EXPOSE 5000

# 运行 Flask 应用
CMD ["python", "app.py"]
