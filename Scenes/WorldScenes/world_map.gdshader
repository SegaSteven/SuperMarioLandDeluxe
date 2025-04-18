shader_type canvas_item;

uniform sampler2D grayscaleImage;
uniform vec4 lowColor : source_color;
uniform vec4 midColor : source_color;
uniform vec4 highColor : source_color;
uniform vec4 HighestColor : source_color;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 grayscaleTexture = texture(grayscaleImage,UV);
	float grayscaleValue = grayscaleTexture.r;
	float alphaVaule = grayscaleTexture.a;

	vec4 color = mix(lowColor, midColor, grayscaleValue);
	color = mix(color, highColor, pow(grayscaleValue, 2.0));
	color = mix(color, HighestColor, pow(grayscaleValue, 2.0));

	color.a *= alphaVaule;

	COLOR = color;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
