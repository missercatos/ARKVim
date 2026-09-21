-- arkvim/scaffold/python.lua — Python 模板（Web / 爬虫 / GUI / 数据 / 测试）
local util = require("arkvim.scaffold.util")

local M = {}
local gen = {}

local PY_REQ = { bins = { "python3" }, pacman = { "python" } }

local function req(extra)
  return vim.tbl_deep_extend("force", { bins = { "python3" } }, extra or {})
end

-- ---------------------------------------------------------------------------
-- 基础 / Web
-- ---------------------------------------------------------------------------

gen.py_pkg = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pyproject.toml"] = util.fill('[build-system]\nrequires = ["setuptools>=68"]\nbuild-backend = "setuptools.build_meta"\n\n[project]\nname = "{{kebab}}"\nversion = "0.1.0"\nrequires-python = ">=3.9"\n', t),
    ["src/" .. t.snake .. "/__init__.py"] = '"""' .. t.NAME .. ' package."""\n__version__ = "0.1.0"\n',
    ["src/" .. t.snake .. "/__main__.py"] = util.fill('from {{snake}} import __version__\ndef main(): print(f"Hello from {{NAME}} (v{__version__})")\nif __name__ == "__main__": main()\n', t),
    [".gitignore"] = ".venv/\n__pycache__/\n*.egg-info/\n",
  })
  return "Python package 已生成"
end

gen.fastapi = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app/__init__.py"] = "",
    ["app/main.py"] = util.fill('from fastapi import FastAPI\napp = FastAPI(title="{{NAME}}")\n@app.get("/")\ndef root(): return {"message": "Hello from {{NAME}}!"}\n', t),
    ["requirements.txt"] = "fastapi>=0.110\nuvicorn[standard]>=0.29\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "FastAPI 已生成"
end

gen.fastapi_db = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app/__init__.py"] = "",
    ["app/main.py"] = util.fill([[from fastapi import FastAPI
from .db import Base, engine
from . import models

app = FastAPI(title="{{NAME}}")

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

@app.get("/")]
def root():
    return {"message": "Hello from {{NAME}}!"}
]], t),
    ["app/db.py"] = 'from sqlalchemy import create_engine\nfrom sqlalchemy.orm import sessionmaker, declarative_base\n\nDATABASE_URL = "sqlite:///./app.db"\nengine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})\nSessionLocal = sessionmaker(bind=engine, autoflush=False)\nBase = declarative_base()\n',
    ["app/models.py"] = 'from sqlalchemy import Column, Integer, String\nfrom .db import Base\n\nclass Item(Base):\n    __tablename__ = "items"\n    id = Column(Integer, primary_key=True)\n    name = Column(String, nullable=False)\n',
    ["alembic.ini"] = "[alembic]\nscript_location = migrations\nsqlalchemy.url = sqlite:///./app.db\n",
    ["requirements.txt"] = "fastapi>=0.110\nuvicorn[standard]>=0.29\nsqlalchemy>=2.0\nalembic>=1.13\n",
    [".gitignore"] = ".venv/\n__pycache__/\n*.db\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npip install -r requirements.txt\nuvicorn app.main:app --reload\n```\n", t),
  })
  return "FastAPI + SQLAlchemy + Alembic 已生成"
end

gen.django = function(target, name)
  util.write_tree(target, {
    ["manage.py"] = '#!/usr/bin/env python\nimport os, sys\nif __name__ == "__main__":\n    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings")\n    from django.core.management import execute_from_command_line\n    execute_from_command_line(sys.argv)\n',
    ["settings.py"] = 'SECRET_KEY = "dev"\nINSTALLED_APPS = ["django.contrib.contenttypes"]\nROOT_URLCONF = "urls"\n',
    ["urls.py"] = 'from django.urls import path\nurlpatterns = []\n',
    ["requirements.txt"] = "django>=5.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n*.pyc\n",
  })
  return "Django 骨架已生成 (需 pip install -r requirements.txt && python manage.py migrate)"
end

gen.flask = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app.py"] = util.fill('from flask import Flask\napp = Flask(__name__)\n@app.route("/")\ndef index(): return "Hello from {{NAME}}!"\nif __name__ == "__main__": app.run(debug=True)\n', t),
    ["requirements.txt"] = "flask>=3.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "Flask 已生成"
end

