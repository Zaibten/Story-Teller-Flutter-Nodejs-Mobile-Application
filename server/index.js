// Very 1st script of node js
console.log('');
console.log("******* Story Teller Server Side *******");
console.log('');

// External Packages
require('dotenv').config();  // <--- Load .env
const express = require('express');
const { default: mongoose } = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const OpenAI = require('openai');
const User = require('./models/user'); // import the model
const cloudinary = require("cloudinary").v2;

const bcrypt = require('bcryptjs'); // for hashing passwords
// Internal Routes
const authRouter = require('./routes/auth.js');

// INIT
const app = express();
const PORT = process.env.PORT || 9000;
const DB = process.env.MONGO_URI;

// Middle ware
app.use(express.json());
app.use(authRouter);

// Serve Static Assets (FIX)
app.use("/assets", express.static("assets"));



// Connections
mongoose.connect(DB)
  .then(() => {
    console.log('MongoDB connection successful');
  })
  .catch((e) => {
    console.log("MongoDB Error:", e);
  });

app.use(cors());
app.use(bodyParser.json({ limit: "10mb" }));


cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// const storyRouter = require('./routes/story.js');
// app.use(storyRouter);

// -------------------- Reset Password --------------------
app.post('/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ success: false, error: "Email and new password are required" });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, error: "User not found" });

    const hashedPassword = await bcrypt.hash(newPassword, 10); // hash new password
    user.password = hashedPassword;
    await user.save();

    res.json({ success: true, message: "Password updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});



// -------------------- Profile Route --------------------
app.post('/profile', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email is required" });

    const user = await User.findOne({ email }).select('-password'); // exclude password
    if (!user) return res.status(404).json({ error: "User not found" });

    res.json({ success: true, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});


// console.log("API KEY:", process.env.OPENAI_API_KEY);

// -------------------- OpenAI Init --------------------

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ✅ SAFE JSON PARSER
function extractJSON(text) {
  try {
    if (!text) return null;

    // remove markdown
    text = text
      .replace(/```json/g, "")
      .replace(/```/g, "")
      .trim();

    const start = text.indexOf("[");
    const end = text.lastIndexOf("]");

    if (start === -1 || end === -1) return null;

    const jsonString = text.substring(start, end + 1);
    return JSON.parse(jsonString);
  } catch (e) {
    console.log("JSON_PARSE_ERROR:", e.message);
    return null;
  }
}

// ✅ SAFE IMAGE PROMPT (IMPORTANT FOR MODERATION ERRORS)
function safePrompt(text = "") {
  return text
    .replace(/violence|kill|death|gun|weapon|blood|fight/gi, "action scene")
    .replace(/horror|scary|dark/gi, "mysterious")
    .substring(0, 180);
}

// MAIN API
app.post('/generate-story-comic', async (req, res) => {
  try {
    const { prompt } = req.body;

    const finalPrompt =
      prompt || "A cute cat goes on a magical adventure";

    // 1️⃣ STORY
    const storyRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: `Write a short kid-friendly story about: ${finalPrompt}`
        }
      ],
      max_tokens: 250,
    });

    const story = storyRes.choices?.[0]?.message?.content || "";

    // 2️⃣ PANELS (FAST)
    const panelRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      messages: [
        { role: "system", content: "Return ONLY JSON array." },
        {
          role: "user",
          content: `
Create 4 comic panels:

[
{"title":"","description":"","imagePrompt":""}
]

Story:
${story}
          `
        }
      ]
    });

    const panels = extractJSON(panelRes.choices?.[0]?.message?.content);

    if (!Array.isArray(panels)) {
      return res.status(500).json({ error: "panel error" });
    }

    // ⚡ RETURN IMMEDIATELY (NO IMAGES YET)
    res.json({
      story,
      panels: panels.map(p => ({
        ...p,
        image: "" // empty for now
      }))
    });

    // 3️⃣ BACKGROUND IMAGE GENERATION (FAST NON-BLOCKING)
    panels.forEach(async (p, index) => {
      try {
        const img = await openai.images.generate({
          model: "gpt-image-1",
          prompt: `${safePrompt(p.imagePrompt)}, cartoon cute cat`,
          size: "1024x1024"
        });

        const imageData = img.data?.[0];

        if (!imageData?.b64_json) return;

        const base64Image = `data:image/png;base64,${imageData.b64_json}`;

        const uploadRes = await cloudinary.uploader.upload(base64Image, {
          folder: "story_comics"
        });

        // (optional) store in DB later
        console.log("Image ready:", uploadRes.secure_url);

      } catch (e) {
        console.log("BG IMAGE ERROR:", e.message);
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "failed" });
  }
});

