#version 330

// Входные данные
in vec2 fragCoord;
out vec4 fragColor;

// Параметры
uniform float time;
uniform sampler2D noise0;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform sampler2D noise3;

// Основная функция
void main() {
    vec2 uv = fragCoord / vec2(8192.0, 6144.0);
    
    // Генерация базового шума
    vec3 noise = texture(noise0, uv * 2.0).rgb;
    noise += texture(noise1, uv * 4.0).rgb * 0.5;
    noise += texture(noise2, uv * 8.0).rgb * 0.25;
    noise += texture(noise3, uv * 16.0).rgb * 0.125;
    
    // Создание звезд
    float stars = pow(texture(noise0, uv * 100.0).r, 100.0);
    
    // Цветовая палитра
    vec3 spaceColor = mix(
        vec3(0.05, 0.1, 0.2), 
        vec3(0.4, 0.3, 0.6), 
        noise.r * 2.0
    );
    
    // Добавляем звезды
    spaceColor += stars * vec3(1.0, 0.9, 0.8);
    
    // Финальный цвет
    fragColor = vec4(spaceColor, 1.0);
}
