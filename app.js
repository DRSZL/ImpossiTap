// HIER DEINE FIREBASE KONFIGURATION AUS DER KONSOLE EINSETZEN
const firebaseConfig = {
    apiKey: "DEIN_KEY",
    authDomain: "DEINE_DOMAIN",
    projectId: "DEINE_ID",
    storageBucket: "DEIN_BUCKET",
    messagingSenderId: "DEINE_ID",
    appId: "DEINE_APP_ID"
};

// Firebase initialisieren
firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

const TARGET_US = 1337000;
let gameState = 'idle';
let startTime = null;

function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    if(id === 'stats') loadLeaderboard();
}

function startGame() {
    gameState = 'idle';
    document.getElementById('timer-display').textContent = '0';
    document.getElementById('timer-display').classList.remove('running');
}

function handleGameTap() {
    if (gameState === 'idle') {
        gameState = 'running';
        startTime = performance.now();
        document.getElementById('timer-display').classList.add('running');
        update();
    } else if (gameState === 'running') {
        gameState = 'done';
        const durationUs = Math.round((performance.now() - startTime) * 1000);
        const diff = Math.abs(durationUs - TARGET_US);
        
        saveScore(durationUs, diff);
        alert(`Ergebnis: ${durationUs.toLocaleString()} μs\nAbweichung: ${diff.toLocaleString()} μs`);
        showScreen('home');
    }
}

function update() {
    if (gameState !== 'running') return;
    const currentUs = Math.round((performance.now() - startTime) * 1000);
    document.getElementById('timer-display').textContent = currentUs.toLocaleString('de-DE');
    requestAnimationFrame(update);
}

async function saveScore(score, diff) {
    const name = prompt("Dein Name für die Weltrangliste:", "Spieler") || "Anonym";
    try {
        await db.collection("scores").add({
            name: name,
            diff: diff,
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
    } catch (e) {
        console.error("Fehler beim Speichern:", e);
    }
}

async function loadLeaderboard() {
    const list = document.getElementById('leaderboard-list');
    list.innerHTML = "<div style='text-align:center; font-family:var(--mono); font-size:10px; color:var(--muted);'>Lade Weltrangliste...</div>";
    try {
        const snapshot = await db.collection("scores").orderBy("diff", "asc").limit(10).get();
        list.innerHTML = "";
        snapshot.forEach(doc => {
            const d = doc.data();
            list.innerHTML += `<div class="rank-item"><span>${d.name}</span><span>${d.diff.toLocaleString()} μs</span></div>`;
        });
    } catch (e) {
        list.innerHTML = "<div style='color:red;'>Fehler beim Laden.</div>";
    }
}
