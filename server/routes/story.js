const express = require("express");
const router = express.Router();
const multer = require("multer");
const fs = require("fs");
const path = require("path");
const OpenAI = require("openai");
const ffmpeg = require("fluent-ffmpeg");

const upload = multer({ dest: "uploads/" });

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// -------------------- Generate Story --------------------
router.post(
  "/generate-story",
  upload.fields([
    { name: "image", maxCount: 1 },
    { name: "audio", maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      let { prompt } = req.body;

      // ------------------ AUDIO → TEXT ------------------
      if (req.files?.audio) {
        const audioPath = req.files.audio[0].path;

        const transcription = await openai.audio.transcriptions.create({
          file: fs.createReadStream(audioPath),
          model: "whisper-1",
        });

        prompt = (prompt || "") + " " + transcription.text;
      }

      // ------------------ IMAGE → DESCRIPTION ------------------
      if (req.files?.image) {
        const imagePath = req.files.image[0].path;
        const base64Image = fs.readFileSync(imagePath, {
          encoding: "base64",
        });

        const imageResponse = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: [
                { type: "text", text: "Describe this image for story creation" },
                {
                  type: "image_url",
                  image_url: {
                    url: `data:image/jpeg;base64,${base64Image}`,
                  },
                },
              ],
            },
          ],
        });

        prompt += " " + imageResponse.choices[0].message.content;
      }

      // ------------------ STORY GENERATION ------------------
      const storyResponse = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: `Create a detailed, emotional, cinematic story from this:\n${prompt}`,
          },
        ],
      });

      const story = storyResponse.choices[0].message.content;

      // ------------------ TEXT → SPEECH ------------------
      const speech = await openai.audio.speech.create({
        model: "gpt-4o-mini-tts",
        voice: "alloy",
        input: story,
      });

      const audioFile = path.join(__dirname, "../assets/story.mp3");
      const buffer = Buffer.from(await speech.arrayBuffer());
      fs.writeFileSync(audioFile, buffer);

      // ------------------ CREATE VIDEO ------------------
      const videoPath = path.join(__dirname, "../assets/story.mp4");

      await new Promise((resolve, reject) => {
        ffmpeg()
          .input("assets/background.jpg") // put any static image
          .loop(10)
          .input(audioFile)
          .outputOptions("-shortest")
          .save(videoPath)
          .on("end", resolve)
          .on("error", reject);
      });

      res.json({
        success: true,
        story,
        audioUrl: "/assets/story.mp3",
        videoUrl: "/assets/story.mp4",
      });

    } catch (err) {
      console.error(err);
      res.status(500).json({ error: "Story generation failed" });
    }
  }
);

module.exports = router;