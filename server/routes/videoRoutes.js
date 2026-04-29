// videoGenerator.js - Fixed version with proper duration
const express = require('express');
const OpenAI = require('openai');
const cloudinary = require('cloudinary').v2;
const axios = require('axios');
const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
require('dotenv').config();

const router = express.Router();

// Initialize OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Ensure temp directory exists
const tempDir = path.join(__dirname, 'temp');
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir);
}

// Download image from URL
async function downloadImage(url, filename) {
  const response = await axios({
    method: 'GET',
    url: url,
    responseType: 'stream'
  });
  
  const filePath = path.join(tempDir, filename);
  const writer = fs.createWriteStream(filePath);
  response.data.pipe(writer);
  
  return new Promise((resolve, reject) => {
    writer.on('finish', () => resolve(filePath));
    writer.on('error', reject);
  });
}

// Generate images from prompt
async function generateImages(prompt, count = 4) {
  const images = [];
  
  const variations = [
    prompt,
    `${prompt} - wide shot, cinematic`,
    `${prompt} - close up, detailed`,
    `${prompt} - aerial view, beautiful lighting`
  ];
  
  for (let i = 0; i < Math.min(count, variations.length); i++) {
    try {
      console.log(`🎨 Generating image ${i + 1}/${count}: ${variations[i]}`);
      
      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: variations[i],
        size: "1024x1024",
        quality: "standard",
        n: 1,
      });
      
      images.push(response.data[0].url);
    } catch (error) {
      console.error(`Error generating image ${i + 1}:`, error.message);
    }
  }
  
  return images;
}

// Create video from images using FFmpeg with proper duration
async function createVideoFromImages(imagePaths, outputPath) {
  return new Promise((resolve, reject) => {
    // Create a temporary file list for FFmpeg concat
    const listFile = path.join(tempDir, `filelist_${Date.now()}.txt`);
    const fileContent = imagePaths.map(p => `file '${p}'`).join('\n');
    fs.writeFileSync(listFile, fileContent);
    
    // Use ffmpeg to create video with 3 seconds per image
    const command = `ffmpeg -f concat -safe 0 -i "${listFile}" -vf "fps=24,scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset fast -crf 23 -r 24 -t ${imagePaths.length * 3} -y "${outputPath}"`;
    
    console.log('Running FFmpeg command:', command);
    
    exec(command, (error, stdout, stderr) => {
      // Clean up list file
      if (fs.existsSync(listFile)) fs.unlinkSync(listFile);
      
      if (error) {
        console.error('FFmpeg error:', error);
        reject(error);
      } else {
        console.log('Video created successfully:', outputPath);
        
        // Verify video duration
        getVideoDuration(outputPath).then(duration => {
          console.log(`Video duration: ${duration} seconds`);
          resolve(outputPath);
        }).catch(err => {
          console.error('Error getting duration:', err);
          resolve(outputPath);
        });
      }
    });
  });
}

// Get video duration using ffprobe
function getVideoDuration(videoPath) {
  return new Promise((resolve, reject) => {
    const command = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${videoPath}"`;
    
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
      } else {
        const duration = parseFloat(stdout);
        resolve(duration);
      }
    });
  });
}

// Upload video to Cloudinary
async function uploadVideoToCloudinary(videoPath, prompt) {
  try {
    // Get video duration first
    const duration = await getVideoDuration(videoPath);
    console.log(`Uploading video with duration: ${duration} seconds`);
    
    const result = await cloudinary.uploader.upload(videoPath, {
      folder: "generated_videos",
      resource_type: "video",
      public_id: `video_${Date.now()}`,
      eager: [
        { streaming_profile: "hd", format: "m3u8" },
        { format: "mp4" }
      ]
    });
    
    // Add duration to result
    result.duration = duration;
    
    return result;
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    throw error;
  }
}

