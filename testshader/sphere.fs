#version 330

in vec2 fragCoord;
out vec4 fragColor;

uniform float iTime;
uniform vec3 iResolution;
uniform vec3 playerPosition; // Позиция игрока в 3D пространстве
uniform vec3 playerRotation; // Вращение игрока (pitch, yaw, roll)

#define GRID 8.
#define debug 10.
#define MAX_BOGEYS 32
#define NUM_BOGEY_COLORS 8
#define PI 3.141592653589793

struct BogeyData {
    vec3 position; // 3D позиция объекта
    int colorIndex;
    float size;
};

uniform BogeyData bogeys[MAX_BOGEYS];
uniform int bogeysCount;

// Цвета
vec3 gridColor = vec3(0.0, 1.0, 0.0);
vec3 sweepColor = vec3(1.0, 1.0, 0.0);
vec3 cursorColor = vec3(0.0, 0.8, 1.0);

vec3 bogeyColors[NUM_BOGEY_COLORS] = vec3[](
    vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0),
    vec3(0.0, 0.0, 1.0), vec3(1.0, 1.0, 0.0),
    vec3(1.0, 0.0, 1.0), vec3(0.0, 1.0, 1.0),
    vec3(1.0, 0.5, 0.0), vec3(0.5, 0.0, 1.0)
);

// Преобразование сферических координат в декартовы
vec3 sphericalToCartesian(float phi, float theta, float radius) {
    float x = radius * sin(theta) * cos(phi);
    float y = radius * sin(theta) * sin(phi);
    float z = radius * cos(theta);
    return vec3(x, y, z);
}

// Матрица вращения по оси X
mat3 rotateX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// Матрица вращения по оси Y
mat3 rotateY(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

// Матрица вращения по оси Z
mat3 rotateZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0
    );
}

// Проекция 3D точки на 2D экран с учетом перспективы
vec2 project3D(vec3 pos, float fov) {
    float factor = fov / (fov + pos.z);
    return pos.xy * factor;
}

// Функция для отрисовки точки на сфере
float drawBogey(vec2 uv, vec3 bogeyPos, float size, vec3 rotation) {
    // Применяем вращение к позиции объекта
    mat3 rot = rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z);
    vec3 rotatedPos = rot * bogeyPos;
    
    // Проецируем на 2D
    vec2 projPos = project3D(rotatedPos, 2.0);
    
    // Рисуем точку
    float d = length(uv - projPos);
    return smoothstep(size + 0.01, size, d);
}

// Функция для отрисовки сетки меридианов и параллелей
void drawGrid(vec2 uv, inout vec3 col, vec3 rotation) {
    float gridIntensity = 0.0;
    
    // Меридианы (долготы)
    for (float i = 0.0; i < PI * 2.0; i += PI / 8.0) {
        for (float j = 0.0; j < PI; j += 0.01) {
            vec3 pos = sphericalToCartesian(i, j, 1.0);
            vec2 projPos = project3D(rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z) * pos, 2.0);
            float d = length(uv - projPos);
            gridIntensity += exp(-d * 200.0) * 0.1;
        }
    }
    
    // Параллели (широты)
    for (float j = 0.0; j < PI; j += PI / 8.0) {
        for (float i = 0.0; i < PI * 2.0; i += 0.01) {
            vec3 pos = sphericalToCartesian(i, j, 1.0);
            vec2 projPos = project3D(rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z) * pos, 2.0);
            float d = length(uv - projPos);
            gridIntensity += exp(-d * 200.0) * 0.1;
        }
    }
    
    col += gridColor * gridIntensity;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    vec3 col = vec3(0.0);
    
    // Вращение сферы в зависимости от позиции игрока
    vec3 sphereRotation = vec3(
        -playerRotation.x, // pitch (наклон вверх/вниз)
        playerRotation.y,  // yaw (поворот влево/вправо)
        0.0               // roll (обычно не используется)
    );
    
    // Отрисовка сферической сетки
    if (debug > 2.) {
        drawGrid(uv, col, sphereRotation);
    }
    
    // Сканирующая линия (меридиан)
    if (debug > 2.) {
        float scanAngle = fract(iTime * 0.2) * PI * 2.0;
        for (float j = 0.0; j < PI; j += 0.01) {
            vec3 pos = sphericalToCartesian(scanAngle, j, 1.0);
            vec2 projPos = project3D(rotateX(sphereRotation.x) * rotateY(sphereRotation.y) * rotateZ(sphereRotation.z) * pos, 2.0);
            float d = length(uv - projPos);
            col += sweepColor * exp(-d * 500.0) * 2.0;
        }
    }
    
    // Отрисовка объектов
    for (int i = 0; i < bogeysCount; i++) {
        vec3 relPos = bogeys[i].position - playerPosition;
        float dist = length(relPos);
        vec3 normPos = relPos / dist;
        
        float b = drawBogey(uv, normPos, bogeys[i].size * (1.0 + 0.2 * sin(iTime * 2.0)), sphereRotation);
        int colorIdx = bogeys[i].colorIndex % NUM_BOGEY_COLORS;
        col += b * bogeyColors[colorIdx] * (1.0 + 0.5 * sin(iTime * 3.0));
    }
    
    // Центральный маркер игрока
    float cursor = exp(-length(uv) * 50.0) * 2.0;
    col += cursor * cursorColor;
    
    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
