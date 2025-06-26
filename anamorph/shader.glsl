uniform vec2 mouse;
uniform vec2 dim;
uniform int itr;
out vec4 ocol;

struct material {
  bool mirror;
  vec3 color;
};

const int BACKGROUND = 0;
const int MIRROR     = 1;
const int FLESH      = 2;
const int EYE_WHITE  = 3;
const int EYE_PUPIL  = 4;
const int LIPS       = 5;
const material materials[] = material[](
  material(false, vec3(.1)),               // background
  material(true,  vec3(1)),                // mirror
  material(false, vec3(.851, .659, .553)), // flesh
  material(false, vec3(.9)),               // eye white
  material(false, vec3(.1, .1, .1)),       // eye pupil
  material(false, vec3(.85, .56, .58))     // lips
);

vec2 sdf_sculpt(vec3 v) {
  float head1 = sdf_sphere(v, .7);
  float head2 = sdf_sphere(v-vec3(0, .5, 0), .7);
  float head3 = sdf_sphere(v-vec3(0, .38, -.4), .33);
  float head_ = sdf_subtract(sdf_smooth_union(head1, head2, .2), head3);
  vec2 head = vec2(head_, FLESH);
  float eye1 = sdf_sphere(v+vec3( .2, 0, .5), .25);
  float eye2 = sdf_sphere(v+vec3(-.2, 0, .5), .25);
  float eyes_ = sdf_subtract(sdf_union(eye1, eye2), head3);
  vec2 eyes = vec2(eyes_, EYE_WHITE);
  float pupil1 = sdf_sphere(v+vec3( .2, 0, .6), .155);
  float pupil2 = sdf_sphere(v+vec3(-.2, 0, .6), .155);
  float pupils_ = sdf_union(pupil1, pupil2);
  vec2 pupils = vec2(pupils_, EYE_PUPIL);
  float mouth_ = sdf_torus(rotx(v, 6.28/4.)*vec3(1, 1., 1.2)-vec3(0, .67, .45), vec2(.15, .05));
  vec2 mouth = vec2(mouth_, LIPS);

  const int N = 4;
  vec2 parts[N] = vec2[N](
    head,
    eyes,
    pupils,
    mouth
  );
  float m = 10000.;
  for (int i = 0; i < N; i++) m = min(m, parts[i].x);
  for (int i = 0; i < N; i++) if (m == parts[i].x) return parts[i];
}

vec2 sdf_mirror(vec3 v) {
  v = roty(rotx(v, 1.5), 2.);
  float mirror1 = sdf_sphere(v*vec3(1, 1.5, 1), .5);
  float mirror2 = sdf_sphere(v*vec3(1, 1, 1.5), .5);
  return vec2(sdf_smooth_union(mirror1, mirror2, .1), MIRROR);
}

vec2 sdf(vec3 v) {
  vec2 sculpt = sdf_sculpt(roty(v+vec3(-.8, 0, 0), -1.2));
  vec2 mirror = sdf_mirror(v+vec3(.8, 0, 0));

  float m = min(sculpt.x, mirror.x);
  if (m == sculpt.x) return sculpt;
  if (m == mirror.x) return mirror;
}

vec3 sdf_normal(vec3 p) { float eps = .0001;
  return normalize(vec3(
    sdf(p+vec3(eps, 0, 0)).x - sdf(p-vec3(eps, 0, 0)).x,
    sdf(p+vec3(0, eps, 0)).x - sdf(p-vec3(0, eps, 0)).x,
    sdf(p+vec3(0, 0, eps)).x - sdf(p-vec3(0, 0, eps)).x));
}

vec2 ray_march(vec3 ray_orig, vec3 ray_dir) {
  float t = 0., max_t = 10.;
  for (int i = 0; i < 60; i++) {
    vec3 p = ray_orig + t*ray_dir;
    vec2 s = sdf(p); t += s.x;
    if (s.x < .0001) return vec2(t, s.y);
    if (t > max_t) break;
  }

  return vec2(max_t, BACKGROUND);
}

vec3 scene_color(vec3 ray_orig, vec3 ray_dir) {
  const vec3 light_pos = vec3(0, 0, 3);

  int num_steps = 5; vec3 avg_col = vec3(0);
  for (int i = 0; i < num_steps; i++) {
    vec3 jittered_dir = normalize(ray_dir + (hash33(vec3(ray_dir.xy*10., i))*2.-1.)*.003);
    //vec3 jittered_dir = normalize(ray_dir + (hash33(vec3(ray_dir.xy*10., i))*2.-1.)*.0);
    vec2 ret = ray_march(ray_orig, jittered_dir);
    vec3 p = ray_orig+ret.x*ray_dir;
    vec3 normal = sdf_normal(p);
    material m = materials[int(ret.y)];
    if (m.mirror) {
      ret = ray_march(p+normal*.01, normalize(reflect(ray_dir, normal)));
    }

    m = materials[int(ret.y)];
    if (ret.x >= 0.) {
      vec3 light_dir = normalize(p - light_pos);
      float shading = max(.1, dot(normal, light_dir));
      avg_col += m.color * shading;
      //avg_col += normal*.5+.5;
      //avg_col += .5*vec3(distance(ray_orig, p));
    }
  }

  return avg_col/float(num_steps);
}

void main() {
  vec2 xy = gl_FragCoord.xy/dim;// * vec2(1, dim[1]/dim[0]);
  vec3 camera_pos = rotx(roty(vec3(0, 0, 2), mouse.x*6.28), mouse.y*6.28);
  vec3 ray_dir = normalize(rotx(roty(vec3(xy*2.-1., -1.), mouse.x*6.28), mouse.y*6.28));
  //vec3 camera_pos = roty(vec3(0, 0, 2), mouse.x*6.28);
  //vec3 ray_dir = normalize(roty(vec3(xy*2.-1., -1.), mouse.x*6.28));
  vec3 col = scene_color(camera_pos, ray_dir);
  ocol = vec4(col, 1);
}

