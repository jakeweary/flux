uniform sampler2D t_src;
uniform int u_src_lvl;
uniform vec2 u_direction;
in vec2 v_uv;
out vec3 f_color;

const int KERNEL_SIZE = int(ceil(KERNEL_SCALE * SIGMA));

// https://www.desmos.com/calculator/qe9uixx0a2
float gauss(float x) {
  const float k1 = 1.0 / (SIGMA * sqrt(radians(360.0)));
  const float k2 = 0.5 / (SIGMA * SIGMA);
  return k1 * exp(-k2 * x * x);
}

void main() {
  vec2 px = u_direction / vec2(textureSize(t_src, u_src_lvl));
  vec3 acc = gauss(0.0) * textureLod(t_src, v_uv, u_src_lvl).rgb;

  #if BILINEAR_OPTIMIZATION
    // https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
    for (int i = 1; i <= KERNEL_SIZE; i += 2) {
      float x = float(i), w1 = gauss(x), w2 = gauss(x + 1.0);
      float x_linear = x + w2 / (w1 + w2);
      vec3 a = textureLod(t_src, v_uv - x_linear * px, u_src_lvl).rgb;
      vec3 b = textureLod(t_src, v_uv + x_linear * px, u_src_lvl).rgb;
      acc += (w1 + w2) * (a + b);
    }
  #else
    for (int i = 1; i <= KERNEL_SIZE; i += 1) {
      float x = float(i);
      vec3 a = textureLod(t_src, v_uv - x * px, u_src_lvl).rgb;
      vec3 b = textureLod(t_src, v_uv + x * px, u_src_lvl).rgb;
      acc += gauss(x) * (a + b);
    }
  #endif

  f_color = acc;
}
