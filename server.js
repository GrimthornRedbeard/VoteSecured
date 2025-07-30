const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 7500;

// Serve static files from various directories
app.use('/docs', express.static(path.join(__dirname, 'docs')));
app.use('/images', express.static(path.join(__dirname, 'images')));
app.use('/assets', express.static(path.join(__dirname, 'assets')));

// Main landing page - new federal-focused page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'index.html'));
});

// State-specific pages
app.get('/states/georgia', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'states', 'georgia.html'));
});

app.get('/states/florida', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'states', 'florida.html'));
});

app.get('/states/texas', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'states', 'texas.html'));
});

app.get('/states/california', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'states', 'california.html'));
});

app.get('/states/federal', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'states', 'federal.html'));
});

// Demo system routes
app.get('/demo', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo.html'));
});

app.get('/demo/voter', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-voter.html'));
});

app.get('/demo/official', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-official.html'));
});

app.get('/demo/security', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-security.html'));
});

app.get('/demo/rcv', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-rcv.html'));
});

app.get('/demo/analytics', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-analytics.html'));
});

app.get('/demo/verification', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'demo-verification.html'));
});

// Documentation
app.get('/docs', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'docs', 'index.html'));
});

// Compliance pages (placeholder routing)
app.get('/compliance/:standard', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'compliance', req.params.standard + '.html'));
});

// Pilot programs
app.get('/pilot-programs', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'pilot-programs.html'));
});

// Resources
app.get('/resources/:type', (req, res) => {
    res.sendFile(path.join(__dirname, 'pages', 'resources', req.params.type + '.html'));
});

// Legacy route - redirect old construction page to Georgia
app.get('/construction', (req, res) => {
    res.redirect(301, '/states/georgia');
});

// Fallback for undefined routes - serve 404 or redirect to main page
app.get('*', (req, res) => {
    // For now, redirect undefined routes to main page
    // In production, this should serve a proper 404 page
    res.redirect('/');
});

app.listen(PORT, () => {
    console.log(`Vote Secured platform server running on port ${PORT}`);
    console.log(`🗳️  Main landing page: http://localhost:${PORT}`);
    console.log(`🍑  Georgia solution: http://localhost:${PORT}/states/georgia`);
    console.log(`🚀  Demo system: http://localhost:${PORT}/demo`);
    console.log(`📋  Documentation: http://localhost:${PORT}/docs`);
    console.log(`\nPlatform Features:`);
    console.log(`- Federal-focused main landing page`);
    console.log(`- State-specific solution pages`);
    console.log(`- Compliance documentation`);
    console.log(`- Demo system integration`);
    console.log(`\nPort Selection: ${PORT} (avoiding conflicts with other services)`);
    console.log(`- nerdi-gras: 3003, talent-matchr: 5000/8001, validentity: 3001, threattape: 3000`);
});

module.exports = app;