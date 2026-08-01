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
        const response = await fetch('/api/get_item/user_key/' + localStorage.getItem("key") + '/1');
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
function in_gelogd() {
    if (localStorage.getItem("key") !== null) {
        return true
    }
    return false
}

async function get_player_data() {
    const Rusername = await get_user_name();
    const data = JSON.parse(await klaarmakeRequest());
    if (!data) {
        return null
    }
    for (let i = 0; i < data.length; i++) {
        if (data[i].username == Rusername) {
            var player_data = data[i];
            var place_in_leaderboard = i + 1;
            return place_in_leaderboard
        }
    }
    return null
}


async function displayLeaderboard() {
    const data = await klaarmakeRequest();
    if (data) {
        var leaderboardDiv = document.getElementById('plek_een');
        var leaderboard = JSON.parse(data)
        leaderboardDiv.innerHTML += leaderboard[0].username + " " + leaderboard[0].user_score + " punten";
        var leaderboardDiv = document.getElementById('plek_twee');
        leaderboardDiv.innerHTML += leaderboard[1].username + " " + leaderboard[1].user_score + " punten";
        var leaderboardDiv = document.getElementById('plek_drie');
        leaderboardDiv.innerHTML += leaderboard[2].username + " " + leaderboard[2].user_score + " punten";
        var leaderboardDiv = document.getElementById('de_rest');
        leaderboardDiv.innerHTML += leaderboard[3].username + " " + leaderboard[3].user_score + " punten";
        console.log("loop")
        for (let i = 4; i < leaderboard.length; i++) {
            var leaderboardDiv = document.getElementById('de_rest');
            leaderboardDiv.innerHTML = leaderboardDiv.innerHTML + "<br>" + leaderboard[i].username + " " + leaderboard[i].user_score + " punten";
            console.log("loop")
        }
        document.getElementById("gefelliciteerd").innerText = "gefelliciteerd je hebt " + score + " punten";
        if (in_gelogd()) {
            document.getElementById("je_bent_op_plek").innerText = "je bent op plek " + await get_player_data() + " in de leaderboard";
        } else {
            document.getElementById("je_bent_op_plek").innerText = "login of maak een acount om op de leaderboard te komen!";
        }


    } else {
        document.getElementById('container').innerHTML = ' server offline )=';
    }
}
