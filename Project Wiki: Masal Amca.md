Application Name: Masal Amca

Project Wiki: AI-Powered Personalized Bedtime Story & White Noise Companion
Important Note on Localization: While this documentation is in English, the App UI, Onboarding, and all generated AI Content (Text & Audio) will be 100% in Turkish to serve the target demographic.

1. Executive Summary
Vision: A premium iOS application that generates hyper-personalized, pedagogically safe bedtime stories in Turkish, combined with a customizable white noise mixer to establish healthy sleep routines for children.

Target Audience: Turkish-speaking parents with children aged 2-9 who are looking for engaging, screen-free bedtime routines.

Core Value Proposition: Replacing static audiobooks with dynamic, on-demand stories where the child is the hero, backed by a native iOS experience that requires no external backend accounts.

2. Technical Architecture (BaaS / Apple Ecosystem)
By eliminating a custom backend, the app relies entirely on Apple's native frameworks and direct API integrations.

Frontend & UI: SwiftUI. Utilizing native components for smooth animations, audio player controls, and an Apple-standard user experience.

Local Storage: SwiftData / CoreData. Used to store user profiles (child's name, age, interests), generated story texts, and local app settings.

Cloud Sync: Apple CloudKit. Allows seamless synchronization of stories and profiles across a parent's devices (e.g., iPhone to iPad) using their existing Apple ID. No separate login required.

AI Integrations (Client-Side API Calls):

Text Generation Engine: Direct API calls to OpenAI (GPT-4o-mini) or Anthropic (Claude 3.5 Haiku) using strict system prompts to generate the Turkish story text based on SwiftData profile inputs.

Voice Generation (TTS): Direct API calls to ElevenLabs. The generated text is sent to ElevenLabs to stream or download high-quality Turkish audio.

Security Note: Because calling APIs directly from the client exposes API keys, we will implement a lightweight serverless edge function (e.g., Cloudflare Workers or Apple's server-side environment if applicable) purely as a secure proxy to hide the API keys, or use strict API key budget limits/obfuscation if doing a pure MVP.

3. Core Features (MVP)
Dynamic Onboarding (Turkish): Collecting the child's data (name, gender, age, favorite animals, current interests, or behavioral goals like "sharing").

AI Story Engine: A prompt orchestrator that takes the onboarding variables and requests a unique, age-appropriate, non-violent story.

High-Fidelity Audio (ElevenLabs): Converting the text to speech using a warm, engaging Turkish voice model.

White Noise Mixer: A native audio player featuring layered, continuous loops (e.g., Rain + Womb sounds + Fan) that can play independently or fade in after a story concludes.

Offline Library: Once an audio file is generated via ElevenLabs, it is cached locally in the app's document directory so the parent can replay favorite stories without incurring additional API costs or requiring an internet connection.

4. Market Research & Competitive Landscape
Global Leaders: Apps like Oscar and Bedtime AI prove the demand for personalized AI stories. They focus heavily on illustrations and text.

Sleep/White Noise Leaders: Apps like White Noise Baby have massive downloads simply for playing static loops.

The Gap in the Turkish Market: Existing Turkish apps (like Masalcı) offer static, pre-recorded audio. There is no dominant local app that natively combines Agentic AI Personalization, ElevenLabs-quality Turkish Audio, and a White Noise Mixer into a single, cohesive iOS experience.

5. Financials & Monetization Strategy
Since you are paying for API usage per generation, a subscription model is necessary to ensure sustainable profit margins.

Estimated Unit Economics (Per Story):

LLM Text (OpenAI/Claude): ~$0.002 - $0.005

ElevenLabs TTS (approx. 500 words/3 mins): ~$0.05 - $0.09 (Pricing depends on tier, but ElevenLabs is a premium cost).

Strategy: Caching audio locally is critical. If a child listens to the same generated story 5 nights in a row, you only pay the API cost once.

Subscription Model (Freemium):

Free Tier: 2 free generated stories upon downloading, plus access to 3 basic white noise sounds.

Premium Subscription (Monthly/Yearly via Apple In-App Purchases): Unlimited (or high daily limit) story generations, full access to the white noise library, custom voice selection, and CloudKit cross-device syncing.

