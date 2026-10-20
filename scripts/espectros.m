function espectros(EEG1,obj)

% recibe el eeg filtrado y la tabla con los eventos
% 20 eventos-> 20 filas, 10*256 columnas
%nob=2;  %numero de objeto
cant_eventos=height(obj.tabla_eventos)-1;   %20 eventos de estimulacion, el primero se descarta
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
    for i=1:cant_eventos %2:eventos-1
        matriz_EEG(i,:,k)=EEG1.data(canal_interes(k),obj.tabla_eventos.muestra(i+1):obj.tabla_eventos.muestra(i+1)+duracion_ventana-1);
    end
end
obj.EEG=matriz_EEG;
%% calculo de FFT
% 5 ventanas de 2 segundos en cada estimulo
Fs     = 256;
% matriz_EEG = double(matriz_EEG);
[cant_eventos, duracion_ventana, cant_canales] = size(matriz_EEG);

N_puntos_2seg    = 2*Fs;                          % 512 muestras por ventana
n_ventanas = floor(duracion_ventana/N_puntos_2seg);                % 5 ventanas por evento

% Separar en ventanas: [nEv x N x nWin x nCh]
Xw = reshape(matriz_EEG(:, 1:n_ventanas*N_puntos_2seg, :), cant_eventos, N_puntos_2seg, n_ventanas, cant_canales);
% reshape(X,[M,N,P,...])
Y  = fft(Xw, [], 2);                  % FFT sobre la dimensión 2
P2 = abs(Y/N_puntos_2seg);
P1 = P2(:, 1:N_puntos_2seg/2+1, :, :);
P1(:, 2:end-1, :, :) = 2*P1(:, 2:end-1, :, :);   % espectro unilateral

f  = Fs*(0:(N_puntos_2seg/2))/N_puntos_2seg;                  % 0 a 128 Hz, paso 0.5 Hz

% Promedio de las 5 ventanas: [nEv x 257 x nCh]
matriz_fft = reshape(mean(P1, 3), cant_eventos, N_puntos_2seg/2+1, cant_canales);
% [fila,indice,valor]=zeros(20);
% for k=1:cant_canales
%     for i=1:cant_eventos %2:eventos-1
%         matriz_EEG(i,:,k)=EEG.data(canal_interes(k),obj(nob).tabla_eventos.muestra(i+1):obj(nob).tabla_eventos.muestra(i+1)+duracion_ventana-1);
%     end
% end
%
% 
etiquetas = {'P3','O1','P4','O2','Pz'};

