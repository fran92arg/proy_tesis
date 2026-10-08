% % function signal=eventos(EEG)
% %% --- 1. Parámetros del usuario -------------------------------------------
% umbral_separacion_s    = 0.5;    % [s] separación máxima entre pulsos de un mismo grupo
%                                  %     (reales ~195 ms; entre grupos hay >2 s)
% periodo_refractario_s  = 0.02;   % [s] dos eventos más cerca que esto = flancos del mismo pulso
% latencia_minima_muestras = 10;   % eventos antes de esta muestra = artefacto inicial del canal
% 
% frecuencia_por_npulsos = [NaN, 8, 15, 23, 40];                    % [Hz]
% etiqueta_por_npulsos   = {'inicio','8 Hz','15 Hz','23 Hz','40 Hz'};
% 
% %% --- 2. Obtener los pulsos reales ----------------------------------------
% tipos_evento       = {EEG.event.type};
% tipos_evento_texto = cellfun(@(x) char(string(x)), tipos_evento, 'UniformOutput', false);
% latencias_todas    = round([EEG.event.latency]);
% 
% % Descartar boundary y el artefacto de la muestra 1
% es_pulso_real = ~strcmp(tipos_evento_texto, 'boundary') & ...
%                 latencias_todas >= latencia_minima_muestras;
% 
% latencia_eventos_muestras = sort(latencias_todas(es_pulso_real));
% tiempo_eventos_s = (latencia_eventos_muestras - 1) / EEG.srate;
% 
% % Quedarse con un solo evento por pulso (descartar el segundo flanco)
% es_segundo_flanco = [false, diff(tiempo_eventos_s) < periodo_refractario_s];
% tiempo_pulsos_s   = tiempo_eventos_s(~es_segundo_flanco);
% 
% fprintf('Eventos: %d -> pulsos: %d\n', numel(tiempo_eventos_s), numel(tiempo_pulsos_s));
% 
% %% --- 3. Agrupar pulsos por cercanía temporal -----------------------------
% separacion_entre_pulsos_s = diff(tiempo_pulsos_s);
% es_inicio_de_grupo = [true, separacion_entre_pulsos_s > umbral_separacion_s];
% 
% id_grupo_de_pulso = cumsum(es_inicio_de_grupo);
% cant_grupos       = max(id_grupo_de_pulso);
% 
% pulsos_por_grupo       = accumarray(id_grupo_de_pulso(:), 1)';
% t_primer_pulso_grupo_s = accumarray(id_grupo_de_pulso(:), tiempo_pulsos_s(:), [], @min)';
% t_ultimo_pulso_grupo_s = accumarray(id_grupo_de_pulso(:), tiempo_pulsos_s(:), [], @max)';
% 
% %% --- 4. Validar y decodificar cada grupo ---------------------------------
% % El primer grupo debe ser el de inicio (1 pulso)
% if pulsos_por_grupo(1) ~= 1
%     warning('El primer grupo tiene %d pulsos (se esperaba 1 = inicio).', pulsos_por_grupo(1));
% end
% 
% % Los grupos siguientes deben tener entre 2 y 5 pulsos
% grupos_invalidos = find(pulsos_por_grupo(2:end) < 2 | pulsos_por_grupo(2:end) > 5) + 1;
% if ~isempty(grupos_invalidos)
%     warning('Grupos con nº de pulsos inválido (esperado 2-5): %s', mat2str(grupos_invalidos));
% end
% 
% % Grupo válido: 1 a 5 pulsos, y después del inicio no se acepta 1 pulso
% grupo_valido = pulsos_por_grupo >= 1 & pulsos_por_grupo <= 5;
% grupo_valido(2:end) = grupo_valido(2:end) & pulsos_por_grupo(2:end) >= 2;
% 
% % Etiqueta y frecuencia de cada grupo ('?' y NaN si no es válido)
% etiqueta_grupo       = repmat({'?'}, cant_grupos, 1);
% frecuencia_grupo_Hz  = nan(cant_grupos, 1);
% etiqueta_grupo(grupo_valido)      = etiqueta_por_npulsos(pulsos_por_grupo(grupo_valido));
% frecuencia_grupo_Hz(grupo_valido) = frecuencia_por_npulsos(pulsos_por_grupo(grupo_valido));
% 
% % Tabla resumen de la decodificación
% tabla_grupos = table((1:cant_grupos)', t_primer_pulso_grupo_s(:), pulsos_por_grupo(:), ...
%     etiqueta_grupo, frecuencia_grupo_Hz, ...
%     'VariableNames', {'grupo','t_inicio_s','npulsos','etiqueta','frecuencia_Hz'});
% disp(tabla_grupos)
% 
% %% --- 5. Tramos de estimulación (grupos de frecuencia) --------------------
% cant_muestras = size(EEG.data, 2);
% 
% idx_grupos_frecuencia = 2:cant_grupos;             % se excluye el grupo 1 (inicio)
% 
% % Inicio del estímulo = último pulso del código (ajustar a t_primer_pulso_grupo_s
% % si el estímulo arranca en el primer pulso del grupo)
% t_inicio_estimulo_s = t_ultimo_pulso_grupo_s(idx_grupos_frecuencia);
% 
% % Fin del estímulo = primer pulso del grupo siguiente (o fin del registro en el último)
% t_fin_estimulo_s = [t_primer_pulso_grupo_s(idx_grupos_frecuencia(2:end)), ...
%                     cant_muestras / EEG.srate];
% 
% % Tramos en muestras: cada fila = [muestra_inicial, muestra_final]
% tramos_muestras = round([t_inicio_estimulo_s(:), t_fin_estimulo_s(:)] * EEG.srate) + 1;
% tramos_muestras(:,2) = min(tramos_muestras(:,2), cant_muestras);   % no pasarse del registro
% 
% frecuencia_tramo_Hz = frecuencia_grupo_Hz(idx_grupos_frecuencia);  % frecuencia de cada tramo
% 
% %% --- 6. Gráficos ---------------------------------------------------------
% % 6.1) Pulsos individuales, con la cantidad de pulsos de cada grupo
% figure;
% stem(tiempo_pulsos_s, ones(size(tiempo_pulsos_s)), 'k', 'Marker', 'none'); hold on;
% for g = 1:cant_grupos
%     text(t_primer_pulso_grupo_s(g), 1.1, sprintf('%d', pulsos_por_grupo(g)), ...
%         'HorizontalAlignment', 'left');
% end
% ylim([0 1.4]);
% xlabel('Tiempo (s)'); ylabel('Pulso');
% title('Pulsos y nº de pulsos por grupo');
% 
% % 6.2) Tipo de grupo (inicio / frecuencia) en el tiempo
% figure;
% stem(t_primer_pulso_grupo_s, pulsos_por_grupo, 'filled');
% yticks(1:5); yticklabels(etiqueta_por_npulsos); ylim([0 5.5]);
% xlabel('Tiempo (s)'); title('Inicio y frecuencia por grupo'); grid on;
% 
% % 6.3) Frecuencia de estimulación en el tiempo (escalones)
% figure;
% stairs(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'LineWidth', 1.5); hold on;
% plot(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'ro');
% xlabel('Tiempo (s)'); ylabel('Frecuencia (Hz)');
% title('Frecuencia de estimulación'); grid on;
%% ========================================================================
%  DECODIFICACIÓN DE EVENTOS EEG POR GRUPOS DE PULSOS
%  Secuencia esperada:
%    - boundary y artefacto inicial del canal (se descartan)
%    - 1 grupo de 1 pulso     -> inicio del registro
%    - grupos de 2 a 5 pulsos -> frecuencia de estimulación
%         2 pulsos = 8 Hz | 3 = 15 Hz | 4 = 23 Hz | 5 = 40 Hz
%  Requiere la estructura EEG (continua) cargada en el workspace.
%% ========================================================================

