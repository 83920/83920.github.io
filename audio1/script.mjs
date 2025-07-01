
let ac = null;
const play_buf = (bufA, bufB=bufA) => {
  if (ac == null) ac = new (window.AudioContext || window.webkitAudioContext)();
  const buf = ac.createBuffer(2, bufA.length, 44100);
  buf.getChannelData(0).set(bufA);
  buf.getChannelData(1).set(bufB);
  const src = ac.createBufferSource(); src.buffer = buf;
  src.connect(ac.destination); src.start();
};

const make_scalar_field = (num_bumps=10) => {
  const coeffs = Array(num_bumps);
  //for (let i = 0; i < num_bumps; i++) coeffs[i] = [ Math.random(), Math.random(), Math.random()*50+3 ]
  for (let i = 0; i < num_bumps; i++)
    coeffs[i] = [ Math.random(), Math.random(), Math.random()*200 ]
  return { coeffs, num_bumps };
};

const eval_orth_grad_field = (scalar_field, [ x, y ]) => {
  let [ dx, dy ] = [ 0, 0 ];
  for (let i = 0; i < scalar_field.num_bumps; i++) {
    const [ ox, oy, h ] = scalar_field.coeffs[i];
    dx += -2*h*(x-ox) * 1/scalar_field.num_bumps * Math.exp(-h*Math.abs((x-ox)**2 + (y-oy)**2));
    dy += -2*h*(y-oy) * 1/scalar_field.num_bumps * Math.exp(-h*Math.abs((x-ox)**2 + (y-oy)**2));
  }
  return [ -dy, dx ];
};

const ctx = document.getElementById('c').getContext('2d'), dim = [0, 0];
ctx.canvas.style.width = ctx.canvas.style.height = Math.min(innerWidth, innerHeight);
ctx.canvas.height = dim[1] = parseInt(ctx.canvas.style.height)/1; let mx;
ctx.canvas.width = dim[0] = parseInt(ctx.canvas.style.width)/1; let my;
ctx.canvas.onpointermove = e => [ mx, my ] = [ e.offsetX/dim[0], e.offsetY/dim[1] ];

const field = make_scalar_field(50);
console.log(field);
const fn = (x, y, s=.01) => {
  const [dx, dy] = eval_orth_grad_field(field, [x, y]);
  return [s*dx, s*dy];
};

ctx.canvas.onpointerdown = e => {
  const bufA = new Float32Array(44100*8);
  const bufB = new Float32Array(bufA.length);
  let [xA, yA] = [mx, my]; const vol = .5;
  let [xB, yB] = [mx+.05, my];
  for (let i = 0; i < bufA.length; i++) {
    const [dxA, dyA] = fn(xA, yA);
    const [dxB, dyB] = fn(xB, yB);
    xA += dxA, yA += dyA;
    xB += dxB, yB += dyB;
    //buf[i] = Math.hypot(x-.5, y-.5)*vol;
    //buf[i] = Math.atan2(y-.5, x-.5)*vol;
    bufA[i] = Math.hypot(xA-mx, yA-my)*vol;
    bufB[i] = Math.hypot(xB-mx, yB-my)*vol;
  }

  play_buf(bufA, bufB);
  //console.log(e.offsetX/dim[0], e.offsetY/dim[1]);
};

let itr = 0; const loop = () => { itr += 1; window.requestAnimationFrame(loop);
  ctx.clearRect(0, 0, dim[0], dim[1]);

  const gdim = 100; ctx.fillStyle = ctx.strokeStyle = '#fff';
  for (let i = 0; i <= gdim; i++) for (let j = 0; j <= gdim; j++) {
    const [x, y] = [i/gdim, j/gdim];
    const [dx, dy] = fn(x, y);
    ctx.beginPath();
    ctx.moveTo(x*dim[0], y*dim[1]);
    ctx.lineTo((x+dx)*dim[0], (y+dy)*dim[1]);
    ctx.stroke();
  }

  ctx.beginPath();
  let [x, y] = [mx, my];
  for (let i = 0; i < 20000; i++) {
    ctx.lineTo(x*dim[0], y*dim[1]);
    const [dx, dy] = fn(x, y);
    x += dx, y += dy;
  }
  ctx.stroke();
}; loop();
