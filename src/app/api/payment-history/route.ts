
import { supabaseAdmin } from "@/integrations/supabase/server";

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("user_id");

    if (!userId) {
      return Response.json({ success: false, error: "user_id is required" }, { status: 400 });
    }

    const { data, error } = await supabaseAdmin
      .from("payment_history")
      .select("*")
      .eq("user_id", userId)
      .order("fecha_pago", { ascending: false })
      .limit(20);

    if (error) {
      console.error("Error fetching payment history:", error);
      return Response.json({ success: false, error: error.message }, { status: 500 });
    }

    return Response.json({ success: true, data: data ?? [] });
  } catch (err) {
    console.error("Payment history route error:", err);
    return Response.json({ success: false, error: "Internal server error" }, { status: 500 });
  }
}
