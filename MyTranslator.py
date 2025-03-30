# -*- coding: utf-8 -*-
import streamlit as st
import sqlite3
import pandas as pd
import torch
import os
from datetime import datetime
from transformers import (
    MBartForConditionalGeneration,
    MBart50TokenizerFast,
    pipeline
)

# ==================== 配置区 ====================
MODEL_NAME = "facebook/mbart-large-50-many-to-many-mmt"
HISTORY_DB = "translation_history.db"
ITEMS_PER_PAGE = 10
DEFAULT_DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# 设置国内镜像源（可选）
os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'  # 使用Hugging Face镜像

# ==================== 国际化文本 ====================
TRANSLATIONS = {
    "en": {
        "title": "🌍 Lingmo Translation Engine",
        "input_placeholder": "Enter text to translate...",
        "src_lang": "Source Language",
        "tgt_lang": "Target Language",
        "translate_btn": "🚀 Translate",
        "result_title": "Translation Result",
        "history_title": "📜 Translation History",
        "export_btn": "📤 Export History",
        "import_btn": "📥 Import History",
        "template_btn": "📋 Download Template",
        "template_download_help": "Download CSV template for import",
        "literary_mode": "Literary Optimization",
        "gpu_toggle": "GPU Acceleration",
        "page_info": "Page {current} of {total}",
        "prev_page": "Previous",
        "next_page": "Next",
        "import_success": "Successfully imported",
        "records": "records",
        "import_failed": "Import failed",
        "download_btn": "Download CSV",
        "translating": "Translating...",
        "translation_failed": "Translation failed",
        "input_warning": "Please input text to translate",
        "no_history": "No translation history"
    },
    "zh": {
        "title": "🌍 凌墨智能翻译引擎",
        "input_placeholder": "输入需要翻译的内容...",
        "src_lang": "源语言",
        "tgt_lang": "目标语言",
        "translate_btn": "🚀 开始翻译",
        "result_title": "翻译结果",
        "history_title": "📜 翻译历史",
        "export_btn": "📤 导出历史",
        "import_btn": "📥 导入历史",
        "template_btn": "📋 下载模板",
        "template_download_help": "下载导入用CSV模板",
        "literary_mode": "文学优化模式",
        "gpu_toggle": "GPU加速",
        "page_info": "第 {current} 页 / 共 {total} 页",
        "prev_page": "上一页",
        "next_page": "下一页",
        "import_success": "成功导入",
        "records": "条记录",
        "import_failed": "导入失败",
        "download_btn": "下载CSV文件",
        "translating": "正在翻译...",
        "translation_failed": "翻译失败",
        "input_warning": "请输入要翻译的内容",
        "no_history": "暂无翻译历史"
    }
}

