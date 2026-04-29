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

const path = require('path');
const { exec } = require('child_process');
const axios = require('axios');
const ffmpeg = require('fluent-ffmpeg');

const fs = require('fs');

const bcrypt = require('bcryptjs'); // for hashing passwords
// Internal Routes
const authRouter = require('./routes/auth.js');

const videoRouter = require('./routes/videoRoutes.js');

// Add with other requires
const puterVideoGenerator = require('./routes/mk.js');




// INIT
const app = express();
const PORT = process.env.PORT || 9000;
const DB = process.env.MONGO_URI;

// Middle ware
app.use(express.json());
app.use(authRouter);

app.use(videoRouter);

// Add after other app.use
app.use('/puter-video', puterVideoGenerator);

// Serve Static Assets (FIX)
app.use("/assets", express.static("assets"));



// // Connections
// mongoose.connect(DB)
//   .then(() => {
//     console.log('MongoDB connection successful');
//   })
//   .catch((e) => {
//     console.log("MongoDB Error:", e);
//   });

app.use(cors());
app.use(bodyParser.json({ limit: "10mb" }));


cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// const storyRouter = require('./routes/story.js');
// app.use(storyRouter);

// // -------------------- Reset Password --------------------
// app.post('/reset-password', async (req, res) => {
//   try {
//     const { email, newPassword } = req.body;
//     if (!email || !newPassword) {
//       return res.status(400).json({ success: false, error: "Email and new password are required" });
//     }

//     const user = await User.findOne({ email });
//     if (!user) return res.status(404).json({ success: false, error: "User not found" });

//     const hashedPassword = await bcrypt.hash(newPassword, 10); // hash new password
//     user.password = hashedPassword;
//     await user.save();

//     res.json({ success: true, message: "Password updated successfully" });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ success: false, error: "Server error" });
//   }
// });



// // -------------------- Profile Route --------------------
// app.post('/profile', async (req, res) => {
//   try {
//     const { email } = req.body;
//     if (!email) return res.status(400).json({ error: "Email is required" });

//     const user = await User.findOne({ email }).select('-password'); // exclude password
//     if (!user) return res.status(404).json({ error: "User not found" });

//     res.json({ success: true, user });
//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: "Server error" });
//   }
// });


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
// Add this after your existing code, before app.listen()

