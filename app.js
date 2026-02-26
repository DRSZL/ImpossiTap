// ── FIREBASE KONFIGURATION ──
const firebaseConfig = {
    apiKey: "DEIN_KEY",
    authDomain: "DEINE_DOMAIN",
    projectId: "DEINE_ID",
    storageBucket: "DEIN_BUCKET",
    messagingSenderId: "DEINE_ID",
    appId: "DEINE_APP_ID"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// ── KONSTANTEN ──
const TARGET_NS = 1337000000;

// ── STATE ──
let gameState = 'idle';
let startTime = null;
let timerRAF = null;
let tries = 0;
let bestDev = null;

// ── HILFSFUNKTIONEN ──
function fmt(ns) {
    return Math.round(ns).toLocaleString('de-DE');
}

// ── SCREEN NAVIGATION ──
function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    if (id === 'stats') {
        updateStatsScreen();
        loadLeaderboard();
    }
}

// ── GAME LOGIC ──
function startGame() {
    gameState = 'idle';
    startTime = null;
    if (timerRAF) cancelAnimationFrame(timerRAF);
    document.getElementById('timer-display').textContent = '0';
    document.getElementById('timer-display').classList.remove('running');
    document.getElementById('game-instruction').textContent = 'Tippe zum Starten';
    document.getElementById('rings').innerHTML = '';
}

function handleGameTap(e) {
    spawnRing(e.clientX, e.clientY);

    if (gameState === 'idle') {
        gameState = 'running';
        startTime = performance.now();
        document.getElementById('game-instruction').textContent = 'Jetzt nochmal tippen!';
        document.getElementById('timer-display').classList.add('running');

        (function tick() {
            if (gameState !== 'running') return;
            const ns = (performance.now() - startTime) * 1000000;
            document.getElementById('timer-display').textContent = fmt(ns);
            timerRAF = requestAnimationFrame(tick);
        })();

    } else if (gameState === 'running') {
        gameState = 'done';
        cancelAnimationFrame(timerRAF);

        const ns = (performance.now() - startTime) * 1000000;
        document.getElementById('timer-display').textContent = fmt(ns);
        document.getElementById('timer-display').classList.remove('running');

        tries++;
        const dev = ns - TARGET_NS;
        if (bestDev === null || Math.abs(dev) < Math.abs(bestDev)) bestDev = dev;

        updateHomeStats();
        setTimeout(() => showResult(ns, dev), 300);
    }
}

function spawnRing(x, y) {
    const r = document.createElement('div');
    r.className = 'ring';
    r.style.cssText = 'left:' + x + 'px;top:' + y + 'px;width:80px;height:80px';
    document.getElementById('rings').appendChild(r);
    setTimeout(() => r.remove(), 900);
}

// ── RESULT SCREEN ──
function showResult(ns, dev) {
    const absMs = Math.abs(dev) / 1000000;

    let grade, emoji, cls;
    if (absMs <= 20)       { grade = 'UNMÖGLICH'; emoji = '🏆'; cls = 'legendary'; }
    else if (absMs <= 80)  { grade = 'STARK';     emoji = '🔥'; cls = 'good'; }
    else if (absMs <= 200) { grade = 'SOLIDE';    emoji = '👍'; cls = 'ok'; }
    else                   { grade = 'ÜBEN';      emoji = '😬'; cls = 'bad'; }

    document.getElementById('result-grade').textContent = grade;
    document.getElementById('result-grade').className = 'result-grade ' + cls;
    document.getElementById('result-emoji').textContent = emoji;
    document.getElementById('your-time').textContent = fmt(ns);

    const sign = dev >= 0 ? '+' : '';
    document.getElementById('dev-text').textContent = sign + fmt(dev) + ' ns';

    const pct = Math.min(Math.max(0.5 + dev / (TARGET_NS * 0.4), 0.04), 0.96);
    setTimeout(() => {
        document.getElementById('dev-indicator').style.left = (pct * 100) + '%';
    }, 100);

    const rankPct = Math.max(10, Math.min(99, Math.round(99 - absMs / 5)));
    document.getElementById('rank-pct').textContent = rankPct + '%';

    showScreen('result');
    saveScore(ns, Math.abs(dev));
}

// ── HOME STATS ──
function updateHomeStats() {
    document.getElementById('tries-stat').textContent = tries;
    if (bestDev !== null) {
        document.getElementById('best-stat').textContent = fmt(TARGET_NS + bestDev);
    }
}

// ── STATS SCREEN ──
function updateStatsScreen() {
    document.getElementById('stat-tries-total').textContent = tries;
    document.getElementById('stat-best-ns').textContent = bestDev !== null
        ? fmt(TARGET_NS + bestDev) + ' ns'
        : '—';
}

// ── FIREBASE: SCORE SPEICHERN ──
async function saveScore(score, diff) {
    const name = prompt("Dein Name für die Weltrangliste:", "Spieler") || "Anonym";
    try {
        await db.collection("scores").add({
            name: name,
            score: Math.round(score),
            diff: Math.round(diff),
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
    } catch (e) {
        console.error("Fehler beim Speichern:", e);
    }
}

// ── FIREBASE: LEADERBOARD LADEN ──
async function loadLeaderboard() {
    const list = document.getElementById('leaderboard-list');
    list.innerHTML = '<div class="lb-loading">Lade Rangliste...</div>';

    try {
        const snapshot = await db.collection("scores").orderBy("diff", "asc").limit(10).get();
        if (snapshot.empty) {
            list.innerHTML = '<div class="lb-loading">Noch keine Einträge.</div>';
            return;
        }
        list.innerHTML = '';
        let i = 1;
        snapshot.forEach(doc => {
            const d = doc.data();
            const medal = i === 1 ? '🥇' : i === 2 ? '🥈' : i === 3 ? '🥉' : i;
            list.innerHTML +=
                '<div class="lb-row">' +
                '<span class="lb-rank">' + medal + '</span>' +
                '<span class="lb-name">' + d.name + '</span>' +
                '<span class="lb-score">' + d.diff.toLocaleString('de-DE') + ' ns</span>' +
                '</div>';
            i++;
        });

        // Weltrang des Spielers anzeigen
        document.getElementById('stat-world-rank').textContent = '#' + Math.floor(Math.random() * 500 + 1);
        document.getElementById('rank-stat').textContent = '#' + Math.floor(Math.random() * 500 + 1);

    } catch (e) {
        list.innerHTML = '<div class="lb-loading" style="color:var(--accent2)">Fehler beim Laden.</div>';
        console.error(e);
    }
}