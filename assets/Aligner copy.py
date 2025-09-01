# # # # import streamlit as st
# # # # import pandas as pd
# # # # import numpy as np
# # # # from sklearn.metrics.pairwise import cosine_similarity
# # # # from fastdtw import fastdtw
# # # # from sentence_transformers import SentenceTransformer
# # # # import re

# # # # def main():
# # # #     # 中英文分句函数（改进版）
# # # #     def split_sentences(text, lang):
# # # #         # 处理特殊符号后的换行
# # # #         text = re.sub(r'([。！？?\!])([^”’])', r'\1\n\2', text)
# # # #         # 处理英文引号
# # # #         text = re.sub(r'([.!?])([’"])', r'\1\n\2', text)
# # # #         # 拆分句子
# # # #         sentences = [s.strip() for s in re.split(r'\n+', text) if s.strip()]
# # # #         return sentences


# # # #     # 对齐算法核心
# # # #     def align_texts(zh_sentences, en_sentences):
# # # #         # 加载多语言句向量模型
# # # #         model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

# # # #         # 生成嵌入向量
# # # #         zh_embeddings = model.encode(zh_sentences)
# # # #         en_embeddings = model.encode(en_sentences)

# # # #         # 构建成本矩阵
# # # #         cost_matrix = np.zeros((len(zh_sentences), len(en_sentences)))
# # # #         for i, zh_vec in enumerate(zh_embeddings):
# # # #             for j, en_vec in enumerate(en_embeddings):
# # # #                 cost_matrix[i, j] = 1 - cosine_similarity([zh_vec], [en_vec])[0][0]

# # # #         # 使用DTW寻找最优路径
# # # #         distance, path = fastdtw(cost_matrix, radius=3)

# # # #         # 处理对齐路径
# # # #         aligned_pairs = []
# # # #         last_zh = last_en = -1

# # # #         for (i, j) in path:
# # # #             if i != last_zh and j != last_en:
# # # #                 # 新的匹配对
# # # #                 aligned_pairs.append((zh_sentences[i], en_sentences[j]))
# # # #                 last_zh = i
# # # #                 last_en = j
# # # #             elif i == last_zh:
# # # #                 # 英文合并
# # # #                 aligned_pairs[-1] = (aligned_pairs[-1][0], aligned_pairs[-1][1] + " " + en_sentences[j])
# # # #                 last_en = j
# # # #             elif j == last_en:
# # # #                 # 中文合并
# # # #                 aligned_pairs[-1] = (aligned_pairs[-1][0] + en_sentences[j], aligned_pairs[-1][1])
# # # #                 last_zh = i

# # # #         return aligned_pairs


# # # #     # Streamlit界面
# # # #     st.title("中英文文档对齐工具")

# # # #     # 文件上传
# # # #     zh_file = st.file_uploader("上传中文文档", type=["txt"])
# # # #     en_file = st.file_uploader("上传英文文档", type=["txt"])

# # # #     # 使用默认文件或上传文件
# # # #     zh_text = ""
# # # #     en_text = ""

# # # #     if zh_file is None:
# # # #         with open("zn.txt", "r", encoding="utf-8") as f:
# # # #             zh_text = f.read()
# # # #     else:
# # # #         zh_text = zh_file.read().decode("utf-8")

# # # #     if en_file is None:
# # # #         with open("en.txt", "r", encoding="utf-8") as f:
# # # #             en_text = f.read()
# # # #     else:
# # # #         en_text = en_file.read().decode("utf-8")

# # # #     # 执行对齐
# # # #     if st.button("开始对齐"):
# # # #         with st.spinner("处理中..."):
# # # #             # 分句处理
# # # #             zh_sentences = split_sentences(zh_text, "zh")
# # # #             en_sentences = split_sentences(en_text, "en")

# # # #             # 执行对齐算法
# # # #             aligned = align_texts(zh_sentences, en_sentences)

# # # #             # 创建DataFrame
# # # #             df = pd.DataFrame(aligned, columns=["中文", "English"])

# # # #             # 显示结果
# # # #             st.dataframe(df)

# # # #             # 下载按钮
# # # #             st.download_button(
# # # #                 label="下载Excel文件",
# # # #                 data=df.to_excel(index=False),
# # # #                 file_name="aligned_text.xlsx",
# # # #                 mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
# # # #             )


# # # # if __name__ == '__main__':
# # # #     from streamlit.web import cli as stcli
# # # #     from streamlit import runtime
# # # #     import sys

