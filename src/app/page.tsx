'use client';

import { loadStripe } from '@stripe/stripe-js';

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!);

export default function Home() {
  const handleCheckout = async () => {
    try {
      const response = await fetch('/api/crear-pago', {
        method: 'POST',
      });

      const { id, error } = await response.json();

      if (error) {
        alert(`Error: ${error}`);
        return;
      }

      const stripe = await stripePromise;
      const { error: stripeError } = await stripe!.redirectToCheckout({
        sessionId: id,
      });

      if (stripeError) {
        alert(stripeError.message);
      }
    } catch (err) {
      console.error('Error en checkout:', err);
      alert('Ocurrió un error. Intenta de nuevo.');
    }
  };

  return (
    <div style={{ padding: '2rem', textAlign: 'center' }}>
      <h1>Planea Docente</h1>
      <p>Sistema profesional de planeación didáctica</p>
      <button 
        onClick={handleCheckout}
        style={{
          padding: '12px 24px',
          fontSize: '16px',
          backgroundColor: '#635bff',
          color: 'white',
          border: 'none',
          borderRadius: '8px',
          cursor: 'pointer',
        }}
      >
        Comprar ahora - $199 MXN
      </button>
    </div>
  );
}