app.get('/generate-story-comic-stream', async (req, res) => {
  const startTime = Date.now();
  const uniqueRequestId = `${Date.now()}-${Math.random().toString(36)}-${req.query.prompt || 'none'}`;

  // No-cache headers
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, private");
  res.setHeader("Pragma", "no-cache");
  res.setHeader("Expires", "0");

  try {
    const prompt = req.query.prompt;
    if (!prompt) return res.status(400).send("Prompt required");

    const send = (data) => res.write(`data: ${JSON.stringify(data)}\n\n`);
    send({ progress: 5 });

    // 🆕 Force uniqueness by appending a random UUID to the prompt
    const uniqueSuffix = `[unique request: ${uniqueRequestId}]`;
    const forcedUniquePrompt = `${prompt}. Generate a completely new, different story every time. Never repeat. ${uniqueSuffix}`;

    // 1️⃣ STORY – high temperature + random seed + unique prompt
    const storyRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: `Write a very short kid-friendly story (max 100 words) based on: "${forcedUniquePrompt}". 
          Be extremely creative and different from any previous story. Use random style, characters, and setting.`
        }
      ],
      max_tokens: 150,
      temperature: 0.9,           // even more creative
      seed: Math.floor(Math.random() * 1000000)  // random seed disables determinism
    });
    const story = storyRes.choices?.[0]?.message?.content || "";
    send({ progress: 20, story });

    // 2️⃣ PANELS – also creative
    const panelRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.7,
      messages: [
        { role: "system", content: "Return ONLY valid JSON array, no extra text." },
        {
          role: "user",
          content: `Generate 4 unique comic panels for the story below. 
          Each panel must have a title, description, and imagePrompt. 
          Make every panel different and unexpected.
          Story: ${story}
          Unique request ID: ${uniqueRequestId}`
        }
      ]
    });

    let panels = extractJSON(panelRes.choices?.[0]?.message?.content);
    if (!Array.isArray(panels)) throw new Error("Panel parsing failed");

    panels = panels.map(p => ({ ...p, image: "" }));
    send({ progress: 40, panels });

    // 3️⃣ IMAGES – same as before (unchanged)
    const concurrency = 2;
    const imageQueue = [...panels.entries()];

    async function processQueue() {
      const batch = [];
      while (imageQueue.length && batch.length < concurrency) {
        batch.push(imageQueue.shift());
      }
      if (batch.length === 0) return;

      await Promise.all(batch.map(async ([idx, panel]) => {
        try {
          const img = await openai.images.generate({
            model: "dall-e-3",
            prompt: safePrompt(panel.imagePrompt) + ", cute cartoon style, completely new scene",
            size: "1024x1024",
            response_format: "b64_json",
          });
          const base64 = img.data?.[0]?.b64_json;
          if (!base64) throw new Error("No base64");

          const uploadRes = await cloudinary.uploader.upload(
            `data:image/png;base64,${base64}`,
            { folder: "story_comics" }
          );
          const imageUrl = uploadRes.secure_url;
          console.log(`📸 Panel ${idx + 1} image URL: ${imageUrl}`);

          panels[idx].image = imageUrl;
          send({ progress: 40 + Math.round(((idx + 1) / panels.length) * 60), panelIndex: idx, image: imageUrl });
        } catch (err) {
          console.error(`Panel ${idx} failed:`, err.message);
          panels[idx].image = "";
        }
      }));

      await processQueue();
    }

    processQueue().then(() => {
      const totalTimeMs = Date.now() - startTime;
      const totalSeconds = Math.floor(totalTimeMs / 1000);
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;
      const formattedTime = `${minutes}:${seconds.toString().padStart(2, '0')}`;

      console.log(`⏱️ Total generation time: ${minutes}m ${seconds}s (${formattedTime})`);

      send({
        progress: 100,
        panels,
        step: "done",
        generationTime: formattedTime,
        generationTimeSeconds: totalSeconds
      });
      res.end();
    }).catch(err => {
      console.error(err);
      send({ error: "image generation failed" });
      res.end();
    });

  } catch (e) {
    console.error(e);
    res.end();
  }
});

