# import streamlit as st
# import pandas as pd
# import numpy as np
# import re
# import os
# from io import BytesIO
# from sklearn.metrics.pairwise import cosine_similarity
# from fastdtw import fastdtw
# from sentence_transformers import SentenceTransformer
# import torch
# from datetime import datetime
# import logging

# # 配置日志系统
# logging.basicConfig(level=logging.INFO)

# # 设置镜像站备用（如需启用取消注释）
# # os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'

# # ========== 工具函数 ==========
# def split_sentences(text, lang):
#     """智能分句函数"""
#     split_patterns = {
#         "zh": r'([。！？?！])([^”’])',
#         "en": r'([.!?])([’"])'
#     }
#     processed = re.sub(split_patterns[lang], r'\1\n\2', text)
#     return [s.strip() for s in re.split(r'\n+', processed) if s.strip()]

# @st.cache_data(show_spinner=False)
# def load_file(uploaded_file, default_path):
#     """带缓存的文件加载"""
#     if uploaded_file:
#         return uploaded_file.read().decode("utf-8")
#     try:
#         with open(default_path, "r", encoding="utf-8") as f:
#             return f.read()
#     except FileNotFoundError:
#         return None

# # ========== 核心功能 ==========
# @st.cache_resource(show_spinner=False)
# def load_model(device="cpu"):
#     """带智能缓存的模型加载"""
#     try:
#         model = SentenceTransformer(
#             "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
#             device=device
#         )
#         logging.info(f"✅ 模型加载成功 | 设备: {device.upper()}")
#         return model
#     except Exception as e:
#         logging.error(f"模型加载失败: {str(e)}")
#         st.error(f"""
#             ❌ 模型加载失败，请检查：
#             1. 网络连接是否正常
#             2. 尝试启用镜像站（取消代码第15行注释）
#             3. 错误详情：{str(e)}
#         """)
#         st.stop()

# def calculate_alignment(zh_sents, en_sents, use_gpu):
#     """执行对齐的核心流程"""
#     # 动态设备选择
#     device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
#     model = load_model(device)
    
#     # 生成嵌入向量
#     with st.spinner("🔍 生成文本嵌入..."):
#         zh_embeddings = model.encode(zh_sents)
#         en_embeddings = model.encode(en_sents)

#     # 相似度计算函数
#     def cosine_distance(a, b):
#         return 1 - cosine_similarity([a], [b])[0][0]

#     # 执行动态时间规整
#     with st.spinner("🔄 动态时间规整对齐中..."):
#         _, path = fastdtw(zh_embeddings, en_embeddings, 
#                          dist=cosine_distance, radius=3)

#     # 构建对齐结果
#     aligned_pairs = []
#     last_zh, last_en = -1, -1
    
#     for i, j in path:
#         if i != last_zh and j != last_en:
#             aligned_pairs.append((zh_sents[i], en_sents[j]))
#             last_zh, last_en = i, j
#         elif i == last_zh:
#             aligned_pairs[-1] = (aligned_pairs[-1][0], 
#                                 aligned_pairs[-1][1] + " " + en_sents[j])
#             last_en = j
#         elif j == last_en:
#             aligned_pairs[-1] = (aligned_pairs[-1][0] + zh_sents[i], 
#                                 aligned_pairs[-1][1])
#             last_zh = i
#     return aligned_pairs

# # ========== 界面组件 ==========
# def main_interface():
#     """主界面布局"""
#     st.title("🌐 智能双语对齐系统")
#     st.caption("专业级中英文文档对齐工具 | 支持GPU加速")

#     # 侧边栏设置
#     with st.sidebar:
#         st.header("⚙️ 设置")
#         use_gpu = st.checkbox("启用GPU加速", 
#                              value=torch.cuda.is_available(),
#                              help="需要NVIDIA显卡并安装CUDA驱动")
        
#         # if st.button("🔄 清空缓存"):
#         #     st.cache_resource.clear()
#         #     st.cache_data.clear()
#         #     st.success("缓存已重置！")
        
#         st.markdown("---")
#         st.header("📁 文件上传")
#         zh_file = st.file_uploader("上传中文文档", type=["txt"], key="zh")
#         en_file = st.file_uploader("上传英文文档", type=["txt"], key="en")

