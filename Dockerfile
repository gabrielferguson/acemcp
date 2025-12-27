# syntax=docker/dockerfile:1

########################
# Build stage
########################
FROM python:3.14-slim AS build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 安装 uv（用来更快安装依赖）
RUN pip install --no-cache-dir -U pip \
 && pip install --no-cache-dir uv

# 只拷贝构建所需文件（按仓库结构：pyproject + src）
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

# 给最终镜像装 git，满足 Hugging Face 自动注入的 `git config` 命令
RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

# 非 root 用户
RUN useradd -m -u 10001 appuser \
 && mkdir -p /data \
 && chown -R appuser:appuser /data

WORKDIR /app

# 把 build 阶段装好的依赖/可执行文件带过来
COPY --from=build /usr/local /usr/local

USER appuser

# Web 管理界面默认端口（README 示例 8888）
EXPOSE 8888

# 默认启动：开启 Web 面板；也允许 docker run 追加参数覆盖
ENTRYPOINT ["acemcp"]
CMD ["--web-port", "8888"]
