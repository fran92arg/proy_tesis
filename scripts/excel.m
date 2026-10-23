clear
clc
load("objetos.mat");
res=table();
for i=1:length(obj)
    tabla=obj(i).tabla_eventos;
%     cod;
    for j=1:height(tabla)
%     tabla=renamevars(tabla,'grupo','codigo');
    codigo(j,:)=obj(i).nombre;
    end
    tabla=addvars(tabla,codigo,'before','grupo');
    tabla=removevars(tabla,[2:6,8]);
    obj(i).tabla_eventos=tabla;
end
% 
for i=1:length(obj)
    res=[res;obj(i).tabla_eventos];
end
writetable(res,'resultados_cba1.xlsx');
