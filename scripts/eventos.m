% function signal=eventos(EEG)
%% --- 1. Parámetros del usuario -------------------------------------------
umbral_separacion_s    = 0.5;    % [s] separación máxima entre pulsos de un mismo grupo
                                 %     (reales ~195 ms; entre grupos hay >2 s)
periodo_refractario_s  = 0.02;   % [s] dos eventos más cerca que esto = flancos del mismo pulso
latencia_minima_muestras = 10;   % eventos antes de esta muestra = artefacto inicial del canal

frecuencia_por_npulsos = [NaN, 8, 15, 23, 40];                    % [Hz]
etiqueta_por_npulsos   = {'inicio','8 Hz','15 Hz','23 Hz','40 Hz'};

%% --- 2. Obtener los pulsos reales ----------------------------------------
tipos_evento       = {EEG.event.type};
tipos_evento_texto = cellfun(@(x) char(string(x)), tipos_evento, 'UniformOutput', false);
latencias_todas    = round([EEG.event.latency]);

% Descartar boundary y el artefacto de la muestra 1
es_pulso_real = ~strcmp(tipos_evento_texto, 'boundary') & ...
                latencias_todas >= latencia_minima_muestras;

latencia_eventos_muestras = sort(latencias_todas(es_pulso_real));
tiempo_eventos_s = (latencia_eventos_muestras - 1) / EEG.srate;

% Quedarse con un solo evento por pulso (descartar el segundo flanco)
es_segundo_flanco = [false, diff(tiempo_eventos_s) < periodo_refractario_s];
tiempo_pulsos_s   = tiempo_eventos_s(~es_segundo_flanco);

fprintf('Eventos: %d -> pulsos: %d\n', numel(tiempo_eventos_s), numel(tiempo_pulsos_s));

%% --- 3. Agrupar pulsos por cercanía temporal -----------------------------
separacion_entre_pulsos_s = diff(tiempo_pulsos_s);
es_inicio_de_grupo = [true, separacion_entre_pulsos_s > umbral_separacion_s];

id_grupo_de_pulso = cumsum(es_inicio_de_grupo);
cant_grupos       = max(id_grupo_de_pulso);

pulsos_por_grupo       = accumarray(id_grupo_de_pulso(:), 1)';
t_primer_pulso_grupo_s = accumarray(id_grupo_de_pulso(:), tiempo_pulsos_s(:), [], @min)';
t_ultimo_pulso_grupo_s = accumarray(id_grupo_de_pulso(:), tiempo_pulsos_s(:), [], @max)';
%% --- 4. Validar y decodificar cada grupo ---------------------------------
% El primer grupo debe ser el de inicio (1 pulso)
if pulsos_por_grupo(1) ~= 1
    warning('El primer grupo tiene %d pulsos (se esperaba 1 = inicio).', pulsos_por_grupo(1));
end

% Los grupos siguientes deben tener entre 2 y 5 pulsos
grupos_invalidos = find(pulsos_por_grupo(2:end) < 2 | pulsos_por_grupo(2:end) > 5) + 1;
if ~isempty(grupos_invalidos)
    warning('Grupos con nº de pulsos inválido (esperado 2-5): %s', mat2str(grupos_invalidos));
end

% Grupo válido: 1 a 5 pulsos, y después del inicio no se acepta 1 pulso
grupo_valido = pulsos_por_grupo >= 1 & pulsos_por_grupo <= 5;
grupo_valido(2:end) = grupo_valido(2:end) & pulsos_por_grupo(2:end) >= 2;

% Etiqueta y frecuencia de cada grupo ('?' y NaN si no es válido)
etiqueta_grupo       = repmat({'?'}, cant_grupos, 1);
frecuencia_grupo_Hz  = nan(cant_grupos, 1);
etiqueta_grupo(grupo_valido)      = etiqueta_por_npulsos(pulsos_por_grupo(grupo_valido));
frecuencia_grupo_Hz(grupo_valido) = frecuencia_por_npulsos(pulsos_por_grupo(grupo_valido));

% Tabla resumen de la decodificación
tabla_grupos = table((1:cant_grupos)', t_primer_pulso_grupo_s(:), pulsos_por_grupo(:), ...
    etiqueta_grupo, frecuencia_grupo_Hz, ...
    'VariableNames', {'grupo','t_inicio_s','npulsos','etiqueta','frecuencia_Hz'});
