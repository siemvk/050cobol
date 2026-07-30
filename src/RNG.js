
function encodeToBase64(str) {
    return btoa(str);
}

function httpGet(theUrl) {
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open("GET", theUrl, false); // false for synchronous request
    xmlHttp.send(null);
    return xmlHttp.responseText;
}

function RNG(daily, moeilijkheid) {
    var info_bestand, directory;
    if (moeilijkheid == 1) {
        info_bestand = "info.json";
        directory = "fotos";
    } else {
        info_bestand = "info_moeilijk.json";
        directory = "fotos_moeilijk";
    }

    if (daily == "1") {
        var info = JSON.parse(httpGet(info_bestand));
        const daily_seeds = [];
        while (daily_seeds.length < 5) {
            var temp = Math.floor(Math.random() * info.foto_hoeveelheid) + 1;
            if (!daily_seeds.includes(temp)) {
                daily_seeds.push(temp);
                var loop = daily_seeds.length; // 1‑based index
                sessionStorage.setItem("DAILY_" + loop, temp);
            }
        }
    }
    var RNG = sessionStorage.getItem("DAILY_" + daily);
    var foto = document.getElementById("img");
    foto.src = directory + "/" + RNG + "/" + RNG + ".jpeg";
    return httpGet(directory + "/" + RNG + "/" + RNG + ".json");
}