// Function to convert English text to Roman Urdu using OpenAI
// Function to convert English text to Authentic Roman Urdu with proper accent cues
async function convertToRomanUrdu(text) {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are a professional Urdu storyteller. Convert the following English text to Natural Roman Urdu that SOUNDS like authentic Urdu when spoken.

IMPORTANT RULES FOR AUTHENTIC URDU ACCENT:
1. Use proper Urdu words (not English words written in Urdu script)
2. Add emotional expressions: 'Achha!', 'Wah!', 'Are!', 'Haye!'
3. Use Urdu sentence structure (verb at the end)
4. Honorifics: 'jee', 'sahab'
5. Common Urdu words: 'bilkul', 'bohat', 'thoda', 'barah'
6. Storytelling phrases: 'chalo', 'suno', 'dekho'

Example: 
English: "The rabbit was very happy"
Bad: "Rabbit bohat khush tha"
Good: "Achha! Khargosh bohat khush tha, bilkul!"

Only return the Roman Urdu text, no explanations.`
        },
        {
          role: "user",
          content: text
        }
      ],
      temperature: 0.4,
      max_tokens: 600
    });
    
    return response.choices[0].message.content;
  } catch (error) {
    console.error("Roman Urdu conversion error:", error);
    return text;
  }
}

// Test different voices for best Urdu accent
app.get('/test-voices', async (req, res) => {
  const testText = "Achha! Suno meri kahani. Ek dafa ka zikr hai...";
  const voices = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'];
  const results = [];
  
  for (const voice of voices) {
    try {
      const mp3 = await openai.audio.speech.create({
        model: "tts-1",
        voice: voice,
        input: testText,
        speed: 0.85
      });
      
      const buffer = Buffer.from(await mp3.arrayBuffer());
      const filePath = path.join(__dirname, 'temp', `test_${voice}.mp3`);
      fs.writeFileSync(filePath, buffer);
      
      // Upload to Cloudinary
      const uploadResult = await cloudinary.uploader.upload(filePath, {
        folder: "voice_tests",
        resource_type: "raw",
        public_id: `voice_${voice}`
      });
      
      results.push({ voice, url: uploadResult.secure_url });
      
      // Cleanup
      setTimeout(() => {
        if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
      }, 1000);
      
    } catch (error) {
      results.push({ voice, error: error.message });
    }
  }
  
  res.json({
    message: "Test different voices to find best Urdu accent",
    recommended: "Try 'fable' or 'nova' for best Urdu accent",
    results
  });
});

// Function to generate voiceover using OpenAI TTS (Fixed for kid-friendly voice)
// Function to generate voiceover with Urdu accent using pronunciation guide
async function generateVoiceover(text, filename) {
  try {
    // First, enhance the Roman Urdu text with pronunciation guides for better accent
    const enhancedText = await enhanceRomanUrduForAccent(text);
    
    // Try different voices - some work better for South Asian accents
    // 'nova' and 'fable' work best for Urdu accent
    const mp3 = await openai.audio.speech.create({
      model: "tts-1",
      voice: "fable", // 'fable' gives better South Asian accent, try 'nova' or 'echo' as alternatives
      input: enhancedText,
      speed: 0.85  // Slower speed helps with clarity
    });
    
    const buffer = Buffer.from(await mp3.arrayBuffer());
    const filePath = path.join(__dirname, 'temp', filename);
    
    // Ensure temp directory exists
    if (!fs.existsSync(path.join(__dirname, 'temp'))) {
      fs.mkdirSync(path.join(__dirname, 'temp'));
    }
    
    fs.writeFileSync(filePath, buffer);
    console.log("✅ Voiceover generated with Urdu accent using 'fable' voice");
    return filePath;
  } catch (error) {
    console.error("Voiceover generation error:", error);
    return null;
  }
}

// Function to enhance Roman Urdu text for better pronunciation
async function enhanceRomanUrduForAccent(text) {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are a pronunciation expert. Convert the following Roman Urdu text into a version that will be spoken with an authentic Urdu accent by an English TTS system.

Rules for better Urdu pronunciation:
1. Add 'ah' sounds at the end of words that end with 'a' (e.g., 'acha' -> 'achah')
2. Double vowels for emphasis (e.g., 'zara' -> 'zaara')
3. Add 'h' to soften sounds (e.g., 'bara' -> 'barah')
4. Break long words with hyphens for clarity
5. Use common Urdu filler words like 'jee', 'hahn'
6. Add pauses with commas and periods

Example:
Original: "Ek dafa ek chota sa bacha tha"
Enhanced: "Jee, ek dafa, ek chotah sa bachah tha..."
Only return the enhanced text, no explanations.`
        },
        {
          role: "user",
          content: text
        }
      ],
      temperature: 0.5,
      max_tokens: 800
    });
    
    return response.choices[0].message.content;
  } catch (error) {
    console.error("Enhancement error:", error);
    return text;
  }
}

// Function to create video with voiceover using FFmpeg
async function createVideoWithVoiceover(imagePaths, voiceoverPath, outputPath, durationPerImage = 4) {
  return new Promise((resolve, reject) => {
    // Get voiceover duration
    exec(`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${voiceoverPath}"`, 
      async (error, stdout) => {
        const voiceDuration = parseFloat(stdout) || (imagePaths.length * durationPerImage);
        
        // Calculate duration per image based on voiceover length
        const actualDurationPerImage = voiceDuration / imagePaths.length;
        
        // Create concat file
        const concatFile = path.join(__dirname, 'temp', `concat_${Date.now()}.txt`);
        let concatContent = '';
        for (const imagePath of imagePaths) {
          concatContent += `file '${imagePath}'\nduration ${actualDurationPerImage}\n`;
        }
        concatContent += `file '${imagePaths[imagePaths.length - 1]}'\n`;
        fs.writeFileSync(concatFile, concatContent);
        
        // FIXED: Use libvo_aacenc instead of aac, and add -strict experimental
        const command = `ffmpeg -f concat -safe 0 -i "${concatFile}" -i "${voiceoverPath}" -vf "fps=24,scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset fast -crf 23 -c:a libvo_aacenc -b:a 128k -pix_fmt yuv420p -shortest -y "${outputPath}"`;
        
        console.log("Running FFmpeg command...");
        
        exec(command, (err, stdout, stderr) => {
          if (fs.existsSync(concatFile)) fs.unlinkSync(concatFile);
          if (err) {
            console.error("FFmpeg stderr:", stderr);
            reject(err);
          } else {
            console.log("Video created successfully");
            resolve(outputPath);
          }
        });
      });
  });
}

