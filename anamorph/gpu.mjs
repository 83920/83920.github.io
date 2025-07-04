
export const make_prog_basic = (gl, vsrc, fsrc) => {
  const [ p, vs, fs ] = [ gl.createProgram(), gl.createShader(gl.VERTEX_SHADER), gl.createShader(gl.FRAGMENT_SHADER) ];
  gl.shaderSource(vs, vsrc); gl.compileShader(vs); gl.attachShader(p, vs);
  gl.shaderSource(fs, fsrc); gl.compileShader(fs); gl.attachShader(p, fs);
  if (!gl.getShaderParameter(vs, gl.COMPILE_STATUS)) console.log('VS: ', gl.getShaderInfoLog(vs));
  if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) console.log('FS: ', gl.getShaderInfoLog(fs));
  gl.linkProgram(p); return p;
};

export const make_prog = (gl, vsrc, fsrc, precision='highp') => {
  return make_prog_basic(gl,
    `#version 300 es \n precision ${precision} float; precision ${precision} int;\n`+vsrc,
    `#version 300 es \n precision ${precision} float; precision ${precision} int;\n`+fsrc);
};

export const make_frag_prog = (gl, fsrc, precision='highp') => {
  return make_prog(gl, `void main() {
    if (gl_VertexID == 0) gl_Position = vec4(-1, -1, 0, 1);
    if (gl_VertexID == 1) gl_Position = vec4( 1, -1, 0, 1);
    if (gl_VertexID == 2) gl_Position = vec4(-1,  1, 0, 1);
    if (gl_VertexID == 3) gl_Position = vec4( 1,  1, 0, 1);
    if (gl_VertexID == 4) gl_Position = vec4(-1,  1, 0, 1);
    if (gl_VertexID == 5) gl_Position = vec4( 1, -1, 0, 1);
  }`, fsrc, precision);
};

export const make_tex = (gl, dims, ifrmt=gl.RGBA32F, frmt=gl.RGBA, dtype=gl.FLOAT) => {
  const type = dims.length == 2 ? gl.TEXTURE_2D : gl.TEXTURE_3D;
  const tex_buf = gl.createTexture();
  gl.bindTexture(type, tex_buf);
  if (dims.length == 2) gl.texImage2D(type, 0, ifrmt, dims[0], dims[1],          0, frmt, dtype, null);
  if (dims.length == 3) gl.texImage3D(type, 0, ifrmt, dims[0], dims[1], dims[2], 0, frmt, dtype, null);
  gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.NEAREST); gl.texParameteri(type, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.NEAREST); gl.texParameteri(type, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  //gl.texParameteri(type, gl.TEXTURE_MIN_FILTER, gl.LINEAR); gl.texParameteri(type, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  //gl.texParameteri(type, gl.TEXTURE_MAG_FILTER, gl.LINEAR); gl.texParameteri(type, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.bindTexture(type, null);
  return tex_buf;
};

export const bind_tex = (gl, prog, tex, name, idx=0, dim=2) => {
  gl.uniform1i(gl.getUniformLocation(prog, name), idx);
  gl.activeTexture(gl.TEXTURE0 + idx);
  gl.bindTexture(dim == 2 ? gl.TEXTURE_2D : gl.TEXTURE_3D, tex);
};

export const upload_tex = (gl, tex, img, frmt=gl.RGBA, dtype=gl.UNSIGNED_BYTE, flip=true) => {
  gl.bindTexture(gl.TEXTURE_2D, tex);
  if (flip) gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
  gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, frmt, dtype, img);
  if (flip) gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
  gl.bindTexture(gl.TEXTURE_2D, null);
};

export const upload_tex_3d = (gl, tex, data, dims) => {
  gl.bindTexture(gl.TEXTURE_3D, tex);
  gl.pixelStorei(gl.UNPACK_ALIGNMENT, 1);
  gl.texImage3D(gl.TEXTURE_3D, 0, gl.R8UI, ...dims, 0, gl.RED_INTEGER, gl.UNSIGNED_BYTE, data);
  gl.pixelStorei(gl.UNPACK_ALIGNMENT, 4);
  gl.bindTexture(gl.TEXTURE_3D, null);
};

export const capture_with_framebuffer = (gl, fb, texs, [ width, height ], callback) => {
  gl.bindFramebuffer(gl.FRAMEBUFFER, fb); let attachements = Array(texs.length);
  for (let i = 0; i < texs.length; i++) { attachements[i] = gl.COLOR_ATTACHMENT0+i;
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0+i, gl.TEXTURE_2D, texs[i], 0); }
  gl.drawBuffers(attachements);
  gl.viewport(0, 0, width, height);
  callback();
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
};