#     # 主内容区
#     col1, col2 = st.columns([3, 1])
    
#     with col1:
#         process_flow(zh_file, en_file, use_gpu)
    
#     with col2:
#         if st.session_state.get("processed"):
#             export_options()

# # ========== 处理流程 ==========
# def process_flow(zh_file, en_file, use_gpu):
#     """处理流程控制"""
#     zh_text = load_file(zh_file, "zn.txt")
#     en_text = load_file(en_file, "en.txt")

#     # 初始化会话状态
#     if 'processed' not in st.session_state:
#         st.session_state.processed = False

#     # 文件检查
#     if not zh_text or not en_text:
#         missing = []
#         if not zh_text: missing.append("中文文档")
#         if not en_text: missing.append("英文文档")
#         st.error(f"❌ 缺少 {' 和 '.join(missing)}")
#         return

#     # 处理按钮
#     if st.button("🚀 开始处理", use_container_width=True, type="primary"):
#         with st.status("📊 处理流程", expanded=True) as status:
#             try:
#                 process_start = datetime.now()
                
#                 # 分句处理
#                 st.write("## 阶段 1/3：分句处理")
#                 zh_sents = split_sentences(zh_text, "zh")
#                 en_sents = split_sentences(en_text, "en")
#                 st.write(f"- 中文句子数：{len(zh_sents)}")
#                 st.write(f"- 英文句子数：{len(en_sents)}")

#                 # 对齐处理
#                 st.write("## 阶段 2/3：语义对齐")
#                 aligned = calculate_alignment(zh_sents, en_sents, use_gpu)
                
#                 # 结果存储
#                 st.write("## 阶段 3/3：结果生成")
#                 st.session_state.df = pd.DataFrame(aligned, columns=["中文", "English"])
#                 st.session_state.aligned = aligned
#                 st.session_state.processed = True

#                 total_time = (datetime.now() - process_start).total_seconds()
#                 status.update(
#                     label=f"✅ 处理完成 | 总耗时 {total_time:.2f}s",
#                     state="complete",
#                     expanded=False
#                 )

#             except Exception as e:
#                 status.update(label="❌ 处理失败", state="error")
#                 st.error(f"错误详情：{str(e)}")
#                 st.stop()

#     # 显示结果
#     if st.session_state.get("processed"):
#         st.success(f"成功对齐 {len(st.session_state.aligned)} 对句子")
#         st.dataframe(
#             st.session_state.df,
#             height=600,
#             use_container_width=True,
#             hide_index=True
#         )

# # ========== 导出功能 ==========
# def export_options():
#     """导出选项组件"""
#     st.subheader("📥 导出选项")
#     export_format = st.radio(
#         "选择格式",
#         ["Excel", "CSV", "TXT", "HTML", "Markdown"],
#         index=0,
#         label_visibility="collapsed"
#     )
    
#     buffer = BytesIO()
#     df = st.session_state.df
    
#     # 生成文件内容
#     if export_format == "Excel":
#         with pd.ExcelWriter(buffer, engine='xlsxwriter') as writer:
#             df.to_excel(writer, index=False)
#         mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
#         ext = "xlsx"
#     elif export_format == "CSV":
#         buffer.write(df.to_csv(index=False, encoding='utf-8-sig').encode('utf-8'))
#         mime_type = "text/csv"
#         ext = "csv"
#     elif export_format == "TXT":
#         content = "\n".join([f"{zh}\t{en}" for zh, en in st.session_state.aligned])
#         buffer.write(content.encode("utf-8"))
#         mime_type = "text/plain"
#         ext = "txt"
#     elif export_format == "HTML":
#         buffer.write(df.to_html(index=False, border=0).encode("utf-8"))
#         mime_type = "text/html"
#         ext = "html"
#     elif export_format == "Markdown":
#         buffer.write(df.to_markdown(index=False).encode("utf-8"))
#         mime_type = "text/markdown"
#         ext = "md"

