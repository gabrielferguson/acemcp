########################
# Build stage
########################
FROM python:3.14-slim AS build

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# uv 用于更快安装（项目文档也推荐 uv/uvx）:contentReference[oaicite:4]{index=4}
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

# 非 root 用户
RUN useradd -m -u 10001 appuser \
 && mkdir -p /data \
 && chown -R appuser:appuser /data

WORKDIR /app

# 把 build 阶段装好的依赖/可执行文件带过来
COPY --from=build /usr/local /usr/local

USER appuser

# Web 管理界面默认端口（README 示例 8888）:contentReference[oaicite:5]{index=5}
EXPOSE 8888

# 默认启动：开启 Web 面板；也允许 docker run 追加参数覆盖
ENTRYPOINT ["acemcp"]
CMD ["--web-port", "8888"]