# # # #     # 设置页面配置
# # # #     st.set_page_config(
# # # #         page_title="智能双语对齐系统",
# # # #         page_icon="🌐",
# # # #         layout="wide",
# # # #         initial_sidebar_state="expanded"
# # # #     )

# # # #     if runtime.exists():
# # # #         main()
# # # #     else:
# # # #         sys.argv = ["streamlit", "run", sys.argv[0]]
# # # #         sys.exit(stcli.main())


# # # import streamlit as st
# # # import pandas as pd
# # # import numpy as np
# # # from sklearn.metrics.pairwise import cosine_similarity
# # # from fastdtw import fastdtw
# # # from sentence_transformers import SentenceTransformer
# # # import re
# # # import os  # 新增导入

# # # # 设置离线模式（新增部分）
# # # os.environ["TRANSFORMERS_OFFLINE"] = "1"
# # # os.environ["HF_DATASETS_OFFLINE"] = "1"

# # # def main():
# # #     # 中英文分句函数保持不变
# # #     def split_sentences(text, lang):
# # #         text = re.sub(r'([。！？?\!])([^”’])', r'\1\n\2', text)
# # #         text = re.sub(r'([.!?])([’"])', r'\1\n\2', text)
# # #         return [s.strip() for s in re.split(r'\n+', text) if s.strip()]

# # #     # 修改后的对齐函数
# # #     def align_texts(zh_sentences, en_sentences):
# # #         # 修改模型加载路径（关键修改）
# # #         model_path = "./models/paraphrase-multilingual-MiniLM-L12-v2"
        
# # #         # 验证模型是否存在（新增校验）
# # #         if not os.path.exists(model_path):
# # #             st.error(f"模型路径 {model_path} 不存在！请检查模型文件")
# # #             return []
            
# # #         try:
# # #             model = SentenceTransformer(model_path)
# # #         except Exception as e:
# # #             st.error(f"模型加载失败：{str(e)}")
# # #             return []

# # #         # 以下代码保持不变...
# # #         zh_embeddings = model.encode(zh_sentences)
# # #         en_embeddings = model.encode(en_sentences)
        
# # #         distance, path = fastdtw(
# # #             zh_embeddings, 
# # #             en_embeddings,
# # #             dist=cosine_distance,  # 使用自定义距离函数
# # #             radius=3
# # #         )

# # #         # cost_matrix = np.zeros((len(zh_sentences), len(en_sentences)))
# # #         # for i, zh_vec in enumerate(zh_embeddings):
# # #         #     for j, en_vec in enumerate(en_embeddings):
# # #         #         cost_matrix[i, j] = 1 - cosine_similarity([zh_vec], [en_vec])[0][0]
# # #         def cosine_distance(vec1, vec2):
# # #             return 1 - cosine_similarity([vec1], [vec2])[0][0]

# # #         # # distance, path = fastdtw(cost_matrix, radius=3)
# # #         # distance, path = fastdtw(zh_embeddings, en_embeddings, dist=cosine_distance, radius=3)

# # #         aligned_pairs = []
# # #         last_zh = last_en = -1

# # #         for (i, j) in path:
# # #             if i != last_zh and j != last_en:
# # #                 aligned_pairs.append((zh_sentences[i], en_sentences[j]))
# # #                 last_zh = i
# # #                 last_en = j
# # #             elif i == last_zh:
# # #                 aligned_pairs[-1] = (aligned_pairs[-1][0], aligned_pairs[-1][1] + " " + en_sentences[j])
# # #                 last_en = j
# # #             elif j == last_en:
# # #                 aligned_pairs[-1] = (aligned_pairs[-1][0] + en_sentences[j], aligned_pairs[-1][1])
# # #                 last_zh = i

# # #         return aligned_pairs

# # #     # 界面部分保持不变...
# # #     st.title("中英文文档对齐工具")

# # #     zh_file = st.file_uploader("上传中文文档", type=["txt"])
# # #     en_file = st.file_uploader("上传英文文档", type=["txt"])

# # #     zh_text = ""
# # #     en_text = ""

# # #     if zh_file is None:
# # #         try:
# # #             with open("zn.txt", "r", encoding="utf-8") as f:
# # #                 zh_text = f.read()
# # #         except FileNotFoundError:
# # #             st.warning("默认中文文件 zn.txt 不存在")
# # #     else:
# # #         zh_text = zh_file.read().decode("utf-8")