#     # 下载按钮
#     st.download_button(
#         label=f"下载 {export_format} 文件",
#         data=buffer.getvalue(),
#         file_name=f"aligned_text.{ext}",
#         mime=mime_type,
#         use_container_width=True
#     )

# # ========== 主程序 ==========
# if __name__ == '__main__':
#     from streamlit.web import cli as stcli
#     from streamlit import runtime
#     import sys
#     st.set_page_config(
#         page_title="智能双语对齐系统",
#         page_icon="🌐",
#         layout="wide",
#         initial_sidebar_state="expanded"
#     )
    
#     # 隐藏默认的汉堡菜单
#     hide_menu_style = """
#         <style>
#         #MainMenu {visibility: hidden;}
#         footer {visibility: hidden;}
#         </style>
#     """
#     st.markdown(hide_menu_style, unsafe_allow_html=True)
#     if runtime.exists():
#         main_interface()
#     else:
#         sys.argv = ["streamlit", "run", sys.argv[0]]
#         sys.exit(stcli.main())

import streamlit as st
import pandas as pd
import numpy as np
import re
import os
from io import BytesIO
from sklearn.metrics.pairwise import cosine_similarity
from fastdtw import fastdtw
from sentence_transformers import SentenceTransformer
import torch
from datetime import datetime
import logging
import markdown  # 新增markdown处理

# 配置日志系统
logging.basicConfig(level=logging.INFO)

# 设置镜像站备用（如需启用取消注释）
os.environ['HF_ENDPOINT'] = 'https://hf-mirror.com'

# ========== 工具函数 ==========
def split_sentences(text, lang):
    """多语言分句函数"""
    lang_rules = {
        "zh": r'([。！？?！])([^”’])',
        "en": r'([.!?])([’"])',
        "ja": r'([。！？?！])',
        "eu": r'([.!?])',
    }
    pattern = lang_rules.get(lang, lang_rules["en"])
    processed = re.sub(pattern, r'\1\n', text)
    return [s.strip() for s in re.split(r'\n+', processed) if s.strip()]