%% --- 1. Parámetros del usuario -------------------------------------------
umbral_separacion_s      = 0.5;    % [s] separación máxima entre pulsos de un mismo grupo
                                   %     (reales ~195 ms; entre grupos hay >2 s)
periodo_refractario_s    = 0.02;   % [s] dos eventos más cerca que esto = flancos del mismo pulso
latencia_minima_muestras = 10;     % eventos antes de esta muestra = artefacto inicial del canal

% Solo para rotular los gráficos (posición = nº de pulsos del grupo)
etiquetas_grafico = {'inicio','8 Hz','15 Hz','23 Hz','40 Hz'};

%% --- 2. Obtener los pulsos reales ----------------------------------------
% tipos_evento       = {EEG.event.type};
% % tipos_evento_texto = cellfun(@(x) char(string(x)), tipos_evento, 'UniformOutput', false);
% cant_eventos = length(tipos_evento);
% tipos_evento_texto = cell(1, cant_eventos);
% for k = 1:cant_eventos
%     tipos_evento_texto{k} = char(string(tipos_evento{k}));
% end
% latencias_todas    = round([EEG.event.latency]);
% 
% % Descartar boundary y el artefacto de la muestra 1
% es_pulso_real = ~strcmp(tipos_evento_texto, 'boundary') & ...
%                 latencias_todas >= latencia_minima_muestras;
% 
% latencia_eventos_muestras = sort(latencias_todas(es_pulso_real));
% tiempo_eventos_s = (latencia_eventos_muestras - 1) / EEG.srate;
% 
% % Quedarse con un solo evento por pulso (descartar el segundo flanco)
% es_segundo_flanco = [false, diff(tiempo_eventos_s) < periodo_refractario_s];
% tiempo_pulsos_s   = tiempo_eventos_s(~es_segundo_flanco);
% 
% cant_pulsos = numel(tiempo_pulsos_s);
% fprintf('Eventos: %d -> pulsos: %d\n', numel(tiempo_eventos_s), cant_pulsos);
%% --- 2. Obtener los pulsos reales ----------------------------------------
latencias_todas = round([EEG.event.latency]);

