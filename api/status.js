import { kv } from "@vercel/kv";

export default async function handler(req, res) {
  const wallet = String(req.query.wallet || "").toLowerCase().trim();
  if (!wallet) return res.status(400).json({ error: "wallet required" });

  const id = await kv.get(`wallet:${wallet}`);
  if (!id) return res.status(200).json({ found: false });

  const record = await kv.get(`req:${id}`);
  if (!record) return res.status(200).json({ found: false });

  res.status(200).json({ found: true, ...record });
}
