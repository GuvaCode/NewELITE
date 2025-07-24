#version 330

in vec3 fragPosition;
out vec4 finalColor;

uniform samplerCube environmentMap;

void main()
{
    vec3 texCoord = normalize(fragPosition);
    finalColor = texture(environmentMap, texCoord);
}