// app.get('/generate-story-comic-stream', async (req, res) => {
//   const startTime = Date.now(); // 🆕 start timer

//   try {
//     const prompt = req.query.prompt;
//     if (!prompt) return res.status(400).send("Prompt required");

//     res.setHeader("Content-Type", "text/event-stream");
//     res.setHeader("Cache-Control", "no-cache");
//     res.setHeader("Connection", "keep-alive");

//     const send = (data) => res.write(`data: ${JSON.stringify(data)}\n\n`);

//     send({ progress: 5 });

//     // 1️⃣ STORY
//     const storyRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       messages: [{ role: "user", content: `Write a very short kid-friendly story (max 100 words): ${prompt}` }],
//       max_tokens: 150,
//       temperature: 0.2,
//     });
//     const story = storyRes.choices?.[0]?.message?.content || "";
//     send({ progress: 20, story });

//     // 2️⃣ PANELS
//     const panelRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       temperature: 0.1,
//       messages: [
//         { role: "system", content: "Return ONLY valid JSON array, no extra text." },
//         { role: "user", content: `4 comic panels: [{"title":"","description":"","imagePrompt":""}] Story: ${story}` }
//       ]
//     });
//     let panels = extractJSON(panelRes.choices?.[0]?.message?.content);
//     if (!Array.isArray(panels)) throw new Error("Panel parsing failed");

//     panels = panels.map(p => ({ ...p, image: "" }));
//     send({ progress: 40, panels });

//     // 3️⃣ IMAGES – PARALLEL with concurrency limit
//     const concurrency = 2;
//     const imageQueue = [...panels.entries()];

//     async function processQueue() {
//       const batch = [];
//       while (imageQueue.length && batch.length < concurrency) {
//         batch.push(imageQueue.shift());
//       }
//       if (batch.length === 0) return;

//       await Promise.all(batch.map(async ([idx, panel]) => {
//         try {
//           const img = await openai.images.generate({
//             model: "dall-e-3",
//             prompt: safePrompt(panel.imagePrompt) + ", cute cartoon style",
//             size: "1024x1024",
//             response_format: "b64_json",
//           });
//           const base64 = img.data?.[0]?.b64_json;
//           if (!base64) throw new Error("No base64");

//           const uploadRes = await cloudinary.uploader.upload(
//             `data:image/png;base64,${base64}`,
//             { folder: "story_comics" }
//           );
//           const imageUrl = uploadRes.secure_url;
//           console.log(`📸 Panel ${idx + 1} image URL: ${imageUrl}`);

//           panels[idx].image = imageUrl;
//           send({ progress: 40 + Math.round(((idx + 1) / panels.length) * 60), panelIndex: idx, image: imageUrl });
//         } catch (err) {
//           console.error(`Panel ${idx} failed:`, err.message);
//           panels[idx].image = "";
//         }
//       }));

//       await processQueue();
//     }

//     // Start parallel image generation
//     processQueue().then(() => {
//       const totalTimeMs = Date.now() - startTime;
//       const totalSeconds = Math.floor(totalTimeMs / 1000);
//       const minutes = Math.floor(totalSeconds / 60);
//       const seconds = totalSeconds % 60;
//       const formattedTime = `${minutes}:${seconds.toString().padStart(2, '0')}`;
      
//       console.log(`⏱️ Total generation time: ${minutes}m ${seconds}s (${formattedTime})`);

//       send({
//         progress: 100,
//         panels,
//         step: "done",
//         generationTime: formattedTime,   // 🆕 send formatted time
//         generationTimeSeconds: totalSeconds // optional
//       });
//       res.end();
//     }).catch(err => {
//       console.error(err);
//       send({ error: "image generation failed" });
//       res.end();
//     });

//   } catch (e) {
//     console.error(e);
//     res.end();
//   }
// });

