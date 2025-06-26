
//// sdf 2d ////

float sdf_box(vec2 p, vec2 b) { vec2 d = abs(p) - b;
  return length(max(d, vec2(0.))) + min(max(d.x, d.y), 0.);
}

float sdf_triangle(vec2 p) {
  const float k = sqrt(3.);
  p.x = abs(p.x) - 1.;
  p.y = p.y + 1. / k;
  if (p.x + k * p.y > 0.) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.;
  p.x -= clamp(p.x, -2., 0.);
  return -length(p) * sign(p.y);
}

float sdf_capsule(vec2 p, vec2 a, vec2 b, float r) {
  vec2 pa = p - a, ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
  return length(pa - ba * h) - r;
}

float sdf_circle(vec2 p, float radius) { return length(p) - radius; }
//float sdf_intersection(float d1, float d2) { return max(d1, d2); }
//float sdf_subtract(float d1, float d2) { return max(d1, -d2); }
//float sdf_union(float d1, float d2) { return min(d1, d2); }

//// misc ////

vec3 rot_z(vec3 v, float ang) {
  return mat3(cos(ang), 0., -sin(ang), 0., 1., 0., sin(ang), 0., cos(ang)) * v;
}

vec3 rot_y(vec3 v, float ang) {
  return mat3(1., 0., 0., 0., cos(ang), -sin(ang), 0., sin(ang), cos(ang)) * v;
}

// plane pt becomes ray_orig + ray_dir * t
float ray_plane_intersection(vec3 ray_orig, vec3 ray_dir, vec3 plane_pt, vec3 plane_normal) {
  float denom = dot(ray_dir, plane_normal);
  if (abs(denom) < .000001) return -1.;
  return dot(plane_pt - ray_orig, plane_normal) / denom;
}

float bilerp(float v00, float v10, float v01, float v11, vec2 f) {
  return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

vec2 bilerp2(vec2 v00, vec2 v10, vec2 v01, vec2 v11, vec2 f) {
  return vec2(bilerp(v00.x, v10.x, v01.x, v11.x, f), bilerp(v00.y, v10.y, v01.y, v11.y, f));
}

vec3 bilerp3(vec3 v00, vec3 v10, vec3 v01, vec3 v11, vec2 f) {
  return vec3(bilerp(v00.x, v10.x, v01.x, v11.x, f),
              bilerp(v00.y, v10.y, v01.y, v11.y, f),
              bilerp(v00.z, v10.z, v01.z, v11.z, f));
}

float dist_to_tri(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2) {
  vec2 e0 = p1-p0, v0 = p-p0, e1 = p2-p1, v1 = p-p1, e2 = p0-p2, v2 = p-p2;
  float s = e0.x*e2.y - e0.y*e2.x;
  if (max(max(s*(v0.y*e0.x-v0.x*e0.y), s*(v1.y*e1.x-v1.x*e1.y)), s*(v2.y*e2.x-v2.x*e2.y)) < 0.)
    return -1.;
  vec2 pq0 = v0 - e0*clamp(dot(v0, e0)/dot(e0, e0), 0., 1.);
  vec2 pq1 = v1 - e1*clamp(dot(v1, e1)/dot(e1, e1), 0., 1.);
  vec2 pq2 = v2 - e2*clamp(dot(v2, e2)/dot(e2, e2), 0., 1.);
  float ds0 = dot(pq0, pq0), ds1 = dot(pq1, pq1), ds2 = dot(pq2, pq2);
  vec2 q = p - ((ds0<ds1 && ds0<ds2) ? pq0 : (ds1<ds2) ? pq1 : pq2 );
  return distance(q, p);
}

vec4 barycentric(vec2 p, vec2 a, vec2 b, vec2 c) {
  float denom = (b.x-a.x)*(c.y-b.y)+(a.y-b.y)*(c.x-b.x);
  float alpha = ((b.x-p.x)*(c.y-b.y)+(p.y-b.y)*(c.x-b.x))/denom;
  float beta = ((c.x-p.x)*(a.y-c.y)+(p.y-c.y)*(a.x-c.x))/denom;
  float gamma = 1.-alpha-beta;
  float is_in_tri = 0. <= alpha && alpha <= 1. && 0. <= beta && beta <= 1. && 0. <= gamma ? 1. : -1.;
  return vec4(is_in_tri, alpha, beta, 1.-alpha-beta);
}

ivec3 ixyz_from_idx(int idx, ivec3 gdim) {
  return ivec3(idx%gdim.x, (idx/gdim.x)%gdim.y, (idx/gdim.x)/gdim.y);
}

ivec2 ixy_from_idx(int idx, ivec2 dim) {
  return ivec2(idx%dim.x, idx/dim.x);
}

int idx_from_ixyz(ivec3 p, ivec3 gdim) {
  return p.x + p.y*gdim.x + p.z*gdim.x*gdim.y;
}

int idx_from_ixy(ivec2 p, ivec2 dim) {
  return p.x + p.y*dim.x;
}

ivec3 ixyz_from_ixy(ivec2 ixy, ivec2 dim, ivec3 gdim) {
  return ixyz_from_idx(idx_from_ixy(ixy, dim), gdim);
}

ivec2 ixy_from_ixyz(ivec3 ixyz, ivec2 dim, ivec3 gdim) {
  return ixy_from_idx(idx_from_ixyz(ixyz, gdim), dim);
}

//// perlin ////

vec2 grad_perlin(vec2 c, float seed) {
  float h = hash13(vec3(c, seed)) * 6.283;
  return vec2(cos(h), sin(h));
}

float perlin2D_once(vec2 p, float seed) { // assumes access to hash.glsl
  vec2 i = floor(p), f = fract(p);
  vec2 u = f*f*f*(f*(f*6. - 15.) + 10.);
  float n00 = dot(grad_perlin(i + vec2(0.), seed), f - vec2(0.));
  float n10 = dot(grad_perlin(i + vec2(1., 0.), seed), f - vec2(1., 0.));
  float n01 = dot(grad_perlin(i + vec2(0., 1.), seed), f - vec2(0., 1.));
  float n11 = dot(grad_perlin(i + vec2(1.), seed), f - vec2(1., 1.));
  return bilerp(n00, n10, n01, n11, u)*1.414;
}

float perlin2D(vec2 p, int octaves, float lacunarity, float gain, float seed) {
  float sum = 0., amplitude = 1., frequency = 1.;
  for (int i = 0; i < octaves; i++) {
    sum += perlin2D_once(p * frequency, seed) * amplitude;
    frequency *= lacunarity;
    amplitude *= gain;
  }

  float norm = (1. - pow(gain, float(octaves))) / (1. - gain);
  return (sum / norm)*.5+.5;
}

