'use client';

import { useEffect } from 'react';

export default function Home() {

  useEffect(() => {
    const script = document.createElement('script');
    script.src = 'https://js.stripe.com/v3/';
    script.async = true;
    document.body.appendChild(script);
  }, []);

  const handlePago = async () => {
    try {
      const stripe = (window as any).Stripe('pk_test_51TFIn1FCwyyS7eA2kIBrgajQfBIELinvVknc3wFvdbgjl1vbIyBLfG6qg5HQFDeYh892uKyhlxCWWtwT1DwLN7hI00EHKuenix');

      const res = await fetch('/api/crear-pago', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      const data = await res.json();

      if (!data.id) {
        alert('Error creando sesión');
        return;
      }

      await stripe.redirectToCheckout({
        sessionId: data.id
      });

    } catch (error) {
      console.error(error);
      alert('Error al procesar el pago');
    }
  };

  return (
    <main style={{ textAlign: 'center', marginTop: '50px' }}>
      <h1>Planea Docente</h1>
      <p>Sistema profesional de planeación didáctica</p>

      <button onClick={handlePago}>
        Comprar ahora - $199 MXN
      </button>
    </main>
  );
}