window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "showHUD") document.getElementById('hud-container').style.display = 'block';
    if (data.action === "hideHUD") document.getElementById('hud-container').style.display = 'none';

    if (data.action === "updatePlayerCount") {
        if(data.players) document.getElementById('player-count').innerText = data.players;
    }

    if (data.action === "updateInfo") {
        if(data.time) document.getElementById('time').innerText = data.time;
        if(data.temp) document.getElementById('temp').innerText = data.temp + "°";
        if(data.cash) document.getElementById('cash').innerText = data.cash;
        if(data.bank) document.getElementById('bank').innerText = data.bank;
    }

    if (data.action === "updateLocation") {
        if(data.street) document.getElementById('street-name').innerText = data.street;
        if(data.zone) document.getElementById('zone-name').innerText = data.zone;
        if(data.headingTxt) document.getElementById('heading-txt').innerText = data.headingTxt;
        if(data.headingDeg) document.getElementById('heading-deg').innerText = data.headingDeg;
    }

    if (data.action === "updateStatus") {
        updateBar('health', data.health);
        updateBar('food', data.food);
        updateBar('stamina', data.stamina);
        updateBar('water', data.water);
        updateBar('armor', data.armor);
        updateBar('oxygen', data.oxygen);

        // ซ่อนเกราะถ้าไม่มี
        document.getElementById('armor-box').style.visibility = (data.armor <= 0) ? 'hidden' : 'visible';
        
        // ซ่อนออกซิเจนถ้าอยู่บนบกหรือเต็ม 100
        document.getElementById('oxygen-box').style.visibility = (data.oxygen >= 100) ? 'hidden' : 'visible';
    }
});

function updateBar(name, value) {
    if (value === undefined) return;
    let bar = document.getElementById(name + '-bar');
    if (!bar) return;

    bar.style.width = value + '%';

    // แดงเมื่อ <= 10%, กระพริบเมื่อ <= 30%
    if (value <= 10) bar.classList.add('critical');
    else bar.classList.remove('critical');

    if (value <= 30) bar.classList.add('blink');
    else bar.classList.remove('blink');
}