
rutaResult  = fullfile(raizProy, 'results');
eeglabRoot  = fullfile(raizProy, 'eeglab');
datos = dir(fullfile(rutaData, '*.edf'));
EEG=pop_biosig(datos,'importevent','off');