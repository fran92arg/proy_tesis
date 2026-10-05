%% ========================================================================
%  DECODIFICACIÓN DE EVENTOS EEG POR GRUPOS DE PULSOS
%  Secuencia esperada en EEG.event:
%    - evento aislado en la muestra 1 (artefacto del canal; se descarta)
%    - 1 grupo de 1 pulso     -> inicio del registro
%    - grupos de 2 a 5 pulsos -> frecuencia de estimulación
%         2 pulsos = 8 Hz | 3 = 15 Hz | 4 = 23 Hz | 5 = 40 Hz
%  Cada pulso genera 2 eventos separados 1 muestra (flanco de subida y de bajada).
%  Requiere la estructura EEG (continua) cargada en el workspace.
%
%  Salidas (todas 1 x cant_muestras, alineadas con EEG.data y vector_tiempo_s):
%    senal_pulsos         : 1 en la muestra de cada pulso
%    senal_codigo_grupo   : nº de pulsos del grupo, en el instante de su primer pulso
%    senal_frecuencia_Hz  : frecuencia de estimulación, constante durante cada tramo
%% ========================================================================

%% --- 1. Parámetros del usuario -------------------------------------------
umbral_separacion_s      = 0.5;    % [s] separación máxima entre pulsos de un mismo grupo
                                   %     (reales ~195 ms; entre grupos hay >2 s)
periodo_refractario_s    = 0.02;   % [s] dos eventos más cerca que esto = flancos del mismo pulso
latencia_minima_muestras = 10;     % eventos antes de esta muestra = artefacto inicial del canal

%% --- 2. Obtener los pulsos reales (un solo lazo, sin indexación lógica) ---
latencias_ordenadas_muestras = sort(round([EEG.event.latency]));        % [muestras], en orden temporal
tiempo_eventos_s = (latencias_ordenadas_muestras - 1) / EEG.srate;      % [s], muestra 1 = t 0
cant_eventos     = numel(tiempo_eventos_s);

tiempo_pulsos_s = [];        % instante de cada pulso (un solo evento por pulso)

for k = 1:cant_eventos

    % Descartar el artefacto inicial del canal
    if latencias_ordenadas_muestras(k) < latencia_minima_muestras
        continue             % pasa directamente al siguiente evento
    end

    % Un evento es pulso nuevo si es el primero que se conserva, o si está
    % suficientemente lejos del ÚLTIMO PULSO GUARDADO (si no, es su segundo flanco)
    es_primer_pulso = isempty(tiempo_pulsos_s);
    if es_primer_pulso || (tiempo_eventos_s(k) - tiempo_pulsos_s(end)) >= periodo_refractario_s
        tiempo_pulsos_s(end+1) = tiempo_eventos_s(k);
    end
end

cant_pulsos = numel(tiempo_pulsos_s);
fprintf('Eventos: %d -> pulsos: %d\n', cant_eventos, cant_pulsos);

%% --- 3. Agrupar pulsos (lazo for) ----------------------------------------
cant_grupos            = 0;
pulsos_por_grupo       = [];     % cantidad de pulsos de cada grupo
t_primer_pulso_grupo_s = [];     % [s] instante del primer pulso de cada grupo
t_ultimo_pulso_grupo_s = [];     % [s] instante del último pulso de cada grupo

for k = 1:cant_pulsos
    % Un pulso abre un grupo nuevo si es el primero o si está lejos del anterior
    abre_grupo_nuevo = (k == 1) || ...
        (tiempo_pulsos_s(k) - tiempo_pulsos_s(k-1)) > umbral_separacion_s;

    if abre_grupo_nuevo
        cant_grupos = cant_grupos + 1;
        pulsos_por_grupo(cant_grupos)       = 1;
        t_primer_pulso_grupo_s(cant_grupos) = tiempo_pulsos_s(k);
    else
        pulsos_por_grupo(cant_grupos) = pulsos_por_grupo(cant_grupos) + 1;
    end

    % El último pulso se va actualizando hasta que cierra el grupo
    t_ultimo_pulso_grupo_s(cant_grupos) = tiempo_pulsos_s(k);
end

%% --- 4. Decodificar cada grupo (switch) ----------------------------------
etiqueta_grupo      = repmat({'?'}, cant_grupos, 1);   % '?' = grupo no reconocido
frecuencia_grupo_Hz = nan(cant_grupos, 1);             % NaN = sin frecuencia

for g = 1:cant_grupos

    % El primer grupo debe ser el de inicio (1 pulso)
    if g == 1 && pulsos_por_grupo(g) ~= 1
        warning('El primer grupo tiene %d pulsos (se esperaba 1 = inicio).', pulsos_por_grupo(g));
    end

    switch pulsos_por_grupo(g)
        case 1
            if g == 1
                etiqueta_grupo{g} = 'inicio';
            else
                warning('Grupo %d (t = %.2f s): 1 pulso fuera del inicio.', g, t_primer_pulso_grupo_s(g));
            end
        case 2
            etiqueta_grupo{g}      = '8 Hz';
            frecuencia_grupo_Hz(g) = 8;
        case 3
            etiqueta_grupo{g}      = '15 Hz';
            frecuencia_grupo_Hz(g) = 15;
        case 4
            etiqueta_grupo{g}      = '23 Hz';
            frecuencia_grupo_Hz(g) = 23;
        case 5
            etiqueta_grupo{g}      = '40 Hz';
            frecuencia_grupo_Hz(g) = 40;
        otherwise
            warning('Grupo %d (t = %.2f s): %d pulsos, fuera de 1-5.', ...
                g, t_primer_pulso_grupo_s(g), pulsos_por_grupo(g));
    end