// Modified MAIN API - generates comic and then auto-creates video
app.post('/generate-story-comic', async (req, res) => {
  try {
    const { prompt } = req.body;
    const finalPrompt = prompt || "A cute cat goes on a magical adventure";

    // 1️⃣ Generate STORY in English
    const storyRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: `Write a short kid-friendly story (max 150 words) about: ${finalPrompt}`
        }
      ],
      max_tokens: 300,
    });

    const englishStory = storyRes.choices?.[0]?.message?.content || "";
    console.log("📖 English Story:", englishStory);

    // 2️⃣ Generate PANELS
    const panelRes = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.2,
      messages: [
        { role: "system", content: "Return ONLY JSON array." },
        {
          role: "user",
          content: `
Create 4 comic panels for this story:

Story: ${englishStory}

Return JSON:
[
  {"title":"","description":"","imagePrompt":""}
]
          `
        }
      ]
    });

    let panels = extractJSON(panelRes.choices?.[0]?.message?.content);
    if (!Array.isArray(panels)) {
      return res.status(500).json({ error: "Panel error" });
    }

    console.log("🎨 Generating comic images...");

    // 3️⃣ Generate IMAGES for all panels (WITHOUT blocking)
    const panelsWithImages = await Promise.all(
      panels.map(async (panel, index) => {
        try {
          const img = await openai.images.generate({
            model: "dall-e-3",
            prompt: `${safePrompt(panel.imagePrompt)}, cartoon style, colorful, kid-friendly`,
            size: "1024x1024",
            response_format: "b64_json",
          });
          
          const base64 = img.data?.[0]?.b64_json;
          if (base64) {
            const base64Image = `data:image/png;base64,${base64}`;
            const uploadRes = await cloudinary.uploader.upload(base64Image, {
              folder: "story_comics"
            });
            console.log(`✅ Panel ${index + 1} image uploaded`);
            return { ...panel, image: uploadRes.secure_url };
          }
          return { ...panel, image: "" };
        } catch (err) {
          console.error(`Panel ${index} error:`, err.message);
          return { ...panel, image: "" };
        }
      })
    );

    // Filter out panels without images
    const validImages = panelsWithImages.filter(p => p.image);
    
    if (validImages.length === 0) {
      return res.json({
        success: true,
        story: englishStory,
        panels: panelsWithImages,
        videoUrl: null,
        message: "No images generated for video"
      });
    }

    // Send response with comic images FIRST
    res.json({
      success: true,
      story: englishStory,
      panels: panelsWithImages,
      videoUrl: null,
      videoGenerating: true,
      message: "Comic generated! Video is being created in background..."
    });

    // 4️⃣ GENERATE VIDEO IN BACKGROUND (non-blocking)
    console.log("🎬 Starting background video generation...");
    
    // Convert story to Roman Urdu
    console.log("🔄 Converting story to Roman Urdu...");
    const romanUrduStory = await convertToRomanUrdu(englishStory);
    console.log("📖 Roman Urdu Story:", romanUrduStory);
    
    // Generate voiceover
    console.log("🎤 Generating voiceover...");
    const voiceoverFile = await generateVoiceover(romanUrduStory, `voice_${Date.now()}.mp3`);
    
    if (voiceoverFile) {
      // Download images for video
      const tempImagePaths = [];
      for (let i = 0; i < validImages.length; i++) {
        const panel = validImages[i];
        try {
          const response = await axios({
            method: 'GET',
            url: panel.image,
            responseType: 'stream'
          });
          const imagePath = path.join(__dirname, 'temp', `video_img_${Date.now()}_${i}.png`);
          const writer = fs.createWriteStream(imagePath);
          response.data.pipe(writer);
          await new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
          });
          tempImagePaths.push(imagePath);
        } catch (err) {
          console.error(`Error downloading image ${i}:`, err.message);
        }
      }
      
      if (tempImagePaths.length > 0) {
        // Create video
        const videoPath = path.join(__dirname, 'temp', `story_video_${Date.now()}.mp4`);
        await createVideoWithVoiceover(tempImagePaths, voiceoverFile, videoPath, 4);
        
        // Upload to Cloudinary
        console.log("☁️ Uploading video to Cloudinary...");
        const uploadResult = await cloudinary.uploader.upload(videoPath, {
          folder: "story_videos",
          resource_type: "video",
          public_id: `story_video_${Date.now()}`
        });
        
        console.log("");
        console.log("═══════════════════════════════════════════════════");
        console.log("🎬 VIDEO GENERATED SUCCESSFULLY! 🎬");
        console.log("═══════════════════════════════════════════════════");
        console.log("📹 Video URL:", uploadResult.secure_url);
        console.log("📖 Story (English):", englishStory);
        console.log("📖 Story (Roman Urdu):", romanUrduStory);
        console.log("═══════════════════════════════════════════════════");
        console.log("");
        
        // Cleanup temp files
        setTimeout(() => {
          [...tempImagePaths, voiceoverFile, videoPath].forEach(file => {
            if (fs.existsSync(file)) fs.unlinkSync(file);
          });
        }, 5000);
      }
    }
    
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Separate endpoint to check video status and get URL
app.get('/get-latest-video', async (req, res) => {
  try {
    const result = await cloudinary.api.resources({
      type: 'upload',
      prefix: 'story_videos',
      resource_type: 'video',
      max_results: 1,
      sort_by: 'created_at',
      sort_order: 'desc'
    });
    
    if (result.resources && result.resources.length > 0) {
      res.json({
        success: true,
        videoUrl: result.resources[0].secure_url,
        createdAt: result.resources[0].created_at
      });
    } else {
      res.json({ success: false, message: "No videos found" });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Test endpoint for Roman Urdu conversion
app.get('/test-roman-urdu', async (req, res) => {
  const testText = req.query.text || "Once upon a time, there was a little cat who loved to explore the magical forest.";
  const romanUrdu = await convertToRomanUrdu(testText);
  res.json({
    original: testText,
    romanUrdu: romanUrdu
  });
});

// Test endpoint for voiceover only
app.post('/test-voiceover', async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) return res.status(400).json({ error: "Text required" });
    
    const romanUrdu = await convertToRomanUrdu(text);
    const voiceFile = await generateVoiceover(romanUrdu, `test_voice_${Date.now()}.mp3`);
    
    if (voiceFile) {
      // Upload to Cloudinary
      const uploadResult = await cloudinary.uploader.upload(voiceFile, {
        folder: "voiceovers",
        resource_type: "raw"
      });
      
      res.json({
        success: true,
        originalText: text,
        romanUrduText: romanUrdu,
        audioUrl: uploadResult.secure_url
      });
      
      setTimeout(() => {
        if (fs.existsSync(voiceFile)) fs.unlinkSync(voiceFile);
      }, 5000);
    } else {
      res.json({ error: "Voice generation failed" });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
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

    const uniqueSuffix = `[unique request: ${uniqueRequestId}]`;
    const forcedUniquePrompt = `${prompt}. Generate a completely new, different story every time. Never repeat. ${uniqueSuffix}`;

    // 1️⃣ STORY
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
      temperature: 0.9,
      seed: Math.floor(Math.random() * 1000000)
    });
    const englishStory = storyRes.choices?.[0]?.message?.content || "";
    send({ progress: 20, story: englishStory });

    // 2️⃣ PANELS
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
          Story: ${englishStory}
          Unique request ID: ${uniqueRequestId}`
        }
      ]
    });

    let panels = extractJSON(panelRes.choices?.[0]?.message?.content);
    if (!Array.isArray(panels)) throw new Error("Panel parsing failed");

    panels = panels.map(p => ({ ...p, image: "" }));
    send({ progress: 40, panels });

    // 3️⃣ GENERATE IMAGES
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

    await processQueue();
    
    send({ progress: 85, status: "Converting story to Roman Urdu..." });

    // 4️⃣ CONVERT STORY TO ROMAN URDU & GENERATE VOICEOVER
    const validPanels = panels.filter(p => p.image);
    let videoUrl = null;
    
    if (validPanels.length > 0) {
      try {
        // Send progress update
        send({ progress: 88, status: "Converting to Roman Urdu with authentic accent..." });
        
        // Convert story to Roman Urdu
        console.log("🔄 Converting to Roman Urdu...");
        const romanUrduStory = await convertToRomanUrdu(englishStory);
        console.log("📖 Roman Urdu Story:", romanUrduStory);
        
        // Send the Roman Urdu story to frontend
        send({ progress: 90, status: "Roman Urdu story ready", romanUrduStory: romanUrduStory });
        
        // Generate voiceover
        console.log("🎤 Generating voiceover with Urdu accent...");
        send({ progress: 92, status: "Generating voiceover with authentic Urdu accent..." });
        
        const voiceoverFile = await generateVoiceover(romanUrduStory, `voice_${Date.now()}.mp3`);
        
        if (voiceoverFile) {
          send({ progress: 94, status: "Downloading images for video..." });
          
          // Download images
          const tempImagePaths = [];
          for (let i = 0; i < validPanels.length; i++) {
            const panel = validPanels[i];
            try {
              const response = await axios({
                method: 'GET',
                url: panel.image,
                responseType: 'stream'
              });
              const imagePath = path.join(__dirname, 'temp', `video_img_${Date.now()}_${i}.png`);
              const writer = fs.createWriteStream(imagePath);
              response.data.pipe(writer);
              await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
              });
              tempImagePaths.push(imagePath);
            } catch (err) {
              console.error(`Error downloading image ${i}:`, err.message);
            }
          }
          
          if (tempImagePaths.length > 0) {
            send({ progress: 96, status: "Creating video with voiceover..." });
            
            // Create video
            const videoPath = path.join(__dirname, 'temp', `story_video_${Date.now()}.mp4`);
            await createVideoWithVoiceover(tempImagePaths, voiceoverFile, videoPath, 4);
            
            // Upload to Cloudinary
            console.log("☁️ Uploading video to Cloudinary...");
            send({ progress: 98, status: "Uploading video to cloud..." });
            
            const uploadResult = await cloudinary.uploader.upload(videoPath, {
              folder: "story_videos",
              resource_type: "video",
              public_id: `story_video_${Date.now()}`
            });
            
            videoUrl = uploadResult.secure_url;
            
            console.log("");
            console.log("═══════════════════════════════════════════════════");
            console.log("🎬 VIDEO GENERATED SUCCESSFULLY! 🎬");
            console.log("═══════════════════════════════════════════════════");
            console.log("📹 Video URL:", videoUrl);
            console.log("📖 Story (English):", englishStory);
            console.log("📖 Story (Roman Urdu):", romanUrduStory);
            console.log("═══════════════════════════════════════════════════");
            console.log("");
            
            // Cleanup
            setTimeout(() => {
              [...tempImagePaths, voiceoverFile, videoPath].forEach(file => {
                if (fs.existsSync(file)) fs.unlinkSync(file);
              });
            }, 5000);
          }
        }
      } catch (videoError) {
        console.error("Video generation error:", videoError);
      }
    }
    
    // Final response with video URL and Roman Urdu story
    send({ 
      progress: 100, 
      step: "done",
      videoUrl: videoUrl,
      romanUrduStory: await convertToRomanUrdu(englishStory), // Ensure we have it
      panels,
      generationTime: `${Math.floor((Date.now() - startTime) / 1000)}s`
    });
    
    res.end();

  } catch (e) {
    console.error(e);
    send({ error: e.message });
    res.end();
  }
});

















// MAIN API
// app.post('/generate-story-comic', async (req, res) => {
//   try {
//     const { prompt } = req.body;

//     const finalPrompt =
//       prompt || "A cute cat goes on a magical adventure";

//     // 1️⃣ STORY
//     const storyRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       messages: [
//         {
//           role: "user",
//           content: `Write a short kid-friendly story about: ${finalPrompt}`
//         }
//       ],
//       max_tokens: 250,
//     });

//     const story = storyRes.choices?.[0]?.message?.content || "";

//     // 2️⃣ PANELS (FAST)
//     const panelRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       temperature: 0.2,
//       messages: [
//         { role: "system", content: "Return ONLY JSON array." },
//         {
//           role: "user",
//           content: `
// Create 4 comic panels:

// [
// {"title":"","description":"","imagePrompt":""}
// ]

// Story:
// ${story}
//           `
//         }
//       ]
//     });

//     const panels = extractJSON(panelRes.choices?.[0]?.message?.content);

//     if (!Array.isArray(panels)) {
//       return res.status(500).json({ error: "panel error" });
//     }

//     // ⚡ RETURN IMMEDIATELY (NO IMAGES YET)
//     res.json({
//       story,
//       panels: panels.map(p => ({
//         ...p,
//         image: "" // empty for now
//       }))
//     });

//     // 3️⃣ BACKGROUND IMAGE GENERATION (FAST NON-BLOCKING)
//     panels.forEach(async (p, index) => {
//       try {
//         const img = await openai.images.generate({
//           model: "gpt-image-1",
//           prompt: `${safePrompt(p.imagePrompt)}, cartoon cute cat`,
//           size: "1024x1024"
//         });

//         const imageData = img.data?.[0];

//         if (!imageData?.b64_json) return;

//         const base64Image = `data:image/png;base64,${imageData.b64_json}`;

//         const uploadRes = await cloudinary.uploader.upload(base64Image, {
//           folder: "story_comics"
//         });

//         // (optional) store in DB later
//         console.log("Image ready:", uploadRes.secure_url);

//       } catch (e) {
//         console.log("BG IMAGE ERROR:", e.message);
//       }
//     });

//   } catch (err) {
//     console.error(err);
//     res.status(500).json({ error: "failed" });
//   }
// });
// app.get('/generate-story-comic-stream', async (req, res) => {
//   const startTime = Date.now();
//   const uniqueRequestId = `${Date.now()}-${Math.random().toString(36)}-${req.query.prompt || 'none'}`;

//   // No-cache headers
//   res.setHeader("Content-Type", "text/event-stream");
//   res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, private");
//   res.setHeader("Pragma", "no-cache");
//   res.setHeader("Expires", "0");

//   try {
//     const prompt = req.query.prompt;
//     if (!prompt) return res.status(400).send("Prompt required");

//     const send = (data) => res.write(`data: ${JSON.stringify(data)}\n\n`);
//     send({ progress: 5 });

//     // 🆕 Force uniqueness by appending a random UUID to the prompt
//     const uniqueSuffix = `[unique request: ${uniqueRequestId}]`;
//     const forcedUniquePrompt = `${prompt}. Generate a completely new, different story every time. Never repeat. ${uniqueSuffix}`;

//     // 1️⃣ STORY – high temperature + random seed + unique prompt
//     const storyRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       messages: [
//         {
//           role: "user",
//           content: `Write a very short kid-friendly story (max 100 words) based on: "${forcedUniquePrompt}". 
//           Be extremely creative and different from any previous story. Use random style, characters, and setting.`
//         }
//       ],
//       max_tokens: 150,
//       temperature: 0.9,           // even more creative
//       seed: Math.floor(Math.random() * 1000000)  // random seed disables determinism
//     });
//     const story = storyRes.choices?.[0]?.message?.content || "";
//     send({ progress: 20, story });

//     // 2️⃣ PANELS – also creative
//     const panelRes = await openai.chat.completions.create({
//       model: "gpt-4o-mini",
//       temperature: 0.7,
//       messages: [
//         { role: "system", content: "Return ONLY valid JSON array, no extra text." },
//         {
//           role: "user",
//           content: `Generate 4 unique comic panels for the story below. 
//           Each panel must have a title, description, and imagePrompt. 
//           Make every panel different and unexpected.
//           Story: ${story}
//           Unique request ID: ${uniqueRequestId}`
//         }
//       ]
//     });

//     let panels = extractJSON(panelRes.choices?.[0]?.message?.content);
//     if (!Array.isArray(panels)) throw new Error("Panel parsing failed");

//     panels = panels.map(p => ({ ...p, image: "" }));
//     send({ progress: 40, panels });

//     // 3️⃣ IMAGES – same as before (unchanged)
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
//             prompt: safePrompt(panel.imagePrompt) + ", cute cartoon style, completely new scene",
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
//         generationTime: formattedTime,
//         generationTimeSeconds: totalSeconds
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














app.get('/check-openai', async (req, res) => {
  try {

    await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: "Hi" }],
      max_tokens: 5,
    });

    res.json({ status: "working", credits: "available" });

  } catch (error) {

    if (error.code === "insufficient_quota") {
      return res.json({ status: "failed", reason: "no_credits" });
    }

    if (error.code === "invalid_api_key") {
      return res.json({ status: "failed", reason: "invalid_key" });
    }

    res.json({ status: "error", message: error.message });
  }
});



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
