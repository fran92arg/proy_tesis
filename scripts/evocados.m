function [pico_amp, snr_valor] = evocados(EEG, freq_objetivo, canal_idx) %01=indice 5 02 indice 14
    % Parámetros de la señal
    Fs = EEG.srate; 
    senal = mean(EEG.data(canal_idx, :, :), 3); % Promedio de épocas en el tiempo
    N = length(senal);
    
    % Calcular FFT
    Y = fft(senal);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(N/2))/N;
    
    % 1. Encontrar el índice de la frecuencia objetivo
    [~, idx_freq] = min(abs(f - freq_objetivo));
    pico_amp = P1(idx_freq); % Amplitud en la frecuencia de estimulación
    
    % 2. Calcular el SNR (Relación Señal/Ruido)
    % Definimos frecuencias vecinas (ej. un radio de 1.5 Hz alrededor, excluyendo la diana)
    ancho_banda_ruido = 1.5; 
    idx_ruido = (f >= (freq_objetivo - ancho_banda_ruido) & f <= (freq_objetivo + ancho_banda_ruido));
    idx_ruido(idx_freq) = 0; % Excluir la frecuencia central
    
    % Evitar bordes o el componente DC (0 Hz)
    idx_ruido(f < 2) = 0; 
    
    ruido_promedio = mean(P1(idx_ruido));
    snr_valor = pico_amp / ruido_promedio; % SNR final
end
% Ejemplo para el canal Oz y estímulo de 40Hz
%[amp_40Hz, snr_40Hz] = analizar_biomarcador_ssvep(EEG, 40, 30);