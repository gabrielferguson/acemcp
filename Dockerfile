# 单阶段 Dockerfile，兼容 Hugging Face Spaces + Dev Mode

FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data

# 必须：给 Dev Mode 准备的系统工具（文档要求 bash/curl/wget/procps/git/git-lfs）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        wget \
        procps \
        git \
        git-lfs && \
    rm -rf /var/lib/apt/lists/*

# 创建运行用户（uid=1000 是 Dev Mode 的要求之一），顺便准备 /app 和 /data
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app /data && \
    chown -R appuser:appuser /app /data

# 代码必须在 /app（Dev Mode 要求）
WORKDIR /app

# 把 Space 仓库里的所有文件拷进来（这里你应该已经把 acemcp 源码放进了 Space 仓库）
COPY . /app

# 安装 acemcp 依赖（用 uv 安装项目本身）
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir uv && \
    uv pip install --system --no-cache-dir .

# 确保 /app 归 uid 1000 管（Dev Mode 要求）
RUN chown -R 1000 /app

# 以后所有进程都用 uid 1000（和上面的 chown 对应）
USER 1000

# Hugging Face Docker 默认暴露端口 7860（也可以在 README 里 app_port 改）
EXPOSE 7860

# 启动 acemcp，Web 管理界面监听 7860
# Dev Mode 只是把你的 app 当子进程起，这里 CMD 必须存在
CMD ["acemcp", "--web-port", "7860"]
