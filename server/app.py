from flask import Flask, request, jsonify, send_from_directory, Blueprint
from utils.database import create_tables, SessionLocal
from models.user import AppUser
from models.route import Route
from models.coordinate import Coordinate

app = Flask(__name__, static_folder="static")

api = Blueprint("api", __name__, url_prefix="/api")
ui = Blueprint("ui", __name__, url_prefix="/ui")

create_tables()

@api.route('/users')
def get_users():
    # Erstellen Sie eine neue Sitzung
    session = SessionLocal()

    # Führen Sie eine Datenbankabfrage durch, um alle Benutzer abzurufen
    users = session.query(AppUser).all()

    # Schließen Sie die Sitzung
    session.close()

    # Geben Sie die Benutzerinformationen zurück (wir nehmen hier an, dass es eine `to_dict`-Methode in der `AppUser`-Klasse gibt)
    return {'users': [user.to_dict() for user in users]}


@api.route('/createTestUser')
def create_test_user():
    email = "testuser@example.com"
    db = SessionLocal()
    user = db.query(AppUser).filter_by(email=email).first()
    if user:
        return jsonify(user.serialize())

    user = AppUser()
    user.name = 'Testbenutzer'
    user.email = email
    user.created_date = '2022-04-18'
    user.last_login = '2022-04-18'
    user.stride_length = 0.5

    # Speichere den Benutzer in der Datenbank
    db.add(user)
    db.commit()

    return jsonify(user.serialize())


@api.route('/startRecording', methods=['POST'])
def start_recording():
    # Lese die Benutzer-ID aus dem JSON-Payload
    user_id = request.json.get('user_id')
    if not user_id:
        return jsonify({'error': 'Benutzer-ID fehlt.'}), 400

    # Suche den Benutzer in der Datenbank
    db = SessionLocal()
    user = db.query(AppUser).filter_by(id=user_id).first()
    if not user:
        return jsonify({'error': 'Benutzer nicht gefunden.'}), 404

    # Erstelle ein neues Route-Objekt in der Datenbank
    route = Route()
    route.user_id = user_id
    db.add(route)
    db.commit()

    # Speichere die Route-ID in der Benutzersitzung
    user.current_route_id = route.id
    db.add(user)
    db.commit()

    return jsonify({'message': 'Aufzeichnung gestartet.', 'route_id': route.id})

@api.route('/record', methods=['POST'])
def record():
    data = request.json
    route_id = data.get('route')
    latitude = data.get('latitude')
    longitude = data.get('longitude')

    if not all([route_id, latitude, longitude]):
        return jsonify({'message': 'Invalid request data.'}), 400

    db = SessionLocal()
    coordinate = Coordinate(route_id=route_id, latitude=latitude, longitude=longitude)
    db.add(coordinate)
    db.commit()

    return jsonify(coordinate.serialize()), 201

@api.route('/route/<route_id>')
def get_route(route_id):
    # Create a new session
    session = SessionLocal()

    # Query the database to get the route
    route = session.query(Route).filter_by(id=route_id).first()
    if not route:
        session.close()
        return jsonify({'error': 'Route not found.'}), 404

    # Query the database to get the coordinates for the route
    coordinates = session.query(Coordinate).filter_by(route_id=route_id).all()

    # Close the session
    session.close()

    # Return the route and its coordinates in GeoJSON format
    return jsonify(route.serialize_geojson())

@ui.route('/map')
def map():
    return send_from_directory(app.static_folder, 'html/map.html')


app.register_blueprint(api)
app.register_blueprint(ui)

if __name__ == "__main__":
    app.run(debug=True)
