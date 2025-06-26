
import * as gpu from './gpu.mjs';
const gl = document.getElementById('c').getContext('webgl2', { powerPreference: 'high-performance' });
gl.disable(gl.DEPTH_TEST); gl.disable(gl.STENCIL_TEST);
gl.getExtension("EXT_color_buffer_float"); const dim = [0, 0];
gl.canvas.style.width  = Math.min(innerWidth, innerHeight);
gl.canvas.style.height = Math.min(innerWidth, innerHeight);
gl.canvas.width  = dim[0] = parseInt(gl.canvas.style.width)/1.5; let mx = .0;
gl.canvas.height = dim[1] = parseInt(gl.canvas.style.height)/1.5; let my = .5;
gl.canvas.onpointermove = e => [ mx, my ] = [ e.offsetX/dim[0], e.offsetY/dim[1] ];

const draw = gpu.make_frag_prog(gl, `
  ${await (await fetch('sdf.glsl')).text()}
  ${await (await fetch('hash.glsl')).text()}
  ${await (await fetch('helpers.glsl')).text()}
  ${await (await fetch('shader.glsl')).text()}`);

let itr = 0; const loop = () => { itr += 1; window.requestAnimationFrame(loop);
  gl.useProgram(draw); gl.viewport(0, 0, ...dim);
  gl.uniform2f(gl.getUniformLocation(draw, 'dim'), ...dim);
  gl.uniform2f(gl.getUniformLocation(draw, 'mouse'), mx, my);
  //gl.uniform2f(gl.getUniformLocation(draw, 'mouse'), 1.03, .47);
  gl.uniform1i(gl.getUniformLocation(draw, 'itr'), itr);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
}; loop();

