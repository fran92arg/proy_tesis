%function estructura=espectros(EEG,tabla_event)
% recibe el eeg filtrado y la tabla con los eventos
% 20 eventos-> 20 filas, 10*256 columnas
cant_eventos=length(tabla_pac.grupo)-1;   %20 eventos de estimulacion, el primero se descarta
duracion_ventana=10*EEG.srate; %10 segundos con fs=256 Hz

canal_interes=[4 5 13 14 21];  %[P3 O1 P4 O2 Pz]
cant_canales=length(canal_interes);
%%
matriz_EEG = zeros(cant_eventos,duracion_ventana,cant_canales);
% el EEG se divide en ventanas de 10 segundos
% cada fila corresponde a un evento distinto, en orden temporal
% hay 2560 columnas en cada fila, 10*256 Hz
% se arma un arreglo de matrices, donde cada matriz es un canal distinto
% [P3 O1 P4 O2 Pz]
for k=1:cant_canales
    for i=1:cant_eventos %2:eventos-1
        matriz_EEG(i,:,k)=EEG.data(canal_interes(k),tabla_pac.muestra(i+1):tabla_pac.muestra(i+1)+duracion_ventana-1);
    end
end
%% calculo de FFT
% 5 ventanas de 2 segundos en cada estimulo
Fs     = 256;
% matriz_EEG = double(matriz_EEG);
[cant_eventos, duracion_ventana, cant_canales] = size(matriz_EEG);

N_puntos_2seg    = 2*Fs;                          % 512 muestras por ventana
n_ventanas = floor(duracion_ventana/N_puntos_2seg);                % 5 ventanas por evento

% Separar en ventanas: [nEv x N x nWin x nCh]
Xw = reshape(matriz_EEG(:, 1:n_ventanas*N_puntos_2seg, :), cant_eventos, N_puntos_2seg, n_ventanas, cant_canales);

Y  = fft(Xw, [], 2);                  % FFT sobre la dimensión 2
P2 = abs(Y/N_puntos_2seg);
P1 = P2(:, 1:N_puntos_2seg/2+1, :, :);
P1(:, 2:end-1, :, :) = 2*P1(:, 2:end-1, :, :);   % espectro unilateral

f  = Fs*(0:(N_puntos_2seg/2))/N_puntos_2seg;                  % 0 a 128 Hz, paso 0.5 Hz

% Promedio de las 5 ventanas: [nEv x 257 x nCh]
matriz_fft = reshape(mean(P1, 3), cant_eventos, N_puntos_2seg/2+1, cant_canales);
figure;
% matriz_fft(i, :, c) es el espectro de amplitud (promediado sobre las 5 ventanas) del evento i, canal c, 
% con el eje de frecuencias f de 0 a 128 Hz en pasos de 0.5 Hz.
plot(f, squeeze(matriz_fft(4,:,3)));
xlabel('Frecuencia (Hz)'); ylabel('Amplitud');
grid on;


% %end
