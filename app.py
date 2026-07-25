import os
import uuid
from flask import Flask, request, jsonify, Response, stream_with_context
from flask_cors import CORS
from groq import Groq
from upstash_redis import Redis
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

groq_client = Groq(api_key=os.getenv("GROQ_API_KEY"))
redis_client = Redis(
    url=os.getenv("UPSTASH_REDIS_REST_URL"),
    token=os.getenv("UPSTASH_REDIS_REST_TOKEN")
)

WITNESS_PROMPT = """You are a witness. Someone has written a letter that was never sent, and you have read it. You stay with what is on the page — you do not interpret, advise, redirect, or reach for resolution. You reflect back only the presence of what was written, not its content or specific words. You do not repeat what they said back to them. You do not name their feelings for them. You do not smooth anything over.

Speak in short, unhurried sentences. Do not ask questions. Do not offer comfort or perspective. Do not use words like healing, journey, valid, space, closure, or process. Do not move toward any kind of ending that feels like release or resolution.

You are simply here, present, having read what they wrote. Write 3 to 4 sentences, then one final line that returns the person to themselves — not with hope or wisdom, but with quiet acknowledgment that they exist and that what they wrote was real.

A letter arrived. You received it. You are still holding it."""


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/letter", methods=["POST"])
def receive_letter():
    data = request.get_json()
    if not data:
        return jsonify({"error": "no data"}), 400

    letter_text = data.get("text", "").strip()
    recipient = data.get("to", "").strip()

    if not letter_text:
        return jsonify({"error": "empty letter"}), 400

    # Store in Redis with 60 second TTL — letter self-destructs
    letter_id = str(uuid.uuid4())
    full_letter = f"Dear {recipient},\n\n{letter_text}" if recipient else letter_text
    redis_client.set(f"letter:{letter_id}", full_letter, ex=60)

    # Call Groq with streaming
    def generate():
        stream = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[
                {"role": "system", "content": WITNESS_PROMPT},
                {"role": "user", "content": full_letter}
            ],
            stream=True,
            max_tokens=200,
            temperature=0.7
        )
        for chunk in stream:
            delta = chunk.choices[0].delta.content
            if delta:
                yield delta

        # Delete from Redis immediately after witness reads
        redis_client.delete(f"letter:{letter_id}")

    return Response(stream_with_context(generate()), mimetype="text/plain")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)