# ==================== 数据库操作 ====================
@st.cache_resource
def init_db():
    conn = sqlite3.connect(HISTORY_DB)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS translations
                (id INTEGER PRIMARY KEY AUTOINCREMENT,
                 timestamp DATETIME,
                 source_text TEXT,
                 translated_text TEXT,
                 src_lang TEXT,
                 tgt_lang TEXT)''')
    conn.commit()
    return conn

def save_to_db(conn, source_text, translated_text, src_lang, tgt_lang):
    c = conn.cursor()
    c.execute('''INSERT INTO translations 
                (timestamp, source_text, translated_text, src_lang, tgt_lang)
                VALUES (?,?,?,?,?)''',
             (datetime.now(), source_text, translated_text, src_lang, tgt_lang))
    conn.commit()

# ==================== 核心功能 ====================
@st.cache_resource(show_spinner=False)
def load_translation_model():
    try:
        model = MBartForConditionalGeneration.from_pretrained(
            MODEL_NAME,
            torch_dtype=torch.float16 if "cuda" in DEFAULT_DEVICE else torch.float32,
            device_map="auto"
        )
        tokenizer = MBart50TokenizerFast.from_pretrained(MODEL_NAME)
        return pipeline(
            "translation",
            model=model,
            tokenizer=tokenizer,
            # device=0 if DEFAULT_DEVICE == "cuda" else -1,
            framework="pt"
        )
    except Exception as e:
        st.error(f"{tr('translation_failed')}: {str(e)}")
        st.stop()

# ==================== 界面组件 ====================
def setup_page():
    st.set_page_config(
        page_title="Lingmo Translator",
        page_icon="🌐",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    st.markdown(f"""
    <style>
    .main {{ 
        background: linear-gradient(135deg, #f8f9fa, #e9ecef);
        padding: 2rem;
    }}
    .stTextArea textarea {{ 
        border: 2px solid #4CAF50 !important;
        border-radius: 15px;
        padding: 1.5rem !important;
        font-size: 16px !important;
        background-color: rgba(255,255,255,0.9) !important;
    }}
    .stButton>button {{
        background: linear-gradient(45deg, #4CAF50, #45a049);
        color: white !important;
        border: none;
        padding: 14px 28px;
        border-radius: 30px;
        font-size: 18px;
        transition: all 0.3s;
    }}
    .stButton>button:hover {{
        transform: scale(1.05);
        box-shadow: 0 5px 15px rgba(76,175,80,0.4);
    }}
    .history-card {{
        background: white;
        border-radius: 15px;
        padding: 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        transition: transform 0.2s;
    }}
    .history-card:hover {{
        transform: translateY(-3px);
    }}
    </style>
    """, unsafe_allow_html=True)

def language_selector():
    langs = {
        "en_XX": "English",
        "zh_CN": "中文(简体)", 
        "fr_XX": "Français",
        "es_XX": "Español",
        "ja_XX": "日本語"
    }
    cols = st.columns(2)
    with cols[0]:
        src = st.selectbox(tr("src_lang"), options=list(langs.values()))
    with cols[1]:
        tgt = st.selectbox(tr("tgt_lang"), options=list(langs.values()))
    return src, tgt

# ==================== 主程序 ====================
def tr(key):
    return TRANSLATIONS[st.session_state.lang][key]

def main():
    setup_page()
    conn = init_db()
    
    # 初始化语言设置
    if "lang" not in st.session_state:
        st.session_state.lang = "zh"
    
    # 侧边栏设置
    with st.sidebar:
        st.session_state.lang = st.selectbox("Language/语言", ["zh", "en"])
        st.markdown("---")
        
        # 模板下载
        template = pd.DataFrame(columns=[
            "timestamp", "source_text", "translated_text", "src_lang", "tgt_lang"
        ]).to_csv(index=False).encode()
        st.download_button(
            label=tr("template_btn"),
            data=template,
            file_name="translation_template.csv",
            help=tr("template_download_help")
        )
        
        # 数据导入
        uploaded_file = st.file_uploader(tr("import_btn"), type=["csv"])
        if uploaded_file:
            try:
                df = pd.read_csv(uploaded_file)
                df.to_sql('translations', conn, if_exists='append', index=False)
                st.success(f"{tr('import_success')} {len(df)} {tr('records')}")
            except Exception as e:
                st.error(f"{tr('import_failed')}: {str(e)}")
        
        # 数据导出
        if st.button(tr("export_btn")):
            df = pd.read_sql("SELECT * FROM translations", conn)
            csv = df.to_csv(index=False).encode()
            st.download_button(
                label=tr("download_btn"),
                data=csv,
                file_name="translation_history.csv",
                mime="text/csv"
            )
        
        # 性能设置
        st.markdown("---")
        literary_mode = st.toggle(tr("literary_mode"))
        use_gpu = st.toggle(tr("gpu_toggle"), DEFAULT_DEVICE=="cuda")

    # 主界面
    st.title(tr("title"))
    
    # 翻译区域
    src, tgt = language_selector()
    input_text = st.text_area(tr("input_placeholder"), height=250)
    
    if st.button(tr("translate_btn"), use_container_width=True):
        if input_text.strip():
            with st.spinner(tr("translating")):
                try:
                    pipe = load_translation_model()
                    result = pipe(
                        input_text, 
                        src_lang=src.split("_")[0],
                        tgt_lang=tgt.split("_")[0],
                        max_length=51200 if literary_mode else 25600,
                        num_beams=5 if literary_mode else 3
                    )
                    translated = result[0]['translation_text']
                    
                    save_to_db(conn, input_text, translated, src, tgt)
                    
                    st.subheader(tr("result_title"))
                    st.markdown(f"""
                    <div class="history-card">
                    {translated}
                    </div>
                    """, unsafe_allow_html=True)
                except Exception as e:
                    st.error(f"{tr('translation_failed')}: {str(e)}")
        else:
            st.warning(tr("input_warning"))

    # 历史记录分页
    st.subheader(tr("history_title"))
    page = st.number_input("Page", min_value=1, value=1)
    total_pages = (pd.read_sql("SELECT COUNT(*) FROM translations", conn).iloc[0,0] + ITEMS_PER_PAGE - 1) // ITEMS_PER_PAGE
    
    history = pd.read_sql(f"""
        SELECT * FROM translations 
        ORDER BY timestamp DESC 
        LIMIT {ITEMS_PER_PAGE} OFFSET {(page-1)*ITEMS_PER_PAGE}
    """, conn)
    
    if not history.empty:
        for _, row in history.iterrows():
            with st.container():
                st.markdown(f"""
                <div class="history-card">
                <small>{row['timestamp']}</small>
                <h6>{row['src_lang']} → {row['tgt_lang']}</h6>
                <blockquote>{row['source_text']}</blockquote>
                <div style="color:#4CAF50;margin-top:1rem;">{row['translated_text']}</div>
                </div>
                """, unsafe_allow_html=True)
        
        # 分页导航
        cols = st.columns([2,3,2])
        with cols[1]:
            st.markdown(f"<center>{tr('page_info').format(current=page, total=total_pages)}</center>", 
                      unsafe_allow_html=True)
        with cols[0]:
            if page > 1 and st.button(tr("prev_page")):
                page -= 1
        with cols[2]:
            if page < total_pages and st.button(tr("next_page")):
                page += 1
    else:
        st.info(tr("no_history"))

if __name__ == '__main__':
    from streamlit.web import cli as stcli
    from streamlit import runtime
    import sys

    if runtime.exists():
        main()
    else:
        sys.argv = ["streamlit", "run", sys.argv[0]]
        sys.exit(stcli.main())