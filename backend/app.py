from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({"message": "3 Tier AWS Flask App Running"})

@app.route("/health")
def health():
    return jsonify({"status": "OK"},200 )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)