function snr_total(obj)
[cant_eventos,frec,cant_canales]=size(obj.matriz_tf);
% aux=obj.tabla_eventos(:,8:12);
etiquetas = {'snr_P3','snr_O1','snr_P4','snr_O2','snr_Pz'};
    for k = 1:cant_canales
    
        for i = 1:cant_eventos
            indice_amp=obj.tabla_eventos.ind_frec(i);
            indice_suma=obj.tabla_eventos.ind_frec(i)-4:obj.tabla_eventos.ind_frec(i)+4;
            suma(i)=sum(obj.matriz_tf(i,indice_suma,k))
            snr(i)=8*obj.matriz_tf(i,indice_amp,k)/(suma(i)-obj.matriz_tf(i,indice_amp,k))
            
        end
    obj.tabla_eventos.(etiquetas{k}) = snr';
    
    end
end