const express = require('express');
const { MongoClient } = require('mongodb');
const path = require('path');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// MongoDB connection string — connects to all 3 nodes so driver auto-routes
const MONGO_URI = process.env.MONGO_URI ||
  'mongodb://mongo-primary:27017,mongo-secondary1:27017,mongo-secondary2:27017/?replicaSet=rs0&readPreference=primaryPreferred';

const DB_NAME = 'appdb';
const COLLECTION = 'items';

let client;

async function getClient() {
  if (!client || !client.topology?.isConnected()) {
    client = new MongoClient(MONGO_URI, {
      serverSelectionTimeoutMS: 3000,
      connectTimeoutMS: 3000,
    });
    await client.connect();
  }
  return client;
}

// GET /api/status — replicaset status + which node is primary
app.get('/api/status', async (req, res) => {
  try {
    const c = await getClient();
    const admin = c.db('admin');
    const rsStatus = await admin.command({ replSetGetStatus: 1 });

    const members = rsStatus.members.map(m => ({
      name: m.name,
      state: m.stateStr,
      health: m.health,
      uptime: m.uptime,
      isPrimary: m.stateStr === 'PRIMARY',
    }));

    const primary = members.find(m => m.isPrimary);

    res.json({ ok: true, setName: rsStatus.set, primary: primary?.name || null, members });
  } catch (err) {
    res.json({ ok: false, error: err.message, members: [] });
  }
});

// GET /api/items — all documents
app.get('/api/items', async (req, res) => {
  try {
    const c = await getClient();
    const items = await c.db(DB_NAME).collection(COLLECTION)
      .find({})
      .sort({ createdAt: -1 })
      .limit(50)
      .toArray();
    res.json({ ok: true, items });
  } catch (err) {
    res.json({ ok: false, error: err.message, items: [] });
  }
});

// POST /api/items — add document
app.post('/api/items', async (req, res) => {
  const { text } = req.body;
  if (!text?.trim()) return res.status(400).json({ ok: false, error: 'text required' });
  try {
    const c = await getClient();
    const result = await c.db(DB_NAME).collection(COLLECTION).insertOne({
      text: text.trim(),
      createdAt: new Date(),
    });
    res.json({ ok: true, id: result.insertedId });
  } catch (err) {
    res.json({ ok: false, error: err.message });
  }
});

// DELETE /api/items/:id
app.delete('/api/items/:id', async (req, res) => {
  const { ObjectId } = require('mongodb');
  try {
    const c = await getClient();
    await c.db(DB_NAME).collection(COLLECTION).deleteOne({ _id: new ObjectId(req.params.id) });
    res.json({ ok: true });
  } catch (err) {
    res.json({ ok: false, error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`App running on port ${PORT}`));
