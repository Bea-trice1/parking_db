import os
import sys

# Add repository root to system path for clean imports
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from app.app import app

# Vercel serverless WSGI handler
if __name__ == '__main__':
    app.run()
