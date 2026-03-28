
import { supabaseAdmin } from "@/integrations/supabase/server";

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("user_id");

    if (!userId) {
      return Response.json({ success: false, error: "user_id is required" }, { status: 400 });
    }

    const { data: subscription, error: subError } = await supabaseAdmin
      .from("subscriptions")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (subError) {
      console.error("Error fetching subscription:", subError);
      return Response.json({ success: false, error: subError.message }, { status: 500 });
    }

    if (!subscription) {
      return Response.json({ success: true, data: null });
    }

    const { data: plan, error: planError } = await supabaseAdmin
      .from("subscription_plans")
      .select("*")
      .eq("id", subscription.plan_id)
      .maybeSingle();

    if (planError) {
      console.error("Error fetching plan:", planError);
    }

    return Response.json({ success: true, data: { subscription, plan: plan ?? null } });
  } catch (err) {
    console.error("User subscription route error:", err);
    return Response.json({ success: false, error: "Internal server error" }, { status: 500 });
  }
}
