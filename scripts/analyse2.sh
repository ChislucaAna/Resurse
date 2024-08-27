from dotenv import load_dotenv

import os
import requests
import tempfile
import shutil
import sys

from langchain_text_splitters import CharacterTextSplitter
from langchain_community.document_loaders import TextLoader
from langchain_chroma import Chroma
from langchain_community.llms import Ollama
from PyPDF2 import PdfReader
import docx

# Initialize environment variables
load_dotenv()

current_dir = os.path.dirname(os.path.abspath(__file__))
persistent_directory = os.path.join(current_dir, "db", "chroma_db")

# Function to extract text from a PDF file
def extract_text_from_pdf(pdf_path):
    reader = PdfReader(pdf_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text()
    return text

# Function to extract text from a Word file
def extract_text_from_word(docx_path):
    doc = docx.Document(docx_path)
    text = ""
    for para in doc.paragraphs:
        text += para.text + "\n"
    return text

input_file_path = os.path.join("/", "resources", sys.argv[1]) 

# Determine the file type based on the extension
file_extension = os.path.splitext(input_file_path)[1].lower()

with tempfile.NamedTemporaryFile(delete=False, suffix=".txt") as temp_txt_file:
    if file_extension == '.pdf':
        # Extract text from the PDF file
        pdf_text = extract_text_from_pdf(input_file_path)
        temp_txt_file.write(pdf_text.encode('utf-8'))
    elif file_extension in ['.doc', '.docx']:
        # Extract text from the Word file
        word_text = extract_text_from_word(input_file_path)
        temp_txt_file.write(word_text.encode('utf-8'))
    else:
        # If the file is neither PDF nor Word, assume it's a code file and process accordingly
        with open(input_file_path, 'r') as code_file:
            code_text = code_file.read()
            temp_txt_file.write(code_text.encode('utf-8'))

    temp_txt_file_path = temp_txt_file.name


try:
    # Re-process the original documents to recreate the chunks
    loader = TextLoader(temp_txt_file_path)
    documents = loader.load()

    # Split the document into chunks
    text_splitter = CharacterTextSplitter(chunk_size=1000, chunk_overlap=10)
    docs = text_splitter.split_documents(documents)

    print("\n--- Document chunks reloaded ---")
    print(f"Number of document chunks: {len(docs)}")

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
        model_local = Ollama(base_url=ollama_base_url, model="llama3")
        # model_local = Ollama(base_url=ollama_base_url, model="phi3:14b")

        response = model_local(query)
            
        # Process the text to extract keywords
        keywords = response.strip().split(",")

        # Add the keywords to the set (to automatically handle duplicates)
        all_keywords.update(keyword.strip() for keyword in keywords)


    # Combine all unique keywords into a comma-separated string
    final_keywords = ", ".join(sorted(all_keywords, key=str.lower))

    # Print the final aggregated keywords
    print("\n--- Final Aggregated Keywords ---")
    print(final_keywords)    
    
finally:
    if os.path.exists(temp_txt_file_path):
        os.remove(temp_txt_file_path)