app.get('/demo-cat-comic', async (req, res) => {
  try {
    // 🐱 HARDCODED PROMPT
    const prompt = "A cute cat goes on a magical adventure in a colorful world";

    // 1️⃣ STORY
    const storyRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: `Write a short, fun, kid-friendly story about: ${prompt}`
        }
      ],
      max_tokens: 200,
    });

    const story = storyRes.choices?.[0]?.message?.content || "";

    // 2️⃣ PANELS
    const panelRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      messages: [
        { role: "system", content: "Return ONLY JSON array." },
        {
          role: "user",
          content: `
Create 4 comic panels:

[
{"title":"","description":"","imagePrompt":""}
]

Story:
${story}
          `
        }
      ]
    });

    const panels = extractJSON(panelRes.choices?.[0]?.message?.content);

    if (!Array.isArray(panels)) {
      return res.json({ error: "panel failed" });
    }

    // 3️⃣ IMAGES + CLOUDINARY
    const results = await Promise.all(
      panels.map(async (p) => {
        try {
          const img = await openai.images.generate({
            model: "gpt-image-1",
            prompt: `${safePrompt(p.imagePrompt)}, cartoon, cute cat, colorful`,
            size: "1024x1024"
          });

          const imageData = img.data?.[0];

          let imageUrl = "";

          if (imageData?.b64_json) {
            const base64Image = `data:image/png;base64,${imageData.b64_json}`;

            const uploadRes = await cloudinary.uploader.upload(base64Image, {
              folder: "demo_cat",
            });

            imageUrl = uploadRes.secure_url;
          }

          return {
            title: p.title,
            description: p.description,
            image: imageUrl
          };

        } catch (e) {
          return {
            title: p.title,
            description: p.description,
            image: ""
          };
        }
      })
    );

    // ✅ SIMPLE RESPONSE
    res.json({
      success: true,
      story,
      panels: results
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Demo failed" });
  }
});

// Story Teller Route
// app.post('/generate-story', async (req, res) => {
//   try {
//     const { prompt } = req.body;

//     // Validate prompt
//     if (!prompt || prompt.trim() === "") {
//       return res.status(400).json({ error: 'Prompt is required' });
//     }

//     // Story prompt for AI
//     const storyPrompt = `
// You are a professional creative storyteller.

// Your job:
// - Convert the given prompt into a short, engaging story.
// - If the prompt is unclear, invalid, or unrelated to storytelling, IGNORE it and still generate a meaningful generic story.

// Prompt:
// "${prompt}"

// Rules:
// - Only return the story.
// - Do NOT explain anything.
// - Do NOT return JSON.
// - Keep it engaging and creative.
// `;

//     const completion = await openai.chat.completions.create({
//       model: "gpt-4o-mini", // fast + good for storytelling
//       messages: [{ role: "user", content: storyPrompt }],
//       temperature: 0.8, // more creativity
//       max_tokens: 500,
//     });

//     const story = completion.choices[0].message.content;

//     res.json({
//       story: story.trim()
//     });

//   } catch (err) {
//     console.error(err.message);
//     res.status(500).json({ error: 'Server error' });
//   }
// });