// Alternative: Create simple video using canvas (no FFmpeg required)
async function createSimpleVideoFromImages(imagePaths, outputPath) {
  return new Promise(async (resolve, reject) => {
    try {
      // Use FFmpeg with simple concat
      const concatFile = path.join(tempDir, `concat_${Date.now()}.txt`);
      let concatContent = '';
      
      for (const imagePath of imagePaths) {
        // Each image will be displayed for 3 seconds (2 frames per second * 3 seconds = 6 frames)
        concatContent += `file '${imagePath}'\nduration 3\n`;
      }
      // Add last image again to ensure duration
      concatContent += `file '${imagePaths[imagePaths.length - 1]}'\n`;
      
      fs.writeFileSync(concatFile, concatContent);
      
      const command = `ffmpeg -f concat -safe 0 -i "${concatFile}" -vf "fps=24,scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -y "${outputPath}"`;
      
      console.log('Running FFmpeg command:', command);
      
      exec(command, (error, stdout, stderr) => {
        if (fs.existsSync(concatFile)) fs.unlinkSync(concatFile);
        
        if (error) {
          console.error('FFmpeg error:', error);
          reject(error);
        } else {
          console.log('Video created successfully:', outputPath);
          resolve(outputPath);
        }
      });
    } catch (error) {
      reject(error);
    }
  });
}

// Clean up temp files
function cleanupTempFiles(filePaths) {
  filePaths.forEach(filePath => {
    if (fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
        console.log(`🧹 Cleaned up: ${filePath}`);
      } catch (err) {
        console.error(`Error cleaning up ${filePath}:`, err);
      }
    }
  });
}

// Main video generation endpoint
router.post('/mk', async (req, res) => {
  const tempFiles = [];
  
  try {
    const { prompt } = req.body;
    
    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }
    
    console.log('🎬 Starting video generation for:', prompt);
    
    // Set SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    const sendProgress = (progress, status, data = {}) => {
      res.write(`data: ${JSON.stringify({ progress, status, ...data })}\n\n`);
    };
    
    sendProgress(10, 'Generating images with DALL-E 3...');
    
    // Generate images
    const imageUrls = await generateImages(prompt, 4);
    
    if (imageUrls.length === 0) {
      throw new Error('No images were generated');
    }
    
    sendProgress(30, `Downloading ${imageUrls.length} images...`);
    
    // Download images
    const imagePaths = [];
    for (let i = 0; i < imageUrls.length; i++) {
      const filename = `img_${Date.now()}_${i}.png`;
      const imagePath = await downloadImage(imageUrls[i], filename);
      imagePaths.push(imagePath);
      tempFiles.push(imagePath);
      sendProgress(30 + (i * 10), `Downloaded image ${i + 1}/${imageUrls.length}`);
    }
    
    sendProgress(60, 'Creating video from images (this takes ~15 seconds)...');
    
    // Create video
    const videoFilename = `video_${Date.now()}.mp4`;
    const videoPath = path.join(tempDir, videoFilename);
    tempFiles.push(videoPath);
    
    // Try to create video
    await createSimpleVideoFromImages(imagePaths, videoPath);
    
    // Verify video file exists and has size
    const stats = fs.statSync(videoPath);
    if (stats.size === 0) {
      throw new Error('Generated video file is empty');
    }
    
    console.log(`Video file size: ${stats.size} bytes`);
    
    // Get actual duration
    const duration = await getVideoDuration(videoPath);
    console.log(`Video duration: ${duration} seconds`);
    
    sendProgress(80, 'Uploading video to Cloudinary...');
    
    // Upload to Cloudinary
    const uploadResult = await uploadVideoToCloudinary(videoPath, prompt);
    
    sendProgress(100, 'Complete!', {
      success: true,
      videoUrl: uploadResult.secure_url,
      streamingUrl: uploadResult.eager?.[0]?.secure_url,
      publicId: uploadResult.public_id,
      duration: duration || (imagePaths.length * 3),
      images: imageUrls
    });
    
    res.end();
    
    // Cleanup after response is sent
    setTimeout(() => {
      cleanupTempFiles(tempFiles);
    }, 5000);
    
  } catch (error) {
    console.error('Error:', error);
    res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
    res.end();
    cleanupTempFiles(tempFiles);
  }
});