# # #     if en_file is None:
# # #         try:
# # #             with open("en.txt", "r", encoding="utf-8") as f:
# # #                 en_text = f.read()
# # #         except FileNotFoundError:
# # #             st.warning("默认英文文件 en.txt 不存在")
# # #     else:
# # #         en_text = en_file.read().decode("utf-8")

# # #     if st.button("开始对齐"):
# # #         if not zh_text or not en_text:
# # #             st.error("请先上传或提供中英文文档")
# # #             return
            
# # #         with st.spinner("处理中..."):
# # #             zh_sentences = split_sentences(zh_text, "zh")
# # #             en_sentences = split_sentences(en_text, "en")

# # #             if not zh_sentences or not en_sentences:
# # #                 st.error("分句失败，请检查文档内容")
# # #                 return

# # #             aligned = align_texts(zh_sentences, en_sentences)

# # #             if not aligned:
# # #                 return

# # #             df = pd.DataFrame(aligned, columns=["中文", "English"])
# # #             st.dataframe(df)

# # #             st.download_button(
# # #                 label="下载Excel文件",
# # #                 data=df.to_excel(index=False),
# # #                 file_name="aligned_text.xlsx",
# # #                 mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
# # #             )

# # # # 以下部分保持不变...
# # # if __name__ == '__main__':
# # #     from streamlit.web import cli as stcli
# # #     from streamlit import runtime
# # #     import sys

# # #     st.set_page_config(
# # #         page_title="智能双语对齐系统",
# # #         page_icon="🌐",
# # #         layout="wide",
# # #         initial_sidebar_state="expanded"
# # #     )

# # #     if runtime.exists():
# # #         main()
# # #     else:
# # #         sys.argv = ["streamlit", "run", sys.argv[0]]
# # #         sys.exit(stcli.main())



# # import streamlit as st
# # import pandas as pd
# # import numpy as np
# # from sklearn.metrics.pairwise import cosine_similarity
# # from fastdtw import fastdtw
# # from sentence_transformers import SentenceTransformer
# # import re
# # import os

# # # 设置离线模式
# # os.environ["TRANSFORMERS_OFFLINE"] = "1"
# # os.environ["HF_DATASETS_OFFLINE"] = "1"

# # def main():
# #     # st.set_page_config(
# #     #     page_title="智能双语对齐系统",
# #     #     page_icon="🌐",
# #     #     layout="wide",
# #     #     initial_sidebar_state="expanded"
# #     # )

# #     # ========== 界面美化 ==========
# #     st.title("🌐 智能双语对齐系统")
# #     st.caption("上传中英文文档，自动实现句子级对齐")

# #     # 使用侧边栏进行文件上传
# #     with st.sidebar:
# #         st.header("📁 文件上传")
# #         zh_file = st.file_uploader("选择中文文档", type=["txt"], key="zh")
# #         en_file = st.file_uploader("选择英文文档", type=["txt"], key="en")
        
# #         st.markdown("---")
# #         st.markdown("**默认文件**")
# #         st.caption("当未上传文件时，自动使用以下文件：")
# #         col1, col2 = st.columns(2)
# #         with col1:
# #             st.code("zn.txt\n(中文示例)")
# #         with col2:
# #             st.code("en.txt\n(英文示例)")

# #     # ========== 核心功能 ==========
# #     def split_sentences(text, lang):
# #         """改进版分句函数"""
# #         text = re.sub(r'([。！？?\!])([^”’])', r'\1\n\2', text)
# #         text = re.sub(r'([.!?])([’"])', r'\1\n\2', text)
# #         return [s.strip() for s in re.split(r'\n+', text) if s.strip()]

# #     def align_texts(zh_sentences, en_sentences):
# #         """优化后的对齐函数"""
# #         # 定义余弦距离函数
# #         def cosine_distance(vec1, vec2):
# #             return 1 - cosine_similarity([vec1], [vec2])[0][0]

# #         # 加载本地模型
# #         model_path = "./models/paraphrase-multilingual-MiniLM-L12-v2"
# #         if not os.path.exists(model_path):
# #             st.error(f"❌ 模型路径 {model_path} 不存在！")
# #             return []

# #         try:
# #             with st.spinner("⚙️ 正在加载语义模型..."):
# #                 model = SentenceTransformer(model_path)
# #         except Exception as e:
# #             st.error(f"❌ 模型加载失败：{str(e)}")
# #             return []

