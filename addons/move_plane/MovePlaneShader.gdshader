shader_type spatial;

render_mode unshaded, depth_draw_never, cull_disabled;

uniform float alpha = 0.25;

void fragment() {
	ALPHA_SCISSOR = 0.0;
	
	float depth = FRAGCOORD.z;
	float screenDepth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0).r;
	
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
	vec4 screenUpos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, screenDepth * 2.0 - 1.0, 1.0);
	
	vec3 pxPos = upos.xyz / upos.w;
	vec3 screenPxPos = screenUpos.xyz / screenUpos.w;
	
	float isEdge = step(abs(screenPxPos.z - pxPos.z), 0.1);
	
	vec2 isBorderV = step(UV, vec2(0.002)) + step(vec2(0.997), UV);
	float isBorder = max(isBorderV.x, isBorderV.y);
	
	ALPHA = isEdge + isBorder + alpha;
	vec3 planeColor = mix(vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), float(FRONT_FACING));
	ALBEDO = mix(planeColor, vec3(0.0, 1.0, 0.0), isEdge);
	// ALBEDO = vec3(0.0, 1.0, 0.0);
}