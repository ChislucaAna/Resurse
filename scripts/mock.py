import os
import shutil
import sys
import tempfile

from langchain_community.document_loaders import Docx2txtLoader, PyPDFLoader, TextLoader
from dotenv import load_dotenv

load_dotenv()

current_dir = os.path.dirname(os.path.abspath(__file__))
input_file_path = os.path.join(current_dir, sys.argv[1])


loader = PyPDFLoader(input_file_path)
documents = loader.load()
print("yay")
