########################
# Build stage
########################
FROM python:3.14-slim AS build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 安装 uv，用它来装依赖
RUN pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir uv

# 只拷贝构建所需文件
COPY pyproject.toml uv.lock README.md README_EN.md UPLOAD_EXCEPTION_HANDLING.md ./
COPY src ./src

# 安装到系统 site-packages（build 阶段）
RUN uv pip install --system --no-cache-dir .

########################
# Runtime stage
########################
FROM python:3.14-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data

# 非 root 用户 + 数据目录
RUN useradd -m -u 10001 appuser \
 && mkdir -p /data \
 && chown -R appuser:appuser /data

WORKDIR /app

# 把 build 阶段装好的依赖/可执行文件带过来
COPY --from=build /usr/local /usr/local

USER appuser

# HF Docker Space 默认应用端口是 7860（也会通过 $PORT 注入）
EXPOSE 7860

# 启动 acemcp，Web 管理界面监听 $PORT（默认 7860）
# 使用 sh -c 是为了在 CMD 里展开环境变量
ENTRYPOINT ["sh", "-c", "exec acemcp --web-port ${PORT:-7860}"]
