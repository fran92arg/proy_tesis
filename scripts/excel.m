clear
clc
load("objetos.mat");
res=table();
M = readtable('codigos.txt');


for i=1:length(obj)
    tabla=obj(i).tabla_eventos;
%     cod;
    for k=1:height(M)
        if obj(i).nombre==string(M.Var1(k))
            obj(i).DC=str2double(string(M.Var3(k)));
        end
    end
    for j=1:height(tabla)
%     tabla=renamevars(tabla,'grupo','codigo');
    codigo(j,:)=obj(i).nombre;
    det(j,:)=obj(i).DC;
    end
    tabla=addvars(tabla,codigo,'before','grupo');
    tabla=addvars(tabla,det,'after','ind_frec');
    tabla=removevars(tabla,[2:6,8]);
    obj(i).tabla_eventos=tabla;
end
% 
for i=1:length(obj)
    res=[res;obj(i).tabla_eventos];
end
writetable(res,'resultados_cba1.xlsx');
