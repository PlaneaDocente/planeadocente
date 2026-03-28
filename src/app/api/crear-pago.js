import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).send('Método no permitido');
  }

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'mxn',
            product_data: {
              name: 'Planea Docente',
            },
            unit_amount: 19900,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: 'https://tudominio.com/success.html',
      cancel_url: 'https://tudominio.com/cancel.html',
    });

    res.status(200).json({ id: session.id });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}