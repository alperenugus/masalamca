/**
 * OAuth2 access token for Google Cloud APIs using a service account JSON key.
 * Used by Cloud Text-to-Speech (Gemini-TTS) from the Worker.
 */
import { SignJWT, importPKCS8 } from "jose";

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/cloud-platform";

interface ServiceAccount {
  type?: string;
  project_id: string;
  private_key: string;
  client_email: string;
}

type TokenCache = {
  accessToken: string;
  projectId: string;
  expiresAtMs: number;
};

let cache: TokenCache | null = null;

export async function getGoogleAccessToken(
  serviceAccountJson: string,
): Promise<{ accessToken: string; projectId: string }> {
  const now = Date.now();
  if (
    cache &&
    now < cache.expiresAtMs - 60_000
  ) {
    return {
      accessToken: cache.accessToken,
      projectId: cache.projectId,
    };
  }

  const sa = JSON.parse(serviceAccountJson) as ServiceAccount;
  if (!sa.private_key || !sa.client_email || !sa.project_id) {
    throw new Error("invalid_service_account_json");
  }

  const privateKey = await importPKCS8(sa.private_key, "RS256");
  const iat = Math.floor(now / 1000);
  const exp = iat + 3600;

  const assertion = await new SignJWT({ scope: SCOPE })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(TOKEN_URL)
    .setIssuedAt(iat)
    .setExpirationTime(exp)
    .sign(privateKey);

  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const text = await res.text();
  if (!res.ok) {
    throw new Error(
      `google_token_exchange_failed: ${res.status} ${text.slice(0, 800)}`,
    );
  }

  const data = JSON.parse(text) as {
    access_token?: string;
    expires_in?: number;
  };
  if (!data.access_token) {
    throw new Error("google_token_missing_access_token");
  }

  const expiresInSec = data.expires_in ?? 3600;
  cache = {
    accessToken: data.access_token,
    projectId: sa.project_id,
    expiresAtMs: now + expiresInSec * 1000,
  };

  return {
    accessToken: cache.accessToken,
    projectId: cache.projectId,
  };
}