% Descartar el artefacto inicial del canal (muestra 1)
es_pulso_real = latencias_todas >= latencia_minima_muestras;

latencia_eventos_muestras = sort(latencias_todas(es_pulso_real));
tiempo_eventos_s = (latencia_eventos_muestras - 1) / EEG.srate;

% Quedarse con un solo evento por pulso (descartar el segundo flanco)
% es_segundo_flanco = [false, diff(tiempo_eventos_s) < periodo_refractario_s];
cant_eventos      = numel(tiempo_eventos_s);
es_segundo_flanco = false(1, cant_eventos);      % preasignado: nadie es duplicado por defecto

for k = 2:cant_eventos                           % el evento 1 nunca puede ser duplicado
    separacion_s = tiempo_eventos_s(k) - tiempo_eventos_s(k-1);
    if separacion_s < periodo_refractario_s
        es_segundo_flanco(k) = true;
    end
end

% tiempo_pulsos_s = tiempo_eventos_s(~es_segundo_flanco);
tiempo_pulsos_s   = tiempo_eventos_s(~es_segundo_flanco);

cant_pulsos = numel(tiempo_pulsos_s);
fprintf('Eventos: %d -> pulsos: %d\n', numel(tiempo_eventos_s), cant_pulsos);
%% --- 3. Agrupar pulsos (lazo for) ----------------------------------------
cant_grupos            = 0;
pulsos_por_grupo       = [];     % cantidad de pulsos de cada grupo
t_primer_pulso_grupo_s = [];     % [s] instante del primer pulso de cada grupo
t_ultimo_pulso_grupo_s = [];     % [s] instante del último pulso de cada grupo

for k = 1:cant_pulsos
    % Un pulso abre un grupo nuevo si es el primero o si está lejos del anterior
    abre_grupo_nuevo = (k == 1) ||  (tiempo_pulsos_s(k) - tiempo_pulsos_s(k-1)) > umbral_separacion_s;

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
%     if g == 1 && pulsos_por_grupo(g) ~= 1
%         warning('El primer grupo tiene %d pulsos (se esperaba 1 = inicio).', pulsos_por_grupo(g));
%     end

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
cant_muestras = size(EEG.data, 2);
cant_tramos   = cant_grupos - 1;                  % se excluye el grupo 1 (inicio)

tramos_muestras     = zeros(cant_tramos, 2);      % cada fila = [muestra_inicial, muestra_final]
frecuencia_tramo_Hz = nan(cant_tramos, 1);

