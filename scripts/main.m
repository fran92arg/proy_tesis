clear
clc
close all
eeglab nogui;
% doble precision
pop_editoptions('option_single', 0);
%% rutas relativas del proyecto
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
cant_archivos=length(datos);
%%
obj(cant_archivos)=pevocado;
%N=1;
%% Cargar los .edf
for i=1:cant_archivos
    obj(i).nombre=datos(i).name(1:end-4);
    aux=strcat(rutaData,'\');
    aux=strcat(aux,datos(i).name);
    EEG = pop_biosig(aux);
    EEG=eeg_checkset(EEG);%verificar consistencia de la estructura
    f_muestreo=EEG.srate;
    %% butterworth pasaalto
    EEG=pasaalto(EEG);
    EEG=eeg_checkset(EEG);%verificar consistencia de la estructura
    %% butterworth Pasabajos
    EEG=pasabajo(EEG);
    EEG=eeg_checkset(EEG);%verificar consistencia de la estructura
    %% Filtro notch 50Hz
    EEG=notch(EEG);
    EEG=eeg_checkset(EEG);%verificar consistencia de la estructura

    %% ICA
    EEG=ICA(EEG); 
    % guardamos el eeg en el objeto para usar fft luego
    obj(i).EEG=EEG.data;
    % agrega _f antes del nombre al nuevo archivo filtrado
    aux=strcat('f_',datos(i).name);
    rutafiltrados= fullfile(raizProy,'Filtrados');
    % outputFile = fullfile('C:\EEGData\Exports', 'my_exported_data.bdf');
    outputFile = fullfile(rutafiltrados, aux);
    % Save EEG to BDF format using pop_writeeeg
    try
        pop_writeeeg(EEG, outputFile, 'TYPE', 'EDF'); 
        fprintf('EEG filtrado guardado con éxito en: %s\n', outputFile);
    catch ME
        fprintf('Error al guardar EEG: %s\n', ME.message);
    end
    % guardamos la tabla de eventos limpia en el objeto
    obj(i).tabla_eventos=eventos(EEG);

end
%%
% savefile('objetos.mat');
save('objetos.mat',"obj")