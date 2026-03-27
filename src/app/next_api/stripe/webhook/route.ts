
import { stripe } from "@zoerai/integration";

export async function POST(req: Request) {
  try {
    const signature = req.headers.get("stripe-signature");
    if (!signature) {
      return new Response("Missing stripe-signature header", { status: 400 });
    }

    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.error("STRIPE_WEBHOOK_SECRET not configured");
      return new Response("Webhook secret not configured", { status: 500 });
    }

    const payload = await req.text();

    const result = await stripe.verifyWebhook({
      webhookSecret,
      request: { payload, signature, webhookSecret },
    });

    if (!result.success) {
      console.error("Webhook verification failed:", result.error);
      return new Response("Webhook verification failed", { status: 400 });
    }

    const event = result.data;

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        console.log("✅ Checkout completed:", session.id);
        break;
      }
      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object;
        console.log("✅ Payment succeeded:", paymentIntent.id);
        break;
      }
      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object;
        console.log("❌ Payment failed:", paymentIntent.id);
        break;
      }
      case "customer.subscription.updated": {
        const sub = event.data.object;
        console.log("🔄 Subscription updated:", sub.id);
        break;
      }
      case "customer.subscription.deleted": {
        const sub = event.data.object;
        console.log("❌ Subscription cancelled:", sub.id);
        break;
      }
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("Webhook route error:", error);
    return new Response("Internal server error", { status: 500 });
  }
}
