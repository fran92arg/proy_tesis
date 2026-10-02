
function estructura=espectros(EEG)
%   recibe el eeg filtrado y un arreglo con los indices de los canales
for i=1:8500

end

%%

% Gráfico
eventos2=reshape(sig,[ventana,length(sig)/ventana]);

epoca=10
   % for i=1:4
       P2 = abs(Y(:,epoca)/ventana);
    P1 = P2(1:ventana/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(ventana/2))/ventana;
    plot(f,P1,"LineWidth",3) 
title("Single-Sided Amplitude Spectrum of S(t)")
xlabel("f (Hz)")
ylabel("|P1(f)|")
hold on

   % end

%end
end