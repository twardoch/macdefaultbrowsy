# macdefaultbrowsy/__main__.py
import sys
import fire
from loguru import logger
from typing import Optional

from . import macdefaultbrowsy

logger.remove()
logger.add(sys.stderr, format="{message}")


def cli(browser_id: str | None = None):
    """
    Manages the default web browser on macOS.

    :param browser_id: The browser to set as default. If not provided,
                       lists available browsers.
    """
    if browser_id:
        macdefaultbrowsy.set_default_browser(browser_id)
    else:
        macdefaultbrowsy.print_browsers_list()


if __name__ == "__main__":
    fire.Fire(cli)
