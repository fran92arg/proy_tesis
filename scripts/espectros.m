% function espectros(EEG1,obj_prueba)
EEG1=EEG;
obj_prueba=obj(1);
% recibe el eeg filtrado y el objeto con la tabla de eventos
% 20 eventos-> 20 filas, 10*256 columnas

% guardia: si ya existe ind_frec, la función ya se ejecutó sobre este objeto
% if ismember('ind_frec', obj_prueba.tabla_eventos.Properties.VariableNames)
%     error('espectros ya se ejecutó sobre este objeto: la fila descartada ya se eliminó');
% end

% copia local de la tabla sin el primer evento (se descarta).
% Desde acá la fila i de "tabla" corresponde al evento i de matriz_EEG,
% por lo que no hacen falta los +1, los (2:end) ni los nan iniciales.
tabla = obj_prueba.tabla_eventos;
cant_eventos = height(tabla);             %20 eventos de estimulacion
duracion_ventana=10*EEG1.srate; %10 segundos con fs=256 Hz
canal_interes=[4 5 13 14 21];
cant_canales=length(canal_interes);
%%
matriz_EEG = zeros(cant_eventos,duracion_ventana,cant_canales);
% el EEG se divide en ventanas de 10 segundos
% cada fila corresponde a un evento distinto, en orden temporal
% hay 2560 columnas en cada fila, 10*256 Hz
% se arma un arreglo de matrices, donde cada matriz es un canal distinto
% [P3 O1 P4 O2 Pz]
for k=1:cant_canales
    for i=1:cant_eventos
        matriz_EEG(i,:,k)=EEG1.data(canal_interes(k),tabla.muestra(i):tabla.muestra(i)+duracion_ventana-1);
    end
end
%% calculo de FFT
% 5 ventanas de 2 segundos en cada estimulo
Fs     = EEG1.srate;
N_puntos_2seg    = 2*Fs;                          % 512 muestras por ventana
n_ventanas = floor(duracion_ventana/N_puntos_2seg);                % 5 ventanas por evento
% Separar en ventanas: [nEv x N x nWin x nCh]
Xw = reshape(matriz_EEG, cant_eventos, N_puntos_2seg, n_ventanas, cant_canales);
Y  = fft(Xw, [], 2);                  % FFT sobre la dimensión 2
P2 = abs(Y/N_puntos_2seg);
P1 = P2(:, 1:N_puntos_2seg/2+1, :, :);
P1(:, 2:end-1, :, :) = 2*P1(:, 2:end-1, :, :);   % espectro unilateral
f  = Fs*(0:(N_puntos_2seg/2))/N_puntos_2seg;                  % 0 a 128 Hz, paso 0.5 Hz
% Promedio de las 5 ventanas: [nEv x 257 x nCh]
matriz_fft = reshape(mean(P1, 3), cant_eventos, N_puntos_2seg/2+1, cant_canales);
% matriz_fft(i, :, c) es el espectro de amplitud (promediado sobre las 5 ventanas) del evento i, canal c,
% con el eje de frecuencias f de 0 a 128 Hz en pasos de 0.5 Hz.
%% amplitud en la frecuencia de estimulación de cada evento
etiquetas = {'P3','O1','P4','O2','Pz'};
fe = tabla.frecuencia_Hz;                               % frecuencia de estimulación de cada evento
[~, indice] = min(abs(f(:).' - fe), [], 2);             % bin más cercano a cada frecuencia
tabla.ind_frec = indice;
for k = 1:cant_canales
    valor = zeros(cant_eventos, 1);
    for i = 1:cant_eventos
        valor(i) = matriz_fft(i, indice(i), k);
    end
    tabla.(['amp_' etiquetas{k}]) = valor;
end
%% se modifica el objeto recién al final, cuando todo el cálculo salió bien
obj_prueba.tabla_eventos = tabla;
obj_prueba.EEG = matriz_EEG;
obj_prueba.matriz_tf = matriz_fft;
% end