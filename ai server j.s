const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const { Configuration, OpenAIApi } = require('openai');
require('dotenv').config();

const app = express();
app.use(bodyParser.json());
app.use(express.static('public'));

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/syzygeist', { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log("MongoDB connected"))
    .catch(err => console.error("MongoDB connection error:", err));

// Composition Schema
const compositionSchema = new mongoose.Schema({
    content: { type: String, required: true },
}, { timestamps: true });
const Composition = mongoose.model('Composition', compositionSchema);

// OpenAI configuration
const openai = new OpenAIApi(new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
}));

// Save composition endpoint
app.post('/api/save-composition', async (req, res) => {
    const { composition } = req.body;
    try {
        const newComposition = new Composition({ content: composition });
        await newComposition.save();
        res.json({ message: 'Composition saved successfully!' });
    } catch (error) {
        console.error("Error saving composition:", error);
        res.status(500).json({ message: 'Failed to save composition.' });
    }
});

// Ask AI endpoint
app.post('/api/ask-ai', async (req, res) => {
    const { query } = req.body;
    try {
        const response = await openai.createCompletion({
            model: 'text-davinci-003',
            prompt: query,
            max_tokens: 100,
        });
        res.json({ answer: response.data.choices[0].text.trim() });
    } catch (error) {
        console.error("Error querying AI:", error);
        res.status(500).json({ answer: "Failed to get response from AI." });
    }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
