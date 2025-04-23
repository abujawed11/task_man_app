from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
import uuid
import logging
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Optional: Setup logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# PostgreSQL config via SQLAlchemy
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize database
db = SQLAlchemy(app)

# ---------------- MODELS ----------------
class User(db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.String(100), primary_key=True)
    username = db.Column(db.String(100), nullable=False, unique=True)
    email = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20))
    password = db.Column(db.String(100), nullable=False)
    role = db.Column(db.String(50))
    fcm_token = db.Column(db.String(200))


class Task(db.Model):
    __tablename__ = 'tasks'
    task_id = db.Column(db.String(100), primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    assigned_by = db.Column(db.String(100))
    assigned_to = db.Column(db.String(100))
    deadline = db.Column(db.Date)
    priority = db.Column(db.String(50))
    status = db.Column(db.String(50))


@app.route('/create_tables')
def create_tables():
    db.create_all()
    return "✅ Tables created successfully!"


@app.route('/')
def home():
    return "API is running. Use /tasks or /create_task"

# ---------------- SIGNUP ----------------
@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        required_fields = ['username', 'email', 'phone', 'password', 'role']
        if not all(field in data for field in required_fields):
            return jsonify({'message': 'Missing required fields'}), 400

        existing_user = User.query.filter_by(username=data['username']).first()
        if existing_user:
            return jsonify({'message': 'User already exists'}), 409

        new_user = User(
            user_id=str(uuid.uuid4()),
            username=data['username'],
            email=data['email'],
            phone=data['phone'],
            password=data['password'],
            role=data['role'],
            fcm_token=data.get('fcm_token', '')
        )
        db.session.add(new_user)
        db.session.commit()
        return jsonify({'message': 'Signup successful'}), 200
    except Exception as e:
        logger.error(f"Signup error: {str(e)}")
        return jsonify({'error': str(e)}), 500

# ---------------- LOGIN ----------------
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        user = User.query.filter_by(username=data['username'], password=data['password']).first()

        if user:
            return jsonify({
                'message': 'Login successful',
                'user_id': user.user_id,
                'username': user.username,
                'role': user.role
            }), 200

        return jsonify({'message': 'Invalid username or password'}), 401
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({'error': str(e)}), 500

# ---------------- CREATE TASK ----------------
@app.route('/create_task', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        logger.debug(f"Received data: {data}")

        required_fields = ['title', 'assigned_by', 'assigned_to', 'deadline', 'priority']
        if not all(field in data for field in required_fields):
            return jsonify({'success': False, 'message': 'Missing required fields'}), 400

        new_task = Task(
            task_id=str(uuid.uuid4()),
            title=data['title'],
            description=data.get('description', ''),
            assigned_by=data['assigned_by'],
            assigned_to=data['assigned_to'],
            deadline=datetime.strptime(data['deadline'], '%Y-%m-%d').date(),
            priority=data['priority'],
            status=data.get('status', 'Pending')
        )
        db.session.add(new_task)
        db.session.commit()

        logger.info(f"Task created successfully: {new_task.task_id}")
        return jsonify({
            'success': True,
            'message': 'Task created successfully',
            'task_id': new_task.task_id
        }), 201
    except Exception as e:
        logger.error(f"Error creating task: {str(e)}")
        return jsonify({'success': False, 'message': f"Error creating task: {str(e)}"}), 500

# ---------------- GET USERS ----------------
@app.route('/users', methods=['GET'])
def get_users():
    try:
        users = User.query.with_entities(User.username).all()
        return jsonify([user.username for user in users]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------------- GET TASKS ----------------
@app.route('/tasks', methods=['GET'])
def get_tasks():
    try:
        username = request.args.get('username')
        role = request.args.get('role')

        if not username or not role:
            return jsonify({'error': 'Missing username or role parameters'}), 400

        if role in ['Admin', 'Super Admin']:
            tasks = Task.query.order_by(Task.deadline.asc()).all()
        else:
            tasks = Task.query.filter(
                (Task.assigned_to == username) | (Task.assigned_by == username)
            ).order_by(Task.deadline.asc()).all()

        formatted_tasks = [
            {
                'task_id': task.task_id,
                'title': task.title,
                'description': task.description,
                'deadline': task.deadline.strftime('%Y-%m-%d') if task.deadline else None,
                'priority': task.priority,
                'status': task.status,
                'assigned_by': task.assigned_by,
                'assigned_to': task.assigned_to
            } for task in tasks
        ]

        return jsonify(formatted_tasks), 200
    except Exception as e:
        logger.error(f"Error fetching tasks: {str(e)}")
        return jsonify({'error': 'Server error', 'details': str(e)}), 500

# ---------------- MAIN ----------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