disp(tabla_grupos)

%% --- 5. Tramos de estimulación (grupos de frecuencia) --------------------
cant_muestras = size(EEG.data, 2);

idx_grupos_frecuencia = 2:cant_grupos;             % se excluye el grupo 1 (inicio)

% Inicio del estímulo = último pulso del código (ajustar a t_primer_pulso_grupo_s
% si el estímulo arranca en el primer pulso del grupo)
t_inicio_estimulo_s = t_ultimo_pulso_grupo_s(idx_grupos_frecuencia);

% Fin del estímulo = primer pulso del grupo siguiente (o fin del registro en el último)
t_fin_estimulo_s = [t_primer_pulso_grupo_s(idx_grupos_frecuencia(2:end)), ...
                    cant_muestras / EEG.srate];

% Tramos en muestras: cada fila = [muestra_inicial, muestra_final]
tramos_muestras = round([t_inicio_estimulo_s(:), t_fin_estimulo_s(:)] * EEG.srate) + 1;
tramos_muestras(:,2) = min(tramos_muestras(:,2), cant_muestras);   % no pasarse del registro

frecuencia_tramo_Hz = frecuencia_grupo_Hz(idx_grupos_frecuencia);  % frecuencia de cada tramo

%% --- 6. Gráficos ---------------------------------------------------------
% 6.1) Pulsos individuales, con la cantidad de pulsos de cada grupo
figure;
stem(tiempo_pulsos_s, ones(size(tiempo_pulsos_s)), 'k', 'Marker', 'none'); hold on;
for g = 1:cant_grupos
    text(t_primer_pulso_grupo_s(g), 1.1, sprintf('%d', pulsos_por_grupo(g)), ...
        'HorizontalAlignment', 'left');
end
ylim([0 1.4]);
xlabel('Tiempo (s)'); ylabel('Pulso');
title('Pulsos y nº de pulsos por grupo');

% 6.2) Tipo de grupo (inicio / frecuencia) en el tiempo
figure;
stem(t_primer_pulso_grupo_s, pulsos_por_grupo, 'filled');
yticks(1:5); yticklabels(etiqueta_por_npulsos); ylim([0 5.5]);
xlabel('Tiempo (s)'); title('Inicio y frecuencia por grupo'); grid on;

% 6.3) Frecuencia de estimulación en el tiempo (escalones)
figure;
stairs(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'LineWidth', 1.5); hold on;
plot(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'ro');
xlabel('Tiempo (s)'); ylabel('Frecuencia (Hz)');
title('Frecuencia de estimulación'); grid on;
%%
%% --- DIAGNÓSTICO: cómo están separados los eventos ---
tipos_evento = {EEG.event.type};

% Convertir cada tipo a texto, sea numérico o char
tipos_evento_texto = cellfun(@(x) char(string(x)), tipos_evento, 'UniformOutput', false);

es_pulso_real = ~strcmp(tipos_evento_texto, 'boundary');
latencia_pulsos_muestras = sort(round([EEG.event(es_pulso_real).latency]));
tiempo_pulsos_s = (latencia_pulsos_muestras - 1) / EEG.srate;

fprintf('Frecuencia de muestreo: %g Hz\n', EEG.srate);
fprintf('Cantidad de eventos (sin boundary): %d\n', numel(tiempo_pulsos_s));

% Cuántos eventos hay de cada tipo
[tipos_distintos, ~, idx_tipo] = unique(tipos_evento_texto);
cantidad_por_tipo = accumarray(idx_tipo(:), 1);
for k = 1:numel(tipos_distintos)
    fprintf('  Tipo "%s": %d eventos\n', tipos_distintos{k}, cantidad_por_tipo(k));
end

separacion_ms = 1000 * diff(tiempo_pulsos_s);
disp('Primeros 30 eventos: latencia (muestras) y separación con el anterior (ms)')
disp([latencia_pulsos_muestras(1:30)', [NaN; separacion_ms(1:29)']])

figure;
histogram(separacion_ms(separacion_ms < 1000), 100);
xlabel('Separación entre eventos consecutivos (ms)'); ylabel('Cantidad');
title('Histograma de separaciones');