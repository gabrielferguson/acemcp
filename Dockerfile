########################
# Build stage
########################
FROM python:3.10-slim AS build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 为可能需要编译的依赖准备基础工具（uvicorn[standard] 里带 uvloop/httptools 等）
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv（项目本身就是用 uv/uvx）
RUN pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir uv

# 拷贝构建所需文件
COPY pyproject.toml uv.lock README.md README_EN.md UPLOAD_EXCEPTION_HANDLING.md ./
COPY src ./src

# 安装 acemcp 到系统 site-packages（build 阶段）
RUN uv pip install --system --no-cache-dir .

########################
# Runtime stage
########################
FROM python:3.10-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data

WORKDIR /app

# 1. 安装 git：解决 HF 在 runtime 阶段强行执行
#    `git config --global user.email ...` / `user.name ...` 时的 git: not found
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
    && rm -rf /var/lib/apt/lists/*

# 2. 创建非 root 用户 + 数据目录（/data 在 HF 会持久化）
RUN useradd -m -u 10001 appuser \
 && mkdir -p /data \
 && chown -R appuser:appuser /data

# 3. 拷贝 build 阶段已经安装好的依赖和 acemcp
COPY --from=build /usr/local /usr/local

# 4. 拷贝我们刚才写的启动脚本
COPY space_web.py ./space_web.py

# 切到非 root 用户运行
USER appuser

# HF Spaces 默认用 PORT 环境变量暴露服务端口，习惯性设一下默认
ENV PORT=7860

# 声明容器监听端口（HF 会把第一个 EXPOSE 的端口当成入口）
EXPOSE 7860

# 只启动 Web 管理界面，不走 acemcp:run（避免 stdio 结束导致进程退出）
CMD ["python", "space_web.py"]
