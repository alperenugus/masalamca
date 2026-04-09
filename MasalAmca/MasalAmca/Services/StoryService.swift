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
    case rateLimited(retryAfterSeconds: Int?)
    case remoteMessage(String, status: Int?)
    case timedOut
    case network(String)
    case decoding
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .remoteMessage(let msg, _):
            return msg
        case .rateLimited:
            return "Çok fazla istek. Lütfen bir süre sonra tekrar dene."
        case .timedOut:
            return "İstek zaman aşımına uğradı. Bağlantını kontrol edip tekrar dene."
        case .emptyAudio:
            return "Ses dosyası alınamadı. Lütfen tekrar dene."
        case .missingProxyURL:
            return "Sunucu adresi yapılandırılmamış."
        default:
            return "Bir hata oluştu, lütfen daha sonra tekrar dene!"
        }
    }
}

private struct ProxyErrorDTO: Codable {
    var error: String?
    var message: String?
    var detail: String?
    var requestID: String?
    var minWords: Int?
    var gotWords: Int?

    enum CodingKeys: String, CodingKey {
        case error, message, detail
        case requestID = "request_id"
        case minWords = "min_words"
        case gotWords = "got_words"
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
        storyReq.timeoutInterval = 60
        storyReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authToken.isEmpty {
            storyReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        let payload = PromptOrchestrator.storyRequest(from: profile)
        storyReq.httpBody = try JSONEncoder().encode(payload)

        let (storyData, storyResp): (Data, URLResponse)
        do {
            (storyData, storyResp) = try await session.data(for: storyReq)
        } catch let urlErr as URLError where urlErr.code == .timedOut {
            throw StoryServiceError.timedOut
        } catch let urlErr as URLError {
            throw StoryServiceError.network(urlErr.localizedDescription)
        } catch {
            throw StoryServiceError.network((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
        guard let http = storyResp as? HTTPURLResponse else { throw StoryServiceError.badStatus(-1) }
        guard (200 ... 299).contains(http.statusCode) else {
            if http.statusCode == 429 {
                let retry = (http.value(forHTTPHeaderField: "Retry-After")).flatMap(Int.init)
                throw StoryServiceError.rateLimited(retryAfterSeconds: retry)
            }
            if let proxy = try? JSONDecoder().decode(ProxyErrorDTO.self, from: storyData) {
                if proxy.error == "too_short", let min = proxy.minWords, let got = proxy.gotWords {
                    let msg = "Masal beklenenden kısa üretildi (\(got)/\(min) kelime). Lütfen tekrar dene."
                    throw StoryServiceError.remoteMessage(msg, status: http.statusCode)
                }
                if let m = proxy.message, !m.isEmpty {
                    throw StoryServiceError.remoteMessage(m, status: http.statusCode)
                }
                if let d = proxy.detail, !d.isEmpty {
                    throw StoryServiceError.remoteMessage("Sunucu yanıtı alınamadı. Lütfen tekrar dene.", status: http.statusCode)
                }
            }
            throw StoryServiceError.badStatus(http.statusCode)
        }
        let dto = try JSONDecoder().decode(StoryGenerateResponseDTO.self, from: storyData)
        #if DEBUG
        print("[StoryService] word_count=\(dto.wordCount ?? -1) model=\(dto.model ?? "unknown")")
        #endif

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
        // Long Turkish stories (many minutes of audio) need far more than 90s end-to-end (proxy + ElevenLabs).
        let wordEstimate = max(1, text.split(whereSeparator: \.isWhitespace).count)
        ttsReq.timeoutInterval = min(300, max(120, Double(wordEstimate) * 0.35))
        ttsReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !authToken.isEmpty {
            ttsReq.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        let ttsBody = TTSRequestDTO(text: text, voiceID: voiceID, outputFormat: "mp3_44100_128")
        ttsReq.httpBody = try JSONEncoder().encode(ttsBody)

        let (audioData, ttsResp): (Data, URLResponse)
        do {
            (audioData, ttsResp) = try await session.data(for: ttsReq)
        } catch let urlErr as URLError where urlErr.code == .timedOut {
            throw StoryServiceError.timedOut
        } catch let urlErr as URLError {
            throw StoryServiceError.network(urlErr.localizedDescription)
        } catch {
            throw StoryServiceError.network((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
        guard let ttsHttp = ttsResp as? HTTPURLResponse else { throw StoryServiceError.badStatus(-1) }
        guard (200 ... 299).contains(ttsHttp.statusCode) else {
            #if DEBUG
            if let errText = String(data: audioData, encoding: .utf8) {
                print("[StoryService] TTS failed status=\(ttsHttp.statusCode) body=\(errText.prefix(500))")
            } else {
                print("[StoryService] TTS failed status=\(ttsHttp.statusCode) body_len=\(audioData.count)")
            }
            #endif
            if ttsHttp.statusCode == 429 {
                let retry = (ttsHttp.value(forHTTPHeaderField: "Retry-After")).flatMap(Int.init)
                throw StoryServiceError.rateLimited(retryAfterSeconds: retry)
            }
            if let proxy = try? JSONDecoder().decode(ProxyErrorDTO.self, from: audioData) {
                if let m = proxy.message, !m.isEmpty {
                    throw StoryServiceError.remoteMessage(m, status: ttsHttp.statusCode)
                }
                if let e = proxy.error, e.contains("timeout") {
                    throw StoryServiceError.remoteMessage(
                        "Seslendirme uzun sürdü ve bağlantı kesildi. Tekrar dene; gerekirse masalı biraz daha kısa seç.",
                        status: ttsHttp.statusCode
                    )
                }
            }
            throw StoryServiceError.badStatus(ttsHttp.statusCode)
        }
        guard !audioData.isEmpty else { throw StoryServiceError.emptyAudio }
        return audioData
    }
}
