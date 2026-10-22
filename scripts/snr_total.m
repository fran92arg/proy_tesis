% function snr_total(obj)
obj1=obj(1);
etiquetas = {'snr_P3','snr_O1','snr_P4','snr_O2','snr_Pz'};
tiempo={'_02','_24','_46','_68','_810'};
cant_canales=length(etiquetas);
cant_eventos=height(obj1.tabla_eventos);
n_ventanas=length(tiempo);
% w=1;
% nombre_col=cell(1,25);
% for i=1:5
%     for j=1:5
%         nombre_col{w}=[etiquetas{i} tiempo{j}];
%         w=w+1;
%     end
% end
% tabla_auxiliar=table(zeros(height(obj.tabla_eventos),length(etiquetas)*length(tiempo)));
% Espectro de cada ventana, sin promediar: [nEv x 257 x nWin x nCh]
% matriz_fft(i,:,w,c) = espectro de amplitud del evento i, ventana w, canal c
for k = 1:cant_canales
    valor = zeros(cant_eventos, n_ventanas);
    aux=1;
    for i = 1:cant_eventos
        %sacamos el indice de la frecuencia de estimulacion
        indice_amp=obj1.tabla_eventos.ind_frec(i);
        
        %un vector con los indices a sumar +/- 2 Hz
        indice_suma=obj1.tabla_eventos.ind_frec(i)-4:obj1.tabla_eventos.ind_frec(i)+4;
        %vector con amplitudes de cada ventana
        amp=squeeze(obj1.matriz_tf(i,indice_amp,:,k))';
        acumulador=obj1.matriz_tf(i,indice_suma,:,k);
        suma=squeeze(sum(acumulador))'; %sumatoria transpuesta, queda vector de 1x5
        valor(i,:)=8*amp./(suma-amp);
%         
    end
% etiquetas = {'snr_P3','snr_O1','snr_P4','snr_O2','snr_Pz'};
% tiempo={'_02','_24','_46','_68','_810'};

% obj.tabla_eventos = table((1:cant_grupos-1)', muestra_evento(2:end), t_evento_grupo_s(2:end)', ...
% pulsos_por_grupo(2:end)', etiqueta_grupo(2:end), frecuencia_grupo_Hz(2:end), ...
% 'VariableNames', {'grupo','muestra','tiempo_s','npulsos','etiqueta','frecuencia_Hz'});

    for w = 1:n_ventanas
        tabla.([etiquetas{k} tiempo{w}]) = valor(:,w);     % una columna por canal y ventana
%     nombre_col{w}=[etiquetas{k} tiempo{w}];
%         break
    end
%     tabla_snr(k)=struct2table(tabla());
end

% % aux=obj.tabla_eventos(:,8:12);
% etiquetas = {'snr_P3','snr_O1','snr_P4','snr_O2','snr_Pz'};
%     for k = 1:cant_canales
%     
%         for i = 1:cant_eventos
%             indice_amp=obj.tabla_eventos.ind_frec(i);
%             indice_suma=obj.tabla_eventos.ind_frec(i)-4:obj.tabla_eventos.ind_frec(i)+4;
%             suma(i)=sum(obj.matriz_tf(i,indice_suma,k))
%             snr(i)=8*obj.matriz_tf(i,indice_amp,k)/(suma(i)-obj.matriz_tf(i,indice_amp,k))
%             
%         end
%     obj.tabla_eventos.(etiquetas{k}) = snr';
%     
%     end
% end
% obj1.tabla_eventos.ind_frec
