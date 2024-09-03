import os
import shutil
import sys
import tempfile

import requests
import torch
from dotenv import load_dotenv
from langchain_chroma import Chroma
from langchain_community.document_loaders import Docx2txtLoader, PyPDFLoader, TextLoader
from langchain_community.llms import Ollama
from langchain_text_splitters import CharacterTextSplitter
from sklearn.metrics.pairwise import cosine_similarity
from transformers import AutoModel, AutoTokenizer

class AiAnalysis:
    def __init__(self) -> None:
        # Initialize environment variables
        load_dotenv()

        self.current_dir = os.path.dirname(os.path.abspath(__file__))
        self.persistent_directory = os.path.join(self.current_dir, "db", "chroma_db")

    def analyse(self, input_file_path):
        input_file_path = os.path.join(
            os.path.dirname(self.current_dir), sys.argv[1]
        ) 

        # Determine the file type based on the extension
        file_extension = os.path.splitext(input_file_path)[1].lower()

        if file_extension == ".pdf":
            # Use PyPDFLoader to load and parse the PDF file
            loader = PyPDFLoader(input_file_path)
            documents = loader.load()
        elif file_extension in [".doc", ".docx"]:
            # Use Docx2txtLoader to load and parse the Word document
            loader = Docx2txtLoader(input_file_path)
            documents = loader.load()
        else:
            # Use TextLoader to load and parse the Code files
            loader = TextLoader(temp_txt_file_path)
            documents = loader.load()


        # Split the document into chunks
        text_splitter = CharacterTextSplitter(chunk_size=1000, chunk_overlap=10)
        docs = text_splitter.split_documents(documents)

        #print("\n--- Document chunks reloaded ---")
        #print(f"Number of document chunks: {len(docs)}")

        # Initialize a set to collect unique keywords
        all_keywords = set()

        # Process each document chunk
        for i, doc in enumerate(docs):
            # Create the query for the current chunk
            query = f"""
            {doc.page_content}
            get keywords from the above content. keywords shall be from cs and maths fields. 
            return only the list of keywords. 
            ... return the keywords one after another with commas on a single line
            """

            ollama_base_url = os.getenv("ngrok_ollama_server")
            model_local = Ollama(base_url=ollama_base_url, model="phi3:14b")

            response = model_local(query)

            #print("This is one response:", response)

            # Process the text to extract keywords
            keywords = response.strip().split(", ")

            # Add the keywords to the set (to automatically handle duplicates)
            all_keywords.update(keyword.strip() for keyword in keywords)

        # combine all unique keywords into a comma-separated string
        final_keywords = ", ".join(sorted(all_keywords, key=str.lower))
        #print(final_keywords)

        # load SciBERT model and tokenizer
        tokenizer = AutoTokenizer.from_pretrained("allenai/scibert_scivocab_uncased")
        model = AutoModel.from_pretrained("allenai/scibert_scivocab_uncased")


        # function to get embeddings for a phrase
        def get_embedding(phrase):
            inputs = tokenizer(phrase, return_tensors="pt")
            outputs = model(**inputs)
            # Get the mean of the embeddings across tokens
            embedding = outputs.last_hidden_state.mean(dim=1)
            return embedding


        answer = ""
        # embeddings for the fields
        embedding1 = get_embedding("mathematics")
        embedding2 = get_embedding("computer science")

        # keep only words related to the mathematics and computer science fields
        for phrase in final_keywords.split(", "):
            embedding = get_embedding(phrase)
            similarity1 = cosine_similarity(
                embedding1.detach().numpy(), embedding.detach().numpy()
            )
            similarity2 = cosine_similarity(
                embedding2.detach().numpy(), embedding.detach().numpy()
            )
            if similarity1[0][0] >= 0.6 or similarity2[0][0] >= 0.6:
                answer += phrase + ", "


        #print("\n--- Final Keywords ---")
        return answer


ai = AiAnalysis()
keywords = ai.analyse(sys.argv[1])
print(keywords)
