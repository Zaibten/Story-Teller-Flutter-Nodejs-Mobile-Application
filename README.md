# ✨ Magic Story – AI-Powered Storytelling App for Kids

**Magic Story** is a delightful mobile application that generates unique, engaging stories for children based on their chosen character, world, and mood. Powered by a **Node.js** backend, **MongoDB** for story/asset storage, and a **Machine Learning image generation model** (e.g., Stable Diffusion / DALL‑E) to create custom illustrations, the app offers an immersive and magical storytelling experience. Built with **Flutter** for a rich, animated cross‑platform UI.

---

## 🚀 Key Features

- 🎭 **Character, World & Mood Selection** – Kids pick a hero (cat, lion, elephant…), a world (forest, space, castle…), and a mood (happy, funny, adventure, bedtime).
- 📖 **Dynamic Story Generation** – Each story is randomly assembled from a JSON dataset or generated via AI, ensuring a fresh tale every time.
- 🔊 **Text‑to‑Speech with Word Highlighting** – The story is read aloud using `flutter_tts`, and the currently spoken word is highlighted in real time.
- 🎬 **Video Story Mode** – Integrated webview plays animated video versions of the story (from a pre‑defined link pool).
- 🎨 **AI Image Generation** *(optional)* – Uses a machine learning model (e.g., Stable Diffusion) to create unique cover images or scene illustrations based on the story context.
- ✨ **Rich Animations** – Floating particles, pulsing buttons, shimmer effects, and smooth transitions – all without third‑party animation packages.
- 📱 **Cross‑Platform** – Works on iOS, Android, and the web (Flutter).

---

## 🧰 Tech Stack

| Layer       | Technology                                                                 |
|-------------|----------------------------------------------------------------------------|
| Frontend    | **Flutter** (Dart) – with Provider for state management                   |
| Backend API | **Node.js** (Express) – serves stories, links, and image generation endpoints |
| Database    | **MongoDB** – stores story templates, character/world/mood metadata, video links |
| AI Image Generation | **Stable Diffusion** (via Replicate API or local inference) – generates custom illustrations |
| Text‑to‑Speech | `flutter_tts` (Android/iOS) + `web_speech_api` (web fallback)            |
| Animations  | Custom `AnimationController` & `AnimatedBuilder` – no external packages   |

---


This README gives a complete overview of the project, its technical architecture, and step‑by‑step setup instructions – ready to be copied into a `README.md` file in your GitHub repository.
