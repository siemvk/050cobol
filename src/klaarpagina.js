async function klaarmakeRequest() {
    try {
        const response = await fetch('/api/leaderboard');
        if (!response.ok) {
            throw new Error('Network response was not ok ' + response.statusText);
        }
        const data = await response.text();
        return data;
    } catch (error) {
        console.error('Error:', error);
        return null;
    }
}

async function get_user_name() {
    try {
        const key = localStorage.getItem("key");
        if (!key) return null;
        const response = await fetch('/api/accName/' + key);
        if (!response.ok) {
            throw new Error('Network response was not ok ' + response.statusText);
        }
        const data = await response.text();
        return data ? data.trim() : null;
    } catch (error) {
        console.error('Error:', error);
        return null;
    }
}

function in_gelogd() {
    if (localStorage.getItem("key") !== null) {
        return true;
    }
    return false;
}

async function get_player_data() {
    const Rusername = await get_user_name();
    if (!Rusername || Rusername === "Verkeerde KEY") {
        return null;
    }
    const rawData = await klaarmakeRequest();
    if (!rawData) {
        return null;
    }
    try {
        const data = JSON.parse(rawData);
        if (!data || !Array.isArray(data)) return null;
        for (let i = 0; i < data.length; i++) {
            if (data[i] && data[i].username && data[i].username.trim() === Rusername) {
                return i + 1;
            }
        }
    } catch (e) {
        console.error("Error parsing leaderboard JSON:", e);
    }
    return null;
}

async function displayLeaderboard() {
    const gefelliciteerdEl = document.getElementById("gefelliciteerd");
    const currentScore = (typeof score !== 'undefined') ? score : 0;
    if (gefelliciteerdEl) {
        gefelliciteerdEl.innerText = "gefelliciteerd je hebt " + currentScore + " punten";
    }

    const plekEl = document.getElementById("je_bent_op_plek");
    if (plekEl) {
        if (in_gelogd()) {
            const rank = await get_player_data();
            if (rank !== null) {
                plekEl.innerText = "je komt daarmee op plek " + rank + " in de leaderboard";
            } else {
                plekEl.innerText = "je bent nog niet opgenomen in de leaderboard";
            }
        } else {
            plekEl.innerText = "login of maak een acount om op de leaderboard te komen!";
        }
    }

    const data = await klaarmakeRequest();
    if (data) {
        try {
            const leaderboard = JSON.parse(data);
            const elements = ['plek_een', 'plek_twee', 'plek_drie'];
            for (let i = 0; i < 3; i++) {
                const el = document.getElementById(elements[i]);
                if (el && leaderboard[i]) {
                    el.innerHTML += " " + leaderboard[i].username + " " + leaderboard[i].user_score + " punten";
                }
            }

            const deRestEl = document.getElementById('de_rest');
            if (deRestEl && leaderboard.length > 3) {
                for (let i = 3; i < leaderboard.length; i++) {
                    if (leaderboard[i] && leaderboard[i].user_score > 0) {
                        deRestEl.innerHTML += (i === 3 ? "" : "<br>") + leaderboard[i].username + " " + leaderboard[i].user_score + " punten";
                    }
                }
            }
        } catch (e) {
            console.error("Leaderboard render error:", e);
        }
    } else {
        const containerEl = document.getElementById('container');
        if (containerEl) {
            containerEl.innerHTML = ' server offline )=';
        }
    }
}
