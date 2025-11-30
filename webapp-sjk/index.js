const express = require("express");
const axios = require("axios");
const cors = require("cors");

console.log(">> index.js berjalan");

const app = express();
app.use(cors());
app.use(express.json());

// HALAMAN UTAMA – kirim HTML + JS + CSS
app.get("/", (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="id">
  <head>
    <meta charset="UTF-8" />
    <title>WebApp SJK</title>
    <style>
      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: #f3f4f6;
        color: #111827;
      }

      .page {
        max-width: 800px;
        margin: 40px auto;
        padding: 24px 28px;
        background: #ffffff;
        border-radius: 8px;
        box-shadow: 0 10px 25px rgba(15, 23, 42, 0.12);
      }

      h1 {
        font-size: 26px;
        margin: 0 0 8px;
      }

      .subtitle {
        margin: 0 0 18px;
        color: #4b5563;
        font-size: 14px;
      }

      code {
        background: #f3f4f6;
        padding: 2px 5px;
        border-radius: 4px;
        font-size: 12px;
      }

      .ask-form {
        display: flex;
        gap: 8px;
        align-items: center;
        margin-bottom: 18px;
      }

      .ask-form input[type="text"] {
        flex: 1;
        padding: 8px 10px;
        font-size: 14px;
        border-radius: 4px;
        border: 1px solid #d1d5db;
        outline: none;
      }

      .ask-form input[type="text"]:focus {
        border-color: #2563eb;
        box-shadow: 0 0 0 1px #2563eb33;
      }

      .ask-form button {
        padding: 8px 16px;
        font-size: 14px;
        border-radius: 4px;
        border: none;
        cursor: pointer;
        background: #2563eb;
        color: #ffffff;
        font-weight: 500;
      }

      .ask-form button:hover {
        background: #1d4ed8;
      }

      .answer-box h3 {
        margin: 0 0 6px;
      }

      /* Kotak jawaban dari n8n */
      #result {
        margin: 0;
        padding: 10px 12px;
        border-radius: 4px;
        border: 1px solid #e5e7eb;
        background: #f9fafb;

        white-space: pre-wrap;        /* wrap tapi tetap hormati \n */
        word-wrap: break-word;
        overflow-wrap: break-word;

        max-height: 260px;            /* kalau terlalu panjang, scroll VERTIKAL */
        overflow-y: auto;
        overflow-x: hidden;           /* jangan ada scroll horizontal */
        font-size: 13px;
      }
    </style>
  </head>
  <body>
    <div class="page">
      <h1>WebApp SJK → n8n → OpenAI</h1>
      <p class="subtitle">
        Tulis pertanyaan, nanti akan dikirim ke endpoint <code>/ask</code> lalu diteruskan ke n8n.
      </p>

      <form class="ask-form" onsubmit="ask(event)">
        <input
          id="q"
          type="text"
          placeholder="Tulis pertanyaan kamu di sini..."
        />
        <button type="submit">Kirim</button>
      </form>

      <div class="answer-box">
        <h3>Jawaban dari n8n:</h3>
        <pre id="result">{}</pre>
      </div>
    </div>

    <script>
      async function ask(event) {
        event.preventDefault();

        const input = document.getElementById("q");
        const question = input.value.trim();
        if (!question) {
          alert("Pertanyaannya jangan kosong dulu 🙂");
          input.focus();
          return;
        }

        const res = await fetch("/ask", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ question }),
        });

        const data = await res.json();
        const resultEl = document.getElementById("result");

        resultEl.innerText =
          typeof data === "string" ? data : JSON.stringify(data, null, 2);
      }
    </script>
  </body>
</html>`);
});

// ENDPOINT /ask – nanti nyambung ke n8n
app.post("/ask", async (req, res) => {
  try {
    const { question } = req.body;

    // TODO: ganti dengan URL webhook n8n kamu
    const webhookUrl =
      "https://ventriloquistic-holden-acapnial.ngrok-free.dev/webhook/webapp-sjk-ask";

    const response = await axios.post(webhookUrl, { question });

    // balikin jawaban dari n8n ke client (browser)
    res.json(response.data);
  } catch (error) {
    console.error("Error di /ask:", error.message);
    res.status(500).json({ error: error.message });
  }
});

// JALANKAN SERVER
app.listen(3000, () => {
  console.log("WebApp running on http://localhost:3000");
});