# #         # 生成嵌入向量
# #         with st.spinner("🔧 正在分析文本特征..."):
# #             zh_embeddings = model.encode(zh_sentences)
# #             en_embeddings = model.encode(en_sentences)

# #         # 执行动态时间规整
# #         with st.spinner("⏳ 正在计算最佳对齐路径..."):
# #             try:
# #                 distance, path = fastdtw(
# #                     zh_embeddings,
# #                     en_embeddings,
# #                     dist=cosine_distance,
# #                     radius=3
# #                 )
# #             except Exception as e:
# #                 st.error(f"❌ 对齐计算失败：{str(e)}")
# #                 return []

# #         # 处理对齐结果
# #         aligned_pairs = []
# #         last_zh = last_en = -1

# #         for (i, j) in path:
# #             if i != last_zh and j != last_en:
# #                 aligned_pairs.append((zh_sentences[i], en_sentences[j]))
# #                 last_zh = i
# #                 last_en = j
# #             elif i == last_zh:
# #                 aligned_pairs[-1] = (aligned_pairs[-1][0], aligned_pairs[-1][1] + " " + en_sentences[j])
# #                 last_en = j
# #             elif j == last_en:
# #                 aligned_pairs[-1] = (aligned_pairs[-1][0] + zh_sentences[i], aligned_pairs[-1][1])
# #                 last_zh = i

# #         return aligned_pairs

# #     # ========== 文件处理 ==========
# #     @st.cache_data
# #     def load_default_file(filename):
# #         """带缓存的默认文件加载"""
# #         try:
# #             with open(filename, "r", encoding="utf-8") as f:
# #                 return f.read()
# #         except FileNotFoundError:
# #             return None

# #     # 获取文本内容
# #     zh_text = zh_file.read().decode("utf-8") if zh_file else load_default_file("zn.txt")
# #     en_text = en_file.read().decode("utf-8") if en_file else load_default_file("en.txt")

# #     # 验证文本内容
# #     if not zh_text or not en_text:
# #         missing_files = []
# #         if not zh_text: missing_files.append("中文文档")
# #         if not en_text: missing_files.append("英文文档")
# #         st.error(f"❌ 缺少{'和'.join(missing_files)}，请上传文件或确保默认文件存在")
# #         return

# #     # ========== 执行对齐 ==========
# #     if st.button("🚀 开始对齐", use_container_width=True):
# #         with st.status("📊 正在处理文档...", expanded=True) as status:
# #             # 分句处理
# #             st.write("🔠 正在拆分句子...")
# #             zh_sentences = split_sentences(zh_text, "zh")
# #             en_sentences = split_sentences(en_text, "en")

# #             if not zh_sentences or not en_sentences:
# #                 st.error("❌ 分句失败，请检查文档内容")
# #                 return

# #             # 执行对齐
# #             st.write("🔍 正在对齐句子...")
# #             aligned = align_texts(zh_sentences, en_sentences)

# #             if not aligned:
# #                 status.update(label="处理失败", state="error")
# #                 return

# #             # 显示结果
# #             status.update(label="处理完成!", state="complete")
            
# #             # 结果展示
# #             st.success(f"✅ 成功对齐 {len(aligned)} 对句子")
# #             df = pd.DataFrame(aligned, columns=["中文", "English"])
            
# #             # 分页显示表格
# #             tab1, tab2 = st.tabs(["📄 表格预览", "📥 数据下载"])
# #             with tab1:
# #                 st.dataframe(
# #                     df,
# #                     use_container_width=True,
# #                     height=600,
# #                     hide_index=True,
# #                     column_config={
# #                         "中文": st.column_config.TextColumn(width="large"),
# #                         "English": st.column_config.TextColumn(width="large")
# #                     }
# #                 )
# #             with tab2:
# #                 st.download_button(
# #                     label="💾 下载Excel文件",
# #                     data=df.to_excel(index=False),
# #                     file_name="aligned_text.xlsx",
# #                     mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
# #                     use_container_width=True
# #                 )

# #             # 显示统计信息
# #             with st.expander("📈 统计信息", expanded=True):
# #                 col1, col2, col3 = st.columns(3)
# #                 col1.metric("中文句子数", len(zh_sentences))
# #                 col2.metric("英文句子数", len(en_sentences))
# #                 col3.metric("对齐率", f"{len(aligned)/max(len(zh_sentences), len(en_sentences))*100:.1f}%")
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

