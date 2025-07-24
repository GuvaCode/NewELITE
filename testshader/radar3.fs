#version 330

in vec2 fragCoord;
out vec4 fragColor;

uniform float iTime;
uniform vec3 iResolution;

#define GRID 8.
#define debug 10. // 0 to 10

struct BogeyData{
    vec2 center;
    float xDev;
    float yDev;
    float speed;
    float tOffset;
};

const BogeyData[] bogeys = BogeyData[](
    BogeyData(vec2( 0.5 ,0.6  ),  0.4,  0.3, 0.6,   0.0),
    BogeyData(vec2( 0.5 ,0.6  ),  0.4,  0.3, 0.6,   0.6),
    BogeyData(vec2( 0.5 ,0.6  ),  0.4,  0.3, 0.6,   1.2),
    BogeyData(vec2( 0.5 ,0.6  ),  0.4,  0.3, 0.6,   1.8),
    BogeyData(vec2( 0.5 ,0.6  ),  0.4,  0.3, 0.6,   2.4),
    BogeyData(vec2( 0.7 ,-0.3  ),  0.1,  0.3, 1.0,   0.0),
    BogeyData(vec2( 0.7 ,-0.3  ), 0.05, 0.25,-1.0,   0.2),
    BogeyData(vec2( 0.7 ,-0.3  ), 0.02,  0.1, 1.0,   0.0),
    BogeyData(vec2(-0.66 ,0.1 ),  0.25,  -0.5, 0.25,  1.0),
    BogeyData(vec2(-0.63,0.1  ),  0.25,  -0.5, 0.25,  0.5),
    BogeyData(vec2(-0.6 ,0.1  ),  0.25,  -0.5, 0.25,  0.0),
    BogeyData(vec2(-0.6 ,0.1  ),  0.25,  -0.5, 0.25,  1.0),
    BogeyData(vec2(-0.57,0.1  ),  0.25,  -0.5, 0.25,  0.5),
    BogeyData(vec2(-0.54 ,0.1 ),  0.25,  -0.5, 0.25,  1.0),
    BogeyData(vec2(-0.15 ,0.65),  0.3,  -0.4, 0.3,  1.0),
    BogeyData(vec2(0.3 ,-0.65 ), 0.27, -0.25, 0.1,  1.0),
    BogeyData(vec2(-0.3 ,-0.65 ), -0.27, 0.25, 0.5,  0.0)
);

// Цвета для разных элементов
vec3 gridColor = vec3(0.0, 1.0, 0.0);      // Зелёный для сетки
vec3 sweepColor = vec3(1.0, 1.0, 0.0);     // Жёлтый для вращающейся линии
vec3 bogeyColor = vec3(1.0, 0.0, 0.0);     // Красный для объектов
vec3 cursorColor = vec3(0.0, 0.8, 1.0);    // Голубой для курсора

float Hash21(vec2 p){
    p = fract(p*vec2(123.34,456.821));
    p += dot(p,p+45.32);
    return fract(p.x*p.y);
}

float noise(in vec2 p){
    vec2 i = vec2(floor(p));
    vec2 f = fract(p);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(Hash21(i + vec2(0.,0.)), Hash21(i + vec2(1.,0.)), u.x),
               mix(Hash21(i + vec2(0.,1.)), Hash21(i + vec2(1.,1.)), u.x), u.y);
}

vec2 radMap(vec2 uv){
    vec2 RadUv = vec2(0.,0.);
    RadUv.x = ((atan(uv.x,uv.y) * 0.15915494309189533576888376337251) ) +0.5;
    RadUv.y = length(uv);
    return RadUv;
}

vec2 project(vec2 uv, float amt){
    mat3 warp = mat3(1.0-amt/3.,0.0,0.0, 0.0,1.+amt,0.0, 0.0,0.-amt,1.0);
    vec3 w = (vec3(uv.xy,1.) *warp);
    return w.xy/w.z+vec2(0.,-amt*.5);
}

