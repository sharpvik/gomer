let app = Elm.Main.init({
    node: document.getElementById('elm-app')
});

let socket = new WebSocket('/conn');

app.ports.sendGoCode.subscribe(goCode => {
    socket.send(JSON.stringify({ goCode }));
});

socket.addEventListener("message", event => {
    const msg = JSON.parse(event.data);
    switch (msg.type) {
        case "codeUpdate":
            app.ports.receiveGoCode.send(msg.data.goCode);
            break;
        case "runResult":
            app.ports.receiveRunResult.send(msg.data.output);
            break;
    }
});