# # 配置设置
# os.environ["TRANSFORMERS_OFFLINE"] = "1"
# # st.set_page_config(
# #     page_title="智能双语对齐系统",
# #     page_icon="🌐",
# #     layout="wide",
# #     initial_sidebar_state="expanded"
# # )

# def main():
#     # ========== 界面组件 ==========
#     st.title("🌐 智能双语对齐系统")
#     st.caption("专业级中英文文档对齐工具 | 支持GPU加速")

#     with st.sidebar:
#         st.header("⚙️ 设置")
#         use_gpu = st.checkbox("启用GPU加速", value=torch.cuda.is_available())
#         export_format = st.selectbox("导出格式", ["Excel", "CSV", "TXT", "HTML", "Markdown"], index=0)
        
#         st.markdown("---")
#         st.header("📁 文件上传")
#         zh_file = st.file_uploader("上传中文文档", type=["txt"], key="zh")
#         en_file = st.file_uploader("上传英文文档", type=["txt"], key="en")

#     # ========== 核心功能 ==========
#     def split_sentences(text, lang):
#         """智能分句函数"""
#         text = re.sub(r'([。！？?！])([^”’])', r'\1\n\2', text) if lang == "zh" \
#             else re.sub(r'([.!?])([’"])', r'\1\n\2', text)
#         return [s.strip() for s in re.split(r'\n+', text) if s.strip()]

#     def align_texts(zh_sentences, en_sentences):
#         """GPU加速的对齐函数"""
#         # 设备选择
#         device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
        
#         # 加载模型
#         model_path = "./models/paraphrase-multilingual-MiniLM-L12-v2"
#         if not os.path.exists(model_path):
#             raise FileNotFoundError(f"模型路径 {model_path} 不存在")

#         try:
#             model = SentenceTransformer(model_path, device=device)
#         except Exception as e:
#             raise RuntimeError(f"模型加载失败: {str(e)}")

#         # 生成嵌入向量
#         with st.spinner(f"正在编码文本 ({device.upper()})..."):
#             zh_embeddings = model.encode(zh_sentences, show_progress_bar=False)
#             en_embeddings = model.encode(en_sentences, show_progress_bar=False)

#         # 对齐计算
#         def cosine_distance(a, b):
#             return 1 - cosine_similarity([a], [b])[0][0]

#         with st.spinner("计算动态时间规整路径..."):
#             _, path = fastdtw(zh_embeddings, en_embeddings, dist=cosine_distance, radius=3)

#         # 构建对齐结果
#         aligned = []
#         last_zh, last_en = -1, -1
#         for i, j in path:
#             if i != last_zh and j != last_en:
#                 aligned.append((zh_sentences[i], en_sentences[j]))
#                 last_zh, last_en = i, j
#             elif i == last_zh:
#                 aligned[-1] = (aligned[-1][0], aligned[-1][1] + " " + en_sentences[j])
#                 last_en = j
#             elif j == last_en:
#                 aligned[-1] = (aligned[-1][0] + zh_sentences[i], aligned[-1][1])
#                 last_zh = i
#         return aligned

#     # ========== 文件处理 ==========
#     @st.cache_data
#     def load_file(uploaded_file, default_path):
#         """带缓存的文件加载"""
#         if uploaded_file:
#             return uploaded_file.read().decode("utf-8")
#         try:
#             with open(default_path, "r", encoding="utf-8") as f:
#                 return f.read()
#         except FileNotFoundError:
#             return None

#     # 加载文本
#     zh_text = load_file(zh_file, "zn.txt")
#     en_text = load_file(en_file, "en.txt")

#     # 验证输入
#     if not zh_text or not en_text:
#         missing = []
#         if not zh_text: missing.append("中文文档")
#         if not en_text: missing.append("英文文档")
#         st.error(f"缺少 {' 和 '.join(missing)}，请上传文件或检查默认文件")
#         return

#     # ========== 执行对齐 ==========
#     if st.button("🚀 开始处理", use_container_width=True):
#         with st.status("📊 处理流程", expanded=True) as status:
#             # 分句处理
#             st.write("🔠 分句处理中...")
#             zh_sents = split_sentences(zh_text, "zh")
#             en_sents = split_sentences(en_text, "en")
#             st.write(f"识别到 {len(zh_sents)} 条中文句子 | {len(en_sents)} 条英文句子")

