
import { stripe } from "@zoerai/integration";
import {
  updateSubscriptionByStripeId,
  updateSubscriptionBySessionId,
  createPaymentHistory,
  getUserSubscription,
} from "@/lib/supabase-subscriptions";
import { supabaseAdmin } from "@/integrations/supabase/server";

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
        const session = event.data.object as {
          id: string;
          customer?: string;
          subscription?: string;
          payment_intent?: string;
          amount_total?: number;
          currency?: string;
          metadata?: Record<string, string>;
        };

        console.log("✅ Checkout completed:", session.id);

        // Update the pre-created subscription row
        await updateSubscriptionBySessionId(session.id, {
          estado: "active",
          stripe_customer_id: session.customer ?? undefined,
          stripe_subscription_id: session.subscription ?? undefined,
          metadata: {
            stripe_session_id: session.id,
            stripe_customer_id: session.customer,
            stripe_subscription_id: session.subscription,
          },
        });

        // Resolve user_id from metadata or subscription row
        const userId = session.metadata?.user_id;
        if (userId && session.amount_total) {
          // Find the subscription we just updated
          const sub = await getUserSubscription(userId);
          await createPaymentHistory({
            user_id: userId,
            subscription_id: sub?.id,
            stripe_payment_intent_id: session.payment_intent ?? undefined,
            monto_centavos: session.amount_total,
            moneda: session.currency ?? "mxn",
            estado: "succeeded",
            descripcion: "Pago de suscripción PlaneaDocente",
            metadata: { stripe_session_id: session.id },
          });
        }
        break;
      }

      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object as {
          id: string;
          amount: number;
          currency: string;
          metadata?: Record<string, string>;
        };

        console.log("✅ Payment succeeded:", paymentIntent.id);

        const userId = paymentIntent.metadata?.user_id;
        if (userId) {
          const sub = await getUserSubscription(userId);
          await createPaymentHistory({
            user_id: userId,
            subscription_id: sub?.id,
            stripe_payment_intent_id: paymentIntent.id,
            monto_centavos: paymentIntent.amount,
            moneda: paymentIntent.currency ?? "mxn",
            estado: "succeeded",
            descripcion: "Pago exitoso PlaneaDocente",
            metadata: { stripe_payment_intent_id: paymentIntent.id },
          });
        }
        break;
      }

      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object as {
          id: string;
          amount: number;
          currency: string;
          metadata?: Record<string, string>;
        };

        console.log("❌ Payment failed:", paymentIntent.id);

        const userId = paymentIntent.metadata?.user_id;
        if (userId) {
          const sub = await getUserSubscription(userId);
          await createPaymentHistory({
            user_id: userId,
            subscription_id: sub?.id,
            stripe_payment_intent_id: paymentIntent.id,
            monto_centavos: paymentIntent.amount,
            moneda: paymentIntent.currency ?? "mxn",
            estado: "failed",
            descripcion: "Pago fallido PlaneaDocente",
            metadata: { stripe_payment_intent_id: paymentIntent.id },
          });
        }
        break;
      }

      case "customer.subscription.updated": {
        const sub = event.data.object as {
          id: string;
          status: string;
          current_period_end?: number;
          cancel_at_period_end?: boolean;
          customer?: string;
        };

        console.log("🔄 Subscription updated:", sub.id);

        await updateSubscriptionByStripeId(sub.id, {
          estado: sub.status,
          stripe_customer_id: sub.customer ?? undefined,
          fecha_fin: sub.current_period_end
            ? new Date(sub.current_period_end * 1000).toISOString()
            : undefined,
          cancelar_al_periodo_fin: sub.cancel_at_period_end ?? false,
        });
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object as { id: string };
        console.log("❌ Subscription cancelled:", sub.id);

        await updateSubscriptionByStripeId(sub.id, {
          estado: "canceled",
          fecha_fin: new Date().toISOString(),
        });
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
