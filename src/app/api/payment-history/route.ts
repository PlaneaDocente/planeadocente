
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

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const {
      user_id,
      subscription_id,
      stripe_payment_intent_id,
      monto_centavos,
      moneda,
      estado,
      descripcion,
      metadata,
    } = body;

    if (!user_id || !monto_centavos || !estado) {
      return Response.json(
        { success: false, error: "user_id, monto_centavos, and estado are required" },
        { status: 400 }
      );
    }

    const { data, error } = await supabaseAdmin
      .from("payment_history")
      .insert({
        user_id,
        subscription_id: subscription_id ?? null,
        stripe_payment_intent_id: stripe_payment_intent_id ?? null,
        monto_centavos,
        moneda: moneda ?? "mxn",
        estado,
        descripcion: descripcion ?? null,
        metadata: metadata ?? {},
      })
      .select()
      .maybeSingle();

    if (error) {
      console.error("Error creating payment history:", error);
      return Response.json({ success: false, error: error.message }, { status: 500 });
    }

    return Response.json({ success: true, data }, { status: 201 });
  } catch (err) {
    console.error("Create payment history route error:", err);
    return Response.json({ success: false, error: "Internal server error" }, { status: 500 });
  }
}