end

% Tabla resumen de la decodificación
tabla_grupos = table((1:cant_grupos)', t_primer_pulso_grupo_s(:), pulsos_por_grupo(:), ...
    etiqueta_grupo, frecuencia_grupo_Hz, ...
    'VariableNames', {'grupo','t_inicio_s','npulsos','etiqueta','frecuencia_Hz'});
disp(tabla_grupos)

%% --- 5. Tramos de estimulación (lazo for) --------------------------------
cant_muestras   = size(EEG.data, 2);              % 76800
vector_tiempo_s = (0:cant_muestras-1) / EEG.srate;  % 1 x cant_muestras, en segundos
cant_tramos     = cant_grupos - 1;                % se excluye el grupo 1 (inicio)

tramos_muestras     = zeros(cant_tramos, 2);      % cada fila = [muestra_inicial, muestra_final]
frecuencia_tramo_Hz = nan(cant_tramos, 1);

for i = 1:cant_tramos
    g = i + 1;                                    % grupo de frecuencia correspondiente

    % Inicio del estímulo = último pulso del código (usar t_primer_pulso_grupo_s
    % si el estímulo arranca en el primer pulso del grupo)
    t_inicio_estimulo_s = t_ultimo_pulso_grupo_s(g);

    % Fin del estímulo = primer pulso del grupo siguiente (o fin del registro)
    if g < cant_grupos
        t_fin_estimulo_s = t_primer_pulso_grupo_s(g + 1);
    else
        t_fin_estimulo_s = cant_muestras / EEG.srate;
    end

    muestra_inicial = round(t_inicio_estimulo_s * EEG.srate) + 1;   % muestra del pulso de inicio
    muestra_final   = round(t_fin_estimulo_s    * EEG.srate);       % última muestra antes del grupo siguiente

    tramos_muestras(i, :)  = [max(1, muestra_inicial), min(cant_muestras, muestra_final)];
    frecuencia_tramo_Hz(i) = frecuencia_grupo_Hz(g);
end

%% --- 6. Construir las señales de tamaño 1 x cant_muestras ----------------
senal_pulsos        = zeros(1, cant_muestras);    % 1 en cada pulso
senal_codigo_grupo  = zeros(1, cant_muestras);    % nº de pulsos del grupo, en su primer pulso
senal_frecuencia_Hz = zeros(1, cant_muestras);    % 0 = inicio / sin estímulo

% 6.1) Señal de pulsos
for k = 1:cant_pulsos
    muestra = round(tiempo_pulsos_s(k) * EEG.srate) + 1;     % tiempo -> nº de muestra
    if muestra >= 1 && muestra <= cant_muestras
        senal_pulsos(muestra) = 1;
    end
end

% 6.2) Señal de código por grupo
for g = 1:cant_grupos
    muestra = round(t_primer_pulso_grupo_s(g) * EEG.srate) + 1;
    if muestra >= 1 && muestra <= cant_muestras
        senal_codigo_grupo(muestra) = pulsos_por_grupo(g);
    end
end

% 6.3) Señal de frecuencia (escalón durante cada tramo)
for i = 1:cant_tramos
    senal_frecuencia_Hz(tramos_muestras(i,1):tramos_muestras(i,2)) = frecuencia_tramo_Hz(i);
end

fprintf('Tamaño vector de tiempo:   %d x %d\n', size(vector_tiempo_s));
fprintf('Tamaño señal de pulsos:    %d x %d\n', size(senal_pulsos));
fprintf('Tamaño señal de código:    %d x %d\n', size(senal_codigo_grupo));
fprintf('Tamaño señal de frecuencia: %d x %d\n', size(senal_frecuencia_Hz));

%% --- 7. Gráficos ---------------------------------------------------------
% 7.1) Pulsos individuales, con la cantidad de pulsos de cada grupo
figure;
stem(tiempo_pulsos_s, ones(size(tiempo_pulsos_s)), 'k', 'Marker', 'none'); hold on;
for g = 1:cant_grupos
    text(t_primer_pulso_grupo_s(g), 1.1, sprintf('%d', pulsos_por_grupo(g)), ...
        'HorizontalAlignment', 'left');
end
ylim([0 1.4]);
xlabel('Tiempo (s)'); ylabel('Pulso');
title('Pulsos y nº de pulsos por grupo');

% 7.2) Las tres señales, alineadas en el mismo eje de tiempo
figure;
subplot(3,1,1); stem(vector_tiempo_s(senal_pulsos > 0), senal_pulsos(senal_pulsos > 0), ...
    'k', 'Marker', 'none');
ylabel('Pulso'); title('Señal de pulsos'); xlim([0 vector_tiempo_s(end)]);

subplot(3,1,2); stem(vector_tiempo_s(senal_codigo_grupo > 0), senal_codigo_grupo(senal_codigo_grupo > 0), ...
    'filled');
ylabel('Nº pulsos'); title('Código por grupo'); xlim([0 vector_tiempo_s(end)]);

subplot(3,1,3); plot(vector_tiempo_s, senal_frecuencia_Hz, 'LineWidth', 1.5);
ylabel('Hz'); xlabel('Tiempo (s)'); title('Frecuencia de estimulación');
xlim([0 vector_tiempo_s(end)]); grid on;