gen.typer = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pyproject.toml"] = util.fill('[build-system]\nrequires = ["hatchling"]\nbuild-backend = "hatchling.build"\n\n[project]\nname = "{{kebab}}"\nversion = "0.1.0"\nrequires-python = ">=3.10"\ndependencies = ["typer[all]>=0.9"]\n\n[project.scripts]\n{{kebab}} = "{{snake}}.main:app"\n', t),
    ["src/" .. t.snake .. "/__init__.py"] = '__version__ = "0.1.0"\n',
    ["src/" .. t.snake .. "/main.py"] = util.fill('import typer\napp = typer.Typer()\n@app.command()\ndef main(name: str = "World"): print(f"Hello from {{NAME}}, {name}!")\nif __name__ == "__main__": app()\n', t),
    [".gitignore"] = ".venv/\n__pycache__/\n*.egg-info/\n",
  })
  return "Typer CLI 已生成"
end

gen.argparse_cli = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/main.py"] = util.fill([[import argparse


def main() -> None:
    parser = argparse.ArgumentParser(prog="{{kebab}}", description="{{NAME}}")
    parser.add_argument("name", nargs="?", default="World", help="名字")
    parser.add_argument("-v", "--verbose", action="store_true", help="详细输出")
    args = parser.parse_args()

    msg = f"Hello from {{NAME}}, {args.name}!"
    print(msg if args.verbose else msg.split("!")[0])


if __name__ == "__main__":
    main()
]], t),
    ["requirements.txt"] = "",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "Python CLI (argparse, 零依赖) 已生成"
end

-- ---------------------------------------------------------------------------
-- 爬虫
-- ---------------------------------------------------------------------------

gen.spider_bs4 = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/fetch.py"] = [[import requests

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/122.0 Safari/537.36"
    )
}


def fetch(url: str, *, timeout: int = 15) -> str:
    resp = requests.get(url, headers=HEADERS, timeout=timeout)
    resp.raise_for_status()
    resp.encoding = resp.apparent_encoding or resp.encoding
    return resp.text
]],
    ["src/" .. t.snake .. "/parse.py"] = [=[from bs4 import BeautifulSoup


def parse(html: str) -> list[dict]:
    """按需改这里的 selector。"""
    soup = BeautifulSoup(html, "html.parser")
    items: list[dict] = []
    for node in soup.select("h2 a"):
        items.append(
            {
                "title": node.get_text(strip=True),
                "url": node.get("href"),
            }
        )
    return items
]=],
    ["src/" .. t.snake .. "/__main__.py"] = util.fill([=[import csv
import sys

from .fetch import fetch
from .parse import parse


def main() -> None:
    url = sys.argv[1] if len(sys.argv) > 1 else "https://news.ycombinator.com/"
    items = parse(fetch(url))

    with open("output.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["title", "url"])
        writer.writeheader()
        writer.writerows(items)

    print(f"{{NAME}}: 抓到 {len(items)} 条 -> output.csv")


if __name__ == "__main__":
    main()
]=], t),
    ["requirements.txt"] = "requests>=2.31\nbeautifulsoup4>=4.12\nlxml>=5.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\noutput.csv\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npython -m venv .venv && source .venv/bin/activate\npip install -r requirements.txt\npython -m {{snake}} https://example.com\n```\n", t),
  })
  return "Python 爬虫 (requests + BeautifulSoup) 已生成"
end

