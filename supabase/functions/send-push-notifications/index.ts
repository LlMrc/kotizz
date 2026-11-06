/**
 * Supabase Edge Function — send-push-notifications (FCM HTTP v1)
 *
 * Utilise l'API officielle Google Firebase Cloud Messaging v1 avec compte de service.
 *
 * Variables requises dans Supabase Dashboard (Settings -> Edge Functions -> Secrets) :
 *   SUPABASE_URL             - URL du projet Supabase
 *   SUPABASE_SERVICE_KEY     - Clé service_role
 *   FIREBASE_SERVICE_ACCOUNT - Tout le contenu du fichier JSON téléchargé (en une seule chaîne de caractères)
 *   CRON_SECRET              - Secret partagé avec PostgreSQL / GitHub Actions
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts";

interface RequestBody {
  type: "reminder" | "penalty";
  secret: string;
}

interface UnpaidMember {
  user_id: string;
  fcm_token: string | null;
  full_name: string;
  group_name: string;
  current_turn: number;
  contribution_amount: number;
  currency: string;
  days_overdue?: number;
  penalty_points?: number;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

// Cache du token d'accès Google OAuth2
let cachedAccessToken: { token: string; expiresAt: number } | null = null;

async function getGoogleAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt > now + 60) {
    return cachedAccessToken.token;
  }

  // Clé privée PKCS8
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");

  // Création du JWT pour Google OAuth2
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  // Échange du JWT contre un access_token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Google Auth error: ${JSON.stringify(data)}`);
  }

  cachedAccessToken = {
    token: data.access_token,
    expiresAt: now + data.expires_in,
  };

  return data.access_token;
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret || body.secret !== cronSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const rawServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!rawServiceAccount) {
    return new Response(
      JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT is missing in secrets" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(rawServiceAccount);
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON in FIREBASE_SERVICE_ACCOUNT secret" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_KEY")!,
  );

  try {
    const accessToken = await getGoogleAccessToken(serviceAccount);

    if (body.type === "reminder") {
      const { data: members, error } = await supabase.rpc("get_unpaid_members_for_reminder");
      if (error) throw error;
      if (!members || members.length === 0) {
        return jsonResponse({ sent: 0, message: "No unpaid members found" });
      }

      const results = await sendBatchFcmV1(
        serviceAccount.project_id,
        accessToken,
        members as UnpaidMember[],
        (m) => ({
          title: "💰 Rappel de cotisation",
          body: `Votre cotisation de ${m.contribution_amount} ${m.currency} pour "${m.group_name}" (Tour ${m.current_turn}) n'est pas encore confirmée. Pensez à payer avant la fin du mois !`,
        })
      );
      return jsonResponse(results);
    } else if (body.type === "penalty") {
      const { data: members, error } = await supabase.rpc("get_penalized_members_today");
      if (error) throw error;
      if (!members || members.length === 0) {
        return jsonResponse({ sent: 0, message: "No penalized members today" });
      }

      const results = await sendBatchFcmV1(
        serviceAccount.project_id,
        accessToken,
        members as UnpaidMember[],
        (m) => ({
          title: "⚠️ Pénalité de retard",
          body: `Votre cotisation pour "${m.group_name}" (Tour ${m.current_turn}) est en retard de ${m.days_overdue} jours. ${m.penalty_points} point(s) de confiance ont été déduits.`,
        })
      );
      return jsonResponse(results);
    } else {
      return jsonResponse({ error: "Unknown type" }, 400);
    }
  } catch (err) {
    console.error("Error sending notifications:", err);
    return jsonResponse({ error: String(err) }, 500);
  }
});

async function sendBatchFcmV1(
  projectId: string,
  accessToken: string,
  members: UnpaidMember[],
  buildNotification: (m: UnpaidMember) => { title: string; body: string }
): Promise<{ sent: number; failed: number }> {
  let sent = 0;
  let failed = 0;

  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  for (const member of members) {
    if (!member.fcm_token) continue;

    const { title, body } = buildNotification(member);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: member.fcm_token,
            notification: {
              title,
              body,
            },
            data: {
              type: "wonn_notification",
              group_name: member.group_name,
            },
            android: {
              priority: "high",
              notification: {
                sound: "default",
                channel_id: "wonn_alerts",
              },
            },
          },
        }),
      });

      if (response.ok) {
        sent++;
      } else {
        const errorData = await response.json();
        console.warn(`FCM v1 failed for user ${member.user_id}:`, errorData);
        failed++;
      }
    } catch (e) {
      console.error(`Error sending push to ${member.user_id}:`, e);
      failed++;
    }
  }

  return { sent, failed };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
