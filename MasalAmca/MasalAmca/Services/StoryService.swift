//
//  StoryService.swift
//  MasalAmca
//

import Foundation

struct StoryGenerationResult: Sendable {
    var story: StoryGenerateResponseDTO
    var audioData: Data
}

enum StoryServiceError: Error, LocalizedError {
    case missingProxyURL
    case badStatus(Int)
    case decoding
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .missingProxyURL: "Sunucu adresi yapılandırılmadı."
        case .badStatus(let c): "Sunucu hatası (\(c))."
        case .decoding: "Yanıt okunamadı."
        case .emptyAudio: "Ses verisi alınamadı."
        }
    }
}

actor StoryService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateStoryAndAudio(
        profile: ChildProfile,
        voiceID: String,
        authToken: String
    ) async throws -> StoryGenerationResult {
        guard let base = AppConfiguration.proxyBaseURL else { throw StoryServiceError.missingProxyURL }

        let storyURL = base.appendingPathComponent("v1").appendingPathComponent("story")
        var storyReq = URLRequest(url: storyURL)
        storyReq.httpMethod = "POST"
        storyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authToken.isEmpty {
            storyReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        let payload = PromptOrchestrator.storyRequest(from: profile)
        storyReq.httpBody = try JSONEncoder().encode(payload)

        let (storyData, storyResp) = try await session.data(for: storyReq)
        guard let http = storyResp as? HTTPURLResponse else { throw StoryServiceError.badStatus(-1) }
        guard (200 ... 299).contains(http.statusCode) else { throw StoryServiceError.badStatus(http.statusCode) }
        let dto = try JSONDecoder().decode(StoryGenerateResponseDTO.self, from: storyData)

        let audioData = try await fetchSpeechAudio(
            text: dto.body,
            voiceID: voiceID,
            authToken: authToken,
            session: session,
            base: base
        )

        return StoryGenerationResult(story: dto, audioData: audioData)
    }

    /// Tek parça TTS (masal üretimi veya ses önizlemesi).
    func fetchSpeechAudio(
        text: String,
        voiceID: String,
        authToken: String
    ) async throws -> Data {
        guard let base = AppConfiguration.proxyBaseURL else { throw StoryServiceError.missingProxyURL }
        return try await fetchSpeechAudio(
            text: text,
            voiceID: voiceID,
            authToken: authToken,
            session: session,
            base: base
        )
    }

    private func fetchSpeechAudio(
        text: String,
        voiceID: String,
        authToken: String,
        session: URLSession,
        base: URL
    ) async throws -> Data {
        let ttsURL = base.appendingPathComponent("v1").appendingPathComponent("tts")
        var ttsReq = URLRequest(url: ttsURL)
        ttsReq.httpMethod = "POST"
        ttsReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authToken.isEmpty {
            ttsReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        let ttsBody = TTSRequestDTO(text: text, voiceID: voiceID, outputFormat: "mp3_44100_128")
        ttsReq.httpBody = try JSONEncoder().encode(ttsBody)

        let (audioData, ttsResp) = try await session.data(for: ttsReq)
        guard let ttsHttp = ttsResp as? HTTPURLResponse else { throw StoryServiceError.badStatus(-1) }
        guard (200 ... 299).contains(ttsHttp.statusCode) else { throw StoryServiceError.badStatus(ttsHttp.statusCode) }
        guard !audioData.isEmpty else { throw StoryServiceError.emptyAudio }
        return audioData
    }
}
