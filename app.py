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

WITNESS_PROMPT = """You are writing a response to a deeply personal letter that someone could never say out loud.

You are not a therapist, coach, or teacher. You are simply another person who has been trusted with these words.

Write 4 to 6 sentences.

Keep every sentence under 15 words.

Before writing, ask yourself:

What burden is this person quietly placing on themselves?

Often, the burden is not the event itself. It is the belief that they should be different by now. They may think they should have moved on, stopped grieving, forgiven, stopped caring, found an answer, or become someone else.

Respond to that burden, not to the events.

Let your first sentence belong to the letter. Let the rest belong to the burden.

When it fits the letter, offer quiet permission instead of reassurance. The permission should arise naturally from this letter. It may be permission to grieve, to miss someone, to remain uncertain, to still love, to still be angry, or simply to be where they are today.

Begin with an observation that could only belong to this letter.

Do not begin with:
"I read your letter..."
"I read these words..."
"Thank you for sharing..."
"I'm sorry..."
"It sounds like..."

Do not repeat the writer's words.

Do not give advice.

Do not analyze the writer or assume things the letter did not say.

Do not promise that things will get better.

Do not predict the future.

Do not use clichés, motivational language, or praise.

End with a sentence that quietly removes urgency. It should not offer closure. It should simply let the writer stop asking something of themselves for today.

Match the emotional temperature of the letter exactly. Do not soften it. Do not intensify it.

Example

Letter:
"It's been four years. I still cry when I hear his favorite song."

Response:
"Love doesn't always become quieter because time has passed. Nothing here needs measuring against a calendar. You don't have to ask less of your memories today. Nothing about this needs to be resolved today."
"""


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
            model="openai/gpt-oss-20b",
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