@st.cache_data(show_spinner=False)
def load_file(uploaded_file, default_path):
    """带缓存的文件加载"""
    if uploaded_file:
        return uploaded_file.read().decode("utf-8")
    try:
        with open(default_path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None

# ========== 核心功能 ==========
@st.cache_resource(show_spinner=False)
def load_model(device="cpu"):
    """带智能缓存的模型加载"""
    try:
        model = SentenceTransformer(
            "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
            device=device
        )
        logging.info(f"✅ 模型加载成功 | 设备: {device.upper()}")
        return model
    except Exception as e:
        logging.error(f"模型加载失败: {str(e)}")
        st.error(f"""
            ❌ 模型加载失败，请检查：
            1. 网络连接是否正常
            2. 尝试启用镜像站（取消代码第15行注释）
            3. 错误详情：{str(e)}
        """)
        st.stop()

def calculate_alignment(sents_a, sents_b, use_gpu):
    """执行对齐的核心流程"""
    # 动态设备选择
    device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
    model = load_model(device)
    
    # 生成嵌入向量
    with st.spinner("🔍 生成文本嵌入..."):
        embeddings_a = model.encode(sents_a)
        embeddings_b = model.encode(sents_b)

    # 相似度计算函数
    def cosine_distance(a, b):
        return 1 - cosine_similarity([a], [b])[0][0]

    # 执行动态时间规整
    with st.spinner("🔄 动态时间规整对齐中..."):
        _, path = fastdtw(embeddings_a, embeddings_b, 
                         dist=cosine_distance, radius=3)

    # 构建对齐结果
    aligned_pairs = []
    last_a, last_b = -1, -1
    
    for i, j in path:
        if i != last_a and j != last_b:
            aligned_pairs.append((sents_a[i], sents_b[j]))
            last_a, last_b = i, j
        elif i == last_a:
            aligned_pairs[-1] = (aligned_pairs[-1][0], 
                                aligned_pairs[-1][1] + " " + sents_b[j])
            last_b = j
        elif j == last_b:
            aligned_pairs[-1] = (aligned_pairs[-1][0] + sents_a[i], 
                                aligned_pairs[-1][1])
            last_a = i
    return aligned_pairs

# ========== 界面组件 ==========
def main_interface():
    """主界面布局"""
    st.title("🌐 智能多语言对齐系统")
    st.caption("专业级多语言文档对齐工具 | 支持GPU加速")

    # 侧边栏设置
    with st.sidebar:
        st.header("⚙️ 设置")
        use_gpu = st.checkbox("启用GPU加速", 
                             value=torch.cuda.is_available(),
                             help="需要NVIDIA显卡并安装CUDA驱动")
        
        st.markdown("---")
        st.header("📁 文件上传")
        col1, col2 = st.columns(2)
        with col1:
            lang_a = st.selectbox("语言A", ["zh", "en", "ja", "eu"], index=0)
            file_a = st.file_uploader(f"上传{lang_a}文档", type=["txt", "md"], key="a")
        with col2:
            lang_b = st.selectbox("语言B", ["en", "zh", "ja", "eu"], index=0)
            file_b = st.file_uploader(f"上传{lang_b}文档", type=["txt", "md"], key="b")

    # 主内容区
    col1, col2 = st.columns([3, 1])
    
    with col1:
        process_flow(file_a, file_b, lang_a, lang_b, use_gpu)
    
    with col2:
        if st.session_state.get("processed"):
            export_options()

# ========== 处理流程 ==========
def process_flow(file_a, file_b, lang_a, lang_b, use_gpu):
    """处理流程控制"""
    text_a = load_file(file_a, "a.txt")
    text_b = load_file(file_b, "b.txt")

    # 初始化会话状态
    if 'processed' not in st.session_state:
        st.session_state.processed = False

    # 文件检查
    if not text_a or not text_b:
        missing = []
        if not text_a: missing.append(f"{lang_a}文档")
        if not text_b: missing.append(f"{lang_b}文档")
        st.error(f"❌ 缺少 {' 和 '.join(missing)}")
        return

    # 处理按钮
    if st.button("🚀 开始处理", use_container_width=True, type="primary"):
        with st.status("📊 处理流程", expanded=True) as status:
            try:
                process_start = datetime.now()
                
                # 分句处理
                st.write("## 阶段 1/3：分句处理")
                sents_a = split_sentences(text_a, lang_a)
                sents_b = split_sentences(text_b, lang_b)
                st.write(f"- {lang_a}句子数：{len(sents_a)}")
                st.write(f"- {lang_b}句子数：{len(sents_b)}")

                # 对齐处理
                st.write("## 阶段 2/3：语义对齐")
                aligned = calculate_alignment(sents_a, sents_b, use_gpu)
                
                # 结果存储
                st.write("## 阶段 3/3：结果生成")
                st.session_state.df = pd.DataFrame(aligned, columns=[lang_a.upper(), lang_b.upper()])
                st.session_state.aligned = aligned
                st.session_state.processed = True

                total_time = (datetime.now() - process_start).total_seconds()
                status.update(
                    label=f"✅ 处理完成 | 总耗时 {total_time:.2f}s",
                    state="complete",
                    expanded=False
                )

            except Exception as e:
                status.update(label="❌ 处理失败", state="error")
                st.error(f"错误详情：{str(e)}")
                st.stop()

    # 显示结果
    if st.session_state.get("processed"):
        st.success(f"成功对齐 {len(st.session_state.aligned)} 对句子")
        st.dataframe(
            st.session_state.df,
            height=600,
            use_container_width=True,
            hide_index=True
        )

# ========== 导出功能 ==========
def generate_html_content(df, format_type):
    """生成美观的HTML内容"""
    css_style = """
    <style>
        .alignment-container {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .pair-item {
            background: white;
            margin: 10px 0;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        .lang-col {
            padding: 10px;
            border-right: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:hover {background-color: #f5f5f5;}
    </style>
    """

    if format_type == "表格":
        table_html = df.to_html(index=False, border=0, classes="dataframe", escape=False)
        content = f"""
        <div class="alignment-container">
            <h2 style="color: #2c3e50; text-align: center;">多语言对齐结果</h2>
            {table_html}
        </div>
        """
    else:
        show_groups = st.checkbox("显示分组编号", value=False, 
                                help="是否在每对译文前显示'第X组'的编号")
        pairs_html = ""
        
        for idx, (a, b) in enumerate(st.session_state.aligned):
            a_html = markdown.markdown(a)
            b_html = markdown.markdown(b)
            
            group_header = f'<h4>第{idx+1}组</h4>' if show_groups else ""
            
            pairs_html += f"""
            <div class="pair-item">
                <div class="lang-col">
                    {group_header}
                    <div class="lang-a">{a_html}</div>
                </div>
                <div class="lang-col">
                    <div class="lang-b">{b_html}</div>
                </div>
            </div>
            """
            
        content = f"""
        <div class="alignment-container">
            <h2 style="color: #2c3e50; text-align: center;">多语言对照结果</h2>
            {pairs_html}
        </div>
        """
    
    return f"<html><head>{css_style}</head><body>{content}</body></html>"
    # else:
    #     pairs_html = ""
        
    #     for idx, (a, b) in enumerate(st.session_state.aligned):
    #         # 转换Markdown为HTML
    #         a_html = markdown.markdown(a)
    #         b_html = markdown.markdown(b)
            
    #         col = f'<h4>第{idx+1}组</h4>'
    #         pairs_html += f"""
    #         <div class="pair-item">
    #             <div class="lang-col">
    #                 {col}
    #                 <div class="lang-a">{a_html}</div>
    #             </div>
    #             <div class="lang-col">
    #                 <div class="lang-b">{b_html}</div>
    #             </div>
    #         </div>
    #         """
    #     content = f"""
    #     <div class="alignment-container">
    #         <h2 style="color: #2c3e50; text-align: center;">多语言对照结果</h2>
    #         {pairs_html}
    #     </div>
    #     """
    
    # return f"<html><head>{css_style}</head><body>{content}</body></html>"

def export_options():
    """导出选项组件"""
    st.subheader("📥 导出选项")
    export_format = st.radio(
        "选择格式",
        ["Excel", "CSV", "TXT", "HTML", "Markdown"],
        index=0,
        label_visibility="collapsed"
    )
    
    if export_format == "HTML":
        html_format = st.radio(
            "HTML格式",
            ["表格", "对照"],
            horizontal=True,
            label_visibility="collapsed"
        )
    
    buffer = BytesIO()
    df = st.session_state.df
    
    # 生成文件内容
    if export_format == "Excel":
        with pd.ExcelWriter(buffer, engine='xlsxwriter') as writer:
            df.to_excel(writer, index=False)
        mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        ext = "xlsx"
    elif export_format == "CSV":
        buffer.write(df.to_csv(index=False, encoding='utf-8-sig').encode('utf-8'))
        mime_type = "text/csv"
        ext = "csv"
    elif export_format == "TXT":
        content = "\n".join([f"{a}\t{b}" for a, b in st.session_state.aligned])
        buffer.write(content.encode("utf-8"))
        mime_type = "text/plain"
        ext = "txt"
    elif export_format == "HTML":
        html_content = generate_html_content(df, html_format)
        buffer.write(html_content.encode("utf-8"))
        mime_type = "text/html"
        ext = "html"
    elif export_format == "Markdown":
        buffer.write(df.to_markdown(index=False).encode("utf-8"))
        mime_type = "text/markdown"
        ext = "md"

    # 下载按钮
    st.download_button(
        label=f"下载 {export_format} 文件",
        data=buffer.getvalue(),
        file_name=f"aligned_text.{ext}",
        mime=mime_type,
        use_container_width=True
    )

# ========== 主程序 ==========
if __name__ == '__main__':
    from streamlit.web import cli as stcli
    from streamlit import runtime
    import sys
    st.set_page_config(
        page_title="智能多语言对齐系统",
        page_icon="🌐",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # 隐藏默认的汉堡菜单
    hide_menu_style = """
        <style>
        #MainMenu {visibility: hidden;}
        footer {visibility: hidden;}
        </style>
    """
    st.markdown(hide_menu_style, unsafe_allow_html=True)
    if runtime.exists():
        main_interface()
    else:
        sys.argv = ["streamlit", "run", sys.argv[0]]
        sys.exit(stcli.main())