// Single image generation
router.post('/generate-image', async (req, res) => {
  let tempImagePath = null;
  
  try {
    const { prompt } = req.body;
    
    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }
    
    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt: prompt,
      size: "1024x1024",
      quality: "standard",
      n: 1,
    });
    
    const imageUrl = response.data[0].url;
    
    // Download and upload to Cloudinary
    tempImagePath = await downloadImage(imageUrl, `temp_${Date.now()}.png`);
    const uploadResult = await cloudinary.uploader.upload(tempImagePath, {
      folder: "generated_images"
    });
    
    // Cleanup
    if (tempImagePath && fs.existsSync(tempImagePath)) {
      fs.unlinkSync(tempImagePath);
    }
    
    res.json({
      success: true,
      imageUrl: uploadResult.secure_url
    });
    
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Check FFmpeg installation
router.get('/check-ffmpeg', (req, res) => {
  exec('ffmpeg -version', (error, stdout, stderr) => {
    if (error) {
      res.json({ installed: false, error: error.message });
    } else {
      res.json({ installed: true, version: stdout.split('\n')[0] });
    }
  });
});

// HTML Interface
router.get('/mk', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>AI Video Generator - Create Videos from Text</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                overflow: hidden;
            }
            
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 40px;
                text-align: center;
            }
            
            .header h1 {
                font-size: 48px;
                margin-bottom: 10px;
            }
            
            .header p {
                font-size: 18px;
                opacity: 0.9;
            }
            
            .content {
                padding: 40px;
            }
            
            .input-section {
                background: #f7f7f7;
                padding: 30px;
                border-radius: 15px;
                margin-bottom: 30px;
            }
            
            .input-group {
                margin-bottom: 20px;
            }
            
            label {
                display: block;
                margin-bottom: 10px;
                font-weight: 600;
                color: #333;
                font-size: 16px;
            }
            
            textarea {
                width: 100%;
                padding: 15px;
                border: 2px solid #e0e0e0;
                border-radius: 10px;
                font-size: 16px;
                font-family: inherit;
                resize: vertical;
                transition: border-color 0.3s;
            }
            
            textarea:focus {
                outline: none;
                border-color: #667eea;
            }
            
            select {
                width: 100%;
                padding: 12px;
                border: 2px solid #e0e0e0;
                border-radius: 10px;
                font-size: 16px;
                background: white;
                cursor: pointer;
            }
            
            .button-group {
                display: flex;
                gap: 15px;
                margin-top: 20px;
            }
            
            button {
                flex: 1;
                padding: 15px 30px;
                font-size: 16px;
                font-weight: 600;
                border: none;
                border-radius: 10px;
                cursor: pointer;
                transition: transform 0.2s, box-shadow 0.2s;
            }
            
            button:hover:not(:disabled) {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            }
            
            .btn-primary {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            
            .btn-secondary {
                background: #48bb78;
                color: white;
            }
            
            button:disabled {
                opacity: 0.6;
                cursor: not-allowed;
            }
            
            .progress-section {
                background: white;
                border: 2px solid #e0e0e0;
                border-radius: 15px;
                padding: 20px;
                margin-bottom: 30px;
                display: none;
            }
            
            .progress-bar-container {
                background: #e0e0e0;
                border-radius: 10px;
                overflow: hidden;
                margin: 15px 0;
            }
            
            .progress-bar {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                height: 40px;
                width: 0%;
                transition: width 0.3s;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                font-weight: 600;
            }
            
            .status-text {
                text-align: center;
                color: #666;
                margin: 10px 0;
                font-size: 14px;
            }
            
            .result-section {
                display: none;
            }
            
            .video-container {
                background: #000;
                border-radius: 15px;
                overflow: hidden;
                margin-bottom: 30px;
            }
            
            video {
                width: 100%;
                display: block;
            }
            
            .video-controls {
                display: flex;
                gap: 10px;
                margin-top: 15px;
                justify-content: center;
                flex-wrap: wrap;
            }
            
            .video-controls a {
                padding: 10px 20px;
                background: #667eea;
                color: white;
                text-decoration: none;
                border-radius: 5px;
                font-size: 14px;
                transition: background 0.3s;
            }
            
            .video-controls a:hover {
                background: #5a67d8;
            }
            
            .images-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 20px;
                margin-top: 30px;
            }
            
            .image-card {
                background: #f7f7f7;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            
            .image-card img {
                width: 100%;
                height: 200px;
                object-fit: cover;
            }
            
            .image-card .caption {
                padding: 10px;
                font-size: 14px;
                color: #666;
                text-align: center;
                font-weight: 500;
            }
            
            .alert {
                padding: 15px;
                border-radius: 10px;
                margin-bottom: 20px;
                animation: slideIn 0.3s ease;
            }
            
            @keyframes slideIn {
                from {
                    transform: translateY(-20px);
                    opacity: 0;
                }
                to {
                    transform: translateY(0);
                    opacity: 1;
                }
            }
            
            .alert-error {
                background: #fed7d7;
                color: #c53030;
                border: 1px solid #fc8181;
            }
            
            .alert-success {
                background: #c6f6d5;
                color: #22543d;
                border: 1px solid #9ae6b4;
            }
            
            .info-text {
                background: #e6f7ff;
                padding: 15px;
                border-radius: 10px;
                margin-top: 20px;
                border-left: 4px solid #1890ff;
            }
            
            .info-text strong {
                color: #1890ff;
            }
            
            .loading-spinner {
                display: inline-block;
                width: 20px;
                height: 20px;
                border: 3px solid rgba(0,0,0,.1);
                border-radius: 50%;
                border-top-color: #667eea;
                animation: spin 1s ease-in-out infinite;
                margin-right: 10px;
                vertical-align: middle;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            h3 {
                margin-bottom: 15px;
                color: #333;
            }
            
            .url-box {
                margin-top: 10px;
                padding: 10px;
                background: #f0f0f0;
                border-radius: 5px;
                word-break: break-all;
            }
            
            .url-box strong {
                display: block;
                margin-bottom: 5px;
                color: #667eea;
            }
            
            .duration-badge {
                display: inline-block;
                background: #48bb78;
                color: white;
                padding: 5px 10px;
                border-radius: 5px;
                font-size: 14px;
                margin-left: 10px;
            }
            
            @media (max-width: 768px) {
                .header h1 { font-size: 32px; }
                .content { padding: 20px; }
                .button-group { flex-direction: column; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎬 AI Video Generator</h1>
                <p>Create stunning videos from text prompts using DALL-E 3</p>
            </div>
            
            <div class="content">
                <div class="input-section">
                    <div class="input-group">
                        <label>🎨 Enter Your Prompt</label>
                        <textarea id="prompt" rows="3" placeholder="Example: A beautiful sunset over mountains with birds flying, cinematic style..."></textarea>
                    </div>
                    
                    <div class="input-group">
                        <label>💡 Quick Examples</label>
                        <select id="exampleSelect" onchange="document.getElementById('prompt').value = this.value">
                            <option value="">Choose an example...</option>
                            <option value="A magical forest with glowing mushrooms and fairies dancing">🌲 Magical Forest with Fairies</option>
                            <option value="Space exploration with colorful nebulas and planets">🚀 Space Exploration</option>
                            <option value="Underwater coral reef with tropical fish and sunlight rays">🐠 Underwater Coral Reef</option>
                            <option value="Futuristic city with flying cars and neon lights at night">🌃 Futuristic City</option>
                            <option value="A cute cat riding a unicorn through a rainbow">🐱 Cute Cat on Unicorn</option>
                        </select>
                    </div>
                    
                    <div class="button-group">
                        <button class="btn-primary" onclick="generateVideo()">🎥 Generate Video (12 seconds)</button>
                        <button class="btn-secondary" onclick="generateImage()">🖼️ Generate Single Image</button>
                    </div>
                    
                    <div class="info-text">
                        <strong>💡 Tips:</strong> Be descriptive! Include details about style, mood, colors, and composition.
                        Video generation takes 30-60 seconds and creates a 12-second MP4 video from 4 AI-generated images (3 seconds each).
                    </div>
                </div>
                
                <div class="progress-section" id="progressSection">
                    <h3>📊 Generating Your Content...</h3>
                    <div class="progress-bar-container">
                        <div class="progress-bar" id="progressBar">0%</div>
                    </div>
                    <div class="status-text" id="statusText">Initializing...</div>
                </div>
                
                <div class="result-section" id="resultSection">
                    <div id="alertContainer"></div>
                    <div id="videoContainer"></div>
                    <div id="imagesContainer"></div>
                </div>
            </div>
        </div>
        
        <script>
            let currentVideoUrl = null;
            
            async function generateVideo() {
                const prompt = document.getElementById('prompt').value;
                if (!prompt) {
                    showAlert('Please enter a prompt first!', 'error');
                    return;
                }
                
                // Reset UI
                document.getElementById('resultSection').style.display = 'none';
                document.getElementById('progressSection').style.display = 'block';
                document.getElementById('progressBar').style.width = '0%';
                document.getElementById('progressBar').textContent = '0%';
                document.getElementById('statusText').innerHTML = '<span class="loading-spinner"></span> Starting video generation...';
                
                try {
                    const response = await fetch('/mk', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ prompt: prompt })
                    });
                    
                    const reader = response.body.getReader();
                    const decoder = new TextDecoder();
                    
                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;
                        
                        const chunk = decoder.decode(value);
                        const lines = chunk.split('\\n');
                        
                        for (const line of lines) {
                            if (line.startsWith('data: ')) {
                                const data = JSON.parse(line.substring(6));
                                
                                if (data.progress !== undefined) {
                                    document.getElementById('progressBar').style.width = data.progress + '%';
                                    document.getElementById('progressBar').textContent = data.progress + '%';
                                    document.getElementById('statusText').innerHTML = data.status || 'Processing...';
                                }
                                
                                if (data.success) {
                                    currentVideoUrl = data.videoUrl;
                                    displayResult(data, prompt);
                                    document.getElementById('progressSection').style.display = 'none';
                                    document.getElementById('resultSection').style.display = 'block';
                                    showAlert('✅ Video generated successfully! Duration: ' + (data.duration || 12) + ' seconds', 'success');
                                }
                                
                                if (data.error) {
                                    throw new Error(data.error);
                                }
                            }
                        }
                    }
                } catch (error) {
                    console.error('Error:', error);
                    document.getElementById('progressSection').style.display = 'none';
                    showAlert('❌ Error: ' + error.message, 'error');
                }
            }
            
            async function generateImage() {
                const prompt = document.getElementById('prompt').value;
                if (!prompt) {
                    showAlert('Please enter a prompt first!', 'error');
                    return;
                }
                
                document.getElementById('resultSection').style.display = 'none';
                document.getElementById('progressSection').style.display = 'block';
                document.getElementById('progressBar').style.width = '50%';
                document.getElementById('progressBar').textContent = '50%';
                document.getElementById('statusText').innerHTML = '<span class="loading-spinner"></span> Generating image...';
                
                try {
                    const response = await fetch('/generate-image', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ prompt: prompt })
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        displaySingleImage(data, prompt);
                        document.getElementById('progressSection').style.display = 'none';
                        document.getElementById('resultSection').style.display = 'block';
                        showAlert('✅ Image generated successfully!', 'success');
                    } else {
                        throw new Error(data.error);
                    }
                } catch (error) {
                    document.getElementById('progressSection').style.display = 'none';
                    showAlert('❌ Error: ' + error.message, 'error');
                }
            }
            
            function displayResult(data, prompt) {
                const videoContainer = document.getElementById('videoContainer');
                const imagesContainer = document.getElementById('imagesContainer');
                
                const duration = data.duration || 12;
                
                // Create video element
                const videoHtml = \`
                    <h3>🎥 Generated Video <span class="duration-badge">Duration: \${duration} seconds</span></h3>
                    <div class="video-container">
                        <video id="generatedVideo" controls autoplay>
                            <source src="\${data.videoUrl}" type="video/mp4">
                            Your browser does not support video playback.
                        </video>
                    </div>
                    <div class="video-controls">
                        <a href="\${data.videoUrl}" download="generated_video.mp4">📥 Download Video</a>
                        <a href="\${data.videoUrl}" target="_blank">🔗 Open in New Tab</a>
                        <a href="#" onclick="copyVideoUrl()">📋 Copy Video URL</a>
                    </div>
                    <div class="url-box">
                        <strong>Video URL:</strong>
                        <a href="\${data.videoUrl}" target="_blank" style="color: #667eea; font-size: 12px;">\${data.videoUrl}</a>
                    </div>
                \`;
                
                videoContainer.innerHTML = videoHtml;
                
                // Add error handling for video
                const videoElement = document.getElementById('generatedVideo');
                if (videoElement) {
                    videoElement.onerror = function(e) {
                        console.error('Video playback error:', e);
                        videoContainer.innerHTML += \`
                            <div class="alert alert-error" style="margin-top: 10px;">
                                ⚠️ Video cannot be played directly. <a href="\${data.videoUrl}" target="_blank">Click here to open in new tab</a>
                            </div>
                        \`;
                    };
                    
                    // Log video metadata when loaded
                    videoElement.onloadedmetadata = function() {
                        console.log('Video duration:', videoElement.duration);
                    };
                }
                
                // Display frames
                if (data.images && data.images.length > 0) {
                    let imagesHtml = '<h3>🖼️ Generated Frames (3 seconds each)</h3><div class="images-grid">';
                    data.images.forEach((img, index) => {
                        imagesHtml += \`
                            <div class="image-card">
                                <img src="\${img}" alt="Frame \${index + 1}" loading="lazy">
                                <div class="caption">Scene \${index + 1} (3 seconds)</div>
                            </div>
                        \`;
                    });
                    imagesHtml += '</div>';
                    imagesContainer.innerHTML = imagesHtml;
                }
            }
            
            function displaySingleImage(data, prompt) {
                const videoContainer = document.getElementById('videoContainer');
                const imagesContainer = document.getElementById('imagesContainer');
                
                videoContainer.innerHTML = \`
                    <h3>🖼️ Generated Image</h3>
                    <div class="image-card" style="max-width: 600px; margin: 0 auto;">
                        <img src="\${data.imageUrl}" alt="Generated image" style="width: 100%;">
                        <div class="caption">Prompt: \${prompt}</div>
                    </div>
                    <div class="video-controls" style="margin-top: 20px;">
                        <a href="\${data.imageUrl}" download="generated_image.png">📥 Download Image</a>
                        <a href="\${data.imageUrl}" target="_blank">🔗 Open in New Tab</a>
                    </div>
                \`;
                imagesContainer.innerHTML = '';
            }
            
            function copyVideoUrl() {
                if (currentVideoUrl) {
                    navigator.clipboard.writeText(currentVideoUrl);
                    showAlert('✅ Video URL copied to clipboard!', 'success');
                }
            }
            
            function showAlert(message, type) {
                const alertContainer = document.getElementById('alertContainer');
                alertContainer.innerHTML = \`
                    <div class="alert alert-\${type}">
                        \${message}
                    </div>
                \`;
                setTimeout(() => {
                    alertContainer.innerHTML = '';
                }, 5000);
            }
            
            // Check FFmpeg on load
            async function checkFFmpeg() {
                try {
                    const response = await fetch('/check-ffmpeg');
                    const data = await response.json();
                    if (!data.installed) {
                        showAlert('⚠️ FFmpeg is not installed. Video generation will not work. Please install FFmpeg first.', 'error');
                    } else {
                        console.log('FFmpeg detected:', data.version);
                    }
                } catch (error) {
                    console.error('Error checking FFmpeg:', error);
                }
            }
            
            checkFFmpeg();
        </script>
    </body>
    </html>
  `);
});

module.exports = router;