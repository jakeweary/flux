uniform sampler2D t_rendered;
uniform sampler2D t_feedback;
uniform float u_mix;
in vec2 v_uv;
out vec3 f_color;

void main() {
  vec3 r = texture(t_rendered, v_uv).rgb;
  vec3 f = texture(t_feedback, v_uv).rgb;
  f_color = mix(r, f, u_mix);
}
