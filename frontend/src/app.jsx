// frontend/src/App.jsx
import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [status, setStatus] = useState({})
  const [payments, setPayments] = useState([])

  useEffect(() => {
    fetch('/api/status')
      .then(res => res.json())
      .then(data => setStatus(data))
    fetch('/api/payments')
      .then(res => res.json())
      .then(data => setPayments(data))
  }, [])

  return (
    <div className="App">
      <h1>Miner Node Dashboard</h1>
      <p>Backend: {status.online ? '🟢 En ligne' : '🔴 Hors ligne'}</p>
      <h2>Paiements reçus</h2>
      {payments.length === 0 && <p>Aucun paiement pour l’instant.</p>}
      <ul>
        {payments.map((p, i) => (
          <li key={i}>{p.amount_btc} BTC - {p.timestamp}</li>
        ))}
      </ul>
    </div>
  )
}

export default App