gen.scrapy = function(target, name)
  local t = util.project_tokens(name)
  local pkg = t.snake
  util.write_tree(target, {
    ["scrapy.cfg"] = "[settings]\ndefault = " .. pkg .. ".settings\n\n[deploy]\nproject = " .. pkg .. "\n",
    [pkg .. "/__init__.py"] = "",
    [pkg .. "/items.py"] = util.fill([=[import scrapy


class MainItem(scrapy.Item):
    title = scrapy.Field()
    url = scrapy.Field()
]=], t),
    [pkg .. "/settings.py"] = util.fill([=[BOT_NAME = "{{kebab}}"

SPIDER_MODULES = ["{{snake}}.spiders"]
NEWSPIDER_MODULE = "{{snake}}.spiders"

ROBOTSTXT_OBEY = True
CONCURRENT_REQUESTS = 8
DOWNLOAD_DELAY = 0.5
DEFAULT_REQUEST_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "User-Agent": "{{kebab}} (+https://example.com)",
}
ITEM_PIPELINES = {"{{snake}}.pipelines.MainPipeline": 300}
REQUEST_FINGERPRINTER_IMPLEMENTATION = "2.7"
]=], t),
    [pkg .. "/pipelines.py"] = [=[class MainPipeline:
    def process_item(self, item, spider):
        return item
]=],
    [pkg .. "/middlewares.py"] = [=[from scrapy import signals


class MainSpiderMiddleware:
    @classmethod
    def from_crawler(cls, crawler):
        s = cls()
        crawler.signals.connect(s.spider_opened, signal=signals.spider_opened)
        return s

    def process_spider_input(self, response, spider):
        return None

    def process_spider_output(self, response, result, spider):
        yield from result

    def spider_opened(self, spider):
        spider.logger.info("Spider opened: %s", spider.name)
]=],
    [pkg .. "/spiders/__init__.py"] = "",
    [pkg .. "/spiders/example.py"] = util.fill([=[import scrapy

from ..items import MainItem


class ExampleSpider(scrapy.Spider):
    name = "example"
    allowed_domains = ["news.ycombinator.com"]
    start_urls = ["https://news.ycombinator.com/"]

    def parse(self, response):
        for node in response.css("h2 a"):
            yield MainItem(
                title=node.css("::text").get(),
                url=node.attrib.get("href"),
            )
]=], t),
    ["requirements.txt"] = "scrapy>=2.11\n",
    [".gitignore"] = ".venv/\n__pycache__/\n.scrapy/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npython -m venv .venv && source .venv/bin/activate\npip install -r requirements.txt\nscrapy crawl example -O output.json\n```\n", t),
  })
  return "Scrapy 爬虫已生成"
end

gen.spider_playwright = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/__main__.py"] = util.fill([=[import asyncio

from playwright.async_api import async_playwright


async def scrape(url: str) -> list[dict]:
    items: list[dict] = []
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        await page.goto(url, wait_until="networkidle")

        for node in await page.query_selector_all("h2 a"):
            items.append(
                {
                    "title": (await node.inner_text()).strip(),
                    "url": await node.get_attribute("href"),
                }
            )

        await browser.close()
    return items


def main() -> None:
    import sys

    url = sys.argv[1] if len(sys.argv) > 1 else "https://example.com"
    items = asyncio.run(scrape(url))
    print(f"{{NAME}}: 抓到 {len(items)} 条")
    for it in items[:10]:
        print("-", it["title"])


if __name__ == "__main__":
    main()
]=], t),
    ["requirements.txt"] = "playwright>=1.42\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n动态页面爬虫（浏览器自动化）\n\n```bash\npip install -r requirements.txt\npython -m playwright install chromium\npython -m {{snake}} https://example.com\n```\n", t),
  })
  return "Playwright 爬虫已生成"
end

gen.spider_httpx = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/__main__.py"] = util.fill([=[import asyncio

import httpx
from parsel import Selector

HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/122.0 Safari/537.36"
}


async def fetch(client: httpx.AsyncClient, url: str) -> str:
    resp = await client.get(url, headers=HEADERS, timeout=15, follow_redirects=True)
    resp.raise_for_status()
    return resp.text


def parse(html: str) -> list[dict]:
    sel = Selector(text=html)
    return [
        {"title": a.css("::text").get(default="").strip(), "url": a.attrib.get("href")}
        for a in sel.css("h2 a")
    ]


async def scrape(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient(http2=True) as client:
        pages = await asyncio.gather(*(fetch(client, u) for u in urls))
    return [item for html in pages for item in parse(html)]


def main() -> None:
    import sys

    urls = sys.argv[1:] or ["https://news.ycombinator.com/"]
    items = asyncio.run(scrape(urls))
    print(f"{{NAME}}: 抓到 {len(items)} 条")
    for it in items[:10]:
        print("-", it["title"])


if __name__ == "__main__":
    main()
]=], t),
    ["requirements.txt"] = "httpx[http2]>=0.27\nparsel>=1.9\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n高并发异步爬虫（httpx + parsel）\n\n```bash\npip install -r requirements.txt\npython -m {{snake}} url1 url2 ...\n```\n", t),
  })
  return "异步爬虫 (httpx + parsel) 已生成"
end

-- ---------------------------------------------------------------------------
-- GUI
-- ---------------------------------------------------------------------------

