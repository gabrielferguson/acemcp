import asyncio
import os

from acemcp.config import init_config
from acemcp.logging_config import setup_logging
from acemcp.web.log_handler import get_log_broadcaster
from acemcp.server import run_web_server


async def main() -> None:
    """
    在 Hugging Face Spaces 里只启动 Web 管理界面，不启 MCP stdio。
    """

    # 初始化配置（会在 /data/.acemcp 下创建 settings.toml 和 data 目录）
    # base_url / token 可以走 settings.toml 或环境变量 ACEMCP_BASE_URL / ACEMCP_TOKEN
    init_config()

    # 先注册日志广播，再设置 logging（跟官方 run() 顺序一致）
    get_log_broadcaster()
    setup_logging()

    # HF 会注入 PORT 环境变量，默认用 7860
    port = int(os.getenv("PORT", "7860"))
    print(f"Starting acemcp web UI on port {port} ...", flush=True)

    # 只跑 Web 管理界面，不跑 stdio_server，这样进程不会因为 stdin 结束而退出
    await run_web_server(port)


if __name__ == "__main__":
    asyncio.run(main())
