vec3 rotx(vec3 p, float ang) {
  return vec3(p.x, cos(ang)*p.y-sin(ang)*p.z, sin(ang)*p.y+cos(ang)*p.z); }
vec3 roty(vec3 p, float ang) {
  return vec3(cos(ang)*p.x+sin(ang)*p.z, p.y, -sin(ang)*p.x+cos(ang)*p.z); }
vec3 rotz(vec3 p, float ang) {
  return vec3(cos(ang)*p.x-sin(ang)*p.y, sin(ang)*p.x+cos(ang)*p.y, p.z); }

float sdf_box(vec3 p, vec3 b) { vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, vec3(0))); }
float sdf_torus(vec3 p, vec2 Rr) {
  return length(vec2(length(p.xz) - Rr.x, p.y)) - Rr.y; }
float sdf_capped_cylinder(vec3 p, vec2 hr) {
  float d1 = length(p.xz) - hr.y, d2 = abs(p.y) - hr.x;
  return min(max(d1, d2), 0.) + length(max(vec2(d1, d2), vec2(0)));
}

float sdf_plane(vec3 p, vec3 n, float d) { return dot(p, n) + d; }
float sdf_sphere(vec3 p, float r) { return length(p) - r; }
float sdf_union(float d1, float d2) { return min(d1, d2); }
float sdf_intersection(float d1, float d2) { return max(d1, d2); }
float sdf_subtract(float d1, float d2) { return max(d1, -d2); }
float sdf_smooth_union(float d1, float d2, float k) {
  float h = max(k - abs(d1 - d2), 0.) / k;
  return min(d1, d2) - h*h*k*.25;
}

float sdf_smooth_intersection(float d1, float d2, float k) {
  float h = max(k - abs(d1 - d2), 0.) / k;
  return max(d1, d2) + h*h*k*.25;
}

float sdf_smooth_subtract(float d1, float d2, float k) {
  float h = max(k - (d1 + d2), 0.) / k;
  return max(d1, -d2) + h*h*k*.25;
}

