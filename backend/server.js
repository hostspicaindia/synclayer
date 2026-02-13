const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// In-memory storage (replace with real DB in production)
const collections = {};

// Helper to get collection
function getCollection(name) {
    if (!collections[name]) {
        collections[name] = {};
    }
    return collections[name];
}

// POST /sync/{collection} - Receive synced data from client
app.post('/sync/:collection', (req, res) => {
    const { collection } = req.params;
    const { recordId, data, timestamp } = req.body;

    console.log(`[PUSH] ${collection}/${recordId}`);

    const coll = getCollection(collection);
    coll[recordId] = {
        recordId,
        data,
        updatedAt: timestamp,
        version: (coll[recordId]?.version || 0) + 1,
    };

    res.json({
        success: true,
        recordId,
        version: coll[recordId].version,
    });
});

// GET /sync/{collection}?since={timestamp} - Return updates since timestamp
app.get('/sync/:collection', (req, res) => {
    const { collection } = req.params;
    const { since } = req.query;

    console.log(`[PULL] ${collection} since=${since || 'beginning'}`);

    const coll = getCollection(collection);
    let records = Object.values(coll);

    // Filter by timestamp if provided
    if (since) {
        const sinceDate = new Date(since);
        records = records.filter(r => new Date(r.updatedAt) > sinceDate);
    }

    console.log(`[PULL] Returning ${records.length} records`);

    res.json({
        records: records.map(r => ({
            recordId: r.recordId,
            data: r.data,
            updatedAt: r.updatedAt,
            version: r.version,
        })),
    });
});

// DELETE /sync/{collection}/{recordId} - Handle deletions
app.delete('/sync/:collection/:recordId', (req, res) => {
    const { collection, recordId } = req.params;

    console.log(`[DELETE] ${collection}/${recordId}`);

    const coll = getCollection(collection);
    delete coll[recordId];

    res.json({
        success: true,
        recordId,
    });
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        collections: Object.keys(collections).length,
        timestamp: new Date().toISOString(),
    });
});

// Debug endpoint - view all data
app.get('/debug/:collection', (req, res) => {
    const { collection } = req.params;
    const coll = getCollection(collection);

    res.json({
        collection,
        count: Object.keys(coll).length,
        records: Object.values(coll),
    });
});

app.listen(PORT, () => {
    console.log(`🚀 SyncLayer Backend running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});
