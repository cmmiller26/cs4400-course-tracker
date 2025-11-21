from flask import Flask, render_template, session, redirect, url_for
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
        if 'user_id' in session:
            role = session.get('role')
            if role == 'student':
                return redirect(url_for('student.index'))
            elif role == 'admin':
                return redirect(url_for('admin.index'))
        return render_template('index.html')

    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return render_template('404.html'), 404

    @app.errorhandler(500)
    def internal_error(error):
        return render_template('500.html'), 500

    return app