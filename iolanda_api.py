from flask import Flask, request, jsonify
from pymongo import MongoClient
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import CORS
import os  # Adicionando a importação do módulo os para acessar variáveis de ambiente


app = Flask(__name__)
CORS(app)

# Conexão com MongoDB Atlas - usando a variável de ambiente MONGO_URI
mongo_uri = os.getenv("MONGO_URI")  # Lê a variável de ambiente MONGO_URI

if not mongo_uri:
    raise ValueError("A variável de ambiente MONGO_URI não está definida!")  # Caso a variável não esteja definida

client = MongoClient(mongo_uri)  # Conecta-se ao MongoDB usando a URI da variável de ambiente
db = client['iolanda_db']
usuarios_collection = db['usuarios']
observatorios_collection = db['observatorios']

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
        "username": data['username']   # novo campo
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
        return jsonify({"status": "ok", "mensagem": "Login bem-sucedido", "nome": usuario["nome"], "username": usuario["username"]})
    else:
        return jsonify({"status": "erro", "mensagem": "Email ou senha incorretos"}), 401
    
@app.route('/observatorios/nome/<nome>', methods=['GET'])
def get_observatorio_por_nome(nome):
    observatorio = observatorios_collection.find_one({"nome": nome})
    if observatorio:
        observatorio['_id'] = str(observatorio['_id'])  # Converte o ObjectId para string
        return jsonify(observatorio)
    else:
        return jsonify({"status": "erro", "mensagem": "Observatório não encontrado"}), 404

@app.route('/observatorios', methods=['POST'])
def cadastrar_observatorio():
    data = request.json
    nome = data['nome']

    if observatorios_collection.find_one({"nome": nome}):
        return jsonify({"status": "erro", "mensagem": "Observatório já existe"}), 400

    novo_obs = {
        "nome": nome,
        "localizacao": {
            "lat": data['localizacao']['lat'],
            "lon": data['localizacao']['lon'],
            "alt": data['localizacao']['alt']
        },
        "hora_local": data.get("hora_local"),
        "raio_equador": data.get("raio_equador"),
        "raio_polo": data.get("raio_polo")
    }

    observatorios_collection.insert_one(novo_obs)
    return jsonify({"status": "ok", "mensagem": "Observatório cadastrado com sucesso"})

@app.route('/observatorios/nome/<nome>', methods=['PUT'])
def atualizar_observatorio(nome):
    data = request.json

    resultado = observatorios_collection.update_one(
        {"nome": nome},
        {"$set": {
            "localizacao": {
                "lat": data['localizacao']['lat'],
                "lon": data['localizacao']['lon'],
                "alt": data['localizacao']['alt']
            },
            "hora_local": data.get("hora_local"),
            "raio_equador": data.get("raio_equador"),
            "raio_polo": data.get("raio_polo")
        }}
    )

    if resultado.matched_count == 0:
        return jsonify({"status": "erro", "mensagem": "Observatório não encontrado"}), 404

    return jsonify({"status": "ok", "mensagem": "Observatório atualizado com sucesso"})

@app.route('/observatorios/nome/<nome>', methods=['DELETE'])
def deletar_observatorio(nome):
    resultado = observatorios_collection.delete_one({"nome": nome})
    
    if resultado.deleted_count == 1:
        return jsonify({"status": "ok", "mensagem": f"Observatório '{nome}' deletado com sucesso"})
    else:
        return jsonify({"status": "erro", "mensagem": "Observatório não encontrado"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


