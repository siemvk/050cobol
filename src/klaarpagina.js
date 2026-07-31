

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
    displayLeaderboard2();
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



async function makeRequest2() {
    try {
        const response = await fetch('/api/leaderboardMoeilijk');
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

async function displayLeaderboard2() {
    const data = await makeRequest2();
    if (data) {
        var leaderboardDiv = document.getElementById('plek_een2');
        var leaderboard = JSON.parse(data)
        leaderboardDiv.innerHTML += leaderboard[0].username + " " + leaderboard[0].user_score_moeilijk + " punten" + '<img src="bages/' + leaderboard[0].bage + '.png" class="medalie" alt="">';
        var leaderboardDiv = document.getElementById('plek_twee2');
        leaderboardDiv.innerHTML += leaderboard[1].username + " " + leaderboard[1].user_score_moeilijk + " punten" + '<img src="bages/' + leaderboard[1].bage + '.png" class="medalie" alt="">';
        var leaderboardDiv = document.getElementById('plek_drie2');
        leaderboardDiv.innerHTML += leaderboard[2].username + " " + leaderboard[2].user_score_moeilijk + " punten" + '<img src="bages/' + leaderboard[2].bage + '.png" class="medalie" alt="">';
        var leaderboardDiv = document.getElementById('de_rest2');
        leaderboardDiv.innerHTML += leaderboard[3].username + " " + leaderboard[3].user_score_moeilijk + " punten" + '<img src="bages/' + leaderboard[3].bage + '.png" class="medalie" alt="">';
        console.log("loop")
        for (let i = 4; i < leaderboard.length; i++) {
            if (leaderboard[i].user_score_moeilijk < 1) {
                return
            }
            var leaderboardDiv = document.getElementById('de_rest2');
            leaderboardDiv.innerHTML = leaderboardDiv.innerHTML + "<br>" + leaderboard[i].username + " " + leaderboard[i].user_score_moeilijk + " punten" + '<img src="bages/' + leaderboard[i].bage + '.png" class="medalie" alt="">';
            console.log(leaderboard[i].bage)
        }
    } else {
        document.getElementById('container2').innerHTML = ' server offline )=';
    }
}


