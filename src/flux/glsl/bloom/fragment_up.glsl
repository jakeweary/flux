uniform sampler2D tPrev;
uniform sampler2D tCurr;
uniform int uCurrLvl;
in vec2 vUV;
out vec3 fColor;

void main() {
  vec3 prev = textureLod(tPrev, vUV, uCurrLvl + 1).rgb;
  vec3 curr = textureLod(tCurr, vUV, uCurrLvl).rgb;
  fColor = curr + prev;
}