vec2 rotate(vec2 p, float rad){
    mat2 m = mat2(cos(rad), sin(rad), -sin(rad), cos(rad));
    return m * p;
}

float circle(vec2 uv, vec2 pos, float rad, float bloom){
    return smoothstep(1.-rad-bloom,1.-rad,1.-length(uv-pos));
}

float triangle(vec2 position, float halfWidth, float halfHeight){
    position.x = abs(position.x);
    position -= vec2(halfWidth, -halfHeight);
    vec2 e = vec2(-halfWidth, 2.0 * halfHeight);
    vec2 q = position - e * clamp(dot(position, e) / dot(e, e), 0.0, 1.0);
    float d = length(q);
    if(max(q.x, q.y) > 0.0) return d;
    return -min(d, position.y);
}

vec2 bogeyCoords(float bogeyTime, BogeyData b){
    if(debug<5.){
        b.speed*=8.;
        bogeyTime += b.tOffset *.2;
    } else {
        bogeyTime += b.tOffset;
    }
    return vec2(b.center.x+b.xDev*sin(bogeyTime*b.speed), b.center.y+b.yDev*cos(bogeyTime*b.speed*1.4));
}

float bogey(vec2 uv, float bogeyTime, BogeyData bD, float str){
    vec2 pos = bogeyCoords(bogeyTime, bD);
    str += .7;
    return circle(uv, pos, .021, 0.01) * str;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    
    if(debug>7.) uv = project(uv, .3+sin(iTime/10.)*.05);
    
    float c = 0.;
    float r = 0.;
    vec3 col = vec3(0.0);
    
    if(debug>8.) uv = rotate(uv, cos(iTime)/256.);
    
    vec2 uvr = uv;
    if(debug>3.) uvr = radMap(uv);
    
    if(debug>8.) uvr = uvr * vec2(1., 1.+sin(iTime)/256.);
    
    vec2 uvg = uv;
    uvg = fract(uvr*vec2(GRID*4., GRID));
    
    float tx = fract(iTime*.2);
    float scanStr = fract(uvr.x-tx);
    
    float bogeyTime = iTime*.2;
    if(debug>1.) bogeyTime = scanStr + bogeyTime;
    bogeyTime = uvr.x - bogeyTime;
    
    if(uvr.y < 1.1 && uvr.y > .1){
        float rings = 0.;
        float rays = 0.;
        float sweep = 0.;
        
        // Сетка (кольца и лучи)
        if(debug > 2.){
            rings += pow(1. - uvg.y, 4.) * .7 + step(.8, 1.-uvg.y) * .5;
            col += rings * gridColor; // Применяем цвет сетки
        }
        
        if(uvr.y < 1.02 && uvr.y > .125){
            rays += step(.9, 1.-uvg.x) * .7;
            rays += step(.9, uvg.x) * .7;
            col += rays * gridColor; // Применяем цвет сетки
            
            // Вращающаяся линия
            if(debug > 2.){
                sweep += pow(scanStr, 10.);
                sweep += step(.995, scanStr) * 2.;
                col += sweep * sweepColor; // Применяем цвет вращающейся линии
            }
            
            // Объекты на радаре
            for(int i = 0; i < bogeys.length(); i++){
                float b = bogey(uv, bogeyTime, bogeys[i], scanStr);
                col += b * bogeyColor; // Применяем цвет объектов
            }
        }
    }
    
    // Курсор в центре
    float cursor = 1.-smoothstep(0.0, 0.02, triangle(rotate(uv, cos(iTime)/8.), .03, .05));
    col += cursor * cursorColor;
    
    if(debug > 0.){
        float cursorLine = 1.-smoothstep(0.0, 0.03, triangle(rotate(uv, cos(iTime)/8.)+vec2(0., .05), .02, .002));
        col -= cursorLine * cursorColor;
    }
    
    fragColor = vec4(col, 1.0);
}

void main(){
    mainImage(fragColor, gl_FragCoord.xy);
}
