var app = require('http').createServer();
var io = require('socket.io')(app);
var os_ults = require('os-utils')
var os = require('os')
var si = require('systeminformation')
console.log("Server Started....");
app.listen(1024, '0.0.0.0');


function listenToASocket(socket, namespace) {
    console.log(`>>>>>>> new connection ${namespace?"to "+namespace:""}`, socket.handshake.query.timestamp);
    _sockets.add(socket);
    //let nsp = namespace?`(${namespace})   `:'';
    console.log(">>>>>socket.conn.transport.name>>>>", socket.conn.transport.name);
    console.log(">>>>>>> Total Sockets", _sockets.size);
    if (namespace) {
        socket.emit("message", "-----NameSpace: " + namespace + " -----");
    }
    socket.on("message", function () {
        let args = Array.prototype.slice.call(arguments);
        console.log(args, arguments.length);
        for (let arg of args) {
            console.log(arg, typeof arg);
        }
    });
    setInterval(() => {
        os_ults.cpuUsage((v) => {
            si.fsStats().then(sys => {
                let data = {
                    cpu: v * 100,
                    ram: (os.totalmem - os.freemem) * 100 / os.totalmem,
                    disk_write: sys.wx_sec / 1000000,
                    disk_read: sys.rx_sec / 1000000,
                }
                socket.emit("monitor", data)
            })


        })
    }, 1000)

    socket.on("ack-message", function () {
        let args = Array.prototype.slice.call(arguments);
        console.log(args, arguments.length);
        console.log(`received ack message: "${args}". Sending back ack!`);
        fn = args.pop();
        fn(`Ack for ${args.map(_ => (_ instanceof Object)?JSON.stringify(_):_).join(", ")}`);
    });
    socket.on("disconnect", () => {
        _sockets.delete(socket);
        console.log(">>>>>>> disconnect", socket.handshake.query.timestamp);
        console.log(">>>>>Disconnected socket transport type:", socket.conn.transport.name);
        console.log(">>>>>>> Total Sockets", _sockets.size);
    });
}

var _sockets = new Set();
io.on('connection', function (socket) {
    listenToASocket(socket, null);
});

var io_adhara = io.of('/adhara');
io_adhara.on('connection', function (socket) {
    listenToASocket(socket, "/adhara");
});

process.on('SIGINT', function () {
    process.exit();
});