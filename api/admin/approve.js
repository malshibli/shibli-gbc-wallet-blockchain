import { kv } from "@vercel/kv";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "Use POST" });

  // Minimal admin gate: a shared secret header (better: wallet-signature verification)
  const key = req.headers["x-admin-key"];
  if (!process.env.ADMIN_KEY || key !== process.env.ADMIN_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { requestId, wallet, approvedAmount, txHash } = req.body || {};
  const w = String(wallet || "").toLowerCase().trim();
  if (!w || !approvedAmount) return res.status(400).json({ error: "wallet + approvedAmount required" });

  let id = requestId;
  if (!id) id = await kv.get(`wallet:${w}`);
  if (!id) return res.status(404).json({ error: "Request not found" });

  const record = await kv.get(`req:${id}`);
  if (!record) return res.status(404).json({ error: "Request not found" });

  record.status = "APPROVED";
  record.approvedAmount = String(approvedAmount);
  record.txHash = txHash || record.txHash || "";
  record.updatedAt = new Date().toISOString();

  await kv.set(`req:${id}`, record);

  res.status(200).json({ id, status: record.status });
}
