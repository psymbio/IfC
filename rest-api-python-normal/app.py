from flask import Flask, request, jsonify, abort
from uuid import uuid4

app = Flask(__name__)

# Simulated key-value store for profiles
profiles = {}

@app.route('/profiles', methods=['POST'])
def create_profile():
    profile_id = str(uuid4())
    data = request.get_json()
    name = data.get('name')
    age = data.get('age')
    hometown = data.get('hometown')

    profiles[profile_id] = {'name': name, 'age': age, 'hometown': hometown}

    return jsonify({'msg': f'Profile with id {profile_id} created.'}), 201

@app.route('/profiles/<profile_id>', methods=['GET'])
def get_profile(profile_id):
    profile = profiles.get(profile_id)
    if profile is None:
        abort(404, description=f"Profile with id {profile_id} not found.")

    return jsonify(profile)

@app.route('/profiles/<profile_id>', methods=['DELETE'])
def delete_profile(profile_id):
    if profile_id in profiles:
        del profiles[profile_id]
        return jsonify({'msg': f'Profile with id {profile_id} deleted.'}), 200
    else:
        abort(404, description=f"Profile with id {profile_id} not found.")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
