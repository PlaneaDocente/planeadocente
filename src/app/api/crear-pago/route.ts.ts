export async function GET() {
  return new Response('API crear-pago OK');
}
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-06-20',
});

export async function POST() {
  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: 'mxn',
            product_data: {
              name: 'Planea Docente',
            },
            unit_amount: 19900, // $199 MXN
          },
          quantity: 1,
        },
      ],
      success_url: 'https://planeadocente.vercel.app/success',
      cancel_url: 'https://planeadocente.vercel.app/cancel',
    });

    return Response.json({ id: session.id });

  } catch (error) {
    console.error(error);
    return new Response('Error al crear pago', { status: 500 });
  }
}