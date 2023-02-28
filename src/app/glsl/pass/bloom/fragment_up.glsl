uniform sampler2D t_prev;
uniform sampler2D t_curr;
uniform int u_curr_lvl;
in vec2 v_uv;
out vec3 f_color;

void main() {
  vec3 prev = textureLod(t_prev, v_uv, u_curr_lvl + 1).rgb;
  vec3 curr = textureLod(t_curr, v_uv, u_curr_lvl).rgb;
  f_color = curr + prev;
}