#             # 执行对齐
#             try:
#                 st.write("🔍 对齐处理中...")
#                 aligned = align_texts(zh_sents, en_sents)
#             except Exception as e:
#                 status.update(label="处理失败 ❌", state="error")
#                 st.error(str(e))
#                 return

#             # 结果处理
#             status.update(label="处理完成 ✅", state="complete")
#             df = pd.DataFrame(aligned, columns=["中文", "English"])
            
#             # 结果显示
#             tab1, tab2 = st.tabs(["📄 数据预览", "📥 导出选项"])
#             with tab1:
#                 st.dataframe(
#                     df,
#                     height=600,
#                     use_container_width=True,
#                     hide_index=True,
#                     column_config={
#                         "中文": st.column_config.TextColumn(width="large"),
#                         "English": st.column_config.TextColumn(width="large")
#                     }
#                 )

#             with tab2:
#                 # 生成文件数据
#                 buffer = BytesIO()
#                 if export_format == "Excel":
#                     df.to_excel(buffer, index=False)
#                     mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
#                     ext = "xlsx"
#                 elif export_format == "CSV":
#                     df.to_csv(buffer, index=False, encoding="utf-8-sig")
#                     mime = "text/csv"
#                     ext = "csv"
#                 elif export_format == "TXT":
#                     txt_content = "\n".join([f"{zh}\t{en}" for zh, en in aligned])
#                     buffer.write(txt_content.encode("utf-8"))
#                     mime = "text/plain"
#                     ext = "txt"
#                 elif export_format == "HTML":
#                     html_content = df.to_html(index=False)
#                     buffer.write(html_content.encode("utf-8"))
#                     mime = "text/html"
#                     ext = "html"
#                 elif export_format == "Markdown":
#                     md_content = df.to_markdown(index=False)
#                     buffer.write(md_content.encode("utf-8"))
#                     mime = "text/markdown"
#                     ext = "md"

#                 # 下载按钮
#                 st.download_button(
#                     label=f"💾 下载 {export_format} 文件",
#                     data=buffer.getvalue(),
#                     file_name=f"aligned_text.{ext}",
#                     mime=mime,
#                     use_container_width=True
#                 )

#             # 统计面板
#             with st.expander("📈 性能统计", expanded=True):
#                 col1, col2, col3 = st.columns(3)
#                 col1.metric("对齐数量", len(aligned))
#                 col2.metric("处理设备", "GPU ✅" if use_gpu and torch.cuda.is_available() else "CPU")
#                 col3.metric("内存占用", f"{torch.cuda.memory_allocated()/1e6:.1f} MB" if use_gpu else "N/A")

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

#     if runtime.exists():
#         main()
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

# 配置设置
os.environ["TRANSFORMERS_OFFLINE"] = "1"
# st.set_page_config(
#     page_title="智能双语对齐系统",
#     page_icon="🌐",
#     layout="wide",
#     initial_sidebar_state="expanded"
# )

