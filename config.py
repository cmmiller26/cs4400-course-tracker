import os
from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

class Config:
    """Flask application configuration"""
    
    # Flask settings
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    DEBUG = True  # Set to False in production
    
    # MySQL Database settings
    DB_CONFIG = {
        'host': os.environ.get('DB_HOST') or 'localhost',
        'user': os.environ.get('DB_USER') or 'root',
        'password': os.environ.get('DB_PASSWORD') or 'your_password_here',
        'database': os.environ.get('DB_NAME') or 'CourseTracker',
        'raise_on_warnings': True,
        'autocommit': False  # We want explicit transaction control
    }