# UNSENT

> A place to write what you couldn't say to anyone. It listens. It responds once. Then it forgets you were ever here.

---

## About

**UNSENT** is a safe, ephemeral space where users can write letters they've never been able to say out loud — to someone they lost, someone who hurt them, someone they never told.

The letter is witnessed once by an AI, receives a quiet, human-like response, and then is permanently deleted. No database stores it. No analytics track it. The letter exists only for the moment it is written and read.

---

## How It Works

1. The user writes a letter in a private, minimal interface.
2. The letter is sent to the backend.
3. A witness (Groq LLM) responds with 4–6 short sentences — not as a therapist, but as a quiet listener.
4. The response is streamed back character by character.
5. The letter is not stored anywhere. No copy is kept.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | HTML, CSS, Vanilla JavaScript (Zero-JS philosophy, Firebase Hosting) |
| **Backend** | Python, Flask |
| **AI Witness** | Groq API (LLM) |
| **Ephemeral Storage** | Upstash Redis (TTL-based auto-delete) |
| **Deployment** | Koyeb / Railway (backend), Firebase Hosting (frontend) |
| **Container** | Docker |

---

## Project Structure

```
unsent/
├── app.py                  # Flask backend with Groq + Redis
├── requirements.txt        # Python dependencies
├── Dockerfile              # Container configuration
├── Procfile                # Deployment configuration
├── .env                    # Environment variables (not in Git)
├── .gitignore              # Git ignore rules
│
├── public/                 # Static frontend
│   ├── index.html          # Main UI
│   ├── unsent_logo.jpeg
│   └── rope1.jpeg
│
├── frontend/               # React/Next.js frontend (legacy)
│
├── .firebase/              # Firebase hosting config
├── .firebaserc
├── firebase.json
└── README.md
```

---

## Setup & Installation

### Prerequisites

- Python 3.11+
- Pip
- Groq API Key
- Upstash Redis instance

### 1. Clone the Repository

```bash
git clone https://github.com/sowbaranika631/unsent.git
cd unsent
```

### 2. Create Virtual Environment

```bash
python -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Set Up Environment Variables

Create a `.env` file in the root directory:

```env
GROQ_API_KEY=your_groq_api_key
UPSTASH_REDIS_REST_URL=your_redis_url
UPSTASH_REDIS_REST_TOKEN=your_redis_token
```

### 5. Run Locally

```bash
python app.py
```

The server runs at `http://localhost:5000`.

---

## API Endpoint

### `POST /letter`

Sends a letter to the witness and streams back a response.

**Request Body:**
```json
{
  "letter": "Your unsent letter here..."
}
```

**Response:**  
Streamed plain text (character by character).

---

## The Witness Prompt

The AI is instructed to act as a **witness**, not a therapist. It:

- Reflects the feeling beneath the words without naming emotions
- Offers quiet permission — to grieve, miss, love, be angry, remain uncertain
- Never gives advice, predictions, or false comfort
- Returns the writer gently to the present moment

---

## Deployment

### Backend (Koyeb / Railway)

1. Push your code to GitHub
2. Connect your repository to Koyeb or Railway
3. Add the environment variables in the dashboard:
   - `GROQ_API_KEY`
   - `UPSTASH_REDIS_REST_URL`
   - `UPSTASH_REDIS_REST_TOKEN`
4. Deploy

### Frontend (Firebase Hosting)

```bash
firebase deploy --only hosting
```

---

## The Statement

> Every app that calls itself a safe space stores your data, sells your patterns, or turns your pain into a retention metric. UNSENT is built on infrastructure designed for ephemerality — a database that deletes itself by design, and a model instructed to witness, not fix. The people who need it most deserve infrastructure that takes their privacy as seriously as they take their silence.

---

## Contributors

- Kaanasree
- Sowbaranika
- Grismitha
- Pondharani

---

## License

MIT

---

**Say it. Once. Then let it go.**