fe = obj.tabla_eventos.frecuencia_Hz(2:end);
[~, indice] = min(abs(f(:).' - fe), [], 2);

obj.tabla_eventos.ind_frec = [nan; indice];

for k = 1:cant_canales
    valor = zeros(cant_eventos, 1);
    for i = 1:cant_eventos
        valor(i) = matriz_fft(i, indice(i), k);
    end
    obj.tabla_eventos.(['amp_' etiquetas{k}]) = [nan; valor];
end
obj.tabla_eventos(1,:)=[];
obj.matriz_tf=matriz_fft;
% figure(2);
% % matriz_fft(i, :, c) es el espectro de amplitud (promediado sobre las 5 ventanas) del evento i, canal c, 
% % con el eje de frecuencias f de 0 a 128 Hz en pasos de 0.5 Hz.
% % canal_interes=[4 5 13 14 21];  %[P3 O1 P4 O2 Pz]
% evento=11;
% canal=2;
% plot(f, squeeze(matriz_fft(evento,:,canal)),'b');
% xlabel('Frecuencia (Hz)'); ylabel('Amplitud');
% legend(obj(nob).nombre)
% grid on;
% hold on
% % title('Evento ',num2str(evento))

% %end
%%
%% ANÁLISIS SSVEP: potencia y SNR en la frecuencia de estimulación
% Requiere en el workspace:
%   matriz_EEG    : [eventos x 2560 x canales], canales en orden [P3 O1 P4 O2 Pz]
%   obj(nob).tabla_eventos con la columna frecuencia_Hz
%                 (la primera fila es el evento descartado, por eso se usa 2:end)

% %% 1. Datos de entrada
% % Frecuencia de estimulación de cada evento, alineada fila a fila con matriz_EEG
% frec_eventos = obj.tabla_eventos.frecuencia_Hz(1:end);
% 
% % Frecuencias de estimulación distintas (sin NaN), ordenadas de menor a mayor
% frecuencias_estimulo = unique(frec_eventos(~isnan(frec_eventos)));
% 
% %% 2. Parámetros del análisis espectral
% frec_muestreo = 256;                         % frecuencia de muestreo del EEG (Hz)
% orden_canales = [2 4 1 3 5];                 % reordena [P3 O1 P4 O2 Pz] -> [O1 O2 P3 P4 Pz]
% nombres_canales = {'O1','O2','P3','P4','Pz'};% nombres según orden_canales
% 
% largo_ventana = 4*frec_muestreo;             % ventana de Welch: 4 s = 1024 muestras
% solapamiento  = largo_ventana/2;             % 50 % de solapamiento entre ventanas
% puntos_fft    = largo_ventana;               % resolución = 256/1024 = 0.25 Hz
% 
% cant_frecuencias = numel(frecuencias_estimulo);   % cantidad de frecuencias distintas
% cant_canales     = numel(orden_canales);          % 5 canales
% cant_bins        = puntos_fft/2 + 1;              % puntos del espectro unilateral
% 
% %% 3. Preasignación de resultados
% potencia_estimulo = zeros(cant_frecuencias, cant_canales);              % PSD en f0
% snr_dB            = zeros(cant_frecuencias, cant_canales);              % SNR espectral (dB)
% psd_guardada      = zeros(cant_bins, cant_canales, cant_frecuencias);   % PSD completa por estímulo
% 
% %% 4. Cálculo para cada frecuencia de estimulación
% for idx_frec = 1:cant_frecuencias
%     frec_estimulo = frecuencias_estimulo(idx_frec);       % frecuencia actual (Hz)
% 
%     % Eventos (filas de matriz_EEG) estimulados a esta frecuencia
%     eventos_frec = find(frec_eventos == frec_estimulo);
% 
%     psd_promedio = 0;                                     % acumulador de PSD promedio
% 
%     % Promedia la PSD de todos los eventos con la misma frecuencia
%     for idx_evento = eventos_frec(:).'
%         % Señal del evento [2560 x 5], en double y con los canales reordenados
%         senal_evento = double(squeeze(matriz_EEG(idx_evento, :, orden_canales)));
% 
%         % PSD de Welch: [bins x canales]; eje_frec en Hz
%         [psd_evento, eje_frec] = pwelch(senal_evento, largo_ventana, solapamiento, puntos_fft, frec_muestreo);
% 
%         psd_promedio = psd_promedio + psd_evento/numel(eventos_frec);
%     end
% 
%     % Bin del espectro más cercano a la frecuencia de estimulación
%     [~, bin_estimulo] = min(abs(eje_frec - frec_estimulo));
% 
%     % Bins excluidos alrededor del pico (±0.5 Hz) para no contaminar el ruido con fuga espectral
%     bins_excluidos = round(0.5/(eje_frec(2) - eje_frec(1)));
% 
%     % Vecindario de ruido: ±1.5 Hz alrededor de f0, sin la zona del pico
%     mascara_ruido = (eje_frec >= frec_estimulo - 2) & (eje_frec <= frec_estimulo + 2);
%     mascara_ruido(bin_estimulo - bins_excluidos : bin_estimulo + bins_excluidos) = false;
% 
%     % Potencia en f0, un valor por canal [1 x 5]
%     potencia_estimulo(idx_frec, :) = psd_promedio(bin_estimulo, :);
% 
%     % SNR en dB: potencia en el pico / potencia media del ruido vecino
%     snr_dB(idx_frec, :) = 10*log10(psd_promedio(bin_estimulo, :) ./ mean(psd_promedio(mascara_ruido, :), 1));
% 
%     % Guarda la PSD completa para graficarla después
%     psd_guardada(:, :, idx_frec) = psd_promedio;
% end
% 
% %% 5. Gráfico: SNR y potencia en f0 por frecuencia de estimulación y canal
% etiquetas_frec = string(frecuencias_estimulo) + " Hz";     % etiquetas del eje x
% 
% figure('Name', 'Resultados SSVEP', 'Position', [100 100 1000 400]);
% 
% subplot(1,2,1);
% bar(snr_dB);                                  % un grupo de barras por frecuencia, una barra por canal
% set(gca, 'XTickLabel', etiquetas_frec);
% xlabel('Frecuencia de estimulación');
% ylabel('SNR (dB)');
% title('SNR espectral en f_0');
% legend(nombres_canales, 'Location', 'best');
% yline(0, 'k--');                              % 0 dB: el pico no sobresale del ruido vecino
% grid on;
% 
% subplot(1,2,2);
% bar(potencia_estimulo);
% set(gca, 'XTickLabel', etiquetas_frec);
% xlabel('Frecuencia de estimulación');
% ylabel('Potencia (\muV^2/Hz)');               % unidades correctas si el EEG está en µV
% title('Potencia en f_0');
% legend(nombres_canales, 'Location', 'best');
% grid on;
% 
% %% 6. Gráfico: PSD de un canal para cada frecuencia de estimulación
% canal_graficar = 1;                           % 1 = O1, 2 = O2, 3 = P3, 4 = P4, 5 = Pz
% 
% figure('Name', 'PSD por estímulo', 'Position', [100 100 1200 600]);
% for idx_frec = 1:cant_frecuencias
%     subplot(2, ceil(cant_frecuencias/2), idx_frec);
%     plot(eje_frec, 10*log10(psd_guardada(:, canal_graficar, idx_frec)));   % PSD en dB
%     xline(frecuencias_estimulo(idx_frec), 'r--');                          % marca f0
%     xlim([max(0, frecuencias_estimulo(idx_frec) - 5), frecuencias_estimulo(idx_frec) + 5]);   % zoom ±5 Hz
%     xlabel('Frecuencia (Hz)');
%     ylabel('PSD (dB/Hz)');
%     title(sprintf('%s, estímulo %.1f Hz', nombres_canales{canal_graficar}, frecuencias_estimulo(idx_frec)));
%     grid on;
% end
% 
% %% 7. Gráfico: PSD de todos los canales para un estímulo
% idx_frec = 1;                                 % primera frecuencia de estimulación
% 
% figure('Name', 'PSD todos los canales');
% plot(eje_frec, 10*log10(psd_guardada(:, :, idx_frec)));
% xline(frecuencias_estimulo(idx_frec), 'k--');
% xlim([0 40]); grid on;
% legend(nombres_canales);
% xlabel('Frecuencia (Hz)');
% ylabel('PSD (dB/Hz)');
% title(sprintf('PSD por canal, estímulo %.1f Hz', frecuencias_estimulo(idx_frec)));
end
