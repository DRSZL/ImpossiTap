let startTime;
let running = false;
const targetUs = 1337000;

function handleTap() {
    if (!running) {
        running = true;
        startTime = performance.now();
        requestAnimationFrame(updateDisplay);
    } else {
        running = false;
        const endTime = performance.now();
        const durationUs = Math.round((endTime - startTime) * 1000);
        const diff = durationUs - targetUs;
        
        alert(`Ergebnis: ${durationUs.toLocaleString()} μs\nAbweichung: ${diff > 0 ? '+' : ''}${diff.toLocaleString()} μs`);
    }
}

function updateDisplay() {
    if (!running) return;
    const now = performance.now();
    const currentUs = Math.round((now - startTime) * 1000);
    document.getElementById('display').innerText = currentUs.toLocaleString('de-DE');
    requestAnimationFrame(updateDisplay);
}

function shareResult() {
    // Platzhalter für die native Share-Funktion
    alert("Share-Funktion wird in der App-Version aktiviert!");
}
