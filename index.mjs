import * as life from './life.wasm';

life.set(3, 0, 1);
life.set(2, 0, 1);
life.set(1, 0, 1);
life.set(1, 1, 1);
life.set(2, 2, 1);


function print () {
	var h = 8;
	var str = "";
	for (let y = -h; y <= +h; y++) {
		for (let x = -h; x <= +h; x++) {
			str = str + (life.get(x, -y) ? "o" : "~") + " ";
		}
		str = str + "\n";
	}

	process.stdout.write(str);
}


setInterval(function () {
	print();
	life.step();

	console.log();
	console.log(); // spacing
	console.log();
}, 1000);