gen.pyside6 = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/__main__.py"] = util.fill([=[import sys

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QLabel, QMainWindow


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("{{NAME}}")
        self.resize(800, 600)

        label = QLabel("Hello from {{NAME}}!")
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.setCentralWidget(label)


def main() -> None:
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
]=], t),
    ["requirements.txt"] = "PySide6>=6.6\n",
    ["pyproject.toml"] = util.fill('[project]\nname = "{{kebab}}"\nversion = "0.1.0"\nrequires-python = ">=3.10"\ndependencies = ["PySide6>=6.6"]\n\n[project.scripts]\n{{kebab}} = "{{snake}}.__main__:main"\n', t),
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nPySide6 (Qt for Python) 桌面应用\n\n```bash\npip install -r requirements.txt\npython -m {{snake}}\n```\n", t),
  })
  return "PySide6 GUI 已生成"
end

gen.tkinter = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/__main__.py"] = util.fill([=[import tkinter as tk
from tkinter import ttk


class App(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("{{NAME}}")
        self.geometry("800x600")

        ttk.Label(self, text="Hello from {{NAME}}!", font=("sans", 20)).pack(expand=True)


def main() -> None:
    App().mainloop()


if __name__ == "__main__":
    main()
]=], t),
    ["requirements.txt"] = "",
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\nTkinter GUI（零第三方依赖）\n\n```bash\npython -m {{snake}}\n```\n", t),
  })
  return "Tkinter GUI 已生成"
end

gen.gradio = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app.py"] = util.fill([=[import gradio as gr


def greet(name: str) -> str:
    return f"Hello from {{NAME}}, {name}!"


demo = gr.Interface(fn=greet, inputs="text", outputs="text", title="{{NAME}}")

if __name__ == "__main__":
    demo.launch()
]=], t),
    ["requirements.txt"] = "gradio>=4.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
  })
  return "Gradio 应用已生成"
end

-- ---------------------------------------------------------------------------
-- 数据 / 测试 / 任务队列
-- ---------------------------------------------------------------------------

