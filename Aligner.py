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

# 配置设置
os.environ["TRANSFORMERS_OFFLINE"] = "1"

def main():
    # ========== 界面组件 ==========
    st.title("🌐 智能双语对齐系统")
    st.caption("专业级中英文文档对齐工具 | 支持GPU加速")

    with st.sidebar:
        st.header("⚙️ 设置")
        use_gpu = st.checkbox("启用GPU加速", value=torch.cuda.is_available())
        
        st.markdown("---")
        st.header("📁 文件上传")
        zh_file = st.file_uploader("上传中文文档", type=["txt"], key="zh")
        en_file = st.file_uploader("上传英文文档", type=["txt"], key="en")

    # ========== 核心功能 ==========
    # def split_sentences(text, lang):
    #     """智能分句函数"""
    #     text = re.sub(r'([。！？?！])([^”’])', r'\1\n\2', text) if lang == "zh" \
    #         else re.sub(r'([.!?])([’"])', r'\1\n\2', text)
    #     return [s.strip() for s in re.split(r'\n+', text) if s.strip() else []
    
    def split_sentences(text, lang):
    # """智能分句函数"""
        text = re.sub(r'([。！？?！])([^”’])', r'\1\n\2', text) if lang == "zh" \
            else re.sub(r'([.!?])([’"])', r'\1\n\2', text)
        return [s.strip() for s in re.split(r'\n+', text) if s.strip()]

    def load_model():
        """模型加载函数"""
        model_path = "./models/paraphrase-multilingual-MiniLM-L12-v2"
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"模型路径 {model_path} 不存在，请确保模型文件已正确放置")
            
        device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
        return SentenceTransformer(model_path, device=device)

    def align_texts(zh_sentences, en_sentences):
        """GPU加速的对齐函数"""
        # 加载模型
        model = load_model()
        
        # 生成嵌入向量
        zh_embeddings = model.encode(zh_sentences)
        en_embeddings = model.encode(en_sentences)

        # 对齐计算
        def cosine_distance(a, b):
            return 1 - cosine_similarity([a], [b])[0][0]

        _, path = fastdtw(zh_embeddings, en_embeddings, 
                         dist=cosine_distance, radius=3)

        # 构建对齐结果
        aligned_pairs = []
        last_zh, last_en = -1, -1
        
        for i, j in path:
            if i != last_zh and j != last_en:
                aligned_pairs.append((zh_sentences[i], en_sentences[j]))
                last_zh, last_en = i, j
            elif i == last_zh:
                aligned_pairs[-1] = (aligned_pairs[-1][0], 
                                    aligned_pairs[-1][1] + " " + en_sentences[j])
                last_en = j
            elif j == last_en:
                aligned_pairs[-1] = (aligned_pairs[-1][0] + zh_sentences[i], 
                                    aligned_pairs[-1][1])
                last_zh = i
        return aligned_pairs

    # ========== 文件处理 ==========
    @st.cache_data(show_spinner=False)
    def load_file(uploaded_file, default_path):
        """带缓存的文件加载"""
        if uploaded_file is not None:
            return uploaded_file.read().decode("utf-8")
        try:
            with open(default_path, "r", encoding="utf-8") as f:
                return f.read()
        except FileNotFoundError:
            return None

    # ========== 主流程 ==========
    zh_text = load_file(zh_file, "zn.txt")
    en_text = load_file(en_file, "en.txt")

    # 初始化会话状态
    if 'processed' not in st.session_state:
        st.session_state.processed = False
    if 'df' not in st.session_state:
        st.session_state.df = pd.DataFrame()
    if 'aligned' not in st.session_state:
        st.session_state.aligned = []

    if not zh_text or not en_text:
        missing = []
        if not zh_text: missing.append("中文文档")
        if not en_text: missing.append("英文文档")
        st.error(f"❌ 缺少 {' 和 '.join(missing)}")
        return

    if st.button("🚀 开始处理", use_container_width=True, type="primary"):
        with st.status("📊 处理流程", expanded=True) as status:
            try:
                # 分句处理
                st.write("## 阶段 1/4：分句处理")
                zh_sents = split_sentences(zh_text, "zh")
                en_sents = split_sentences(en_text, "en")
                st.write(f"- 中文句子数：{len(zh_sents)}")
                st.write(f"- 英文句子数：{len(en_sents)}")

                # 执行对齐
                st.write("## 阶段 2/4：语义对齐")
                aligned = align_texts(zh_sents, en_sents)
                
                # 保存结果到会话状态
                st.session_state.df = pd.DataFrame(aligned, columns=["中文", "English"])
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

    # 显示结果和导出选项（独立于处理按钮）
    if st.session_state.processed:
        st.success(f"成功对齐 {len(st.session_state.aligned)} 对句子")
        
        with st.container():
            col1, col2 = st.columns([3, 1])
            
            with col1:
                st.subheader("📄 数据预览")
                st.dataframe(
                    st.session_state.df,
                    height=600,
                    use_container_width=True,
                    hide_index=True
                )
            
            with col2:
                st.subheader("📥 导出选项")
                export_format = st.radio("选择格式", 
                    ["Excel", "CSV", "TXT", "HTML", "Markdown"],
                    index=0,
                    label_visibility="collapsed")
                
                buffer = BytesIO()
                if export_format == "Excel":
                    with pd.ExcelWriter(buffer, engine='xlsxwriter') as writer:
                        st.session_state.df.to_excel(writer, index=False)
                    mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                    ext = "xlsx"
                elif export_format == "CSV":
                    buffer.write(st.session_state.df.to_csv(index=False, encoding='utf-8-sig').encode('utf-8'))
                    mime_type = "text/csv"
                    ext = "csv"
                elif export_format == "TXT":
                    txt_content = "\n".join([f"{zh}\t{en}" for zh, en in st.session_state.aligned])
                    buffer.write(txt_content.encode("utf-8"))
                    mime_type = "text/plain"
                    ext = "txt"
                elif export_format == "HTML":
                    html_content = st.session_state.df.to_html(index=False, border=0)
                    buffer.write(html_content.encode("utf-8"))
                    mime_type = "text/html"
                    ext = "html"
                elif export_format == "Markdown":
                    md_content = st.session_state.df.to_markdown(index=False)
                    buffer.write(md_content.encode("utf-8"))
                    mime_type = "text/markdown"
                    ext = "md"

                st.download_button(
                    label=f"下载 {export_format} 文件",
                    data=buffer.getvalue(),
                    file_name=f"aligned_text.{ext}",
                    mime=mime_type,
                    use_container_width=True
                )

if __name__ == '__main__':
    main()