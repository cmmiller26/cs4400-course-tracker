#!/usr/bin/env python3
"""
CourseTracker Application Entry Point

This is the main entry point for the CourseTracker Flask application.
Run this file to start the development server.

Usage:
    python run.py
"""

from app import create_app
from utils.db_connection import test_connection

def main():
    """Initialize and run the Flask application."""
    # Create the Flask app using the factory pattern
    app = create_app()

    # Test database connection on startup
    print("\n" + "="*70)
    print("CourseTracker - University Course Tracking System")
    print("="*70)
    print("Testing database connection...")
    print("="*70)

    if test_connection():
        print("✓ Database connection successful!")
    else:
        print("⚠️  WARNING: Database connection failed!")
        print("   Please check your database configuration in .env")

    print("="*70)
    print("Starting Flask development server...")
    print("="*70 + "\n")

    # Run the application
    app.run(
        debug=app.config.get('DEBUG', True),
        host='0.0.0.0',
        port=5001
    )

if __name__ == '__main__':
    main()
