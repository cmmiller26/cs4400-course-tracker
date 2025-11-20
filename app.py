from flask import Flask, render_template
from config import Config

# Import blueprints
from routes.student_routes import student_bp
from routes.admin_routes import admin_bp
from routes.auth_routes import auth_bp

def create_app():
    """
    Application factory pattern for creating Flask app.

    Returns:
        Flask app instance
    """
    app = Flask(__name__)
    app.config.from_object(Config)

    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(student_bp, url_prefix='/student')
    app.register_blueprint(admin_bp, url_prefix='/admin')

    # Home route
    @app.route('/')
    def index():
        return render_template('index.html')

    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return render_template('404.html'), 404

    @app.errorhandler(500)
    def internal_error(error):
        return render_template('500.html'), 500

    return app

if __name__ == '__main__':
    app = create_app()
    
    # Test database connection on startup
    print("\n" + "="*50)
    print("Testing database connection...")
    print("="*50)
    from utils.db_connection import test_connection
    if test_connection():
        print("Database connection successful!")
    else:
        print("WARNING: Database connection failed!")
    print("="*50 + "\n")
    
    # Run the app
    app.run(debug=True, host='0.0.0.0', port=5001)