import { kv } from "@vercel/kv";
import { nanoid } from "nanoid";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "Use POST" });

  const { fullName, nationalId, wallet, amount, notes } = req.body || {};
  if (!fullName || !nationalId || !wallet || !amount) {
    return res.status(400).json({ error: "Missing fields" });
  }

  const id = nanoid(10);
  const record = {
    id,
    fullName,
    nationalId,
    wallet: wallet.toLowerCase(),
    requestedAmount: String(amount),
    notes: notes || "",
    status: "PENDING",
    approvedAmount: "",
    txHash: "",
    createdAt: new Date().toISOString(),
  };

  await kv.set(`req:${id}`, record);
  await kv.set(`wallet:${record.wallet}`, id);

  res.status(200).json({ id, status: record.status });
}
