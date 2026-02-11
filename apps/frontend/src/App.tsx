import React, { useEffect, useState } from "react";

type Change = { id: string; title: string; status: string; created_at: number };

const API = "/api"; // ingress routes by host -> api.opsdesk.local; UI will call that host in browser

export default function App() {
  const [changes, setChanges] = useState<Change[]>([]);
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    fetch("https://api.opsdesk.local/api/changes", { method: "GET" })
      .then(async (r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then(setChanges)
      .catch((e) => setErr(String(e)));
  }, []);

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 p-6">
      <h1 className="text-3xl font-bold">OpsDesk</h1>
      <p className="text-slate-300 mt-2">Jour 1: UI + API + Worker déployés sur Kubernetes.</p>

      {err && (
        <div className="mt-4 p-3 rounded bg-red-900/40 border border-red-800">
          API error: {err} (TLS self-signed: accepte l’avertissement navigateur)
        </div>
      )}

      <div className="mt-6 p-4 rounded bg-slate-900 border border-slate-800">
        <h2 className="text-xl font-semibold">Changes</h2>
        <ul className="mt-3 space-y-2">
          {changes.map((c) => (
            <li key={c.id} className="p-3 rounded bg-slate-950 border border-slate-800">
              <div className="font-medium">{c.title}</div>
              <div className="text-sm text-slate-400">status={c.status}</div>
            </li>
          ))}
          {changes.length === 0 && <li className="text-slate-400">Aucune donnée (normal en Jour 1).</li>}
        </ul>
      </div>
    </div>
  );
}