gen.pandas = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/analysis.py"] = util.fill([=["""数据分析入口：把数据放到 data/ 下再跑。"""

import pathlib

import pandas as pd

DATA_DIR = pathlib.Path(__file__).resolve().parents[2] / "data"


def load(path: str | None = None) -> pd.DataFrame:
    if path is None:
        csv = next(DATA_DIR.glob("*.csv"), None)
        if csv is None:
            raise FileNotFoundError(f"把 csv 放到 {DATA_DIR}/ 下")
        path = str(csv)
    return pd.read_csv(path)


def summarize(df: pd.DataFrame) -> pd.DataFrame:
    print(df.info())
    print(df.describe(include="all"))
    return df.describe(include="all")


def main() -> None:
    summarize(load())


if __name__ == "__main__":
    main()
]=], t),
    ["data/.gitkeep"] = "",
    ["requirements.txt"] = "pandas>=2.2\nmatplotlib>=3.8\njupyterlab>=4.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\ndata/*.csv\n!data/.gitkeep\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npip install -r requirements.txt\npython -m {{snake}}.analysis\n```\n", t),
  })
  return "Python 数据分析 (pandas) 已生成"
end

gen.streamlit = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app.py"] = util.fill([=[import streamlit as st

st.set_page_config(page_title="{{NAME}}", page_icon="📊")

st.title("{{NAME}}")
st.write("改 app.py 开始你的数据应用。")

name = st.text_input("你的名字", "World")
if st.button("打招呼"):
    st.success(f"Hello, {name}!")
]=], t),
    ["requirements.txt"] = "streamlit>=1.32\npandas>=2.2\n",
    [".streamlit/config.toml"] = '[theme]\nbase = "dark"\n',
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npip install -r requirements.txt\nstreamlit run app.py\n```\n", t),
  })
  return "Streamlit 数据应用已生成"
end

gen.pytest = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["pyproject.toml"] = util.fill([[[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "{{kebab}}"
version = "0.1.0"
requires-python = ">=3.10"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"

[tool.coverage.run]
source = ["{{snake}}"]
]], t),
    ["src/" .. t.snake .. "/__init__.py"] = "",
    ["src/" .. t.snake .. "/core.py"] = 'def add(a: int, b: int) -> int:\n    return a + b\n',
    ["tests/__init__.py"] = "",
    ["tests/test_core.py"] = util.fill([=[from {{snake}}.core import add


def test_add() -> None:
    assert add(1, 2) == 3


def test_add_negative() -> None:
    assert add(-1, 1) == 0
]=], t),
    ["requirements-dev.txt"] = "pytest>=8.0\npytest-cov>=5.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n.pytest_cache/\n.coverage\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npip install -r requirements-dev.txt\npytest\n```\n", t),
  })
  return "pytest 项目骨架已生成"
end

gen.celery = function(target, name)
  local t = util.project_tokens(name)
  util.write_tree(target, {
    ["app/__init__.py"] = "",
    ["app/celery_app.py"] = util.fill([=[from celery import Celery

app = Celery("{{kebab}}", broker="redis://localhost:6379/0", backend="redis://localhost:6379/1")
app.conf.task_default_queue = "{{kebab}}"

app.autodiscover_tasks(["app"])
]=], t),
    ["app/tasks.py"] = util.fill([=[from .celery_app import app


@app.task
def add(a: int, b: int) -> int:
    return a + b
]=], t),
    ["requirements.txt"] = "celery[redis]>=5.3\nredis>=5.0\n",
    [".gitignore"] = ".venv/\n__pycache__/\n",
    ["README.md"] = util.fill("# {{NAME}}\n\n```bash\npip install -r requirements.txt\ncelery -A app.celery_app worker -l info\n```\n", t),
  })
  return "Celery 任务队列已生成"
end

M.frameworks = {
  -- 基础 / Web
  { label = "Python package", lang = "python", gen = gen.py_pkg, main = "", requires = PY_REQ },
  { label = "FastAPI (Python)", lang = "python", gen = gen.fastapi, main = "app/main.py", requires = PY_REQ },
  { label = "FastAPI + SQLAlchemy + Alembic", lang = "python", gen = gen.fastapi_db, main = "app/main.py", requires = PY_REQ },
  { label = "Django (Python)", lang = "python", gen = gen.django, main = "", requires = PY_REQ },
  { label = "Flask (Python)", lang = "python", gen = gen.flask, main = "app.py", requires = PY_REQ },
  { label = "Typer CLI (Python)", lang = "python", gen = gen.typer, main = "", requires = PY_REQ },
  { label = "Python CLI (argparse)", lang = "python", gen = gen.argparse_cli, main = "",
    requires = req({ note = "零第三方依赖" }) },

  -- 爬虫
  { label = "爬虫 · requests + BeautifulSoup", lang = "python", gen = gen.spider_bs4, main = "",
    requires = req({ note = "依赖: requests / beautifulsoup4 / lxml" }) },
  { label = "爬虫 · Scrapy", lang = "python", gen = gen.scrapy, main = "",
    requires = req({ bins = { "python3", "scrapy" }, pacman = { "python", "python-scrapy" } }) },
  { label = "爬虫 · Playwright (动态页)", lang = "python", gen = gen.spider_playwright, main = "",
    requires = req({ note = "需: pip install -r requirements.txt && python -m playwright install chromium" }) },
  { label = "爬虫 · httpx + parsel (异步)", lang = "python", gen = gen.spider_httpx, main = "",
    requires = req({ note = "依赖: httpx[http2] / parsel" }) },

  -- GUI
  { label = "PySide6 GUI (Qt for Python)", lang = "python", gen = gen.pyside6, main = "",
    requires = req({ note = "需: PySide6（系统或 pip）" }) },
  { label = "Tkinter GUI (零依赖)", lang = "python", gen = gen.tkinter, main = "",
    requires = req({ bins = { "python3", "tk" }, pacman = { "python", "tk" } }) },
  { label = "Gradio 应用", lang = "python", gen = gen.gradio, main = "app.py",
    requires = req({ note = "依赖: gradio" }) },

  -- 数据 / 测试 / 队列
  { label = "数据分析 (pandas)", lang = "python", gen = gen.pandas, main = "",
    requires = req({ note = "依赖: pandas / matplotlib / jupyterlab" }) },
  { label = "Streamlit 数据应用", lang = "python", gen = gen.streamlit, main = "app.py",
    requires = req({ note = "依赖: streamlit" }) },
  { label = "pytest 项目骨架", lang = "python", gen = gen.pytest, main = "",
    requires = req({ note = "依赖: pytest / pytest-cov" }) },
  { label = "Celery + Redis 任务队列", lang = "python", gen = gen.celery, main = "app/tasks.py",
    requires = req({ note = "需要 Redis 服务" }) },
}

return M
