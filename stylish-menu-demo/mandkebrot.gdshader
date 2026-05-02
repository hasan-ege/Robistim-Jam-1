shader_type canvas_item;

// configuracion de colore
group_uniforms Colores;
uniform vec4 color_fondo : source_color = vec4(0.15, 0.25, 0.35, 1.0);
uniform vec4 color_linea : source_color = vec4(1.0, 1.0, 1.0, 0.15);
uniform vec4 color_picos : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// opcione de cuadro
group_uniforms Cuadricula;
uniform float tamano_cuadros : hint_range(0.01, 0.5) = 0.05;
uniform float grosor_linea : hint_range(0.0, 0.1) = 0.005;
uniform vec2 velocidad_fondo = vec2(0.1, 0.05); 
uniform float rotacion_cuadricula : hint_range(0.0, 360.0) = 0.0;

// oico
group_uniforms Picos;
uniform float cantidad_picos : hint_range(1.0, 50.0) = 12.0;
uniform float vel_picos_arriba : hint_range(-10.0, 10.0) = 1.5;
uniform float vel_picos_abajo : hint_range(-10.0, 10.0) = -1.5;

uniform float inclinacion_punta : hint_range(0.1, 0.9) = 0.5; 
uniform float intensidad_picos : hint_range(0.0, 1.2) = 0.4;
uniform float cierre_picos : hint_range(0.0, 1.0) = 0.0;
uniform float rotacion_picos : hint_range(-180.0, 180.0) = 0.0;

vec2 rotate_uv(vec2 uv, float degrees, float aspect) {
    float rad = radians(degrees);
    mat2 rotation_matrix = mat2(
        vec2(cos(rad), -sin(rad)),
        vec2(sin(rad), cos(rad))
    );
    vec2 p = uv - vec2(0.5 * aspect, 0.5);
    p = rotation_matrix * p;
    return p + vec2(0.5 * aspect, 0.5);
}

void fragment() {
    float aspect = (1.0 / SCREEN_PIXEL_SIZE).x / (1.0 / SCREEN_PIXEL_SIZE).y;
    vec2 uv_screen = vec2(UV.x * aspect, UV.y);

    vec2 uv_grid = rotate_uv(uv_screen, rotacion_cuadricula, aspect);
    uv_grid += TIME * velocidad_fondo;
    
    vec2 grid_pos = abs(mod(uv_grid, tamano_cuadros) - (tamano_cuadros * 0.5));
    float grid_line = max(
        step(grid_pos.x, tamano_cuadros * grosor_linea),
        step(grid_pos.y, tamano_cuadros * grosor_linea)
    );
    
    vec4 background_layer = mix(color_fondo, color_linea, grid_line * color_linea.a);

    // no entiendo bien que hacer para que no se redondeen los picos pipi
    vec2 uv_picos = rotate_uv(uv_screen, rotacion_picos, aspect);
    float x_base = (uv_picos.x / aspect) * cantidad_picos;
    
  
    float rampa_arriba = fract(x_base + (TIME * vel_picos_arriba));
    float forma_arriba = (rampa_arriba < inclinacion_punta) ? (rampa_arriba / inclinacion_punta) : ((1.0 - rampa_arriba) / (1.0 - inclinacion_punta));
    float rampa_abajo = fract(x_base + (TIME * vel_picos_abajo));
    float forma_abajo = (rampa_abajo < inclinacion_punta) ? (rampa_abajo / inclinacion_punta) : ((1.0 - rampa_abajo) / (1.0 - inclinacion_punta));
    
    float closure_offset = cierre_picos * 0.5;
    float upper_limit = (forma_arriba * intensidad_picos * (1.0 - cierre_picos)) + closure_offset;
    float lower_limit = 1.0 - (forma_abajo * intensidad_picos * (1.0 - cierre_picos)) - closure_offset;

    // visivilidad
    float visibility_mask = step(upper_limit, uv_picos.y) * step(uv_picos.y, lower_limit);

    COLOR = mix(color_picos, background_layer, visibility_mask);
}