for i = 1:cant_tramos
    g = i + 1;                                    % grupo de frecuencia correspondiente

    % Inicio del estímulo = último pulso del código (usar t_primer_pulso_grupo_s
    % si el estímulo arranca en el primer pulso del grupo)
    t_inicio_estimulo_s = t_primer_pulso_grupo_s(g);

    % Fin del estímulo = primer pulso del grupo siguiente (o fin del registro)
    if g < cant_grupos
        t_fin_estimulo_s = t_primer_pulso_grupo_s(g + 1);
    else
        t_fin_estimulo_s = cant_muestras / EEG.srate;
    end

    muestra_inicial = round(t_inicio_estimulo_s * EEG.srate) + 1;
    muestra_final   = round(t_fin_estimulo_s    * EEG.srate) + 1;

    tramos_muestras(i, :)     = [min(muestra_inicial, cant_muestras),min(muestra_final,   cant_muestras)];
    frecuencia_tramo_Hz(i)    = frecuencia_grupo_Hz(g);
end

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
yticks(1:5); yticklabels(etiquetas_grafico); ylim([0 5.5]);
xlabel('Tiempo (s)'); title('Inicio y frecuencia por grupo'); grid on;

% 6.3) Frecuencia de estimulación en el tiempo (escalones)
figure;
stairs(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'LineWidth', 1.5); hold on;
plot(tramos_muestras(:,1) / EEG.srate, frecuencia_tramo_Hz, 'ro');
xlabel('Tiempo (s)'); ylabel('Frecuencia (Hz)');
title('Frecuencia de estimulación'); grid on;
%%
%% --- Un solo impulso por grupo, con su etiqueta de frecuencia -------------
cant_muestras = size(EEG.data, 2);                       % 76800

% Qué pulso representa al grupo: primero o último (ajustar según el protocolo)
t_evento_grupo_s = t_primer_pulso_grupo_s;               % o t_ultimo_pulso_grupo_s

senal_evento_codigo = zeros(1, cant_muestras);           % valor = nº de pulsos del grupo (1..5)
senal_evento_Hz     = zeros(1, cant_muestras);           % valor = frecuencia en Hz (0 = sin frecuencia)
muestra_evento      = zeros(cant_grupos, 1);             % muestra donde cae cada grupo

for g = 1:cant_grupos
    muestra = round(t_evento_grupo_s(g) * EEG.srate) + 1;    % tiempo -> nº de muestra
    muestra_evento(g) = muestra;

    if muestra >= 1 && muestra <= cant_muestras
        senal_evento_codigo(muestra) = pulsos_por_grupo(g);

        if ~isnan(frecuencia_grupo_Hz(g))                    % el grupo de inicio no tiene frecuencia
            senal_evento_Hz(muestra) = frecuencia_grupo_Hz(g);
        end
    end
end

% Tabla que conserva la etiqueta de texto de cada evento
tabla_eventos = table((1:cant_grupos)', muestra_evento, t_evento_grupo_s(:), ...
    pulsos_por_grupo(:), etiqueta_grupo, frecuencia_grupo_Hz, ...
    'VariableNames', {'grupo','muestra','tiempo_s','npulsos','etiqueta','frecuencia_Hz'});
disp(tabla_eventos);
%plot(EEG.times,tabla_eventos.frecuencia_Hz);
plot(t_evento_grupo_s, frecuencia_grupo_Hz, 'o'); hold on;
stairs(t_evento_grupo_s, frecuencia_grupo_Hz);
figure(2);
stem(tabla_eventos.tiempo_s,tabla_eventos.frecuencia_Hz);
%%
L=length(EEG.times);
eventos_largo=zeros(1,L);
% k=1;
% for i=8326:L
%     if i==tabla_eventos.muestra(k)
%         eventos_largo(i)=tabla_eventos.frecuencia_Hz(k);
%          k=k+1;
%     end
%end
eventos_largo(tabla_eventos.muestra)=tabla_eventos.frecuencia_Hz;

hola=reshape(eventos_largo,[1024,76800/1024]);
reseeg=reshape(EEG.times,[1024,76800/1024]);
for i=31:33
    figure(i);
    stem(reseeg(:,i),hola(:,i));
end

%resta=tabla_eventos.muestra(i)