// Home Route (Dashboard UI)
app.get("/home", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Code Sync Server</title>
<link rel="icon" type="image/x-icon" href="assets/images/logo.png" />
      <script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;700&display=swap');
        body {
          margin: 0;
          font-family: 'Montserrat', sans-serif;
          background-color: #1e1e2f;
          color: #e4e4e4;
          display: flex;
          flex-direction: column;
          min-height: 100vh;
          overflow-x: hidden;
          position: relative;
        }
        .particle-container {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          z-index: -1;
        }
        .dashboard-container {
          width: 90%;
          max-width: 1200px;
          padding: 30px;
          background-color: #2b2b3d;
          border-radius: 15px;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
          margin: 30px auto;
          flex-grow: 1;
          animation: fadeIn 1.2s ease-in-out;
          z-index: 1;
        }
        @keyframes fadeIn {
          0% { opacity: 0; transform: translateY(20px); }
          100% { opacity: 1; transform: translateY(0); }
        }
        .header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 30px;
        }
        .header img {
          height: 100px;
          width: 100px;
          border-radius: 50%;
          box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .header h1 {
          font-size: 36px;
          color: #fff;
          font-weight: 700;
          margin: 0;
        }
        .header p {
          font-size: 18px;
          color: #bbb;
          margin-top: 5px;
          text-align: center;
        }
        .main-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 30px;
          margin-bottom: 40px;
        }
        .cards {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .card {
          background: linear-gradient(145deg, #3b3b4f, #242435);
          padding: 20px;
          border-radius: 10px;
          box-shadow: inset 0 4px 8px rgba(0, 0, 0, 0.3), 0 5px 15px rgba(0, 0, 0, 0.3);
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          border-left: 5px solid #ff7f50;
        }
        .card:hover {
          transform: translateY(-5px) scale(1.02);
          box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
        }
        .card h3 {
          font-size: 24px;
          color: #ffcc00;
          margin-bottom: 10px;
        }
        .card p {
          font-size: 16px;
          color: #ddd;
        }
        .recent-activities {
          background: linear-gradient(145deg, #41415b, #2c2c3d);
          padding: 20px;
          border-radius: 10px;
          box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .recent-activities h2 {
          font-size: 28px;
          margin-bottom: 15px;
          color: #ffcc00;
        }
        .recent-activities ul {
          padding-left: 20px;
        }
        .recent-activities li {
          font-size: 16px;
          color: #ddd;
          margin-bottom: 10px;
        }
        footer {
          background-color: #282836;
          color: #999;
          padding: 20px;
          text-align: center;
          font-size: 14px;
          border-top: 2px solid #444;
        }
        footer p {
          margin: 0;
        }
        footer a {
          color: #ff7f50;
          text-decoration: none;
          font-weight: 500;
        }
      </style>
    </head>
    <body>
      <div id="particle-container" class="particle-container"></div>
      <div class="dashboard-container">
        <div class="header">
          <img src="/assets/images/logo.png" alt="App Logo" />
          <div>
            <h1>Code Sync Server Dashboard</h1>
            <p>3D Virtually Perfect</p>
          </div>
        </div>

        <footer>
          <p>&copy; 2025 Anatomy. All rights reserved. 
          <a href="#">Terms</a> | <a href="#">Privacy Policy</a></p>
        </footer>
      </div>

      <script>
        particlesJS("particle-container", {
          particles: {
            number: { value: 80, density: { enable: true, value_area: 800 } },
            shape: { type: "circle" },
            opacity: { value: 0.5 },
            size: { value: 3 },
            line_linked: { enable: true, color: "#fff", opacity: 0.5, width: 2 },
          },
          interactivity: {
            events: {
              onhover: { enable: true, mode: "repulse" },
            },
          },
        });
      </script>
    </body>
    </html>
  `);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running at:`);
  console.log(`➡️ http://localhost:${PORT}`);
  console.log(`➡️ http://0.0.0.0:${PORT}`);
});

























// // index.js
// console.log("******* Code Sync Server *******");

// // -------------------- Packages --------------------
// require('dotenv').config();
// const express = require('express');
// const bodyParser = require('body-parser');
// const cors = require('cors');
// const OpenAI = require('openai');

// // -------------------- App Init --------------------
// const app = express();
// const PORT = process.env.PORT || 5000;

// app.use(cors());
// app.use(bodyParser.json({ limit: "10mb" }));

// // -------------------- OpenAI Init --------------------
// const openai = new OpenAI({
//   apiKey: process.env.OPENAI_API_KEY,
// });

// // -------------------- API ROUTES --------------------

// // Homepage
// app.get('/', (req, res) => {
//   res.send({ message: 'Welcome to Code Sync API' });
// });

// // Fix code route
// app.post('/fix-code', async (req, res) => {
//   try {
//     const { code } = req.body;

//     if (!code) {
//       return res.status(400).json({ error: 'Code is required' });
//     }

//     // Prompt to OpenAI
//     const prompt = `
// You are an expert developer and code reviewer. 
// 1. Detect any errors in the following code.
// 2. Highlight the errors in a readable format.
// 3. Correct the code.
// 4. Identify the programming language/framework.

// Code:
// ${code}

// Format your response as JSON:
// {
//   "correctedCode": "<corrected code here>",
//   "errors": "<highlighted errors here>",
//   "language": "<language/framework here>"
// }
// `;

//     const completion = await openai.chat.completions.create({
//       model: "gpt-4",
//       messages: [{ role: "user", content: prompt }],
//       temperature: 0,
//     });

//     const resultText = completion.choices[0].message.content;

//     // Try to parse JSON
//     let parsed;
//     try {
//       parsed = JSON.parse(resultText);
//     } catch (err) {
//       parsed = {
//         correctedCode: resultText,
//         errors: "Unable to parse errors",
//         language: "Unknown",
//       };
//     }

//     res.json(parsed);

//   } catch (err) {
//     console.error(err.message);
//     res.status(500).json({ error: 'Server error' });
//   }
// });

// // -------------------- Start Server --------------------
// app.listen(PORT, () => {
//   console.log(`Server running on port ${PORT}`);
// });
