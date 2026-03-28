
import { NextResponse } from "next/server";
import { supabaseAdmin } from "@/integrations/supabase/server";

export async function GET() {
  const checks: Record<string, string> = {
    status: "ok",
    timestamp: new Date().toISOString(),
  };

  // Check Stripe env vars
  checks.stripe_secret_key = process.env.STRIPE_SECRET_KEY ? "configured" : "MISSING";
  checks.stripe_webhook_secret = process.env.STRIPE_WEBHOOK_SECRET ? "configured" : "MISSING";
  checks.stripe_url = process.env.NEXT_PUBLIC_STRIPE_URL || "not set (will use localhost:3000)";

  // Check DB connectivity
  try {
    const { error } = await supabaseAdmin
      .from("subscription_plans")
      .select("id")
      .limit(1)
      .maybeSingle();
    checks.database = error ? `error: ${error.message}` : "connected";
  } catch {
    checks.database = "connection failed";
  }

  const allOk =
    checks.stripe_secret_key === "configured" &&
    checks.database === "connected";

  return NextResponse.json(checks, { status: allOk ? 200 : 503 });
}
