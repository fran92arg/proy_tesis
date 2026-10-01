function signal=eventos(EEG)
% Eventos (sin boundary)
tipos = {EEG.event.type};
keep  = ~strcmp(tipos, 'boundary');
idx   = round([EEG.event(keep).latency]);
tipos = tipos(keep);

% Códigos numéricos (si los tipos son texto, se mapean a 1..K)
cod = cellfun(@(x) double(str2double(string(x))), tipos);
if any(isnan(cod))
    cod = grp2idx(tipos)';
end

% Señal de eventos
sig = zeros(1, N);
sig(idx) = cod;
signal=sig;
end