def main():
    # ========== 界面组件 ==========
    st.title("🌐 智能双语对齐系统")
    st.caption("专业级中英文文档对齐工具 | 支持GPU加速")

    with st.sidebar:
        st.header("⚙️ 设置")
        use_gpu = st.checkbox("启用GPU加速", value=torch.cuda.is_available())
        export_format = st.selectbox(
            "导出格式",
            ["Excel", "CSV", "TXT", "HTML", "Markdown"],
            index=0
        )
        
        st.markdown("---")
        st.header("📁 文件上传")
        zh_file = st.file_uploader("上传中文文档", type=["txt"], key="zh")
        en_file = st.file_uploader("上传英文文档", type=["txt"], key="en")

    # ========== 核心功能 ==========
    def split_sentences(text, lang):
        """智能分句函数"""
        start_time = datetime.now()
        text = re.sub(r'([。！？?！])([^”’])', r'\1\n\2', text) if lang == "zh" \
            else re.sub(r'([.!?])([’"])', r'\1\n\2', text)
        sentences = [s.strip() for s in re.split(r'\n+', text) if s.strip()]
        st.write(f"🔠 分句完成 | 耗时 {(datetime.now()-start_time).total_seconds():.2f}s")
        return sentences

    def align_texts(zh_sentences, en_sentences):
        """GPU加速的对齐函数"""
        # 设备检测与选择
        device = "cuda" if use_gpu and torch.cuda.is_available() else "cpu"
        st.write(f"⚙️ 使用设备: {device.upper()}")

        # 模型加载
        model_path = "./models/paraphrase-multilingual-MiniLM-L12-v2"
        st.write("🔍 正在加载语义模型...")
        try:
            model_load_start = datetime.now()
            model = SentenceTransformer(model_path, device=device)
            st.write(f"✅ 模型加载成功 | 耗时 {(datetime.now()-model_load_start).total_seconds():.2f}s")
        except Exception as e:
            raise RuntimeError(f"❌ 模型加载失败: {str(e)}")

        # 文本编码
        st.write("📡 正在编码文本...")
        encode_start = datetime.now()
        zh_embeddings = model.encode(zh_sentences, show_progress_bar=False)
        en_embeddings = model.encode(en_sentences, show_progress_bar=False)
        st.write(f"✅ 编码完成 | 耗时 {(datetime.now()-encode_start).total_seconds():.2f}s")
        st.write(f"📊 中文嵌入维度: {zh_embeddings.shape} | 英文嵌入维度: {en_embeddings.shape}")

        # 对齐计算
        st.write("⏳ 正在计算对齐路径...")
        def cosine_distance(a, b):
            return 1 - cosine_similarity([a], [b])[0][0]

        dtw_start = datetime.now()
        try:
            _, path = fastdtw(zh_embeddings, en_embeddings, 
                             dist=cosine_distance, radius=3)
            st.write(f"✅ 对齐计算完成 | 耗时 {(datetime.now()-dtw_start).total_seconds():.2f}s")
        except Exception as e:
            raise RuntimeError(f"❌ 对齐计算失败: {str(e)}")

        # 构建对齐结果
        st.write("🔗 正在构建对齐结果...")
        build_start = datetime.now()
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
        st.write(f"✅ 结果构建完成 | 耗时 {(datetime.now()-build_start).total_seconds():.2f}s")
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

    if not zh_text or not en_text:
        missing = []
        if not zh_text: missing.append("中文文档")
        if not en_text: missing.append("英文文档")
        st.error(f"❌ 缺少 {' 和 '.join(missing)}")
        return

    if st.button("🚀 开始处理", use_container_width=True, type="primary"):
        process_start = datetime.now()
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
                
                # 结果处理
                st.write("## 阶段 3/4：结果处理")
                df = pd.DataFrame(aligned, columns=["中文", "English"])
                
                # 文件导出
                st.write("## 阶段 4/4：文件导出")
                buffer = BytesIO()
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
                    txt_content = "\n".join([f"{zh}\t{en}" for zh, en in aligned])
                    buffer.write(txt_content.encode("utf-8"))
                    mime_type = "text/plain"
                    ext = "txt"
                elif export_format == "HTML":
                    html_content = df.to_html(index=False, border=0)
                    buffer.write(html_content.encode("utf-8"))
                    mime_type = "text/html"
                    ext = "html"
                elif export_format == "Markdown":
                    md_content = df.to_markdown(index=False)
                    buffer.write(md_content.encode("utf-8"))
                    mime_type = "text/markdown"
                    ext = "md"

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

        # 结果显示
        st.success(f"成功对齐 {len(aligned)} 对句子")
        with st.container():
            col1, col2 = st.columns([3, 1])
            
            with col1:
                st.subheader("📄 数据预览")
                st.dataframe(
                    df,
                    height=600,
                    use_container_width=True,
                    hide_index=True
                )
            
            with col2:
                st.subheader("📥 导出选项")
                st.download_button(
                    label=f"下载 {export_format} 文件",
                    data=buffer.getvalue(),
                    file_name=f"aligned_text.{ext}",
                    mime=mime_type,
                    use_container_width=True
                )
                
                # 性能统计
                st.subheader("📈 性能指标")
                st.metric("总处理时间", f"{total_time:.2f}秒")
                st.metric("处理设备", "GPU 🚀" if torch.cuda.is_available() else "CPU 💻")
                if torch.cuda.is_available():
                    st.metric("显存占用", f"{torch.cuda.memory_allocated()/1e6:.1f} MB")

if __name__ == '__main__':
    from streamlit.web import cli as stcli
    from streamlit import runtime
    import sys

    st.set_page_config(
        page_title="智能双语对齐系统",
        page_icon="🌐",
        layout="wide",
        initial_sidebar_state="expanded"
    )

    if runtime.exists():
        main()
    else:
        sys.argv = ["streamlit", "run", sys.argv[0]]
        sys.exit(stcli.main())