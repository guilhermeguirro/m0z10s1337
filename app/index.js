const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Mozio Demo</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                    background: linear-gradient(45deg, #1a2a6c, #b21f1f, #fdbb2d);
                    background-size: 400% 400%;
                    animation: gradient 15s ease infinite;
                }
                
                @keyframes gradient {
                    0% { background-position: 0% 50%; }
                    50% { background-position: 100% 50%; }
                    100% { background-position: 0% 50%; }
                }
                
                .container {
                    text-align: center;
                    padding: 2rem;
                    background: rgba(255, 255, 255, 0.9);
                    border-radius: 10px;
                    box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
                    backdrop-filter: blur(4px);
                    border: 1px solid rgba(255, 255, 255, 0.18);
                }
                
                h1 {
                    color: #333;
                    font-size: 3rem;
                    margin-bottom: 1rem;
                }
                
                .subtitle {
                    color: #666;
                    font-size: 1.2rem;
                }
                
                .status {
                    margin-top: 2rem;
                    padding: 0.5rem 1rem;
                    background: #4CAF50;
                    color: white;
                    border-radius: 5px;
                    display: inline-block;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Hello Mozio!</h1>
                <p class="subtitle">Running on AWS ECS Fargate</p>
                <div class="status">Status: Active</div>
            </div>
        </body>
        </html>
    `);
});

app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

app.listen(port, () => {
    console.log(`App listening at port ${port}`);
}); 
