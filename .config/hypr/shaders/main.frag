#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;

out vec4 fragColor;

void main() {
  vec4 color = texture(tex, v_texcoord);
  float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  float intensity = 0.6;
  vec3 desaturated = mix(color.rgb, vec3(gray), intensity);
  fragColor = vec4(desaturated, color.a);
}
