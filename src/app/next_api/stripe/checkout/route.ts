
import { stripe } from "@zoerai/integration";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { productName, amount, currency, quantity, interval } = body;

    if (!productName || !amount || !currency) {
      return Response.json({ success: false, error: "Missing required fields" }, { status: 400 });
    }

    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    if (!stripeSecretKey) {
      return Response.json(
        { success: false, error: "STRIPE_SECRET_KEY not configured on server" },
        { status: 500 }
      );
    }

    const stripeUrl = process.env.NEXT_PUBLIC_STRIPE_URL || "http://localhost:3000";

    const result = await stripe.createCheckoutSession({
      stripeKey: stripeSecretKey,
      request: {
        mode: "payment",
        lineItems: [
          {
            priceData: {
              currency: currency || "mxn",
              unitAmount: amount,
              productData: {
                name: productName,
                description: `Suscripción PlaneaDocente · ${
                  interval === "year" ? "Plan Anual" : "Plan Mensual"
                } · Incluye 15 días de prueba gratuita`,
              },
            },
            quantity: quantity || 1,
          },
        ],
        successUrl: `${stripeUrl}/suscripcion/exito?session_id={CHECKOUT_SESSION_ID}`,
        cancelUrl: `${stripeUrl}/suscripcion/cancelado`,
      },
    });

    if (!result.success) {
      console.error("Stripe checkout error:", result.error);
      return Response.json({ success: false, error: result.error }, { status: 500 });
    }

    return Response.json({ success: true, data: result.data });
  } catch (error) {
    console.error("Checkout route error:", error);
    return Response.json({ success: false, error: "Internal server error" }, { status: 500 });
  }
}
