from flask import Flask, request, jsonify
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Conexão com MongoDB Atlas (troquei a URI aqui)
client = MongoClient("mongodb+srv://AlunoUnivap:projetoiolanda@iolanda-cluster.otillni.mongodb.net/?retryWrites=true&w=majority&appName=iolanda-cluster")
db = client['iolanda_db']
usuarios_collection = db['usuarios']

@app.route('/cadastro', methods=['POST'])
def cadastrar():
    data = request.json
    email = data['email']
    
    if usuarios_collection.find_one({"email": email}):
        return jsonify({"status": "erro", "mensagem": "Usuário já existe"}), 400

    novo_usuario = {
        "nome": data['nome'],
        "email": email,
        "senha": generate_password_hash(data['senha']),
        "observatorio": data['observatorio']
    }
    
    usuarios_collection.insert_one(novo_usuario)
    return jsonify({"status": "ok", "mensagem": "Usuário cadastrado com sucesso"})

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data['email']
    senha = data['senha']
    
    usuario = usuarios_collection.find_one({"email": email})
    
    if usuario and check_password_hash(usuario['senha'], senha):
        return jsonify({"status": "ok", "mensagem": "Login bem-sucedido", "nome": usuario["nome"], "observatorio": usuario["observatorio"]})
    else:
        return jsonify({"status": "erro", "mensagem": "Email ou senha incorretos"}), 401

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
