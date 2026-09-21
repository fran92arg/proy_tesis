clear
clc
close all
eeglab;
%% rutas relativaas
% scriptDir   = fileparts(mfilename('fullpath'));
rutaScripts   = fileparts(mfilename('fullpath')); % me da la ruta actual del script que ejecuto
raizProy = fileparts(rutaScripts); % subo un nivel de la carpeta que obtuve antes
rutaData     = fullfile(raizProy, 'data'); %T oma el valor que tenga la variable 
% raizProy y le agrega 'data' como subcarpeta, uniendo ambas partes con el separador 
% correcto (segun windows o linux)
%SOLO FUNCIONAN AL CORRER CON F5
%%
rutaResult  = fullfile(raizProy, 'results');
eeglabRoot  = fullfile(raizProy, 'eeglab');
datos = dir(fullfile(rutaData, '*.edf')); % con esto cargo los nombres de los .edf 
% en una estructura
%% Cargar
aux=strcat(rutaData,'\');
aux=strcat(aux,datos.name);
EEG = pop_biosig(aux);
EEG=eeg_checkset(EEG);%verificar consistencia de la estructura
f_muestreo=EEG.srate;
%% butterworth pasaalto
EEG=pasaalto(EEG);

%% Pasabajos
EEG=pasabajo(EEG);

%% Filtro notch 50Hz
EEG=notch(EEG);

% %% Cleanline
% EEG = pop_cleanline(EEG, 'bandwidth', 1, ...
%     'chanlist', 1, ... %canales EEG, excluyendo el EKG
%     'computepower', 1, ...
%     'linefreqs', [50 100], ... % o [50 100] para incluir el armónico
%     'normSpectrum', 0, ...
%     'p', 0.01, ...
%     'plotfigures', 0, ...
%     'scanforlines', 1, ...
%     'sigtype', 'Channels', ...
%     'tau', 100, ...
%     'verb', 1, ...
%     'winsize', 6, ...
%     'winstep', 1);
% EEG=eeg_checkset(EEG)
% EEG=pop_saveset(EEG,'moreno_filtradocleanline.set','C:\Users\natyr\OneDrive\Escritorio')
% figure(4)
% %pwelch(EEG.data(1,:),hanning(1024),[], 2048,256); %señal de entrada, ventana(resolucion espectral o no me acuerdo),no superposiciónd de ventanas,cant de puntos,f muestreo señal
% periodogram(EEG.data(1,:),[],1024,256)
% 
% hold on;
% %pwelch(eeg_filt_lp(1,:),hanning(1024),[],2048,256);
% periodogram(eeg_filt_lp(1,:),[],1024,256)

%% ICA
EEG=ICA(EEG)
rutafiltrados= fullfile(raizProy,'Filtrados');
% EEG=pop_writeeeg(EEG,rutafiltrados,'TIPE','EDF');

