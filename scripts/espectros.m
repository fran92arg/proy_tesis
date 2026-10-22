function espectros(EEG1,obj)
% recibe el eeg filtrado y el objeto con la tabla de eventos
% la tabla ya no incluye el evento de inicio: 20 eventos -> 20 filas
% guarda el espectro de cada ventana de 2 s por separado (sin promediar)

tabla = obj.tabla_eventos;
cant_eventos = height(tabla);             % 20 eventos de estimulacion
duracion_ventana = 10*EEG1.srate;         % 10 segundos -> 2560 muestras a 256 Hz
canal_interes = [4 5 13 14 21];           % [P3 O1 P4 O2 Pz]
cant_canales = length(canal_interes);

%% segmentado: un evento por fila, 10 s por evento, un canal por página
% matriz_EEG: [nEv x 2560 x nCh]
matriz_EEG = zeros(cant_eventos,duracion_ventana,cant_canales);
for k = 1:cant_canales
    for i = 1:cant_eventos
        matriz_EEG(i,:,k) = EEG1.data(canal_interes(k), tabla.muestra(i):tabla.muestra(i)+duracion_ventana-1);
    end
end
%% FFT de cada ventana de 2 s
Fs = EEG1.srate;
N_puntos_2seg = 2*Fs;                                  % 512 muestras por ventana
n_ventanas = floor(duracion_ventana/N_puntos_2seg);    % 5 ventanas por evento
% Separar en ventanas: [nEv x N x nWin x nCh]
Xw = reshape(matriz_EEG(:, 1:n_ventanas*N_puntos_2seg, :), cant_eventos, N_puntos_2seg, n_ventanas, cant_canales);
Y  = fft(Xw, [], 2);                                   % FFT sobre la dimensión 2
P2 = abs(Y/N_puntos_2seg);
P1 = P2(:, 1:N_puntos_2seg/2+1, :, :);
P1(:, 2:end-1, :, :) = 2*P1(:, 2:end-1, :, :);         % espectro unilateral
f  = Fs*(0:(N_puntos_2seg/2))/N_puntos_2seg;           % 0 a Fs/2, paso 0.5 Hz

% Espectro de cada ventana, sin promediar: [nEv x 257 x nWin x nCh]
% matriz_fft(i,:,w,c) = espectro de amplitud del evento i, ventana w, canal c
matriz_fft = P1;
%% amplitud en la frecuencia de estimulación, por evento y por ventana
fe = tabla.frecuencia_Hz;                              % frecuencia de estimulación de cada evento
[~, indice] = min(abs(f(:).' - fe), [], 2);            % bin más cercano a cada frecuencia
tabla.ind_frec = indice;
etiquetas = {'P3','O1','P4','O2','Pz'};
tiempo={'_02','_24','_46','_68','_810'};
for k = 1:cant_canales
    valor = zeros(cant_eventos, n_ventanas);
  
    for i = 1:cant_eventos
        valor(i,:) = squeeze(matriz_fft(i, indice(i), :, k)).';   % [1 x nWin]
%         tabla.(['amp_' etiquetas{k} tiempo{k}]) = valor(i,k);
    end
    for w = 1:n_ventanas
        tabla.(['amp_' etiquetas{k} tiempo{w}]) = valor(:,w);     % una columna por canal y ventana
    end
end
%% se modifica el objeto recién al final, cuando todo el cálculo salió bien
obj.tabla_eventos = tabla;
obj.EEG = matriz_EEG;
obj.matriz_tf = matriz_fft;
obj.frec=f;
end